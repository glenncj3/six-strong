extends Node
# TransitionManager Autoload
# Provides enhanced scene transitions with multiple effect types
# Uses shaders and tweens to create polished visual transitions
# Implements strategy pattern for extensible transition types

signal transition_started(type: GameConstants.TransitionType)
signal transition_midpoint  # Fires when old scene should be swapped
signal transition_completed(type: GameConstants.TransitionType)

# Reference to the transition layer (set by Main scene)
var _transition_layer: CanvasLayer = null
var _color_rect: ColorRect = null
var _is_transitioning: bool = false
var _current_type: GameConstants.TransitionType = GameConstants.TransitionType.FADE

# Shader materials (lazy-loaded)
var _dissolve_material: ShaderMaterial = null
var _wipe_material: ShaderMaterial = null

# Strategy pattern: registered transition handlers
# Each handler is a Dictionary with "out" and "in" Callables
var _transition_handlers: Dictionary = {}


func _ready() -> void:
	# Register built-in transition handlers
	_register_builtin_handlers()
	# Defer initialization until Main scene is ready
	call_deferred("_initialize")


func _register_builtin_handlers() -> void:
	"""Register all built-in transition type handlers."""
	register_handler(GameConstants.TransitionType.FADE, _fade_out, _fade_in)
	register_handler(GameConstants.TransitionType.SLIDE_LEFT,
		func(d): await _slide_out(Vector2.LEFT, d),
		func(d): await _slide_in(Vector2.RIGHT, d))
	register_handler(GameConstants.TransitionType.SLIDE_RIGHT,
		func(d): await _slide_out(Vector2.RIGHT, d),
		func(d): await _slide_in(Vector2.LEFT, d))
	register_handler(GameConstants.TransitionType.SLIDE_UP,
		func(d): await _slide_out(Vector2.UP, d),
		func(d): await _slide_in(Vector2.DOWN, d))
	register_handler(GameConstants.TransitionType.SLIDE_DOWN,
		func(d): await _slide_out(Vector2.DOWN, d),
		func(d): await _slide_in(Vector2.UP, d))
	register_handler(GameConstants.TransitionType.SCALE, _scale_out, _scale_in)
	register_handler(GameConstants.TransitionType.DISSOLVE, _dissolve_out, _dissolve_in)
	register_handler(GameConstants.TransitionType.WIPE_RADIAL,
		func(d): await _wipe_out(true, d),
		func(d): await _wipe_in(true, d))
	register_handler(GameConstants.TransitionType.WIPE_HORIZONTAL,
		func(d): await _wipe_out(false, d),
		func(d): await _wipe_in(false, d))


func register_handler(type: GameConstants.TransitionType, out_func: Callable, in_func: Callable) -> void:
	"""
	Register a transition handler for a specific type.
	Allows extending with custom transitions without modifying this class.

	Args:
		type: The transition type to handle
		out_func: Callable(duration: float) for the 'out' transition
		in_func: Callable(duration: float) for the 'in' transition
	"""
	_transition_handlers[type] = {"out": out_func, "in": in_func}


func _initialize() -> void:
	"""Initialize transition layer reference from Main scene."""
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		_transition_layer = main.get_node_or_null("TransitionLayer")
		_color_rect = main.get_node_or_null("TransitionLayer/ColorRect")
		if _color_rect:
			_color_rect.modulate.a = 0
			_color_rect.color = Color.BLACK


func is_transitioning() -> bool:
	"""Check if a transition is currently in progress."""
	return _is_transitioning


# =============================================================================
# PUBLIC API - Transition Out (first half)
# =============================================================================

func transition_out(type: GameConstants.TransitionType = GameConstants.TransitionType.FADE, duration: float = -1.0) -> void:
	"""
	Perform the 'out' half of a transition (hide current scene).

	Args:
		type: The transition type to use
		duration: Override duration, or -1 for default
	"""
	if _is_transitioning:
		push_warning("TransitionManager: Transition already in progress")
		return

	if not _color_rect:
		_initialize()
		if not _color_rect:
			push_error("TransitionManager: ColorRect not found")
			return

	_is_transitioning = true
	_current_type = type

	var actual_duration = duration if duration > 0 else GameConstants.ANIM_DURATION_NORMAL

	transition_started.emit(type)

	# Use registered handler or fallback to fade
	var handler = _transition_handlers.get(type, _transition_handlers.get(GameConstants.TransitionType.FADE))
	if handler and handler.has("out"):
		await handler["out"].call(actual_duration)
	else:
		await _fade_out(actual_duration)

	transition_midpoint.emit()


