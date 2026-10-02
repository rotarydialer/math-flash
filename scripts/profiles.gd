extends Node

## Autoload. The students who use this device and which one is playing. Each profile has an id,
## which names its stats file and never changes, a display name, and optionally a picture (a file
## name from picture_dir). Saved to user://profiles.cfg. Selecting a profile emits `selected`;
## GameState points Stats at it.

signal selected(id: String)

const StatsScript := preload("res://scripts/stats.gd")

const MAX_NAME_LENGTH := 12
const PICTURE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "svg"]

## History recorded before profiles existed; the first profile created takes it over so no
## progress is lost. Tests set this to "" so they never touch real history.
var legacy_id := "default"
var save_path := "user://profiles.cfg"
## Pictures to choose from. Gitignored, and packed into the build like any other resource.
## Tests point this at their own fixtures.
var picture_dir := "res://profiles/images/"
## Who's playing; "" until someone has picked a profile.
var current_id := ""
## [{id, name, picture}] in the order they were made; picture is "" for none.
var _list: Array = []

func _ready() -> void:
	load_file(save_path)

func load_file(path: String) -> void:
	save_path = path
	var cfg := ConfigFile.new()
	cfg.load(path)
	_list = Array(cfg.get_value("profiles", "list", []))
	# profiles saved before pictures existed have no picture field
	for p in _list:
		if not p.has("picture"):
			p["picture"] = ""
	current_id = str(cfg.get_value("profiles", "current", ""))
	if find(current_id).is_empty():
		current_id = ""

func all() -> Array:
	return _list.duplicate(true)

## The profile with this id, or {} if there isn't one.
func find(id: String) -> Dictionary:
	for p in _list:
		if p["id"] == id:
			return p
	return {}

func current_name() -> String:
	return find(current_id).get("name", "")

## Why this name can't be used, or "" if it can. Renaming passes the profile's own id, so it
## can keep its name or just change its capitals.
func name_problem(player_name: String, own_id := "") -> String:
	var n := player_name.strip_edges()
	if n.is_empty():
		return "Type a name first"
	if n.length() > MAX_NAME_LENGTH:
		return "That name is too long"
	for p in _list:
		if p["id"] != own_id and str(p["name"]).to_lower() == n.to_lower():
			return "%s is already here" % p["name"]
	return ""

## Adds a profile and returns its id, or "" if the name can't be used. Doesn't select it.
func create(player_name: String) -> String:
	if not name_problem(player_name).is_empty():
		return ""
	var id := _new_id()
	if _list.is_empty() and not legacy_id.is_empty() and FileAccess.file_exists(StatsScript.path_for(legacy_id)):
		id = legacy_id
	_list.append({"id": id, "name": player_name.strip_edges(), "picture": ""})
	_save()
	return id

## Renames a profile; false (and nothing changes) if the name can't be used.
func rename(id: String, player_name: String) -> bool:
	var p := find(id)
	if p.is_empty() or not name_problem(player_name, id).is_empty():
		return false
	p["name"] = player_name.strip_edges()
	_save()
	return true

## Removes a profile and its stats file for good. If it was playing, nobody is now.
func delete(id: String) -> void:
	var p := find(id)
	if p.is_empty():
		return
	_list.erase(p)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(StatsScript.path_for(id)))
	if current_id == id:
		current_id = ""
	_save()

func select(id: String) -> void:
	if find(id).is_empty():
		return
	current_id = id
	_save()
	selected.emit(id)

## The picture files there are to choose from, sorted.
func pictures() -> PackedStringArray:
	var out := PackedStringArray()
	for file in ResourceLoader.list_directory(picture_dir):
		if file.get_extension().to_lower() in PICTURE_EXTENSIONS:
			out.append(file)
	out.sort()
	return out

## A picture file's texture, or null for "" or a file that's no longer there.
func picture_texture(file: String) -> Texture2D:
	var path := picture_dir.path_join(file)
	if file.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

## A profile's picture, or null if it has none (or it's gone).
func picture_of(id: String) -> Texture2D:
	return picture_texture(find(id).get("picture", ""))

func set_picture(id: String, file: String) -> void:
	var p := find(id)
	if p.is_empty():
		return
	p["picture"] = file
	_save()

func _new_id() -> String:
	var id := ""
	while id.is_empty() or not find(id).is_empty() or id == legacy_id:
		id = "p%08x" % randi()
	return id

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profiles", "list", _list)
	cfg.set_value("profiles", "current", current_id)
	cfg.save(save_path)
