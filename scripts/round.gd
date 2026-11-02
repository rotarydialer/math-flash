class_name FlashRound
extends RefCounted

## Pure model of one round: the dealt deck, which card is up, and how each was answered. A timed
## round also scores each answer in points (see points_for); an untimed one keeps no points.

const Config := preload("res://data/config.gd")

var deck: Array
var index := 0
var results: Array[bool] = []
var timed := false
## Points for each answer so far (timed rounds only).
var points: Array[int] = []
## ✓ answers in a row, ending with the latest one.
var streak := 0

func _init(cards: Array, is_timed := false) -> void:
	deck = cards
	timed = is_timed

func size() -> int:
	return deck.size()

func current() -> Dictionary:
	return deck[index] if index < deck.size() else {}

## Records the answer to the current card and moves on to the next. `seconds` is how long the
## card was up before it was flipped; only a timed round uses it.
func record(correct: bool, seconds := -1.0) -> void:
	if is_done():
		return
	results.append(correct)
	streak = streak + 1 if correct else 0
	if timed:
		points.append(points_for(correct, seconds, streak))
	index += 1

func is_done() -> bool:
	return index >= deck.size()

func score() -> int:
	return results.count(true)

func total_points() -> int:
	var total := 0
	for p in points:
		total += p
	return total

func last_points() -> int:
	return points.back() if not points.is_empty() else 0

## The points for one answer: nothing for a ✗; for a ✓, BASE_POINTS plus up to SPEED_POINTS for
## flipping it quickly (all of it within FAST_TIME, none by TIME_LIMIT), times the streak
## multiplier. `streak` counts this answer, so the first ✓ in a row is ×1.
static func points_for(correct: bool, seconds: float, streak_len: int) -> int:
	if not correct:
		return 0
	var speed := 1.0 - inverse_lerp(Config.FAST_TIME, Config.TIME_LIMIT, maxf(seconds, 0.0))
	var bonus := Config.SPEED_POINTS * clampf(speed, 0.0, 1.0)
	return roundi((Config.BASE_POINTS + bonus) * multiplier_for(streak_len))

## The points multiplier for a ✓ that makes `streak_len` in a row: ×1 for the first, then
## STREAK_STEP more for each, up to STREAK_MAX.
static func multiplier_for(streak_len: int) -> float:
	return minf(1.0 + Config.STREAK_STEP * maxi(streak_len - 1, 0), Config.STREAK_MAX)
