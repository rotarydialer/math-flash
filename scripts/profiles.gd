extends Node

## Autoload. The students who use this device and which one is playing. Each profile has an id,
## which names its stats file and never changes, and a display name. Saved to
## user://profiles.cfg. Selecting a profile emits `selected`; GameState points Stats at it.

signal selected(id: String)

const StatsScript := preload("res://scripts/stats.gd")

const MAX_NAME_LENGTH := 12

## History recorded before profiles existed; the first profile created takes it over so no
## progress is lost. Tests set this to "" so they never touch real history.
var legacy_id := "default"
var save_path := "user://profiles.cfg"
## Who's playing; "" until someone has picked a profile.
var current_id := ""
## [{id, name}] in the order they were made.
var _list: Array = []

func _ready() -> void:
	load_file(save_path)

func load_file(path: String) -> void:
	save_path = path
	var cfg := ConfigFile.new()
	cfg.load(path)
	_list = Array(cfg.get_value("profiles", "list", []))
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

## Why this name can't be used for a new profile, or "" if it can.
func name_problem(player_name: String) -> String:
	var n := player_name.strip_edges()
	if n.is_empty():
		return "Type a name first"
	if n.length() > MAX_NAME_LENGTH:
		return "That name is too long"
	for p in _list:
		if str(p["name"]).to_lower() == n.to_lower():
			return "%s is already here" % p["name"]
	return ""

## Adds a profile and returns its id, or "" if the name can't be used. Doesn't select it.
func create(player_name: String) -> String:
	if not name_problem(player_name).is_empty():
		return ""
	var id := _new_id()
	if _list.is_empty() and not legacy_id.is_empty() and FileAccess.file_exists(StatsScript.path_for(legacy_id)):
		id = legacy_id
	_list.append({"id": id, "name": player_name.strip_edges()})
	_save()
	return id

func select(id: String) -> void:
	if find(id).is_empty():
		return
	current_id = id
	_save()
	selected.emit(id)

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
