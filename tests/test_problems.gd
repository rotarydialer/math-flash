extends SceneTree

## Headless tests for problem generation, rounds, stats and profiles. Run with:
##   godot --headless --path . --script res://tests/test_problems.gd
## Exit code = number of failing checks (0 = all passed).

const Config := preload("res://data/config.gd")
const StatsScript := preload("res://scripts/stats.gd")
const ProfilesScript := preload("res://scripts/profiles.gd")

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
	_test_both_orders()
	_test_regrouping()
	_test_deal()
	_test_deal_small_level()
	_test_round()
	_test_stats()
	_test_profiles()
	print("Checks: %d  Failures: %d" % [_checks, _failures])
	if _failures == 0:
		print("ALL TESTS PASSED")
	quit(_failures)

func _test_answer() -> void:
	var p := Problems.make(3, "+", 4)
	_check(p["answer"] == 7, "3 + 4 = 7")
	_check(p["key"] == "3+4", "fact key is compact and order-sensitive")
	_check(Problems.make(4, "+", 3)["key"] != p["key"], "4+3 is filed separately from 3+4")
	var q := Problems.make(7, "-", 2)
	_check(q["answer"] == 5 and q["key"] == "7-2", "7 - 2 = 5, filed as 7-2")
	_check(Problems.text(q) == "7 − 2", "a card shows a true minus sign")
	_check(Problems.text(p) == "3 + 4", "a card shows the plus sign")
	var m := Problems.make(6, "*", 7)
	_check(m["answer"] == 42 and m["key"] == "6*7", "6 × 7 = 42, filed as 6*7")
	_check(Problems.text(m) == "6 × 7", "a card shows a times sign")
	var d := Problems.make(42, "/", 7)
	_check(d["answer"] == 6 and d["key"] == "42/7", "42 ÷ 7 = 6, filed as 42/7")
	_check(Problems.text(d) == "42 ÷ 7", "a card shows a division sign")

func _test_level_lookup() -> void:
	var cfg := Categories.level(&"addition", 2)
	_check(cfg["op"] == "+" and cfg["number"] == 2, "level config carries its op and number")
	_check(cfg["category"] == &"addition", "level config carries its category id")
	_check(Categories.level(&"addition", 99)["number"] == Categories.level_count(&"addition"),
		"out-of-range level clamps to the last")
	_check(Categories.level(&"nope", 1).is_empty(), "unknown category gives an empty config")

## Every level's facts respect its ranges and limits, and every answer is right.
func _test_level_facts() -> void:
	for cat in Categories.DATA:
		for n in range(1, Categories.level_count(cat["id"]) + 1):
			var cfg := Categories.level(cat["id"], n)
			var name := "%s %d" % [cat["name"], n]
			var facts := Problems.all_facts(cfg)
			_check(facts.size() >= Config.DECK_SIZE, "%s has at least a deck's worth of facts" % name)
			var ok := true
			var keys := {}
			for p in facts:
				var in_order := _in(p["a"], cfg["a"]) and _in(p["b"], cfg["b"])
				var swapped: bool = cfg.get("both_orders", false) and _in(p["b"], cfg["a"]) and _in(p["a"], cfg["b"])
				ok = ok and (in_order or swapped)
				ok = ok and p["answer"] == Problems.answer(p["a"], cfg["op"], p["b"])
				ok = ok and p["answer"] >= 0
				if cfg.has("max_result"):
					ok = ok and p["answer"] <= cfg["max_result"]
				if cfg.get("no_regroup", false):
					ok = ok and not Problems._regroups(p["a"], cfg["op"], p["b"])
				for skip in cfg.get("skip_numbers", []):
					ok = ok and p["a"] != skip and p["b"] != skip and p["answer"] != skip
				if cfg["op"] == "/":
					ok = ok and p["b"] != 0 and p["answer"] * p["b"] == p["a"]
				if cfg.get("regroup_only", false):
					ok = ok and Problems._regroups(p["a"], cfg["op"], p["b"])
				keys[p["key"]] = true
			_check(ok, "%s facts are in range with correct, non-negative answers" % name)
			_check(keys.size() == facts.size(), "%s facts are all distinct" % name)
	_check(Problems.all_facts(Categories.level(&"addition", 1)).size() == 21, "sums to 5 is 21 facts")
	_check(Problems.all_facts(Categories.level(&"addition", 2)).size() == 66, "sums to 10 is 66 facts")
	_check(Problems.all_facts(Categories.level(&"addition", 3)).size() == 121, "0..10 + 0..10 is 121 facts")
	# levels 4 and 5 split two-digit + one-digit exactly into no-carry and carry
	_check(Problems.all_facts(Categories.level(&"addition", 4)).size()
		+ Problems.all_facts(Categories.level(&"addition", 5)).size() == 90 * 9,
		"addition 4 and 5 together cover every two-digit + one-digit fact")
	# subtraction mirrors addition: each addition fact has exactly one take-away partner
	_check(Problems.all_facts(Categories.level(&"subtraction", 1)).size() == 21, "from 5 or less is 21 facts")
	_check(Problems.all_facts(Categories.level(&"subtraction", 2)).size() == 66, "from 10 or less is 66 facts")
	_check(Problems.all_facts(Categories.level(&"subtraction", 3)).size() == 121, "up to 20 − 10 is 121 facts")
	# 13 × 13 = 169, less the 25 facts with a 1 in them
	_check(Problems.all_facts(Categories.level(&"multiplication", 4)).size() == 144, "up to 12 × 12 without × 1 is 144 facts")
	# division mirrors multiplication: one fact per divisor × quotient
	_check(Problems.all_facts(Categories.level(&"division", 1)).size() == 22, "÷ 1, 2 is 22 facts")
	_check(Problems.all_facts(Categories.level(&"division", 3)).size() == 44, "÷ 6 to 9 is 44 facts")
	# divisors 2..12 × quotients 0 and 2..12
	_check(Problems.all_facts(Categories.level(&"division", 4)).size() == 132, "up to 144 ÷ 12 without 1s is 132 facts")
	_check(Problems.all_facts({"op": "/", "a": [0, 5], "b": [0, 0]}).is_empty(), "nothing is ever divided by zero")

