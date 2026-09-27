extends Node

## Autoload. Every answer, filed per fact per profile, so we can later work out what a student
## needs more practice on. Saved to user://stats_<profile>.cfg with one section per fact key
## ("3+4"): right, wrong, recent (the last RECENT_HISTORY answers, oldest first) and last_seen
## (unix time). GameState keeps profile_id in step with the Profiles autoload.

const Config := preload("res://data/config.gd")

var profile_id := "default":
	set(value):
		profile_id = value
		_load()

var _cfg := ConfigFile.new()

func _ready() -> void:
	_load()

static func path_for(id: String) -> String:
	return "user://stats_%s.cfg" % id

func save_path() -> String:
	return path_for(profile_id)

func record(problem: Dictionary, correct: bool) -> void:
	var key: String = problem["key"]
	var f := fact(key)
	f["right" if correct else "wrong"] += 1
	var recent: Array = f["recent"]
	recent.append(correct)
	while recent.size() > Config.RECENT_HISTORY:
		recent.pop_front()
	for field in f:
		_cfg.set_value(key, field, f[field])
	_cfg.set_value(key, "last_seen", int(Time.get_unix_time_from_system()))
	_cfg.save(save_path())

## A fact's tallies; zeroes for a fact never answered.
func fact(key: String) -> Dictionary:
	return {
		"right": int(_cfg.get_value(key, "right", 0)),
		"wrong": int(_cfg.get_value(key, "wrong", 0)),
		"recent": Array(_cfg.get_value(key, "recent", [])),
		"last_seen": int(_cfg.get_value(key, "last_seen", 0)),
	}

## Totals over every fact in a level: {right, wrong, seen (facts answered at least once), facts}.
func level_summary(level_cfg: Dictionary) -> Dictionary:
	var out := {"right": 0, "wrong": 0, "seen": 0, "facts": 0}
	for p in Problems.all_facts(level_cfg):
		out["facts"] += 1
		if not _cfg.has_section(p["key"]):
			continue
		var f := fact(p["key"])
		out["right"] += f["right"]
		out["wrong"] += f["wrong"]
		out["seen"] += 1
	return out

## Wipes the current profile's history (tests use a throwaway profile and clear it).
func clear() -> void:
	_cfg = ConfigFile.new()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path()))

func _load() -> void:
	_cfg = ConfigFile.new()
	_cfg.load(save_path())
