extends Node
# AnimationManager Autoload
# Provides reusable animation presets for UI elements
# Centralizes animation logic for consistent visual polish

# =============================================================================
# TWEEN FACTORY HELPER
# =============================================================================

func _create_tween(node: Node, delay: float = 0.0,
		ease_type: Tween.EaseType = Tween.EASE_OUT,
		trans_type: Tween.TransitionType = Tween.TRANS_CUBIC) -> Tween:
	"""
	Create a configured tween with standard settings.

	Args:
		node: The node to create the tween on
		delay: Optional delay before animation starts
		ease_type: Easing type (default: EASE_OUT)
		trans_type: Transition type (default: TRANS_CUBIC)

	Returns:
		Configured Tween ready for property tweening
	"""
	var tween = node.create_tween()
	tween.set_ease(ease_type)
	tween.set_trans(trans_type)
	if delay > 0:
		tween.tween_interval(delay)
	return tween


func _get_duration(duration: float, default: float) -> float:
	"""Return duration if positive, otherwise return default."""
	return duration if duration > 0 else default


# =============================================================================
# ENTRANCE ANIMATIONS
# =============================================================================

func fade_in(node: CanvasItem, duration: float = -1.0, delay: float = 0.0) -> Tween:
	"""
	Fade a node in from transparent to opaque.

	Args:
		node: The CanvasItem to animate
		duration: Animation duration (default: ANIM_DURATION_FAST)
		delay: Delay before starting animation

	Returns:
		The Tween object for chaining
	"""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)
	node.modulate.a = 0

	var tween = _create_tween(node, delay)
	tween.tween_property(node, "modulate:a", 1.0, d)
	return tween


func fade_out(node: CanvasItem, duration: float = -1.0, delay: float = 0.0) -> Tween:
	"""
	Fade a node out from opaque to transparent.

	Args:
		node: The CanvasItem to animate
		duration: Animation duration (default: ANIM_DURATION_FAST)
		delay: Delay before starting animation

	Returns:
		The Tween object for chaining
	"""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)

	var tween = _create_tween(node, delay)
	tween.tween_property(node, "modulate:a", 0.0, d)
	return tween


func scale_pop(node: Control, duration: float = -1.0, delay: float = 0.0) -> Tween:
	"""
	Pop in with scale overshoot effect (0.8 -> 1.05 -> 1.0).

	Args:
		node: The Control to animate
		duration: Animation duration (default: ANIM_DURATION_NORMAL)
		delay: Delay before starting animation

	Returns:
		The Tween object for chaining
	"""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_NORMAL)

	# Set pivot to center
	node.pivot_offset = node.size / 2
	node.scale = Vector2(0.8, 0.8)
	node.modulate.a = 0

	var tween = _create_tween(node, delay, GameConstants.ANIM_EASE_STANDARD, GameConstants.ANIM_TRANS_BOUNCE)
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector2.ONE, d)
	tween.tween_property(node, "modulate:a", 1.0, d * 0.5)

	return tween


func slide_in(node: Control, from_direction: Vector2, distance: float = 50.0,
		duration: float = -1.0, delay: float = 0.0) -> Tween:
	"""
	Slide in from a direction with fade.

	Args:
		node: The Control to animate
		from_direction: Normalized direction vector (e.g., Vector2.DOWN for slide up)
		distance: How far to slide from
		duration: Animation duration (default: ANIM_DURATION_NORMAL)
		delay: Delay before starting animation

	Returns:
		The Tween object for chaining
	"""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_NORMAL)
	var start_pos = node.position + from_direction * distance
	var end_pos = node.position

	node.position = start_pos
	node.modulate.a = 0

	var tween = _create_tween(node, delay)
	tween.set_parallel(true)
	tween.tween_property(node, "position", end_pos, d)
	tween.tween_property(node, "modulate:a", 1.0, d * 0.7)

	return tween


func slide_in_from_bottom(node: Control, distance: float = 50.0,
		duration: float = -1.0, delay: float = 0.0) -> Tween:
	"""Convenience method: Slide in from bottom."""
	return slide_in(node, Vector2.DOWN, distance, duration, delay)