## A times-table level deals both orders once each, and nothing outside its tables.
func _test_both_orders() -> void:
	var keys := {}
	for p in Problems.all_facts(Categories.level(&"multiplication", 1)):
		keys[p["key"]] = true
	_check(keys.has("7*2") and keys.has("2*7"), "the 2 times table comes both ways round")
	_check(keys.has("0*0") and keys.has("1*2") and keys.has("2*1"), "small facts in both tables appear")
	_check(not keys.has("7*3") and not keys.has("3*7"), "facts from other tables stay out")
	# 0..10 × 0..2 is 33; flipping adds 3..10 × 0..2 the other way round, 24 more
	_check(keys.size() == 57, "times 0, 1, 2 is 57 facts in both orders")

static func _in(v: int, r: Array) -> bool:
	return v >= r[0] and v <= r[1]

func _test_regrouping() -> void:
	_check(not Problems._regroups(23, "+", 4), "23 + 4 needs no carry")
	_check(Problems._regroups(27, "+", 4), "27 + 4 carries")
	_check(not Problems._regroups(90, "+", 9), "90 + 9 needs no carry")
	_check(not Problems._regroups(47, "-", 3), "47 − 3 needs no borrow")
	_check(Problems._regroups(43, "-", 7), "43 − 7 borrows")
	_check(not Problems._regroups(40, "-", 0), "40 − 0 needs no borrow")

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
	var add2 := Categories.level(&"addition", 2)
	stats.record(p, true, add2)
	stats.record(p, false, add2)
	stats.record(p, true, add2)
	var reloaded := StatsScript.new()
	reloaded.profile_id = "unit_test"
	var f: Dictionary = reloaded.fact("3+4")
	_check(f["right"] == 2 and f["wrong"] == 1, "tallies survive a reload")
	_check(f["recent"] == [true, false, true], "recent answers are kept in order")
	_check(f["last_seen"] > 0, "last_seen is stamped")
	_check(reloaded.fact("5+5")["right"] == 0, "an unseen fact reads as zeroes")
	for i in Config.RECENT_HISTORY + 5:
		stats.record(p, false, add2)
	_check(stats.fact("3+4")["recent"].size() == Config.RECENT_HISTORY, "recent history is capped")
	var summary: Dictionary = stats.level_summary(add2)
	_check(summary["seen"] == 1 and summary["right"] == 2 and summary["wrong"] == Config.RECENT_HISTORY + 6,
		"level summary totals the answers given in the level")
	_check(reloaded.level_summary(add2)["right"] == 2 and reloaded.level_summary(add2)["seen"] == 1,
		"level tallies survive a reload")
	# 2+3 is in Addition 1, 2 and 3; answering it in level 1 must only count for level 1
	stats.record(Problems.make(2, "+", 3), true, Categories.level(&"addition", 1))
	var add1: Dictionary = stats.level_summary(Categories.level(&"addition", 1))
	_check(add1["right"] == 1 and add1["seen"] == 1, "an answer counts for the level it was given in")
	_check(stats.level_summary(add2)["right"] == 2 and stats.level_summary(add2)["seen"] == 1,
		"...and not for another level that shares the fact")
	_check(stats.level_summary(Categories.level(&"addition", 3))["right"] == 0, "...nor a level never played")
	_check(stats.fact("2+3")["right"] == 1, "the fact's own history still has the answer")
	var other := StatsScript.new()
	other.profile_id = "unit_test_other"
	_check(other.fact("3+4")["right"] == 0, "profiles keep separate histories")
	stats.clear()
	stats.free()
	reloaded.free()
	other.free()

