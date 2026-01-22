class_name FloatingNumber
extends Node2D
## Floating number popup for damage, healing, gold, XP, etc.
## Spawns, animates upward with scale pop, then fades out.

@onready var label: Label = $Label

var _value: String = ""
var _color: Color = Color.WHITE
var _duration: float = 1.0
var _rise_distance: float = 50.0
var _start_scale: float = 0.5
var _peak_scale: float = 1.2
var _is_critical: bool = false


func _ready() -> void:
	# Start invisible
	modulate.a = 0
	scale = Vector2(_start_scale, _start_scale)

	# Configure label
	label.text = _value
	label.add_theme_color_override("font_color", _color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Start animation
	_play_animation()


func setup(value: String, color: Color = Color.WHITE, is_critical: bool = false) -> void:
	"""Configure the floating number before adding to scene."""
	_value = value
	_color = color
	_is_critical = is_critical

	if is_critical:
		_peak_scale = 1.5
		_rise_distance = 70.0
		_duration = 1.2


func _play_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade in quickly
	tween.tween_property(self, "modulate:a", 1.0, GameConstants.ANIM_DURATION_INSTANT)

	# Scale pop: small -> big -> normal
	tween.tween_property(self, "scale", Vector2(_peak_scale, _peak_scale), GameConstants.ANIM_DURATION_FAST * 0.75) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	tween.set_parallel(false)
	tween.tween_property(self, "scale", Vector2.ONE, GameConstants.ANIM_DURATION_FAST) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Rise upward
	tween.set_parallel(true)
	var end_pos = position + Vector2(0, -_rise_distance)
	tween.tween_property(self, "position", end_pos, _duration * 0.8) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Fade out at end
	tween.tween_property(self, "modulate:a", 0.0, _duration * 0.4) \
		.set_delay(_duration * 0.5)

	# Critical shake
	if _is_critical:
		tween.set_parallel(false)
		_add_shake(tween)

	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _add_shake(tween: Tween) -> void:
	"""Add shake effect for critical hits."""
	var base_x = position.x
	var shake_step = GameConstants.ANIM_DURATION_INSTANT * 0.3  # Quick shake steps
	for i in range(3):
		var offset = GameConstants.SHAKE_INTENSITY_LIGHT * (1.0 - float(i) / 3.0)
		tween.tween_property(self, "position:x", base_x + offset, shake_step)
		tween.tween_property(self, "position:x", base_x - offset, shake_step)
	tween.tween_property(self, "position:x", base_x, shake_step)


# =============================================================================
# STATIC FACTORY METHODS
# =============================================================================

static func create_damage(value: int, is_critical: bool = false) -> FloatingNumber:
	"""Create a damage number popup."""
	var popup = _create_instance()
	var color = GameConstants.COLOR_RUBY if not is_critical else Color(1.0, 0.3, 0.3)
	popup.setup("-" + str(value), color, is_critical)
	return popup


static func create_heal(value: int) -> FloatingNumber:
	"""Create a healing number popup."""
	var popup = _create_instance()
	popup.setup("+" + str(value), GameConstants.COLOR_EMERALD)
	return popup


static func create_gold(value: int, is_gain: bool = true) -> FloatingNumber:
	"""Create a gold change popup."""
	var popup = _create_instance()
	var prefix = "+" if is_gain else "-"
	popup.setup(prefix + str(value), GameConstants.COLOR_GOLD)
	return popup


static func create_xp(value: int) -> FloatingNumber:
	"""Create an XP gain popup."""
	var popup = _create_instance()
	popup.setup("+" + str(value) + " XP", GameConstants.COLOR_AMETHYST)
	return popup


static func create_custom(text: String, color: Color, is_critical: bool = false) -> FloatingNumber:
	"""Create a custom text popup."""
	var popup = _create_instance()
	popup.setup(text, color, is_critical)
	return popup


static func _create_instance() -> FloatingNumber:
	"""Create a new FloatingNumber instance."""
	var scene = load("res://scenes/effects/floating_number.tscn")
	return scene.instantiate()
