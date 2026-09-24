class_name Problems
extends RefCounted

## Pure problem generation — no nodes, so it runs headless in tests. A problem is a Dictionary
## `{a, b, op, answer, key}`; `key` (e.g. "3+4") is how Stats files answers for that fact.

static func answer(a: int, op: String, b: int) -> int:
	match op:
		"+":
			return a + b
	push_error("Problems: unknown operator '%s'" % op)
	return 0

static func make(a: int, op: String, b: int) -> Dictionary:
	return {"a": a, "b": b, "op": op, "answer": answer(a, op, b), "key": "%d%s%d" % [a, op, b]}

## Every fact a level allows, in a stable order.
static func all_facts(level_cfg: Dictionary) -> Array:
	var op: String = level_cfg["op"]
	var ra: Array = level_cfg["a"]
	var rb: Array = level_cfg["b"]
	var facts := []
	for a in range(ra[0], ra[1] + 1):
		for b in range(rb[0], rb[1] + 1):
			var p := make(a, op, b)
			if level_cfg.has("max_result") and p["answer"] > level_cfg["max_result"]:
				continue
			if level_cfg.get("no_regroup", false) and _regroups(a, b):
				continue
			facts.append(p)
	return facts

## True when adding column by column would carry.
static func _regroups(a: int, b: int) -> bool:
	while a > 0 or b > 0:
		if a % 10 + b % 10 > 9:
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
