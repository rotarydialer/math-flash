class_name ProgressButton
extends Button

## A button that fills from the left like a bar behind its text: first `right` of the way across
## in Config.PROGRESS_RIGHT, then `wrong` more in Config.PROGRESS_WRONG (both fractions of the full
## width), leaving the rest clear. The level list uses it for how much of the level has been tried
## and how those answers went.
##
## A button draws its text in the same pass as its background, so there's no room to slip a bar
## between them. Instead the button's own backgrounds are swapped for empty ones (keeping their
## margins), and a child drawn behind the button paints the real background and then the bar.

const Config := preload("res://data/config.gd")

const STATES := ["normal", "hover", "pressed", "hover_pressed"]

var right := 0.0:
	set(value):
		right = clampf(value, 0.0, 1.0)
		_backdrop.queue_redraw()
var wrong := 0.0:
	set(value):
		wrong = clampf(value, 0.0, 1.0)
		_backdrop.queue_redraw()

var _backdrop: Control
## The theme's background for each state, which the backdrop draws in the button's place.
var _boxes := {}

func _init() -> void:
	_backdrop = Control.new()
	_backdrop.show_behind_parent = true
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.draw.connect(_draw_backdrop)
	add_child(_backdrop)
	# hovering or pressing redraws the button; the backdrop follows suit
	draw.connect(_backdrop.queue_redraw)

func _ready() -> void:
	for state in STATES:
		var box := get_theme_stylebox(state)
		_boxes[state] = box
		var empty := StyleBoxEmpty.new()
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			empty.set_content_margin(side, box.get_content_margin(side))
		add_theme_stylebox_override(state, empty)

func _draw_backdrop() -> void:
	if _boxes.is_empty():
		return
	var box: StyleBox = _boxes[_state()]
	var rect := Rect2(Vector2.ZERO, size)
	_backdrop.draw_style_box(box, rect)
	var radius := 0
	var flat := box as StyleBoxFlat
	if flat:
		# the bar sits inside the border, its outer corners rounded to match
		rect = rect.grow_individual(-flat.border_width_left, -flat.border_width_top,
			-flat.border_width_right, -flat.border_width_bottom)
		radius = maxi(0, flat.corner_radius_top_left - flat.border_width_left)
	var start := 0.0
	for segment in [[right, Config.PROGRESS_RIGHT], [wrong, Config.PROGRESS_WRONG]]:
		var end := minf(start + segment[0], 1.0)
		if end > start:
			var fill := StyleBoxFlat.new()
			fill.bg_color = segment[1]
			if start == 0.0:
				fill.corner_radius_top_left = radius
				fill.corner_radius_bottom_left = radius
			if end >= 1.0:
				fill.corner_radius_top_right = radius
				fill.corner_radius_bottom_right = radius
			_backdrop.draw_style_box(fill, Rect2(rect.position.x + rect.size.x * start, rect.position.y,
				rect.size.x * (end - start), rect.size.y))
		start = end

func _state() -> String:
	match get_draw_mode():
		DRAW_PRESSED:
			return "pressed"
		DRAW_HOVER:
			return "hover"
		DRAW_HOVER_PRESSED:
			return "hover_pressed"
	return "normal"
