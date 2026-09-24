class_name UiTheme
extends RefCounted

## The shared look for buttons and labels: big, rounded, high-contrast, finger-sized.
## Screens set `theme = UiTheme.build()` on their root so every child inherits it.

const Config := preload("res://data/config.gd")

const BUTTON := Color("ffffff")
const BUTTON_HOVER := Color("f4f7fc")
const BUTTON_PRESSED := Color("d6e2f5")
const BUTTON_EDGE := Color("9fb4d6")

static var _theme: Theme

static func build() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.set_color("font_color", "Label", Config.INK)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color"]:
		_theme.set_color(state, "Button", Config.INK)
	_theme.set_font_size("font_size", "Button", Config.FONT_BUTTON)
	_theme.set_stylebox("normal", "Button", _box(BUTTON))
	_theme.set_stylebox("hover", "Button", _box(BUTTON_HOVER))
	_theme.set_stylebox("pressed", "Button", _box(BUTTON_PRESSED))
	_theme.set_stylebox("hover_pressed", "Button", _box(BUTTON_PRESSED))
	_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	return _theme

static func _box(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = BUTTON_EDGE
	box.set_border_width_all(3)
	box.border_width_bottom = 7
	box.set_corner_radius_all(24)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	return box
