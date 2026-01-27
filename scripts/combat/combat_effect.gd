class_name CombatEffect
extends RefCounted
## Unified effect structure for combat modifiers and triggers.

static var _next_id: int = 0

var id: String = ""
var source_type: String = ""  # "character", "item", or "skill"
var source_id: String = ""

# What the effect does
var effect_type: String = ""  # "stat_modifier", "triggered", "on_tick"

# For stat_modifier effects
var stat: String = ""
var value: float = 0.0
var modifier_type: String = ""  # "flat" or "percent"

# For triggered effects
var trigger: String = ""
var action: Callable

# Duration
var duration_type: String = ""  # "seconds", "cooldowns", "permanent", "combat"
var duration_value: float = 0.0

# Targeting
var target_type: String = "self"  # "self", "source", "specific"
var target_id: String = ""


static func _generate_id() -> String:
	_next_id += 1
	return "effect_%d" % _next_id


static func create_stat_modifier(
	p_source_type: String,
	p_source_id: String,
	p_stat: String,
	p_value: float,
	p_modifier_type: String,
	p_duration_type: String,
	p_duration_value: float = 0.0
) -> CombatEffect:
	var e = CombatEffect.new()
	e.id = _generate_id()
	e.source_type = p_source_type
	e.source_id = p_source_id
	e.effect_type = "stat_modifier"
	e.stat = p_stat
	e.value = p_value
	e.modifier_type = p_modifier_type
	e.duration_type = p_duration_type
	e.duration_value = p_duration_value
	return e


static func create_triggered(
	p_source_type: String,
	p_source_id: String,
	p_trigger: String,
	p_action: Callable,
	p_duration_type: String,
	p_duration_value: float = 0.0
) -> CombatEffect:
	var e = CombatEffect.new()
	e.id = _generate_id()
	e.source_type = p_source_type
	e.source_id = p_source_id
	e.effect_type = "triggered"
	e.trigger = p_trigger
	e.action = p_action
	e.duration_type = p_duration_type
	e.duration_value = p_duration_value
	return e
