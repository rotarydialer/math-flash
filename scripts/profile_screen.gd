class_name ProfileScreen
extends Control

## Who's playing: a box to type a new player's name (up top, clear of the phone's keyboard), then
## one row per profile: a big button with their picture and name (the current one shows pressed
## in), and a Picture button to change it. Picking a name switches to that profile and opens the
## menu. A new player picks their picture straight away, then goes to the menu. Back only shows once
## someone has picked, and returns to the menu unchanged.
##
## Choosing a picture is an overlay: a grid of every picture, plus the plain initial for none.
## The Picture buttons and the overlay only appear if there are pictures to choose from.

const Config := preload("res://data/config.gd")

const ROW_HEIGHT := 140.0
const ROW_AVATAR := 104.0
const TILE := 190.0               # a picture in the grid
const TILE_COLUMNS := 3

var _back: Button
var _list: VBoxContainer
var _name_edit: LineEdit
var _add: Button
var _error: Label
var _picker: Control
var _picker_title: Label
var _grid: GridContainer
## The profile choosing a picture, and whether it was just made (then it plays once it's chosen).
var _picking_id := ""
var _picking_new := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.build()
	var box := _page_box(self)
	_title_label(box).text = "Who's playing?"
	box.add_child(_build_add_row())
	_error = Label.new()
	_error.add_theme_font_size_override("font_size", 28)
	_error.add_theme_color_override("font_color", Config.WRONG)
	_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_error)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 22)
	_scroll(box).add_child(_list)
	_back = _back_button(self, GameState.to_menu)
	_build_picker()
	GameState.profiles_opened.connect(refresh)

## The column every page lays out in, under the corner buttons.
func _page_box(parent: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 50
	box.offset_right = -50
	box.offset_top = 130
	box.offset_bottom = -40
	box.add_theme_constant_override("separation", 30)
	parent.add_child(box)
	return box

func _title_label(box: Container) -> Label:
	var title := Label.new()
	title.add_theme_font_size_override("font_size", Config.FONT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	return title

func _scroll(box: Container) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	return scroll

func _back_button(parent: Control, action: Callable) -> Button:
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(150, 84)
	back.position = Vector2(24, 36)
	back.pressed.connect(action)
	parent.add_child(back)
	return back

func _build_add_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "New player's name"
	_name_edit.max_length = Profiles.MAX_NAME_LENGTH
	_name_edit.custom_minimum_size = Vector2(0, 100)
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_submitted.connect(func(_text: String) -> void: add_player())
	_name_edit.text_changed.connect(func(_text: String) -> void: _error.text = "")
	row.add_child(_name_edit)
	_add = Button.new()
	_add.text = "Add"
	_add.custom_minimum_size = Vector2(150, 100)
	_add.pressed.connect(add_player)
	row.add_child(_add)
	return row

func _build_picker() -> void:
	_picker = Control.new()
	_picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picker.visible = false
	add_child(_picker)
	var bg := ColorRect.new()
	bg.color = Config.BACKGROUND
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picker.add_child(bg)
	var box := _page_box(_picker)
	_picker_title = _title_label(box)
	_picker_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_grid = GridContainer.new()
	_grid.columns = TILE_COLUMNS
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 22)
	_scroll(box).add_child(_grid)
	_back_button(_picker, refresh)

func refresh() -> void:
	_picker.visible = false
	_back.visible = not Profiles.current_id.is_empty()
	_name_edit.clear()
	_error.text = ""
	_clear(_list)
	var have_pictures := not Profiles.pictures().is_empty()
	for p in Profiles.all():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_list.add_child(row)
		var btn := ProfileButton.new(ROW_AVATAR)
		btn.show_player(p["name"], Profiles.picture_of(p["id"]))
		btn.add_theme_font_size_override("font_size", Config.FONT_HEADER + 10)
		btn.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.toggle_mode = true
		btn.button_pressed = p["id"] == Profiles.current_id
		btn.pressed.connect(GameState.select_profile.bind(p["id"]))
		row.add_child(btn)
		var pic := Button.new()
		pic.text = "Picture"
		pic.add_theme_font_size_override("font_size", 28)
		pic.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		pic.visible = have_pictures
		pic.pressed.connect(open_picker.bind(p["id"], false))
		row.add_child(pic)

## Makes a profile from the typed name. It picks a picture first if there are any, then plays.
func add_player() -> void:
	var problem := Profiles.name_problem(_name_edit.text)
	if not problem.is_empty():
		_error.text = problem
		return
	var id := Profiles.create(_name_edit.text)
	if Profiles.pictures().is_empty():
		GameState.select_profile(id)
	else:
		open_picker(id, true)

func open_picker(id: String, is_new: bool) -> void:
	_picking_id = id
	_picking_new = is_new
	var p := Profiles.find(id)
	_picker_title.text = "Pick a picture for %s" % p["name"]
	_clear(_grid)
	_grid.add_child(_tile(null, p["name"], "", p["picture"]))
	for file in Profiles.pictures():
		_grid.add_child(_tile(Profiles.picture_texture(file), p["name"], file, p["picture"]))
	_picker.visible = true

## One choice in the grid: a picture (or the plain initial, for none), pressed in if it's current.
func _tile(texture: Texture2D, player_name: String, file: String, current: String) -> Button:
	var tile := Button.new()
	tile.custom_minimum_size = Vector2(TILE, TILE)
	tile.toggle_mode = true
	tile.button_pressed = file == current
	tile.pressed.connect(_choose.bind(file))
	var avatar := Avatar.new()
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP]:
		avatar.set_offset(side, 16)
	for side in [SIDE_RIGHT, SIDE_BOTTOM]:
		avatar.set_offset(side, -16)
	avatar.initial = player_name.left(1)
	avatar.texture = texture
	tile.add_child(avatar)
	return tile

func _choose(file: String) -> void:
	Profiles.set_picture(_picking_id, file)
	if _picking_new:
		GameState.select_profile(_picking_id)
	else:
		refresh()

## Android's back gesture: close the picture grid, else back to the menu, else quit.
func go_back() -> void:
	if _picker.visible:
		refresh()
	elif not Profiles.current_id.is_empty():
		GameState.to_menu()
	else:
		get_tree().quit()

func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
