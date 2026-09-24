extends Node2D

## Root scene wiring: builds the menu and play screens in code and shows whichever one
## GameState says is up. Android's back gesture steps up a screen: round → levels →
## categories → quit.

const Config := preload("res://data/config.gd")

var _menu: MenuScreen
var _play: PlayScreen

func _ready() -> void:
	RenderingServer.set_default_clear_color(Config.BACKGROUND)
	var layer := CanvasLayer.new()
	add_child(layer)
	_menu = MenuScreen.new()
	_play = PlayScreen.new()
	layer.add_child(_menu)
	layer.add_child(_play)
	GameState.menu_opened.connect(_show.bind(_menu))
	GameState.round_started.connect(func(_cfg: Dictionary, _total: int) -> void: _show(_play))
	GameState.boot()

func _show(screen: Control) -> void:
	_menu.visible = screen == _menu
	_play.visible = screen == _play

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _play.visible:
		GameState.to_menu()
	elif not _menu.category_id.is_empty():
		_menu.show_categories()
	else:
		get_tree().quit()
