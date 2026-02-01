extends Node2D
## VFXPlayer - Renders a 3D effect scene via SubViewport into a 2D Sprite2D.
## Auto-frees after the effect lifetime expires.

var _effect_instance: Node3D
var _lifetime: float = 1.5
var _elapsed: float = 0.0

# Shared hue-shift shader (created once, reused across all instances)
static var _hue_shift_shader: Shader


static func play_at(parent: Node, effect_scene: PackedScene, pos: Vector2,
		size: Vector2 = Vector2(128, 128), duration: float = 1.5,
		hue_shift: float = 0.0) -> Node2D:
	var cam_cfg = {"position": Vector3(0, 1.0, 2.5), "fov": 40.0}
	return _create_player(parent, effect_scene, pos, size, duration, cam_cfg, true, hue_shift)


static func play_arc(parent: Node, effect_scene: PackedScene, from_pos: Vector2,
		to_pos: Vector2, size: Vector2 = Vector2(128, 128), duration: float = 0.4,
		arc_height: float = 80.0, on_arrive: Callable = Callable(),
		hue_shift: float = 0.0) -> Node2D:
	var cam_cfg = {"position": Vector3(0, 0.8, 3.5), "fov": 50.0}
	var player = _create_player(parent, effect_scene, from_pos, size, duration + 0.1, cam_cfg, false, hue_shift)

	var sprite: Sprite2D = player.get_node("Sprite")
	sprite.offset = Vector2(0, size.y * 0.15)

	var tween = player.create_tween()
	tween.tween_method(func(t: float):
		var linear_pos = from_pos.lerp(to_pos, t)
		var arc_offset = arc_height * 4.0 * t * (1.0 - t)
		player.position = linear_pos + Vector2(0, -arc_offset)
	, 0.0, 1.0, duration)
	tween.tween_callback(func():
		if on_arrive.is_valid():
			on_arrive.call()
		player.queue_free()
	)

	return player


## Shared setup: creates a VFXPlayer node with SubViewport, Camera3D, effect, and Sprite2D.
static func _create_player(parent: Node, effect_scene: PackedScene, pos: Vector2,
		size: Vector2, duration: float, cam_config: Dictionary,
		trigger_effect: bool, hue_shift: float = 0.0) -> Node2D:
	var player = load("res://scripts/effects/vfx_player.gd").new()
	player._lifetime = duration
	player.position = pos

	var vp = SubViewport.new()
	vp.size = Vector2i(int(size.x), int(size.y))
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	player.add_child(vp)

	var cam = Camera3D.new()
	cam.position = cam_config.position
	cam.rotation.x = -atan2(cam_config.position.y, cam_config.position.z)
	cam.fov = cam_config.fov
	vp.add_child(cam)

	var effect = effect_scene.instantiate()
	if trigger_effect:
		effect.set("auto_animate", false)
		player._effect_instance = effect
	vp.add_child(effect)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	player.add_child(sprite)

	parent.add_child(player)

	sprite.texture = vp.get_texture()
	sprite.centered = true

	if hue_shift != 0.0:
		_apply_hue_shift(sprite, hue_shift)

	return player


static func _apply_hue_shift(sprite: Sprite2D, shift: float) -> void:
	if _hue_shift_shader == null:
		_hue_shift_shader = Shader.new()
		_hue_shift_shader.code = """
shader_type canvas_item;
uniform float hue_shift : hint_range(0.0, 1.0) = 0.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 hsv = rgb2hsv(tex.rgb);
	hsv.x = fract(hsv.x + hue_shift);
	COLOR = vec4(hsv2rgb(hsv), tex.a);
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = _hue_shift_shader
	mat.set_shader_parameter("hue_shift", shift)
	sprite.material = mat


func _ready() -> void:
	if not _effect_instance:
		return
	if _effect_instance.has_method("explosion"):
		_effect_instance.call_deferred("explosion")
	elif _effect_instance.has_method("activate_effects"):
		_effect_instance.call_deferred("activate_effects")


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