# =============================================================================
# PUBLIC API - Transition In (second half)
# =============================================================================

func transition_in(type: GameConstants.TransitionType = GameConstants.TransitionType.FADE, duration: float = -1.0) -> void:
	"""
	Perform the 'in' half of a transition (reveal new scene).
	Uses the same type as transition_out if called without specifying.

	Args:
		type: The transition type to use (defaults to current)
		duration: Override duration, or -1 for default
	"""
	if not _color_rect:
		push_error("TransitionManager: ColorRect not found")
		_is_transitioning = false
		return

	var actual_duration = duration if duration > 0 else GameConstants.ANIM_DURATION_NORMAL

	# Use registered handler or fallback to fade
	var handler = _transition_handlers.get(type, _transition_handlers.get(GameConstants.TransitionType.FADE))
	if handler and handler.has("in"):
		await handler["in"].call(actual_duration)
	else:
		await _fade_in(actual_duration)

	_is_transitioning = false
	transition_completed.emit(type)


# =============================================================================
# PUBLIC API - Full Transition (convenience)
# =============================================================================

func do_transition(type: GameConstants.TransitionType = GameConstants.TransitionType.FADE,
		duration: float = -1.0, callback: Callable = Callable()) -> void:
	"""
	Perform a complete transition with optional callback at midpoint.

	Args:
		type: The transition type to use
		duration: Duration for each half (total is 2x this)
		callback: Optional callable to execute at midpoint (scene swap)
	"""
	await transition_out(type, duration)

	if callback.is_valid():
		callback.call()

	# Small delay at midpoint for visual clarity
	await get_tree().create_timer(0.05).timeout

	await transition_in(type, duration)


# =============================================================================
# FADE TRANSITIONS
# =============================================================================

func _fade_out(duration: float) -> void:
	"""Fade to black."""
	_color_rect.material = null  # Remove any shader
	_color_rect.color = Color.BLACK
	_color_rect.modulate.a = 0

	var tween = create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(GameConstants.ANIM_TRANS_STANDARD)
	tween.tween_property(_color_rect, "modulate:a", 1.0, duration)
	await tween.finished


func _fade_in(duration: float) -> void:
	"""Fade from black."""
	var tween = create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(GameConstants.ANIM_TRANS_STANDARD)
	tween.tween_property(_color_rect, "modulate:a", 0.0, duration)
	await tween.finished


# =============================================================================
# SLIDE TRANSITIONS
# =============================================================================

func _slide_out(direction: Vector2, duration: float) -> void:
	"""Slide a cover panel in from the edge."""
	_color_rect.material = null
	_color_rect.color = Color.BLACK
	_color_rect.modulate.a = 1.0

	# Start off-screen in opposite direction
	var viewport_size = get_viewport().get_visible_rect().size
	var start_offset = -direction * viewport_size
	_color_rect.position = start_offset

	var tween = create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(GameConstants.ANIM_TRANS_STANDARD)
	tween.tween_property(_color_rect, "position", Vector2.ZERO, duration)
	await tween.finished


func _slide_in(direction: Vector2, duration: float) -> void:
	"""Slide the cover panel off to reveal new scene."""
	var viewport_size = get_viewport().get_visible_rect().size
	var end_offset = direction * viewport_size

	var tween = create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(GameConstants.ANIM_TRANS_STANDARD)
	tween.tween_property(_color_rect, "position", end_offset, duration)
	await tween.finished

	_color_rect.position = Vector2.ZERO
	_color_rect.modulate.a = 0


# =============================================================================
# SCALE TRANSITIONS
# =============================================================================

func _scale_out(duration: float) -> void:
	"""Scale up a dark overlay from the center."""
	_color_rect.material = null
	_color_rect.color = Color.BLACK
	_color_rect.modulate.a = 1.0

	# Start scaled down at center
	_color_rect.pivot_offset = _color_rect.size / 2
	_color_rect.scale = Vector2(0.01, 0.01)

	var tween = create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(GameConstants.ANIM_TRANS_BOUNCE)
	tween.tween_property(_color_rect, "scale", Vector2.ONE, duration)
	await tween.finished


