class_name AnswerButton
extends Button

## Big round ✓ or ✗ button with the mark drawn in code (no font glyphs to go missing on a phone).

const Config := preload("res://data/config.gd")

var correct: bool

func _init(is_correct: bool) -> void:
	correct = is_correct
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Config.ANSWER_BUTTON_SIZE
	size = Config.ANSWER_BUTTON_SIZE

func _draw() -> void:
	var color := Config.RIGHT if correct else Config.WRONG
	if is_pressed() or button_pressed:
		color = color.darkened(0.15)
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = color.darkened(0.25)
	box.border_width_bottom = 10
	box.set_corner_radius_all(int(size.y / 2.0))
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var c := Vector2(size.x / 2.0, size.y / 2.0 - 4)
	var r := size.y * 0.24
	var w := size.y * 0.1
	if correct:
		draw_polyline(PackedVector2Array([c + Vector2(-r, 0), c + Vector2(-r * 0.3, r * 0.7),
			c + Vector2(r, -r * 0.7)]), Color.WHITE, w, true)
	else:
		draw_line(c + Vector2(-r, -r) * 0.8, c + Vector2(r, r) * 0.8, Color.WHITE, w, true)
		draw_line(c + Vector2(-r, r) * 0.8, c + Vector2(r, -r) * 0.8, Color.WHITE, w, true)
