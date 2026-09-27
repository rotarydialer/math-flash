extends Node2D

## Root scene wiring: builds the profile, menu and play screens in code and shows whichever one
## GameState says is up. Android's back gesture steps up a screen: round → levels →
## categories → quit (from the profile picker it goes back to the menu, if someone's playing).

const Config := preload("res://data/config.gd")

var _profiles: ProfileScreen
var _menu: MenuScreen
var _play: PlayScreen

func _ready() -> void:
	RenderingServer.set_default_clear_color(Config.BACKGROUND)
	var layer := CanvasLayer.new()
	add_child(layer)
	_profiles = ProfileScreen.new()
	_menu = MenuScreen.new()
	_play = PlayScreen.new()
	layer.add_child(_profiles)
	layer.add_child(_menu)
	layer.add_child(_play)
	GameState.profiles_opened.connect(_show.bind(_profiles))
	GameState.menu_opened.connect(_show.bind(_menu))
	GameState.round_started.connect(func(_cfg: Dictionary, _total: int) -> void: _show(_play))
	GameState.boot()

func _show(screen: Control) -> void:
	_profiles.visible = screen == _profiles
	_menu.visible = screen == _menu
	_play.visible = screen == _play

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _profiles.visible:
		if Profiles.current_id.is_empty():
			get_tree().quit()
		else:
			GameState.to_menu()
	elif _play.visible:
		GameState.to_menu()
	elif not _menu.category_id.is_empty():
		_menu.show_categories()
	else:
		get_tree().quit()
