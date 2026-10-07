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
	_test_easy_facts()
	_test_regrouping()
	_test_deal()
	_test_deal_small_level()
	_test_deal_steering()
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
					ok = ok and p["answer"] <= Problems._max_result(cfg, p)
				if cfg.get("no_regroup", false):
					ok = ok and not Problems._regroups(p["a"], cfg["op"], p["b"])
				if n > 1:
					ok = ok and not Problems.is_easy(p)
				if cfg["op"] == "/":
					ok = ok and p["b"] != 0 and p["answer"] * p["b"] == p["a"]
				if cfg.get("regroup_only", false):
					ok = ok and Problems._regroups(p["a"], cfg["op"], p["b"])
				keys[p["key"]] = true
			_check(ok, "%s facts are in range with correct, non-negative answers" % name)
			_check(keys.size() == facts.size(), "%s facts are all distinct" % name)
	# sums to 5, plus n + 0, 0 + n, n + 1, 1 + n with sums 6..10
	_check(Problems.all_facts(Categories.level(&"addition", 1)).size() == 41, "sums to 5, + 0 and + 1 to 10 is 41 facts")
	# after level 1, no 0s or 1s: 2..8 + 2..8 with sums to 10
	_check(Problems.all_facts(Categories.level(&"addition", 2)).size() == 28, "sums to 10 without 0s and 1s is 28 facts")
	_check(Problems.all_facts(Categories.level(&"addition", 3)).size() == 81, "2..10 + 2..10 is 81 facts")
	# levels 4 and 5 split two-digit + one-digit (2..9) exactly into no-carry and carry
	_check(Problems.all_facts(Categories.level(&"addition", 4)).size()
		+ Problems.all_facts(Categories.level(&"addition", 5)).size() == 90 * 8,
		"addition 4 and 5 together cover every two-digit + 2..9 fact")
	# subtraction mirrors addition: each addition fact has exactly one take-away partner
	_check(Problems.all_facts(Categories.level(&"subtraction", 1)).size() == 21, "from 5 or less is 21 facts")
	# ...and loses its − 0s and − 1s the same way, plus n − n: 3..10 take away 2 up to one less
	_check(Problems.all_facts(Categories.level(&"subtraction", 2)).size() == 36, "from 10 or less without − 0, − 1, n − n is 36 facts")
	_check(Problems.all_facts(Categories.level(&"subtraction", 3)).size() == 90, "up to 20 − 10 without − 0, − 1, n − n is 90 facts")
	_check(Problems.all_facts(Categories.level(&"multiplication", 4)).size() == 121, "2..12 × 2..12 is 121 facts")
	# division mirrors multiplication: one fact per divisor × quotient
	_check(Problems.all_facts(Categories.level(&"division", 1)).size() == 22, "÷ 1, 2 is 22 facts")
	# divisors × quotients 2..10, now that 0 ÷ n and n ÷ n are level 1 only
	_check(Problems.all_facts(Categories.level(&"division", 3)).size() == 36, "÷ 6 to 9 is 36 facts")
	_check(Problems.all_facts(Categories.level(&"division", 4)).size() == 121, "divisors and quotients 2..12 is 121 facts")
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

## Facts with a 0 or 1 in them are level 1 practice only.
func _test_easy_facts() -> void:
	for spec in [[7, "+", 0], [1, "+", 8], [9, "-", 1], [6, "-", 0], [7, "-", 7], [0, "*", 7], [12, "*", 1],
			[9, "/", 1], [0, "/", 4], [6, "/", 6]]:
		_check(Problems.is_easy(Problems.make(spec[0], spec[1], spec[2])), "%d %s %d is easy" % spec)
	for spec in [[2, "+", 2], [7, "-", 6], [2, "*", 3], [3, "*", 3], [12, "/", 6], [8, "/", 4]]:
		_check(not Problems.is_easy(Problems.make(spec[0], spec[1], spec[2])), "%d %s %d isn't easy" % spec)
	var add1 := {}
	for p in Problems.all_facts(Categories.level(&"addition", 1)):
		add1[p["key"]] = true
	_check(add1.has("4+1") and add1.has("0+5"), "level 1 keeps its easy facts")
	_check(add1.has("9+1") and add1.has("1+9") and add1.has("10+0") and add1.has("0+7"), "addition 1 has + 0 and + 1 up to 10")
	_check(not add1.has("6+2") and not add1.has("10+1"), "...but no other sums over 5, and nothing over 10")
	var times2 := {}
	for p in Problems.all_facts(Categories.level(&"multiplication", 2)):
		times2[p["key"]] = true
	_check(times2.has("3*2") and not times2.has("3*1") and not times2.has("0*4"), "times 3, 4, 5 drops × 0 and × 1")

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

