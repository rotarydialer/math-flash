extends Node

## Autoload singleton. Owns which screen is up and the round in progress; broadcasts via signals
## so the screens stay decoupled. Answers are handed to the Stats autoload as they come in, filed
## under whichever profile the Profiles autoload says is playing.

signal profiles_opened()
signal menu_opened()
signal round_started(level_cfg: Dictionary, total: int)
signal card_shown(problem: Dictionary, index: int, total: int)
signal round_finished(score: int, total: int)

enum State { PROFILES, MENU, PLAYING, SUMMARY }

const Config := preload("res://data/config.gd")

var state: int = State.MENU
var level_cfg: Dictionary = {}
var current_round: FlashRound
## Level to open straight into at boot, from `-- --level=N` (0 = show the menu), in the
## category from `--category=id` (Addition if omitted).
var start_level := 0
var start_category: StringName = &"addition"

func _ready() -> void:
	_parse_cmdline()
	Profiles.selected.connect(_on_profile_selected)
	if not Profiles.current_id.is_empty():
		Stats.profile_id = Profiles.current_id

## `godot --path . -- --level=3` launches straight into Addition level 3;
## add `--category=subtraction` for another category (playtesting).
func _parse_cmdline() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			start_level = maxi(0, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--category="):
			start_category = StringName(arg.get_slice("=", 1))

## Main calls this once at boot. Nobody's picked a profile yet → ask who's playing.
func boot() -> void:
	if start_level > 0 and not Categories.category(start_category).is_empty():
		start_round(start_category, start_level)
	elif Profiles.current_id.is_empty():
		to_profiles()
	else:
		to_menu()

func to_profiles() -> void:
	state = State.PROFILES
	profiles_opened.emit()

## Switch who's playing and open the menu on its top page.
func select_profile(id: String) -> void:
	Profiles.select(id)
	level_cfg = {}
	to_menu()

## Delete a player and their history, then ask who's playing.
func delete_profile(id: String) -> void:
	Profiles.delete(id)
	if Stats.profile_id == id:
		Stats.clear()
	to_profiles()

func _on_profile_selected(id: String) -> void:
	Stats.profile_id = id

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
