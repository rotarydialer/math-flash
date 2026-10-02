extends Node

## Autoload. Every answer, filed per fact per profile, so we can later work out what a student
## needs more practice on. Saved to user://stats_<profile>.cfg with one section per fact key
## ("3+4"): right, wrong, recent (the last RECENT_HISTORY answers, oldest first) and last_seen
## (unix time). Levels share facts (Addition 1's are all in Addition 2 too), so each level also
## keeps its own tallies, in a "level:<category>:<n>" section: right, wrong and seen (the fact
## keys answered there). A level's progress is only what was answered in that level.
## GameState keeps profile_id in step with the Profiles autoload.

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

static func level_section(level_cfg: Dictionary) -> String:
	return "level:%s:%d" % [level_cfg["category"], level_cfg["number"]]

## Files one answer, given in this level, under both the fact and the level.
func record(problem: Dictionary, correct: bool, level_cfg: Dictionary) -> void:
	var key: String = problem["key"]
	var section := level_section(level_cfg)
	var tally := "right" if correct else "wrong"
	_cfg.set_value(section, tally, int(_cfg.get_value(section, tally, 0)) + 1)
	var seen := PackedStringArray(_cfg.get_value(section, "seen", PackedStringArray()))
	if not key in seen:
		seen.append(key)
		_cfg.set_value(section, "seen", seen)
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

## How the student has done in a level, counting only answers given there:
## {right, wrong, seen (facts answered at least once), facts (in the level)}.
func level_summary(level_cfg: Dictionary) -> Dictionary:
	var section := level_section(level_cfg)
	var seen := PackedStringArray(_cfg.get_value(section, "seen", PackedStringArray()))
	var facts := Problems.all_facts(level_cfg)
	# only facts the level still deals, in case its definition has changed since
	var tried := facts.filter(func(p: Dictionary) -> bool: return p["key"] in seen).size()
	return {
		"right": int(_cfg.get_value(section, "right", 0)),
		"wrong": int(_cfg.get_value(section, "wrong", 0)),
		"seen": tried,
		"facts": facts.size(),
	}

## Wipes the current profile's history (tests use a throwaway profile and clear it).
func clear() -> void:
	_cfg = ConfigFile.new()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path()))

func _load() -> void:
	_cfg = ConfigFile.new()
	_cfg.load(save_path())
