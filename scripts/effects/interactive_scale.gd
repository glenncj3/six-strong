class_name InteractiveScale
extends RefCounted
## Shared scale animation utility for interactive UI elements.
## Encapsulates the common pattern of hover/press/release scale tweens,
## providing a single source of truth for interactive feedback behavior.
##
## Usage:
##   var scaler = InteractiveScale.new(my_control)
##   scaler.hover()    # On mouse enter
##   scaler.unhover()  # On mouse exit
##   scaler.press()    # On button down
##   scaler.release()  # On button up (with bounce)

var _node: Control
var _current_tween: Tween = null
var hover_scale: float = GameConstants.HOVER_SCALE
var press_scale: float = GameConstants.PRESS_SCALE


func _init(node: Control, p_hover_scale: float = -1.0, p_press_scale: float = -1.0) -> void:
	_node = node
	if p_hover_scale > 0:
		hover_scale = p_hover_scale
	if p_press_scale > 0:
		press_scale = p_press_scale


func hover() -> void:
	"""Scale up for hover state."""
	_animate(hover_scale, GameConstants.ANIM_DURATION_FAST, false)


func unhover() -> void:
	"""Return to normal scale."""
	_animate(1.0, GameConstants.ANIM_DURATION_FAST, false)


func press() -> void:
	"""Compress scale for press state."""
	_animate(press_scale, GameConstants.ANIM_DURATION_INSTANT, false)


func release(is_hovered: bool = false) -> void:
	"""Bounce back on release, to hover scale if still hovered."""
	var target = hover_scale if is_hovered else 1.0
	_animate(target, GameConstants.ANIM_DURATION_FAST, true)


func animate_to(target: float, duration: float = -1.0, bounce: bool = false) -> void:
	"""Animate to an arbitrary scale value."""
	var d = duration if duration > 0 else GameConstants.ANIM_DURATION_FAST
	_animate(target, d, bounce)


func _animate(target: float, duration: float, bounce: bool) -> void:
	"""Core animation - kills previous tween, sets pivot, creates new tween."""
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()

	_node.pivot_offset = _node.size / 2
	_current_tween = _node.create_tween()
	_current_tween.set_ease(Tween.EASE_OUT)
	_current_tween.set_trans(Tween.TRANS_BACK if bounce else Tween.TRANS_CUBIC)
	_current_tween.tween_property(_node, "scale", Vector2(target, target), duration)