## Untried and missed facts get places in the deck, however the shuffle falls.
func _test_deal_steering() -> void:
	var cfg := Categories.level(&"multiplication", 3)
	var keys: Array = Problems.all_facts(cfg).map(func(p: Dictionary) -> String: return p["key"])
	var quota := ceili(Config.DECK_SIZE * Config.UNTRIED_SHARE)
	var last_untried := true
	var some_untried := true
	var missed_in := true
	var missed_first := true
	var tidy := true
	for seed_value in 30:
		# 55 of 56 tried: the one left always comes up
		var deck := Problems.deal(cfg, Config.DECK_SIZE, seed_value, {"tried": keys.slice(1)})
		last_untried = last_untried and _keys(deck).has(keys[0])
		# 10 untried: at least a quarter of the deck is them
		deck = Problems.deal(cfg, Config.DECK_SIZE, seed_value, {"tried": keys.slice(10)})
		some_untried = some_untried and _keys(deck).filter(func(k: String) -> bool: return keys.find(k) < 10).size() >= quota
		# 6 missed: at least 3 of them, alongside the untried quota
		var missed := keys.slice(20, 26)
		deck = Problems.deal(cfg, Config.DECK_SIZE, seed_value, {"tried": keys.slice(10), "missed": missed})
		var dealt := _keys(deck)
		missed_in = missed_in and dealt.filter(func(k: String) -> bool: return missed.has(k)).size() >= Config.MIN_MISSED
		missed_in = missed_in and dealt.filter(func(k: String) -> bool: return keys.find(k) < 10).size() >= quota
		# still wrong last time beats got right since
		deck = Problems.deal(cfg, Config.DECK_SIZE, seed_value, {"missed": [keys[30]], "shaky": keys.slice(40, 50)})
		dealt = _keys(deck)
		missed_first = missed_first and dealt.has(keys[30])
		missed_first = missed_first and dealt.filter(func(k: String) -> bool: return keys.find(k) >= 40 and keys.find(k) < 50).size() >= Config.MIN_MISSED - 1
		# keys from other levels are ignored; the deck stays full and distinct
		deck = Problems.deal(cfg, Config.DECK_SIZE, seed_value, {"tried": keys, "missed": ["1+1", "2*2"]})
		var unique := {}
		for k in _keys(deck):
			unique[k] = true
		tidy = tidy and deck.size() == Config.DECK_SIZE and unique.size() == deck.size()
	_check(last_untried, "the last untried fact always makes the deck")
	_check(some_untried, "at least %d%% of a deck is untried facts while there are enough" % roundi(Config.UNTRIED_SHARE * 100))
	_check(missed_in, "at least %d missed facts make the deck, as well as the untried ones" % Config.MIN_MISSED)
	_check(missed_first, "facts still wrong come before ones got right since")
	_check(tidy, "other levels' keys are ignored and the deck stays full and distinct")
	var small := Problems.deal({"op": "+", "a": [0, 1], "b": [0, 1]}, 20, 1, {"missed": ["0+0", "1+1"], "shaky": ["0+1"]})
	_check(_keys(small).size() == 4, "a small level still deals each fact once with a history")
	var history := {"tried": keys.slice(5), "missed": keys.slice(30, 34)}
	_check(str(Problems.deal(cfg, 20, 9, history)) == str(Problems.deal(cfg, 20, 9, history)), "same seed and history, same deck")

static func _keys(deck: Array) -> Array:
	return deck.map(func(p: Dictionary) -> String: return p["key"])

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
	var history: Dictionary = stats.practice_history(add2)
	_check(history["tried"] == ["3+4"], "practice history lists the facts tried in the level")
	_check(history["missed"] == ["3+4"] and history["shaky"].is_empty(), "a fact whose last answer was wrong is missed")
	stats.record(p, true, add2)
	history = stats.practice_history(add2)
	_check(history["missed"].is_empty() and history["shaky"] == ["3+4"], "...and shaky once it's been got right since")
	stats.record(Problems.make(5, "+", 1), true, add2)   # dealt at level 2 before it lost its easy facts
	_check(stats.level_summary(add2)["seen"] == 1, "facts a level no longer deals don't count as tried")
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