func _scale_in(duration: float) -> void:
	"""Scale down the overlay to reveal new scene."""
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(GameConstants.ANIM_TRANS_STANDARD)
	tween.tween_property(_color_rect, "scale", Vector2(0.01, 0.01), duration)
	await tween.finished

	_color_rect.scale = Vector2.ONE
	_color_rect.modulate.a = 0


# =============================================================================
# DISSOLVE TRANSITIONS (shader-based)
# =============================================================================

func _dissolve_out(duration: float) -> void:
	"""Dissolve effect using noise shader."""
	_setup_dissolve_shader()
	_color_rect.modulate.a = 1.0
	_color_rect.material.set_shader_parameter("progress", 0.0)

	var tween = create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_set_dissolve_progress, 0.0, 1.0, duration)
	await tween.finished


func _dissolve_in(duration: float) -> void:
	"""Reverse dissolve effect."""
	var tween = create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_set_dissolve_progress, 1.0, 0.0, duration)
	await tween.finished

	_color_rect.material = null
	_color_rect.modulate.a = 0


func _set_dissolve_progress(value: float) -> void:
	"""Helper to set dissolve shader progress."""
	if _color_rect.material:
		_color_rect.material.set_shader_parameter("progress", value)


func _setup_dissolve_shader() -> void:
	"""Create and apply the dissolve shader."""
	if not _dissolve_material:
		var shader = Shader.new()
		shader.code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float noise = random(UV * 20.0);
	float threshold = progress;

	if (noise < threshold - edge_width) {
		COLOR = color;
	} else if (noise < threshold) {
		// Edge glow
		float edge = (threshold - noise) / edge_width;
		COLOR = mix(vec4(0.85, 0.65, 0.13, 1.0), color, edge);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
"""
		_dissolve_material = ShaderMaterial.new()
		_dissolve_material.shader = shader
		_dissolve_material.set_shader_parameter("color", Color.BLACK)

	_color_rect.material = _dissolve_material


# =============================================================================
# WIPE TRANSITIONS (shader-based)
# =============================================================================

func _wipe_out(radial: bool, duration: float) -> void:
	"""Wipe effect using shader."""
	_setup_wipe_shader(radial)
	_color_rect.modulate.a = 1.0
	_color_rect.material.set_shader_parameter("progress", 0.0)

	var tween = create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_set_wipe_progress, 0.0, 1.0, duration)
	await tween.finished


func _wipe_in(radial: bool, duration: float) -> void:
	"""Reverse wipe effect."""
	var tween = create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_set_wipe_progress, 1.0, 0.0, duration)
	await tween.finished

	_color_rect.material = null
	_color_rect.modulate.a = 0


func _set_wipe_progress(value: float) -> void:
	"""Helper to set wipe shader progress."""
	if _color_rect.material:
		_color_rect.material.set_shader_parameter("progress", value)


func _setup_wipe_shader(radial: bool) -> void:
	"""Create and apply the wipe shader."""
	var shader = Shader.new()

	if radial:
		shader.code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float softness : hint_range(0.0, 0.2) = 0.02;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	float max_dist = 0.707; // sqrt(0.5^2 + 0.5^2)
	float normalized_dist = dist / max_dist;

	float threshold = progress * 1.2; // Overshoot to ensure full coverage
	float alpha = smoothstep(threshold - softness, threshold, normalized_dist);

	COLOR = vec4(color.rgb, 1.0 - alpha);
}
"""
	else:
		shader.code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float softness : hint_range(0.0, 0.2) = 0.02;

void fragment() {
	float threshold = progress * 1.1; // Slight overshoot
	float alpha = smoothstep(threshold - softness, threshold, 1.0 - UV.x);

	COLOR = vec4(color.rgb, alpha);
}
"""

	_wipe_material = ShaderMaterial.new()
	_wipe_material.shader = shader
	_wipe_material.set_shader_parameter("color", Color.BLACK)
	_color_rect.material = _wipe_material


# =============================================================================
# UTILITY METHODS
# =============================================================================

func set_transition_color(color: Color) -> void:
	"""Set the color used for solid transitions (fade, slide, scale)."""
	if _color_rect:
		_color_rect.color = color


func get_current_transition_type() -> GameConstants.TransitionType:
	"""Get the currently active transition type."""
	return _current_type
