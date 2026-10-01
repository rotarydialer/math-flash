class_name Categories
extends RefCounted

## Registry of problem categories and their levels. The menu lists them in this order, and
## `scripts/problems.gd` turns a level's ranges into concrete facts.
##
## Each level may set:
##   a, b          inclusive [lo, hi] range for each operand
##   max_result    drop facts whose answer is above this
##   easy_max_result  ...except easy facts (see below), which may go up to this instead
##   no_regroup    drop facts that need carrying or borrowing in any column
##   regroup_only  keep only facts that need carrying or borrowing
##   both_orders   also deal each fact the other way round (b op a), for times tables
##   hint          short range description shown under the level name
## Every level after the first also drops the very easy facts, those with a 0 or 1 in them, and
## n − n (`Problems.is_easy`): n + 0, n − 1, n − n, n × 1, n ÷ 1, 0 ÷ n and so on are level 1
## practice only.
## Facts with a negative answer, division by zero or a remainder are always dropped, so ranges
## can be written loosely (division levels give a dividend range and let the filter do the rest).
## Adding a category: a new entry here plus its operator in `Problems.answer` / `Problems.SYMBOLS`.

static var DATA := [
	{
		"id": &"addition",
		"name": "Addition",
		"op": "+",
		"levels": [
			{"hint": "Sums to 5, + 0, + 1", "a": [0, 10], "b": [0, 10], "max_result": 5, "easy_max_result": 10},
			{"hint": "Sums to 10", "a": [0, 10], "b": [0, 10], "max_result": 10},
			{"hint": "Up to 10 + 10", "a": [0, 10], "b": [0, 10]},
			{"hint": "Two digits + one", "a": [10, 99], "b": [1, 9], "no_regroup": true},
			{"hint": "Two digits + one, carry", "a": [10, 99], "b": [1, 9], "regroup_only": true},
			{"hint": "Two digits + two", "a": [10, 99], "b": [10, 99], "no_regroup": true},
		],
	},
	{
		"id": &"subtraction",
		"name": "Subtraction",
		"op": "-",
		"levels": [
			{"hint": "From 5 or less", "a": [0, 5], "b": [0, 5]},
			{"hint": "From 10 or less", "a": [0, 10], "b": [0, 10]},
			{"hint": "Up to 20 − 10", "a": [0, 20], "b": [0, 10], "max_result": 10},
			{"hint": "Two digits − one", "a": [10, 99], "b": [1, 9], "no_regroup": true},
		],
	},
	{
		"id": &"multiplication",
		"name": "Multiplication",
		"op": "*",
		"levels": [
			{"hint": "Times 0, 1, 2", "a": [0, 10], "b": [0, 2], "both_orders": true},
			{"hint": "Times 3, 4, 5", "a": [0, 10], "b": [3, 5], "both_orders": true},
			{"hint": "Times 6 to 9", "a": [0, 10], "b": [6, 9], "both_orders": true},
			{"hint": "Up to 12 × 12", "a": [0, 12], "b": [0, 12]},
		],
	},
	{
		"id": &"division",
		"name": "Division",
		"op": "/",
		"levels": [
			{"hint": "Divide by 1, 2", "a": [0, 20], "b": [1, 2], "max_result": 10},
			{"hint": "Divide by 3, 4, 5", "a": [0, 50], "b": [3, 5], "max_result": 10},
			{"hint": "Divide by 6 to 9", "a": [0, 90], "b": [6, 9], "max_result": 10},
			{"hint": "Up to 144 ÷ 12", "a": [0, 144], "b": [0, 12], "max_result": 12},
		],
	},
]

static func category(id: StringName) -> Dictionary:
	for cat in DATA:
		if cat["id"] == id:
			return cat
	return {}

static func level_count(id: StringName) -> int:
	return category(id).get("levels", []).size()

## Fully-resolved settings for a 1-based level: the level's own keys plus its category's
## `op`, `category` id, `number` and `skip_easy` (true after level 1), so problems.gd needs
## nothing else.
static func level(id: StringName, number: int) -> Dictionary:
	var cat := category(id)
	var levels: Array = cat.get("levels", [])
	if levels.is_empty():
		return {}
	var n := clampi(number, 1, levels.size())
	var cfg: Dictionary = levels[n - 1].duplicate()
	cfg["op"] = cat["op"]
	cfg["category"] = id
	cfg["category_name"] = cat["name"]
	cfg["number"] = n
	cfg["skip_easy"] = n > 1
	return cfg
