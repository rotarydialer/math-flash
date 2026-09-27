class_name ProfileScreen
extends Control

## Who's playing: a box to type a new player's name (up top, clear of the phone's keyboard), then
## one big button per profile (the current one shows pressed in). Picking a name, or adding one,
## switches to that profile and opens the menu. Back only shows once someone has picked, and
## returns to the menu unchanged.

const Config := preload("res://data/config.gd")

var _back: Button
var _list: VBoxContainer
var _name_edit: LineEdit
var _add: Button
var _error: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.build()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 50
	box.offset_right = -50
	box.offset_top = 130
	box.offset_bottom = -40
	box.add_theme_constant_override("separation", 30)
	add_child(box)
	var title := Label.new()
	title.text = "Who's playing?"
	title.add_theme_font_size_override("font_size", Config.FONT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_build_add_row())
	_error = Label.new()
	_error.add_theme_font_size_override("font_size", 28)
	_error.add_theme_color_override("font_color", Config.WRONG)
	_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_error)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 22)
	scroll.add_child(_list)
	_back = Button.new()
	_back.text = "Back"
	_back.custom_minimum_size = Vector2(150, 84)
	_back.position = Vector2(24, 36)
	_back.pressed.connect(GameState.to_menu)
	add_child(_back)
	GameState.profiles_opened.connect(refresh)

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

func refresh() -> void:
	_back.visible = not Profiles.current_id.is_empty()
	_name_edit.clear()
	_error.text = ""
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for p in Profiles.all():
		var btn := Button.new()
		btn.text = p["name"]
		btn.add_theme_font_size_override("font_size", Config.FONT_HEADER + 10)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 140)
		btn.toggle_mode = true
		btn.button_pressed = p["id"] == Profiles.current_id
		btn.pressed.connect(GameState.select_profile.bind(p["id"]))
		_list.add_child(btn)

## Makes a profile from the typed name and starts playing as it.
func add_player() -> void:
	var problem := Profiles.name_problem(_name_edit.text)
	if not problem.is_empty():
		_error.text = problem
		return
	GameState.select_profile(Profiles.create(_name_edit.text))
