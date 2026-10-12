class_name Avatar
extends Control

## A profile picture, cropped to a centred circle with a rim. With no picture it shows the
## player's initial on a plain disc instead. Purely visual: taps pass through to whatever holds it.

const Config := preload("res://data/config.gd")

const RIM := 0.05                 # rim width, as a fraction of the diameter

const SHADER_CODE := """
shader_type canvas_item;
uniform vec2 center;              // the circle, in the control's own coordinates
uniform float radius;
uniform vec4 rim_color : source_color;
uniform float rim;                // rim width, same units
varying vec2 local;
void vertex() {
	local = VERTEX;
}
void fragment() {
	float r = distance(local, center);
	float aa = fwidth(r);
	COLOR = mix(COLOR, rim_color, smoothstep(radius - rim - aa, radius - rim, r));
	COLOR.a *= 1.0 - smoothstep(radius - aa, radius, r);
}
"""

static var _shader: Shader

var texture: Texture2D:
	set(value):
		texture = value
		_update_material()
		queue_redraw()
var initial := "":
	set(value):
		initial = value
		queue_redraw()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_update_circle)

func _draw() -> void:
	var d := minf(size.x, size.y)
	var rect := Rect2((size - Vector2(d, d)) / 2.0, Vector2(d, d))
	if texture:
		draw_texture_rect_region(texture, rect, _square_region())
		return
	var center := rect.get_center()
	var rim_w := d * RIM
	draw_circle(center, d / 2.0, Config.AVATAR_BLANK)
	draw_arc(center, d / 2.0 - rim_w / 2.0, 0.0, TAU, 64, Config.AVATAR_RIM, rim_w, true)
	var font := get_theme_default_font()
	var font_size := int(d * 0.5)
	var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	draw_string(font, Vector2(rect.position.x, baseline), initial.to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER, d, font_size, Config.INK)

## The biggest centred square of the texture, in pixels.
func _square_region() -> Rect2:
	var tex_size := texture.get_size()
	var side := minf(tex_size.x, tex_size.y)
	return Rect2((tex_size - Vector2(side, side)) / 2.0, Vector2(side, side))

func _update_material() -> void:
	if not texture:
		material = null
		return
	if not _shader:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("rim_color", Config.AVATAR_RIM)
	material = mat
	_update_circle()

func _update_circle() -> void:
	if material:
		var d := minf(size.x, size.y)
		material.set_shader_parameter("center", size / 2.0)
		material.set_shader_parameter("radius", d / 2.0)
		material.set_shader_parameter("rim", d * RIM)
