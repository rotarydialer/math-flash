class_name FlashRound
extends RefCounted

## Pure model of one round: the dealt deck, which card is up, and how each was answered.

var deck: Array
var index := 0
var results: Array[bool] = []

func _init(cards: Array) -> void:
	deck = cards

func size() -> int:
	return deck.size()

func current() -> Dictionary:
	return deck[index] if index < deck.size() else {}

## Records the answer to the current card and moves on to the next.
func record(correct: bool) -> void:
	if is_done():
		return
	results.append(correct)
	index += 1

func is_done() -> bool:
	return index >= deck.size()

func score() -> int:
	return results.count(true)
