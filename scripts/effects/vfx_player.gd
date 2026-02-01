extends Node2D
## VFXPlayer - Renders a 3D effect scene via SubViewport into a 2D Sprite2D.
## Auto-frees after the effect lifetime expires.

var _effect_instance: Node3D
var _lifetime: float = 1.5
var _elapsed: float = 0.0


static func play_at(parent: Node, effect_scene: PackedScene, pos: Vector2,
		size: Vector2 = Vector2(128, 128), duration: float = 1.5) -> Node2D:
	var cam_cfg = {"position": Vector3(0, 1.0, 2.5), "fov": 40.0}
	var player = _create_player(parent, effect_scene, pos, size, duration, cam_cfg, true)
	return player


static func play_arc(parent: Node, effect_scene: PackedScene, from_pos: Vector2,
		to_pos: Vector2, size: Vector2 = Vector2(128, 128), duration: float = 0.4,
		arc_height: float = 80.0, on_arrive: Callable = Callable()) -> Node2D:
	var cam_cfg = {"position": Vector3(0, 0.8, 3.5), "fov": 50.0}
	var player = _create_player(parent, effect_scene, from_pos, size, duration + 0.1, cam_cfg, false)

	# Offset sprite so the flame base aligns with the node position
	var sprite: Sprite2D = player.get_node("Sprite")
	sprite.offset = Vector2(0, size.y * 0.15)

	# Tween position along arc
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
## When trigger_effect is true, calls the effect's explosion() method on ready.
static func _create_player(parent: Node, effect_scene: PackedScene, pos: Vector2,
		size: Vector2, duration: float, cam_config: Dictionary,
		trigger_effect: bool) -> Node2D:
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

	return player


func _ready() -> void:
	if _effect_instance and _effect_instance.has_method("explosion"):
		_effect_instance.call_deferred("explosion")


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