func _test_profiles() -> void:
	var path := "user://profiles_unit_test.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var profiles := ProfilesScript.new()
	profiles.legacy_id = ""
	profiles.load_file(path)
	_check(profiles.all().is_empty() and profiles.current_id.is_empty(), "no profiles to start with")
	var ada: String = profiles.create("  Ada ")
	var bo: String = profiles.create("Bo")
	_check(not ada.is_empty() and not bo.is_empty() and ada != bo, "each profile gets its own id")
	_check(profiles.find(ada)["name"] == "Ada", "names are trimmed")
	_check(profiles.current_id.is_empty(), "creating a profile doesn't select it")
	_check(profiles.create("ada").is_empty(), "names are unique, ignoring case")
	_check(profiles.create("   ").is_empty(), "a blank name is refused")
	_check(not profiles.name_problem("x".repeat(ProfilesScript.MAX_NAME_LENGTH + 1)).is_empty(), "a long name is refused")
	var picked: Array[String] = []
	profiles.selected.connect(func(id: String) -> void: picked.append(id))
	profiles.select(bo)
	profiles.select("nobody")
	_check(profiles.current_id == bo and profiles.current_name() == "Bo", "select switches who's playing")
	_check(picked == [bo], "select announces real profiles only")
	var reloaded := ProfilesScript.new()
	reloaded.load_file(path)
	_check(reloaded.all().size() == 2 and reloaded.all()[0]["name"] == "Ada", "profiles survive a reload, in order")
	_check(reloaded.current_id == bo, "who's playing survives a reload")
	profiles.picture_dir = "res://tests/fixtures/pictures/"
	_check(profiles.pictures() == PackedStringArray(["blue.png", "green.png"]), "pictures lists the image files, sorted")
	_check(profiles.find(ada)["picture"] == "" and profiles.picture_of(ada) == null, "a new profile has no picture")
	profiles.set_picture(ada, "green.png")
	_check(profiles.picture_of(ada) is Texture2D, "a chosen picture loads")
	reloaded.load_file(path)
	_check(reloaded.find(ada)["picture"] == "green.png", "the chosen picture survives a reload")
	profiles.set_picture(ada, "gone.png")
	_check(profiles.picture_of(ada) == null, "a picture that's been removed reads as none")
	profiles.picture_dir = "res://no/such/dir/"
	_check(profiles.pictures().is_empty(), "no picture folder means no pictures")
	_check(profiles.rename(ada, "ADA") and profiles.find(ada)["name"] == "ADA", "a profile can change its own name's capitals")
	_check(not profiles.rename(ada, "bo") and profiles.find(ada)["name"] == "ADA", "renaming to another player's name is refused")
	_check(profiles.rename(ada, " Ava ") and profiles.find(ada)["name"] == "Ava", "renaming trims the name")
	reloaded.load_file(path)
	_check(reloaded.find(ada)["name"] == "Ava", "a rename survives a reload")
	var ada_stats := StatsScript.new()
	ada_stats.profile_id = ada
	ada_stats.record(Problems.make(1, "+", 1), true, Categories.level(&"addition", 1))
	profiles.delete(bo)
	_check(profiles.find(bo).is_empty() and profiles.current_id.is_empty(), "deleting who's playing leaves nobody playing")
	profiles.delete(ada)
	_check(profiles.all().is_empty(), "deleting removes the profile")
	_check(not FileAccess.file_exists(StatsScript.path_for(ada)), "deleting removes their stats file")
	reloaded.load_file(path)
	_check(reloaded.all().is_empty(), "a delete survives a reload")
	ada_stats.free()
	var old := ConfigFile.new()
	old.set_value("profiles", "list", [{"id": "p1", "name": "Old"}])
	old.save(path)
	reloaded.load_file(path)
	_check(reloaded.find("p1").get("picture") == "", "a profile saved before pictures existed loads with none")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	profiles.free()
	reloaded.free()
