extends SceneTree

## Headless tests for problem generation, rounds and stats. Run with:
##   godot --headless --path . --script res://tests/test_problems.gd
## Exit code = number of failing checks (0 = all passed).

const Config := preload("res://data/config.gd")
const StatsScript := preload("res://scripts/stats.gd")

var _failures := 0
var _checks := 0

func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", msg)

func _initialize() -> void:
	print("Running problems tests...")
	_test_answer()
	_test_level_lookup()
	_test_level_facts()
	_test_regrouping()
	_test_deal()
	_test_deal_small_level()
	_test_round()
	_test_stats()
	print("Checks: %d  Failures: %d" % [_checks, _failures])
	if _failures == 0:
		print("ALL TESTS PASSED")
	quit(_failures)

func _test_answer() -> void:
	var p := Problems.make(3, "+", 4)
	_check(p["answer"] == 7, "3 + 4 = 7")
	_check(p["key"] == "3+4", "fact key is compact and order-sensitive")
	_check(Problems.make(4, "+", 3)["key"] != p["key"], "4+3 is filed separately from 3+4")

func _test_level_lookup() -> void:
	var cfg := Categories.level(&"addition", 2)
	_check(cfg["op"] == "+" and cfg["number"] == 2, "level config carries its op and number")
	_check(cfg["category"] == &"addition", "level config carries its category id")
	_check(Categories.level(&"addition", 99)["number"] == Categories.level_count(&"addition"),
		"out-of-range level clamps to the last")
	_check(Categories.level(&"nope", 1).is_empty(), "unknown category gives an empty config")

## Every level's facts respect its ranges and limits, and every answer is right.
func _test_level_facts() -> void:
	for n in range(1, Categories.level_count(&"addition") + 1):
		var cfg := Categories.level(&"addition", n)
		var facts := Problems.all_facts(cfg)
		_check(not facts.is_empty(), "level %d has facts" % n)
		var ok := true
		var keys := {}
		for p in facts:
			ok = ok and p["a"] >= cfg["a"][0] and p["a"] <= cfg["a"][1]
			ok = ok and p["b"] >= cfg["b"][0] and p["b"] <= cfg["b"][1]
			ok = ok and p["answer"] == p["a"] + p["b"]
			if cfg.has("max_result"):
				ok = ok and p["answer"] <= cfg["max_result"]
			if cfg.get("no_regroup", false):
				ok = ok and p["a"] % 10 + p["b"] <= 9
			keys[p["key"]] = true
		_check(ok, "level %d facts are in range with correct answers" % n)
		_check(keys.size() == facts.size(), "level %d facts are all distinct" % n)
	_check(Problems.all_facts(Categories.level(&"addition", 1)).size() == 21, "sums to 5 is 21 facts")
	_check(Problems.all_facts(Categories.level(&"addition", 2)).size() == 66, "sums to 10 is 66 facts")
	_check(Problems.all_facts(Categories.level(&"addition", 3)).size() == 121, "0..10 + 0..10 is 121 facts")

func _test_regrouping() -> void:
	_check(not Problems._regroups(23, 4), "23 + 4 needs no carry")
	_check(Problems._regroups(27, 4), "27 + 4 carries")
	_check(not Problems._regroups(90, 9), "90 + 9 needs no carry")

func _test_deal() -> void:
	var cfg := Categories.level(&"addition", 3)
	var a := Problems.deal(cfg, Config.DECK_SIZE, 7)
	var b := Problems.deal(cfg, Config.DECK_SIZE, 7)
	_check(a.size() == Config.DECK_SIZE, "deal returns a full deck")
	_check(str(a) == str(b), "same seed deals the same deck")
	_check(str(a) != str(Problems.deal(cfg, Config.DECK_SIZE, 8)), "different seeds deal different decks")
	var keys := {}
	for p in a:
		keys[p["key"]] = true
	_check(keys.size() == a.size(), "no fact repeats within a deck")

func _test_deal_small_level() -> void:
	var cfg := {"op": "+", "a": [0, 1], "b": [0, 1]}
	var deck := Problems.deal(cfg, 20, 1)
	_check(deck.size() == 4, "a level smaller than the deck deals each fact once")

func _test_round() -> void:
	var r := FlashRound.new(Problems.deal(Categories.level(&"addition", 1), 5, 3))
	_check(r.size() == 5 and r.index == 0 and not r.is_done(), "a new round starts at card 0")
	var first := r.current()
	r.record(true)
	_check(r.current() != first, "recording an answer moves to the next card")
	r.record(false)
	r.record(true)
	r.record(true)
	r.record(false)
	_check(r.is_done() and r.current().is_empty(), "the round ends after the last card")
	_check(r.score() == 3, "score counts the right answers")
	r.record(true)
	_check(r.results.size() == 5, "answers after the end are ignored")

## Stats files each answer per fact and survives a reload from disk.
func _test_stats() -> void:
	var stats := StatsScript.new()
	stats.profile_id = "unit_test"
	stats.clear()
	var p := Problems.make(3, "+", 4)
	stats.record(p, true)
	stats.record(p, false)
	stats.record(p, true)
	var reloaded := StatsScript.new()
	reloaded.profile_id = "unit_test"
	var f: Dictionary = reloaded.fact("3+4")
	_check(f["right"] == 2 and f["wrong"] == 1, "tallies survive a reload")
	_check(f["recent"] == [true, false, true], "recent answers are kept in order")
	_check(f["last_seen"] > 0, "last_seen is stamped")
	_check(reloaded.fact("5+5")["right"] == 0, "an unseen fact reads as zeroes")
	for i in Config.RECENT_HISTORY + 5:
		stats.record(p, false)
	_check(stats.fact("3+4")["recent"].size() == Config.RECENT_HISTORY, "recent history is capped")
	var summary: Dictionary = stats.level_summary(Categories.level(&"addition", 2))
	_check(summary["seen"] == 1 and summary["right"] == 2, "level summary totals the facts in the level")
	var other := StatsScript.new()
	other.profile_id = "unit_test_other"
	_check(other.fact("3+4")["right"] == 0, "profiles keep separate histories")
	stats.clear()
	stats.free()
	reloaded.free()
	other.free()
