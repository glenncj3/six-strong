class_name ButtonEffects
extends RefCounted
# ButtonEffects - Adds visual interaction effects to buttons
# Provides hover scale, press compress, and release bounce animations
# Uses InteractiveScale for consistent animation behavior

const InteractiveScaleClass = preload("res://scripts/effects/interactive_scale.gd")

# Track connected buttons and their scalers to avoid duplicate connections
static var _connected_buttons: Dictionary = {}  # button_id -> InteractiveScale


static func apply_effects(button: BaseButton) -> void:
	"""
	Apply hover/press/release effects to a button.

	Args:
		button: The BaseButton (Button, TextureButton, etc.) to enhance
	"""
	if button == null:
		return

	# Avoid duplicate connections
	var button_id = button.get_instance_id()
	if _connected_buttons.has(button_id):
		return

	# Create InteractiveScale instance for this button
	var scaler = InteractiveScaleClass.new(button)
	_connected_buttons[button_id] = scaler

	# Connect signals using shared InteractiveScale
	button.mouse_entered.connect(func():
		if not button.disabled:
			scaler.hover())
	button.mouse_exited.connect(func():
		if not button.disabled:
			scaler.unhover())
	button.button_down.connect(func():
		if not button.disabled:
			scaler.press())
	button.button_up.connect(func():
		if not button.disabled:
			var is_hovered = button.get_global_rect().has_point(button.get_global_mouse_position())
			scaler.release(is_hovered))

	# Clean up on tree exit
	button.tree_exiting.connect(func():
		_connected_buttons.erase(button_id))


static func apply_effects_to_children(parent: Node) -> void:
	"""
	Apply effects to all BaseButton children of a node.

	Args:
		parent: Parent node to search for buttons
	"""
	for child in parent.get_children():
		if child is BaseButton:
			apply_effects(child)
		# Recurse into containers
		if child.get_child_count() > 0:
			apply_effects_to_children(child)


# =============================================================================
# ENHANCED EFFECTS WITH LIFT (for special buttons)
# =============================================================================

static func apply_effects_with_lift(button: BaseButton, lift_amount: float = 4.0) -> void:
	"""
	Apply hover/press effects with vertical lift on hover.
	Use for special buttons that need extra prominence.

	Args:
		button: The BaseButton to enhance
		lift_amount: Pixels to lift on hover
	"""
	if button == null:
		return

	# Avoid duplicate connections
	var button_id = button.get_instance_id()
	if _connected_buttons.has(button_id):
		return

	# Create InteractiveScale for this button
	var scaler = InteractiveScaleClass.new(button)
	_connected_buttons[button_id] = scaler

	# Store original Y position for lift
	var original_y = button.position.y if button is Control else 0.0

	# Connect signals with lift behavior
	button.mouse_entered.connect(func():
		if not button.disabled:
			scaler.hover()
			_animate_lift(button, original_y - lift_amount, GameConstants.ANIM_DURATION_FAST, false))
	button.mouse_exited.connect(func():
		if not button.disabled:
			scaler.unhover()
			_animate_lift(button, original_y, GameConstants.ANIM_DURATION_FAST, false))
	button.button_down.connect(func():
		if not button.disabled:
			scaler.press())
	button.button_up.connect(func():
		if not button.disabled:
			var is_hovered = button.get_global_rect().has_point(button.get_global_mouse_position())
			scaler.release(is_hovered)
			var target_y = (original_y - lift_amount) if is_hovered else original_y
			_animate_lift(button, target_y, GameConstants.ANIM_DURATION_FAST, true))

	# Clean up on tree exit
	button.tree_exiting.connect(func():
		_connected_buttons.erase(button_id))


static func _animate_lift(button: BaseButton, target_y: float, duration: float, bounce: bool) -> void:
	"""Helper to animate button Y position (lift effect)."""
	if not button is Control:
		return

	var tween = button.create_tween()
	tween.set_ease(GameConstants.ANIM_EASE_STANDARD)
	tween.set_trans(GameConstants.ANIM_TRANS_BOUNCE if bounce else GameConstants.ANIM_TRANS_STANDARD)
	tween.tween_property(button, "position:y", target_y, duration)