func slide_in_from_top(node: Control, distance: float = 50.0,
		duration: float = -1.0, delay: float = 0.0) -> Tween:
	"""Convenience method: Slide in from top."""
	return slide_in(node, Vector2.UP, distance, duration, delay)


func slide_in_from_left(node: Control, distance: float = 50.0,
		duration: float = -1.0, delay: float = 0.0) -> Tween:
	"""Convenience method: Slide in from left."""
	return slide_in(node, Vector2.LEFT, distance, duration, delay)


func slide_in_from_right(node: Control, distance: float = 50.0,
		duration: float = -1.0, delay: float = 0.0) -> Tween:
	"""Convenience method: Slide in from right."""
	return slide_in(node, Vector2.RIGHT, distance, duration, delay)


# =============================================================================
# CASCADE ANIMATIONS
# =============================================================================

func cascade_children(parent: Node, animation_func: Callable,
		delay_between: float = -1.0) -> Array[Tween]:
	"""
	Apply an animation function to all child Controls with staggered delay.

	Args:
		parent: Parent node whose children to animate
		animation_func: Function that takes (node, delay) and returns Tween
		delay_between: Delay between each child (default: CASCADE_DELAY)

	Returns:
		Array of all created Tweens
	"""
	var delay = delay_between if delay_between > 0 else GameConstants.CASCADE_DELAY
	var tweens: Array[Tween] = []
	var index = 0

	for child in parent.get_children():
		if child is Control:
			var tween = animation_func.call(child, index * delay)
			if tween:
				tweens.append(tween)
			index += 1

	return tweens


func cascade_fade_in(parent: Node, delay_between: float = -1.0) -> Array[Tween]:
	"""Cascade fade in all Control children."""
	return cascade_children(parent, func(node, delay): return fade_in(node, -1, delay), delay_between)


func cascade_scale_pop(parent: Node, delay_between: float = -1.0) -> Array[Tween]:
	"""Cascade scale pop all Control children."""
	return cascade_children(parent, func(node, delay): return scale_pop(node, -1, delay), delay_between)


func cascade_slide_in_from_bottom(parent: Node, delay_between: float = -1.0) -> Array[Tween]:
	"""Cascade slide in from bottom for all Control children."""
	return cascade_children(parent, func(node, delay): return slide_in_from_bottom(node, 30, -1, delay), delay_between)


# =============================================================================
# EXIT ANIMATIONS
# =============================================================================

func scale_out(node: Control, duration: float = -1.0) -> Tween:
	"""Scale out and fade (reverse of scale_pop)."""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)

	node.pivot_offset = node.size / 2

	var tween = _create_tween(node, 0.0, Tween.EASE_IN, GameConstants.ANIM_TRANS_STANDARD)
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector2(0.8, 0.8), d)
	tween.tween_property(node, "modulate:a", 0.0, d)

	return tween


func slide_out(node: Control, to_direction: Vector2, distance: float = 50.0,
		duration: float = -1.0) -> Tween:
	"""Slide out in a direction with fade."""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)
	var end_pos = node.position + to_direction * distance

	var tween = _create_tween(node, 0.0, Tween.EASE_IN, GameConstants.ANIM_TRANS_STANDARD)
	tween.set_parallel(true)
	tween.tween_property(node, "position", end_pos, d)
	tween.tween_property(node, "modulate:a", 0.0, d)

	return tween


# =============================================================================
# INTERACTIVE FEEDBACK ANIMATIONS
# =============================================================================

func hover_scale_up(node: Control, scale: float = -1.0, duration: float = -1.0) -> Tween:
	"""
	Scale up on hover.

	Args:
		node: The Control to animate
		scale: Target scale (default: HOVER_SCALE)
		duration: Animation duration (default: ANIM_DURATION_FAST)

	Returns:
		The Tween object
	"""
	var s = scale if scale > 0 else GameConstants.HOVER_SCALE
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)

	node.pivot_offset = node.size / 2

	var tween = _create_tween(node)
	tween.tween_property(node, "scale", Vector2(s, s), d)

	return tween


