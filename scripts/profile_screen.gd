class_name ProfileScreen
extends Control

## Who's playing: a box to type a new player's name (up top, clear of the phone's keyboard), then
## one row per profile: a big button with their picture and name (the current one shows pressed
## in), and an Edit button. Picking a name switches to that profile and opens the menu. A new player
## picks their picture straight away, then goes to the menu. Back only shows once someone has
## picked, and returns to the menu unchanged.
##
## Two overlays sit on top. Edit: rename the player, change their picture, or delete them (after
## a confirm, since their progress goes too). The picture grid: every picture, plus the plain
## initial for none; it and the Change Picture button only appear if there are pictures.

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
var _editor: Control
var _editor_title: Label
var _editor_avatar: Avatar
var _rename_edit: LineEdit
var _rename_save: Button
var _rename_error: Label
var _change_picture: Button
var _delete: Button
var _confirm: VBoxContainer
var _confirm_label: Label
var _confirm_delete: Button
var _editing_id := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.build()
	var box := _page_box(self)
	_title_label(box).text = "Who's playing?"
	_build_add_row(box)
	_error = _error_label(box)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 22)
	_scroll(box).add_child(_list)
	_back = _back_button(self, GameState.to_menu)
	_build_editor()
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

func _error_label(box: Container) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Config.WRONG)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	return label

## A name box and its button, side by side.
func _name_row(box: Container, placeholder: String, button_text: String, action: Callable) -> LineEdit:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.max_length = Profiles.MAX_NAME_LENGTH
	edit.custom_minimum_size = Vector2(0, 100)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_submitted.connect(func(_text: String) -> void: action.call())
	row.add_child(edit)
	var btn := Button.new()
	btn.text = button_text
	btn.custom_minimum_size = Vector2(150, 100)
	btn.pressed.connect(action)
	row.add_child(btn)
	return edit

## A page that covers the list.
func _overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	var bg := ColorRect.new()
	bg.color = Config.BACKGROUND
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	return overlay

func _centered_button(box: Container, label: String, action: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(360, 100)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(action)
	box.add_child(btn)
	return btn

func _warning_ink(btn: Button) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		btn.add_theme_color_override(state, Config.WRONG)

func _back_button(parent: Control, action: Callable) -> Button:
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(150, 84)
	back.position = Vector2(24, 36)
	back.pressed.connect(action)
	parent.add_child(back)
	return back

func _build_add_row(box: Container) -> void:
	_name_edit = _name_row(box, "New player's name", "Add", add_player)
	_name_edit.text_changed.connect(func(_text: String) -> void: _error.text = "")
	_add = _name_edit.get_parent().get_child(1) as Button

func _build_editor() -> void:
	_editor = _overlay()
	var box := _page_box(_editor)
	_editor_title = _title_label(box)
	_editor_avatar = Avatar.new()
	_editor_avatar.custom_minimum_size = Vector2(0, 180)
	box.add_child(_editor_avatar)
	_rename_edit = _name_row(box, "Name", "Save", save_rename)
	_rename_edit.text_changed.connect(func(_text: String) -> void: _rename_error.text = "")
	_rename_save = _rename_edit.get_parent().get_child(1) as Button
	_rename_error = _error_label(box)
	_change_picture = _centered_button(box, "Change Picture", func() -> void: open_picker(_editing_id, false))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_delete = _centered_button(box, "Delete", _ask_delete)
	_warning_ink(_delete)
	_confirm = VBoxContainer.new()
	_confirm.add_theme_constant_override("separation", 24)
	_confirm.visible = false
	box.add_child(_confirm)
	_confirm_label = Label.new()
	_confirm_label.add_theme_font_size_override("font_size", 30)
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm.add_child(_confirm_label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	_confirm.add_child(buttons)
	for spec in [["Keep", _cancel_delete], ["Delete", func() -> void: GameState.delete_profile(_editing_id)]]:
		var btn := Button.new()
		btn.text = spec[0]
		btn.custom_minimum_size = Vector2(240, 100)
		btn.pressed.connect(spec[1])
		buttons.add_child(btn)
	_confirm_delete = buttons.get_child(1) as Button
	_warning_ink(_confirm_delete)
	_back_button(_editor, refresh)

func _build_picker() -> void:
	_picker = _overlay()
	var box := _page_box(_picker)
	_picker_title = _title_label(box)
	_picker_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_grid = GridContainer.new()
	_grid.columns = TILE_COLUMNS
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 22)
	_scroll(box).add_child(_grid)
	_back_button(_picker, _close_picker)

func refresh() -> void:
	_picker.visible = false
	_editor.visible = false
	_back.visible = not Profiles.current_id.is_empty()
	_name_edit.clear()
	_error.text = ""
	_clear(_list)
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
		var edit := Button.new()
		edit.text = "Edit"
		edit.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		edit.pressed.connect(open_editor.bind(p["id"]))
		row.add_child(edit)

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

func open_editor(id: String) -> void:
	_editing_id = id
	var p := Profiles.find(id)
	_editor_title.text = "Edit %s" % p["name"]
	_editor_avatar.initial = str(p["name"]).left(1)
	_editor_avatar.texture = Profiles.picture_of(id)
	_rename_edit.text = p["name"]
	_rename_error.text = ""
	_change_picture.visible = not Profiles.pictures().is_empty()
	_delete.text = "Delete %s" % p["name"]
	_cancel_delete()
	_picker.visible = false
	_editor.visible = true

func save_rename() -> void:
	var problem := Profiles.name_problem(_rename_edit.text, _editing_id)
	if not problem.is_empty():
		_rename_error.text = problem
		return
	Profiles.rename(_editing_id, _rename_edit.text)
	refresh()

func _ask_delete() -> void:
	_confirm_label.text = "Delete %s and all their progress? This can't be undone." % Profiles.find(_editing_id)["name"]
	_delete.visible = false
	_confirm.visible = true

func _cancel_delete() -> void:
	_confirm.visible = false
	_delete.visible = true

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
		open_editor(_picking_id)

## Back from the grid: a new player lands in the list; otherwise back to editing them.
func _close_picker() -> void:
	if _picking_new:
		refresh()
	else:
		open_editor(_picking_id)

## Android's back gesture steps back one page: delete confirm → editor → list → menu (or quit, if
## nobody's picked yet).
func go_back() -> void:
	if _picker.visible:
		_close_picker()
	elif _editor.visible and _confirm.visible:
		_cancel_delete()
	elif _editor.visible:
		refresh()
	elif not Profiles.current_id.is_empty():
		GameState.to_menu()
	else:
		get_tree().quit()

func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
