class_name PlayScreen
extends Control

## The round itself: a top bar, the flash card, and the ✗ / ✓ buttons, which wake up only once the
## card is flipped. The end-of-round summary is an overlay on top. Driven by GameState signals.

const Config := preload("res://data/config.gd")

var _title: Label
var _counter: Label
var _card: FlashCard
var _wrong_btn: AnswerButton
var _right_btn: AnswerButton
var _overlay: Control
var _overlay_title: Label
var _overlay_score: Label
var _overlay_missed: Label
var _missed: Array[String] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.build()
	_build_top_bar()
	_card = FlashCard.new()
	add_child(_card)
	_card.flipped.connect(_on_flipped)
	_wrong_btn = _make_answer_button(false, Config.VIEWPORT_W * 0.28)
	_right_btn = _make_answer_button(true, Config.VIEWPORT_W * 0.72)
	_build_overlay()
	GameState.round_started.connect(_on_round_started)
	GameState.card_shown.connect(_on_card_shown)
	GameState.round_finished.connect(_on_round_finished)

func _build_top_bar() -> void:
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(150, 84)
	back.position = Vector2(24, 36)
	back.pressed.connect(GameState.to_menu)
	add_child(back)
	_title = _make_label("", Config.FONT_HEADER, Vector2(0, 150))
	_counter = Label.new()
	_counter.add_theme_font_size_override("font_size", Config.FONT_HEADER)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter.position = Vector2(Config.VIEWPORT_W - 224, 52)
	_counter.size = Vector2(200, 50)
	add_child(_counter)

## A full-width, centred label.
func _make_label(text: String, font_size: int, pos: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos
	label.size = Vector2(Config.VIEWPORT_W, font_size * 1.5)
	add_child(label)
	return label

func _make_answer_button(correct: bool, center_x: float) -> AnswerButton:
	var btn := AnswerButton.new(correct)
	btn.position = Vector2(center_x, Config.ANSWER_BUTTON_Y) - Config.ANSWER_BUTTON_SIZE / 2.0
	btn.pressed.connect(_on_answer.bind(correct))
	add_child(btn)
	return btn

func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Config.BACKGROUND
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 60
	box.offset_right = -60
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 32)
	_overlay.add_child(box)
	_overlay_title = _box_label(box, Config.FONT_TITLE)
	_overlay_score = _box_label(box, Config.FONT_CARD)
	_overlay_score.add_theme_color_override("font_color", Config.ANSWER_INK)
	_overlay_missed = _box_label(box, 30)
	_overlay_missed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for spec in [["Play Again", GameState.play_again], ["Levels", GameState.to_menu]]:
		var btn := Button.new()
		btn.text = spec[0]
		btn.custom_minimum_size = Vector2(360, 100)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(spec[1])
		box.add_child(btn)

func _box_label(box: Container, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	return label

func _set_answer_buttons(enabled: bool) -> void:
	for btn in [_wrong_btn, _right_btn]:
		btn.disabled = not enabled
		btn.modulate.a = 1.0 if enabled else Config.BUTTON_DISABLED_ALPHA

func _on_round_started(level_cfg: Dictionary, _total: int) -> void:
	_overlay.visible = false
	_missed.clear()
	_title.text = "%s · Level %d" % [level_cfg["category_name"], level_cfg["number"]]

func _on_card_shown(problem: Dictionary, index: int, total: int) -> void:
	_counter.text = "%d / %d" % [index + 1, total]
	_card.show_problem(problem)
	_set_answer_buttons(false)

func _on_flipped() -> void:
	_set_answer_buttons(true)

func _on_answer(correct: bool) -> void:
	if not _card.showing_answer:
		return
	if not correct:
		# non-breaking spaces keep each fact on one line when the list wraps
		_missed.append(("%s = %d" % [_card.question_text(), _card.problem["answer"]]).replace(" ", "\u00a0"))
	_set_answer_buttons(false)
	GameState.answer(correct)

func _on_round_finished(score: int, total: int) -> void:
	_overlay_title.text = "All done!" if score < total else "Perfect!"
	_overlay_score.text = "%d / %d" % [score, total]
	_overlay_missed.text = "Practice these:\n" + "      ".join(_missed) if not _missed.is_empty() else ""
	_overlay.visible = true
