class_name FlashCard
extends Control

## One flash card, drawn in code. Front: the problem. Tap it and it flips to show the answer.
## Tapping the answer side does nothing — the ✓ / ✗ buttons move things on from there.

signal flipped()

const Config := preload("res://data/config.gd")

var problem: Dictionary = {}
var showing_answer := false
var flipping := false
var _tween: Tween

func _ready() -> void:
	size = Config.CARD_SIZE
	pivot_offset = size / 2.0
	position = Vector2(Config.VIEWPORT_W / 2.0, Config.CARD_CENTER_Y) - pivot_offset
	mouse_filter = Control.MOUSE_FILTER_STOP

## Deal a new problem face up, popping it in.
func show_problem(p: Dictionary) -> void:
	problem = p
	showing_answer = false
	flipping = false
	_kill_tween()
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	queue_redraw()
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, Config.DEAL_TIME)
	_tween.tween_property(self, "modulate:a", 1.0, Config.DEAL_TIME * 0.6)

## Turn the card over to show the answer (no-op if it's already over or turning).
func flip() -> void:
	if showing_answer or flipping or problem.is_empty():
		return
	flipping = true
	_kill_tween()
	scale = Vector2.ONE
	modulate.a = 1.0
	var half := Config.FLIP_TIME / 2.0
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "scale:x", 0.0, half).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void:
		showing_answer = true
		queue_redraw())
	_tween.tween_property(self, "scale:x", 1.0, half).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func() -> void:
		flipping = false
		flipped.emit())

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		accept_event()
		flip()

func question_text() -> String:
	return "%d %s %d" % [problem["a"], problem["op"], problem["b"]]

func _draw() -> void:
	if problem.is_empty():
		return
	var rect := Rect2(Vector2.ZERO, size)
	var box := StyleBoxFlat.new()
	box.bg_color = Config.CARD_BACK if showing_answer else Config.CARD_FRONT
	box.border_color = Config.CARD_EDGE
	box.set_border_width_all(4)
	box.border_width_bottom = 12
	box.set_corner_radius_all(Config.CARD_RADIUS)
	box.shadow_color = Color(0, 0, 0, 0.12)
	box.shadow_size = 18
	box.shadow_offset = Vector2(0, 10)
	draw_style_box(box, rect)
	if showing_answer:
		_draw_centered(question_text() + " =", Config.FONT_CARD / 2, size.y * 0.26, Config.INK)
		_draw_centered(str(problem["answer"]), Config.FONT_CARD_ANSWER, size.y * 0.6, Config.ANSWER_INK)
	else:
		_draw_centered(question_text(), Config.FONT_CARD, size.y * 0.5, Config.INK)

## Draws one line of text centred horizontally with its visual middle at `mid_y`.
func _draw_centered(text: String, font_size: int, mid_y: float, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var baseline := mid_y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, color)
