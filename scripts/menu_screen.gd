class_name MenuScreen
extends Control

## Level picker: one section per category, one big button per level with its range and how the
## student has done on it so far. Rebuilt every time it opens so the numbers stay current.

const Config := preload("res://data/config.gd")

var _list: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.build()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 50
	box.offset_right = -50
	box.offset_top = 70
	box.offset_bottom = -40
	box.add_theme_constant_override("separation", 30)
	add_child(box)
	var title := Label.new()
	title.text = "Math Flash"
	title.add_theme_font_size_override("font_size", Config.FONT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 22)
	scroll.add_child(_list)
	GameState.menu_opened.connect(_rebuild)

func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for cat in Categories.DATA:
		var header := Label.new()
		header.text = cat["name"]
		header.add_theme_font_size_override("font_size", Config.FONT_HEADER + 6)
		_list.add_child(header)
		for n in range(1, cat["levels"].size() + 1):
			_list.add_child(_level_button(Categories.level(cat["id"], n)))

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
