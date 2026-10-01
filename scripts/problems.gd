class_name Problems
extends RefCounted

## Pure problem generation — no nodes, so it runs headless in tests. A problem is a Dictionary
## `{a, b, op, answer, key}`; `key` (e.g. "3+4", "7-2") is how Stats files answers for that fact.

## How each operator is shown on a card (a true minus sign reads better than a hyphen).
const SYMBOLS := {"+": "+", "-": "−", "*": "×", "/": "÷"}

static func answer(a: int, op: String, b: int) -> int:
	match op:
		"+":
			return a + b
		"-":
			return a - b
		"*":
			return a * b
		"/":
			return a / b if b != 0 else 0
	push_error("Problems: unknown operator '%s'" % op)
	return 0

static func make(a: int, op: String, b: int) -> Dictionary:
	return {"a": a, "b": b, "op": op, "answer": answer(a, op, b), "key": "%d%s%d" % [a, op, b]}

## The problem as the student sees it, e.g. "7 − 2".
static func text(p: Dictionary) -> String:
	return "%d %s %d" % [p["a"], SYMBOLS.get(p["op"], p["op"]), p["b"]]

## Every fact a level allows, in a stable order. Negative answers, division by zero and
## division with a remainder are never dealt. With
## `both_orders`, each fact also comes the other way round (7 × 2 as well as 2 × 7).
static func all_facts(level_cfg: Dictionary) -> Array:
	var op: String = level_cfg["op"]
	var ra: Array = level_cfg["a"]
	var rb: Array = level_cfg["b"]
	var pairs: Array[Vector2i] = []
	for a in range(ra[0], ra[1] + 1):
		for b in range(rb[0], rb[1] + 1):
			pairs.append(Vector2i(a, b))
	if level_cfg.get("both_orders", false):
		for pair in pairs.duplicate():
			pairs.append(Vector2i(pair.y, pair.x))
	var facts := []
	var seen := {}
	for pair in pairs:
		var a := pair.x
		var b := pair.y
		if op == "/" and (b == 0 or a % b != 0):
			continue
		var p := make(a, op, b)
		if seen.has(p["key"]):
			continue
		seen[p["key"]] = true
		if p["answer"] < 0:
			continue
		if level_cfg.get("skip_easy", false) and is_easy(p):
			continue
		if level_cfg.has("max_result") and p["answer"] > level_cfg["max_result"]:
			continue
		if level_cfg.get("no_regroup", false) and _regroups(a, op, b):
			continue
		if level_cfg.get("regroup_only", false) and not _regroups(a, op, b):
			continue
		facts.append(p)
	return facts

## A fact with a 0 or 1 in it: n + 0, n + 1, n − 0, n − 1, n × 0, n × 1. Division counts the
## times fact it undoes (divisor × answer), so n ÷ 1, n ÷ n and 0 ÷ n are easy too. And any
## number take away itself, n − n.
static func is_easy(p: Dictionary) -> bool:
	if p["op"] == "-" and p["a"] == p["b"]:
		return true
	var numbers: Array = [p["b"], p["answer"]] if p["op"] == "/" else [p["a"], p["b"]]
	return numbers.has(0) or numbers.has(1)

## True when working column by column would carry (addition) or borrow (subtraction).
static func _regroups(a: int, op: String, b: int) -> bool:
	while a > 0 or b > 0:
		if op == "+" and a % 10 + b % 10 > 9:
			return true
		if op == "-" and a % 10 < b % 10:
			return true
		a /= 10
		b /= 10
	return false

## A shuffled deck of up to `size` distinct problems from the level (a level with fewer facts
## than that deals each one once). Same seed, same deck.
static func deal(level_cfg: Dictionary, size: int, seed_value: int) -> Array:
	var facts := all_facts(level_cfg)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_shuffle(facts, rng)
	return facts.slice(0, mini(size, facts.size()))

## Fisher–Yates on our own RNG (Array.shuffle uses the global one, which isn't seedable per deck).
static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
