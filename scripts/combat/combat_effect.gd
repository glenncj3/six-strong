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

# Status effect fields (all default to inert values so existing code is unaffected)
var effect_id: String = ""           # "poison", "haste" — identity for merging
var stacks: int = 0                  # 0 = non-stackable
var max_stacks: int = 0             # 0 = unlimited
var tick_interval: float = 0.0      # seconds between ticks (0 = no ticking)
var tick_elapsed: float = 0.0       # internal timer
var on_tick: Callable                # called each tick
var merge_behavior: String = "none"  # "add_stacks", "refresh_duration", "extend_duration"
var tags: Array = []                 # ["debuff", "dot"], ["buff", "speed"]
var continuous_modifier: String = "" # "cooldown_tick_rate"
var continuous_value: float = 0.0    # 2.0 for haste
var on_apply: Callable               # called when effect is applied or merged


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


static func create_status_effect(config: Dictionary) -> CombatEffect:
	var e = CombatEffect.new()
	e.id = _generate_id()
	e.source_type = config.get("source_type", "")
	e.source_id = config.get("source_id", "")
	e.effect_type = config.get("effect_type", "status")
	e.effect_id = config.get("effect_id", "")
	e.stacks = config.get("stacks", 0)
	e.max_stacks = config.get("max_stacks", 0)
	e.tick_interval = config.get("tick_interval", 0.0)
	e.on_tick = config.get("on_tick", Callable())
	e.merge_behavior = config.get("merge_behavior", "none")
	e.tags = config.get("tags", [])
	e.continuous_modifier = config.get("continuous_modifier", "")
	e.continuous_value = config.get("continuous_value", 0.0)
	e.on_apply = config.get("on_apply", Callable())
	e.duration_type = config.get("duration_type", "permanent")
	e.duration_value = config.get("duration_value", 0.0)
	# Also support stat_modifier fields for hybrid effects
	e.stat = config.get("stat", "")
	e.value = config.get("value", 0.0)
	e.modifier_type = config.get("modifier_type", "")
	return e
