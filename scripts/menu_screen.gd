class_name MenuScreen
extends Control

## Two-page picker. The top page has one big button per category; picking one opens its level
## list (with a Back button), one button per level with its range and how the student has done
## on it so far. The button fills like a bar: as far across as the share of facts tried, green for
## the % right and red for the % wrong. Rebuilt on every change so the numbers stay current. Coming back from a round
## lands on that round's category. The top page's corner button shows who's playing (picture and
## name) and opens the profile picker.

const Config := preload("res://data/config.gd")

var _title: Label
var _back: Button
var _profile: ProfileButton
var _list: VBoxContainer
## The category whose levels are showing; empty on the top page.
var category_id: StringName = &""

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
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", Config.FONT_TITLE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
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
	_back.pressed.connect(show_categories)
	add_child(_back)
	_profile = ProfileButton.new(60)
	_profile.custom_minimum_size = Vector2(150, 84)
	_profile.pressed.connect(GameState.to_profiles)
	add_child(_profile)
	# pinned to the top-right corner, growing leftwards to fit the name
	_profile.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	_profile.offset_top = 36
	_profile.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	GameState.menu_opened.connect(_on_menu_opened)

func _on_menu_opened() -> void:
	var cat: StringName = GameState.level_cfg.get("category", &"")
	if cat.is_empty():
		show_categories()
	else:
		show_levels(cat)

func show_categories() -> void:
	category_id = &""
	_title.text = "Math Flash Cards"
	_back.visible = false
	_profile.show_player(Profiles.current_name(), Profiles.picture_of(Profiles.current_id))
	_profile.visible = not _profile.text.is_empty()
	_clear_list()
	for cat in Categories.DATA:
		var btn := Button.new()
		btn.text = cat["name"]
		btn.add_theme_font_size_override("font_size", Config.FONT_HEADER + 10)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 140)
		btn.pressed.connect(show_levels.bind(cat["id"]))
		_list.add_child(btn)

func show_levels(id: StringName) -> void:
	category_id = id
	_title.text = Categories.category(id)["name"]
	_back.visible = true
	_profile.visible = false
	_clear_list()
	for n in range(1, Categories.level_count(id) + 1):
		_list.add_child(_level_button(Categories.level(id, n)))

func _clear_list() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

func _level_button(cfg: Dictionary) -> ProgressButton:
	var s := Stats.level_summary(cfg)
	var answered: int = s["right"] + s["wrong"]
	var btn := ProgressButton.new()
	btn.text = "Level %d  ·  %s\n%s" % [cfg["number"], cfg["hint"], _progress_text(s)]
	if answered > 0:
		var tried: float = float(s["seen"]) / s["facts"]
		btn.right = tried * s["right"] / answered
		btn.wrong = tried - btn.right
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 130)
	btn.pressed.connect(GameState.start_round.bind(cfg["category"], cfg["number"]))
	return btn

func _progress_text(s: Dictionary) -> String:
	var answered: int = s["right"] + s["wrong"]
	if answered == 0:
		return "New!"
	return "%d%% right  ·  %d of %d facts tried" % [roundi(100.0 * s["right"] / answered), s["seen"], s["facts"]]
