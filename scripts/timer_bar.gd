class_name TimerBar
extends Control

## The timed-mode clock above the card, drawn in code: a rounded bar that drains from full to empty
## over Config.TIME_LIMIT, fading from TIMER_FULL to TIMER_EMPTY as it goes. Once empty it just
## stays empty; nothing else happens, the speed bonus is simply gone. stop() freezes it where it is.

const Config := preload("res://data/config.gd")

var running := false
var _started_ms := 0
var _stopped_ms := 0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Refill the bar and start it draining.
func start() -> void:
	_started_ms = Time.get_ticks_msec()
	running = true
	queue_redraw()

## Freeze the bar where it is.
func stop() -> void:
	if running:
		_stopped_ms = Time.get_ticks_msec()
		running = false
		queue_redraw()

## Seconds since start(), up to the stop() if it's stopped.
func elapsed() -> float:
	var now := Time.get_ticks_msec() if running else _stopped_ms
	return maxf(0.0, (now - _started_ms) / 1000.0)

## The share of the bar left, 1 (just started) to 0 (out of time).
func remaining() -> float:
	return clampf(1.0 - elapsed() / Config.TIME_LIMIT, 0.0, 1.0)

func _process(_delta: float) -> void:
	if running and visible:
		queue_redraw()

func _draw() -> void:
	var radius := int(size.y / 2.0)
	var track := StyleBoxFlat.new()
	track.bg_color = Config.TIMER_TRACK
	track.set_corner_radius_all(radius)
	draw_style_box(track, Rect2(Vector2.ZERO, size))
	var left := remaining()
	if left <= 0.0:
		return
	var fill := StyleBoxFlat.new()
	fill.bg_color = Config.TIMER_EMPTY.lerp(Config.TIMER_FULL, left)
	fill.set_corner_radius_all(radius)
	# never narrower than its own rounded ends, so it shrinks to a dot rather than a sliver
	draw_style_box(fill, Rect2(Vector2.ZERO, Vector2(maxf(size.x * left, size.y), size.y)))
