class_name MenuScreen
extends Control

## Two-page picker. The top page has one big button per category; picking one opens its level
## list (with a Back button), one button per level with its range and how the student has done
## on it so far. Rebuilt on every change so the numbers stay current. Coming back from a round
## lands on that round's category.

const Config := preload("res://data/config.gd")

var _title: Label
var _back: Button
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
	GameState.menu_opened.connect(_on_menu_opened)

func _on_menu_opened() -> void:
	var cat: StringName = GameState.level_cfg.get("category", &"")
	if cat.is_empty():
		show_categories()
	else:
		show_levels(cat)

func show_categories() -> void:
	category_id = &""
	_title.text = "Math Flash"
	_back.visible = false
	_clear_list()
	for cat in Categories.DATA:
		var btn := Button.new()
		btn.text = "%s\n%d levels" % [cat["name"], cat["levels"].size()]
		btn.add_theme_font_size_override("font_size", Config.FONT_HEADER + 10)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 180)
		btn.pressed.connect(show_levels.bind(cat["id"]))
		_list.add_child(btn)

func show_levels(id: StringName) -> void:
	category_id = id
	_title.text = Categories.category(id)["name"]
	_back.visible = true
	_clear_list()
	for n in range(1, Categories.level_count(id) + 1):
		_list.add_child(_level_button(Categories.level(id, n)))

func _clear_list() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

func _level_button(cfg: Dictionary) -> Button:
	var btn := Button.new()
	btn.text = "Level %d  ·  %s\n%s" % [cfg["number"], cfg["hint"], _progress_text(cfg)]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 130)
	btn.pressed.connect(GameState.start_round.bind(cfg["category"], cfg["number"]))
	return btn

func _progress_text(cfg: Dictionary) -> String:
	var s := Stats.level_summary(cfg)
	var answered: int = s["right"] + s["wrong"]
	if answered == 0:
		return "New!"
	return "%d%% right  ·  %d of %d facts tried" % [roundi(100.0 * s["right"] / answered), s["seen"], s["facts"]]
