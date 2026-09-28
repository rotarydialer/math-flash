class_name ProfileButton
extends Button

## A button showing a player: their picture (or initial) on the left, then their name. Widens its
## own left margin to make room for the picture, so it sizes itself like any other button.

const GAP := 18.0                 # between the picture and the name

var avatar: Avatar
var _avatar_size: float
var _left_margin := 0.0

func _init(avatar_size: float) -> void:
	_avatar_size = avatar_size
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	avatar = Avatar.new()
	avatar.size = Vector2(avatar_size, avatar_size)
	add_child(avatar)
	resized.connect(_place_avatar)

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var box := get_theme_stylebox(state).duplicate() as StyleBox
		_left_margin = box.content_margin_left
		box.content_margin_left += _avatar_size + GAP
		add_theme_stylebox_override(state, box)
	_place_avatar()

func show_player(player_name: String, picture: Texture2D) -> void:
	text = player_name
	avatar.initial = player_name.left(1)
	avatar.texture = picture

func _place_avatar() -> void:
	avatar.position = Vector2(_left_margin, (size.y - _avatar_size) / 2.0)