func hover_scale_down(node: Control, duration: float = -1.0) -> Tween:
	"""Return to normal scale after hover."""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)

	var tween = _create_tween(node)
	tween.tween_property(node, "scale", Vector2.ONE, d)

	return tween


func press_scale(node: Control, scale: float = -1.0, duration: float = -1.0) -> Tween:
	"""
	Scale down on press.

	Args:
		node: The Control to animate
		scale: Target scale (default: PRESS_SCALE)
		duration: Animation duration (default: ANIM_DURATION_INSTANT)

	Returns:
		The Tween object
	"""
	var s = scale if scale > 0 else GameConstants.PRESS_SCALE
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_INSTANT)

	node.pivot_offset = node.size / 2

	var tween = _create_tween(node, 0.0, Tween.EASE_OUT, Tween.TRANS_QUAD)
	tween.tween_property(node, "scale", Vector2(s, s), d)

	return tween


func release_bounce(node: Control, duration: float = -1.0) -> Tween:
	"""Bounce back to normal scale on release (with overshoot)."""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)

	var tween = _create_tween(node, 0.0, GameConstants.ANIM_EASE_STANDARD, GameConstants.ANIM_TRANS_BOUNCE)
	tween.tween_property(node, "scale", Vector2.ONE, d)

	return tween


# =============================================================================
# CARD-SPECIFIC ANIMATIONS
# =============================================================================

func card_hover_lift(node: Control, lift: float = -1.0, duration: float = -1.0) -> Tween:
	"""
	Lift card on hover (move up + slight scale).

	Args:
		node: The card Control to animate
		lift: Pixels to lift (default: CARD_HOVER_LIFT)
		duration: Animation duration

	Returns:
		The Tween object
	"""
	var l = lift if lift > 0 else GameConstants.CARD_HOVER_LIFT
	var s = GameConstants.CARD_HOVER_SCALE
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)

	node.pivot_offset = node.size / 2

	var tween = _create_tween(node)
	tween.set_parallel(true)
	tween.tween_property(node, "position:y", node.position.y - l, d)
	tween.tween_property(node, "scale", Vector2(s, s), d)

	return tween


func card_hover_drop(node: Control, original_y: float, duration: float = -1.0) -> Tween:
	"""
	Drop card back to original position.

	Args:
		node: The card Control to animate
		original_y: The original Y position to return to
		duration: Animation duration

	Returns:
		The Tween object
	"""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)

	var tween = _create_tween(node)
	tween.set_parallel(true)
	tween.tween_property(node, "position:y", original_y, d)
	tween.tween_property(node, "scale", Vector2.ONE, d)

	return tween


func card_select_bounce(node: Control, duration: float = -1.0) -> Tween:
	"""Selection animation with bounce effect."""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_NORMAL)

	node.pivot_offset = node.size / 2

	var tween = _create_tween(node, 0.0, GameConstants.ANIM_EASE_STANDARD, GameConstants.ANIM_TRANS_BOUNCE)
	# Quick scale up then settle
	tween.tween_property(node, "scale", Vector2(1.1, 1.1), d * 0.3)
	tween.tween_property(node, "scale", Vector2.ONE, d * 0.7)

	return tween


# =============================================================================
# VALUE CHANGE ANIMATIONS
# =============================================================================

func number_pop(label: Label, new_value: String, color: Color = Color.WHITE,
		duration: float = -1.0) -> Tween:
	"""
	Animate a label text change with scale pop.

	Args:
		label: The Label node
		new_value: New text to display
		color: Flash color for the change
		duration: Animation duration

	Returns:
		The Tween object
	"""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_FAST)
	var original_color = label.modulate

	label.pivot_offset = label.size / 2

	var tween = _create_tween(label, 0.0, GameConstants.ANIM_EASE_STANDARD, GameConstants.ANIM_TRANS_BOUNCE)

	# Scale up and flash color
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), d * 0.3)
	tween.tween_property(label, "modulate", color, d * 0.3)

	tween.set_parallel(false)
	tween.tween_callback(func(): label.text = new_value)

	# Scale back and restore color
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, d * 0.7)
	tween.tween_property(label, "modulate", original_color, d * 0.7)

	return tween


