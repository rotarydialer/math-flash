extends Node

## Autoload singleton. Owns which screen is up and the round in progress; broadcasts via signals
## so the screens stay decoupled. Answers are handed to the Stats autoload as they come in.

signal menu_opened()
signal round_started(level_cfg: Dictionary, total: int)
signal card_shown(problem: Dictionary, index: int, total: int)
signal round_finished(score: int, total: int)

enum State { MENU, PLAYING, SUMMARY }

const Config := preload("res://data/config.gd")

var state: int = State.MENU
var level_cfg: Dictionary = {}
var current_round: FlashRound
## Level to open straight into at boot, from `-- --level=N` (0 = show the menu).
var start_level := 0

func _ready() -> void:
	_parse_cmdline()

## `godot --path . -- --level=3` launches straight into Addition level 3 (playtesting).
func _parse_cmdline() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			start_level = maxi(0, int(arg.get_slice("=", 1)))

## Main calls this once at boot.
func boot() -> void:
	if start_level > 0:
		start_round(&"addition", start_level)
	else:
		to_menu()

func to_menu() -> void:
	state = State.MENU
	menu_opened.emit()

func start_round(category_id: StringName, level_number: int) -> void:
	level_cfg = Categories.level(category_id, level_number)
	current_round = FlashRound.new(Problems.deal(level_cfg, Config.DECK_SIZE, randi()))
	state = State.PLAYING
	round_started.emit(level_cfg, current_round.size())
	_show_card()

func play_again() -> void:
	start_round(level_cfg["category"], level_cfg["number"])

## The player marked the current card right or wrong.
func answer(correct: bool) -> void:
	if state != State.PLAYING:
		return
	Stats.record(current_round.current(), correct)
	current_round.record(correct)
	if current_round.is_done():
		state = State.SUMMARY
		round_finished.emit(current_round.score(), current_round.size())
	else:
		_show_card()

func _show_card() -> void:
	card_shown.emit(current_round.current(), current_round.index, current_round.size())
