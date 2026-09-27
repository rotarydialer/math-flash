extends Node2D

## Headless end-to-end playtest: builds the real PlayScreen, then a bot plays one full round of
## every level in every category through the actual tap flow — tap the card, wait for the flip, press
## ✓ or ✗ at random — checking the counter, button states, the summary score and that Stats
## recorded every answer. It also walks the two-page menu (categories → levels → round → back) and
## the profile picker (first launch → add a player → switch players).
## Uses throwaway profiles so real progress isn't touched. Run with:
##   godot --headless --path . res://tests/Playtest.tscn
## Prints PLAYTEST PASSED / FAILED; exit code = number of failing checks.

const MAX_SETTLE_FRAMES := 300

var _failures := 0
var _checks := 0
var _play: PlayScreen
var _menu: MenuScreen
var _profiles: ProfileScreen

func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", msg)

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_profiles = ProfileScreen.new()
	layer.add_child(_profiles)
	_menu = MenuScreen.new()
	layer.add_child(_menu)
	_play = PlayScreen.new()
	layer.add_child(_play)
	_run.call_deferred()

func _run() -> void:
	_check_profiles()
	Stats.profile_id = "playtest"
	Stats.clear()
	_check_menu()
	for cat in Categories.DATA:
		for n in range(1, Categories.level_count(cat["id"]) + 1):
			await _play_level(cat["id"], n)
	Stats.clear()
	print("Checks: %d  Failures: %d" % [_checks, _failures])
	print("PLAYTEST PASSED" if _failures == 0 else "PLAYTEST FAILED")
	get_tree().quit(_failures)

func _play_level(category_id: StringName, n: int) -> void:
	GameState.start_round(category_id, n)
	var cfg := GameState.level_cfg
	var total := GameState.current_round.size()
	var before: Dictionary = Stats.level_summary(cfg)
	var expected_score := 0
	for i in total:
		_check(GameState.state == GameState.State.PLAYING, "L%d card %d: still playing" % [n, i])
		_check(_play._counter.text == "%d / %d" % [i + 1, total], "L%d card %d: counter reads right" % [n, i])
		_check(_play._right_btn.disabled and _play._wrong_btn.disabled, "L%d card %d: answer buttons wait for the flip" % [n, i])
		_play._right_btn.pressed.emit()
		_check(GameState.current_round.index == i, "L%d card %d: an early ✓ tap is ignored" % [n, i])
		_play._card.flip()
		await _settle()
		_check(_play._card.showing_answer, "L%d card %d: card shows its answer" % [n, i])
		_check(not _play._right_btn.disabled and not _play._wrong_btn.disabled, "L%d card %d: answer buttons wake up" % [n, i])
		var correct := randf() < 0.7
		if correct:
			expected_score += 1
		(_play._right_btn if correct else _play._wrong_btn).pressed.emit()
	_check(GameState.state == GameState.State.SUMMARY, "L%d: round ends in the summary" % n)
	_check(_play._overlay.visible, "L%d: summary overlay is up" % n)
	_check(_play._overlay_score.text == "%d / %d" % [expected_score, total], "L%d: summary shows the score" % n)
	_check(GameState.current_round.score() == expected_score, "L%d: round score matches the bot's answers" % n)
	var after: Dictionary = Stats.level_summary(cfg)
	_check(after["right"] - before["right"] == expected_score, "L%d: Stats counted every ✓" % n)
	_check(after["wrong"] - before["wrong"] == total - expected_score, "L%d: Stats counted every ✗" % n)
	print("%s level %d: %d / %d" % [category_id, n, expected_score, total])
	GameState.to_menu()
	_check(_menu.category_id == category_id, "L%d: leaving a round lands on its category's levels" % n)

## The top page lists categories; a category button opens its levels; Back returns.
func _check_menu() -> void:
	GameState.level_cfg = {}
	GameState.to_menu()
	_check(_menu.category_id.is_empty(), "menu opens on the category page")
	_check(_menu._list.get_child_count() == Categories.DATA.size(), "one button per category")
	_check(not _menu._back.visible, "no Back button on the top page")
	for i in Categories.DATA.size():
		var cat: Dictionary = Categories.DATA[i]
		(_menu._list.get_child(i) as Button).pressed.emit()
		_check(_menu.category_id == cat["id"], "the %s button opens %s" % [cat["name"], cat["name"]])
		_check(_menu._list.get_child_count() == Categories.level_count(cat["id"]), "%s: one button per level" % cat["name"])
		_check(_menu._back.visible, "%s: the level page has a Back button" % cat["name"])
		_menu._back.pressed.emit()
		_check(_menu.category_id.is_empty(), "%s: Back returns to the category page" % cat["name"])

## First launch asks who's playing; adding a name plays as them; the menu's name button switches
## players, and each player's answers are kept apart.
func _check_profiles() -> void:
	var path := "user://profiles_playtest.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Profiles.legacy_id = ""
	Profiles.load_file(path)
	GameState.boot()
	_check(GameState.state == GameState.State.PROFILES, "first launch opens the profile picker")
	_check(not _profiles._back.visible, "no Back before anyone has picked")
	_profiles._name_edit.text = "  "
	_profiles._add.pressed.emit()
	_check(Profiles.all().is_empty() and not _profiles._error.text.is_empty(), "a blank name is refused with a message")
	_profiles._name_edit.text = "Ada"
	_profiles._name_edit.text_submitted.emit("Ada")
	var ada := Profiles.current_id
	_check(Profiles.current_name() == "Ada", "adding a name plays as them")
	_check(Stats.profile_id == ada, "Stats follows the new profile")
	_check(GameState.state == GameState.State.MENU and _menu.category_id.is_empty(), "adding a player opens the menu")
	_check(_menu._profile.visible and _menu._profile.text == "Ada", "the menu shows who's playing")
	Stats.record(Problems.make(3, "+", 4), true)
	_menu._profile.pressed.emit()
	_check(GameState.state == GameState.State.PROFILES, "the name button opens the picker")
	_check(_profiles._back.visible, "the picker has Back once someone's playing")
	_check(_profiles._list.get_child_count() == 1, "one button per player")
	_profiles._name_edit.text = "ada"
	_profiles._add.pressed.emit()
	_check(Profiles.all().size() == 1 and not _profiles._error.text.is_empty(), "a duplicate name is refused with a message")
	_profiles._name_edit.text = "Bo"
	_profiles._add.pressed.emit()
	var bo := Profiles.current_id
	_check(bo != ada and _menu._profile.text == "Bo", "a second player can be added")
	_check(Stats.fact("3+4")["right"] == 0, "a new player starts with no history")
	GameState.to_profiles()
	_check((_profiles._list.get_child(1) as Button).button_pressed, "the picker marks who's playing")
	(_profiles._list.get_child(0) as Button).pressed.emit()
	_check(Profiles.current_id == ada and Stats.fact("3+4")["right"] == 1, "switching back brings back that player's history")
	for id in [ada, bo]:
		Stats.profile_id = id
		Stats.clear()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

## Wait for the flip to finish (bounded so a hang fails instead of freezing).
func _settle() -> void:
	for i in MAX_SETTLE_FRAMES:
		if not _play._card.flipping:
			return
		await get_tree().process_frame
	_check(false, "card never finished flipping (%d frames)" % MAX_SETTLE_FRAMES)