func count_up(label: Label, from_value: int, to_value: int,
		duration: float = -1.0, prefix: String = "", suffix: String = "") -> Tween:
	"""
	Animate counting from one number to another.

	Args:
		label: The Label node
		from_value: Starting number
		to_value: Ending number
		duration: Animation duration
		prefix: Text before the number
		suffix: Text after the number

	Returns:
		The Tween object
	"""
	var d = _get_duration(duration, GameConstants.ANIM_DURATION_SLOW)

	var tween = _create_tween(label, 0.0, Tween.EASE_OUT, Tween.TRANS_QUAD)

	tween.tween_method(
		func(value: int):
			label.text = prefix + str(value) + suffix,
		from_value, to_value, d
	)

	return tween


# =============================================================================
# AMBIENT ANIMATIONS
# =============================================================================

func pulse(node: CanvasItem, min_alpha: float = 0.8, max_alpha: float = 1.0,
		duration: float = 1.0) -> Tween:
	"""
	Create a continuous pulsing effect.

	Args:
		node: The CanvasItem to animate
		min_alpha: Minimum alpha value
		max_alpha: Maximum alpha value
		duration: Full cycle duration

	Returns:
		The Tween object (loops infinitely)
	"""
	var tween = _create_tween(node, 0.0, Tween.EASE_IN_OUT, Tween.TRANS_SINE)
	tween.set_loops()
	tween.tween_property(node, "modulate:a", min_alpha, duration / 2)
	tween.tween_property(node, "modulate:a", max_alpha, duration / 2)

	return tween


func gentle_bob(node: Control, amplitude: float = 3.0, duration: float = 2.0) -> Tween:
	"""
	Create a gentle bobbing/floating effect.

	Args:
		node: The Control to animate
		amplitude: Pixels to move up/down
		duration: Full cycle duration

	Returns:
		The Tween object (loops infinitely)
	"""
	var original_y = node.position.y

	var tween = _create_tween(node, 0.0, Tween.EASE_IN_OUT, Tween.TRANS_SINE)
	tween.set_loops()
	tween.tween_property(node, "position:y", original_y - amplitude, duration / 2)
	tween.tween_property(node, "position:y", original_y + amplitude, duration / 2)

	return tween


# =============================================================================
# SCREEN SHAKE
# =============================================================================

func shake(node: CanvasItem, intensity: float = -1.0, duration: float = -1.0) -> Tween:
	"""
	Apply screen shake effect.

	Args:
		node: The CanvasItem to shake (usually a container)
		intensity: Shake intensity in pixels (default: SHAKE_INTENSITY_LIGHT)
		duration: Shake duration (default: SHAKE_DURATION_NORMAL)

	Returns:
		The Tween object
	"""
	var i = intensity if intensity > 0 else GameConstants.SHAKE_INTENSITY_LIGHT
	var d = _get_duration(duration, GameConstants.SHAKE_DURATION_NORMAL)

	var original_pos = node.position if node is Control else (node as Node2D).position
	var shake_count = int(d / 0.05)  # Shake every 50ms

	var tween = node.create_tween()

	for j in range(shake_count):
		var offset = Vector2(randf_range(-i, i), randf_range(-i, i))
		# Reduce intensity over time
		offset *= (1.0 - float(j) / shake_count)
		tween.tween_property(node, "position", original_pos + offset, 0.05)

	# Return to original
	tween.tween_property(node, "position", original_pos, 0.05)

	return tween


func error_shake(node: Control) -> Tween:
	"""Quick horizontal shake for invalid actions."""
	var original_x = node.position.x
	var intensity = GameConstants.SHAKE_INTENSITY_LIGHT

	var tween = node.create_tween()
	tween.tween_property(node, "position:x", original_x - intensity, 0.05)
	tween.tween_property(node, "position:x", original_x + intensity, 0.05)
	tween.tween_property(node, "position:x", original_x - intensity * 0.5, 0.05)
	tween.tween_property(node, "position:x", original_x + intensity * 0.5, 0.05)
	tween.tween_property(node, "position:x", original_x, 0.05)

	return tween
