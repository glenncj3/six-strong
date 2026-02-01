extends Node2D
class_name SpriteSheetVFX
## Animated sprite sheet effect that plays once and auto-frees.
## Animates by stepping through a grid of frames via region_rect.

var _sprite: Sprite2D
var _frame_size: Vector2i
var _total_frames: int
var _columns: int
var _fps: float
var _elapsed: float = 0.0
var _current_frame: int = 0
var _finished: bool = false
var _travel_from: Vector2
var _travel_to: Vector2
var _traveling: bool = false
var _travel_duration: float = 0.0


func setup(texture: Texture2D, frame_size: Vector2i, total_frames: int, columns: int, fps: float = 24.0) -> void:
	_frame_size = frame_size
	_total_frames = total_frames
	_columns = columns
	_fps = fps

	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, frame_size.x, frame_size.y)
	# Anchor at bottom-center so position = source, sprite extends upward
	_sprite.offset = Vector2(0, -frame_size.y / 2.0)
	add_child(_sprite)
	_set_frame(0)


func place_between(source_pos: Vector2, target_pos: Vector2) -> void:
	"""Position at source, rotate toward target, scale so sprite height = distance."""
	global_position = source_pos
	var delta_vec = target_pos - source_pos
	var distance = delta_vec.length()
	# Rotation: sprite extends upward (negative Y), so angle toward target
	rotation = delta_vec.angle() + PI / 2.0
	# Scale Y so the sprite height matches the distance
	var scale_y = distance / float(_frame_size.y) * 1.2
	var scale_x = distance / float(_frame_size.y) * 1.2
	scale = Vector2(scale_x, scale_y)


func travel_to(source_pos: Vector2, target_pos: Vector2, projectile_scale: float = 1.0) -> void:
	"""Animate position from source to target over the animation duration."""
	_travel_from = source_pos
	_travel_to = target_pos
	_traveling = true
	_travel_duration = float(_total_frames) / _fps
	global_position = source_pos
	# Point sprite in travel direction
	var delta_vec = target_pos - source_pos
	rotation = delta_vec.angle() + PI / 2.0
	scale = Vector2(projectile_scale, projectile_scale)
	# Center the sprite instead of anchoring at bottom
	_sprite.offset = Vector2.ZERO
	# Additive blend makes black background transparent
	_sprite.material = CanvasItemMaterial.new()
	_sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


func _process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	var frame = int(_elapsed * _fps)
	if frame >= _total_frames:
		_finished = true
		queue_free()
		return
	if frame != _current_frame:
		_current_frame = frame
		_set_frame(frame)
	if _traveling and _travel_duration > 0.0:
		var t = clampf(_elapsed / _travel_duration, 0.0, 1.0)
		global_position = _travel_from.lerp(_travel_to, t)


func _set_frame(frame: int) -> void:
	var col = frame % _columns
	var row = frame / _columns
	_sprite.region_rect = Rect2(
		col * _frame_size.x,
		row * _frame_size.y,
		_frame_size.x,
		_frame_size.y
	)
