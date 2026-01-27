class_name SkillEffectRegistry
extends RefCounted
## Registry for skill effects. New effects are added via register(), not by
## modifying this class. Follows Open/Closed Principle.
##
## Usage:
##   var registry = SkillEffectRegistry.new()
##   registry.register_effect("heal_team", _effect_heal_team, "Heal all team members for {value} health")
##   registry.execute(skill_data, context)
##
## Effect handlers have signature:
##   func(effect_data: Dictionary, context: SkillContext) -> void

## Effect metadata structure:
##   {
##     "handler": Callable,
##     "description_template": String (with {value}, {stat} placeholders),
##     "validator": Callable (optional),
##     "is_lingering": bool
##   }
var _effects: Dictionary = {}

# Legacy support: maps effect_type -> handler only
var _handlers: Dictionary = {}


func register(effect_type: String, handler: Callable) -> void:
	"""
	Register a new effect handler (legacy method - use register_effect for full metadata).

	Args:
		effect_type: The effect type identifier (e.g., "heal_team")
		handler: Callable with signature (effect_data: Dictionary, context: SkillContext) -> void
	"""
	if effect_type.is_empty():
		push_warning("SkillEffectRegistry: Cannot register empty effect type")
		return
	if not handler.is_valid():
		push_warning("SkillEffectRegistry: Cannot register invalid handler for: %s" % effect_type)
		return
	_handlers[effect_type] = handler
	# Also update _effects for consistency
	if not _effects.has(effect_type):
		_effects[effect_type] = {
			"handler": handler,
			"description_template": "",
			"validator": Callable(),
			"is_lingering": false
		}
	else:
		_effects[effect_type]["handler"] = handler


func register_effect(
	effect_type: String,
	handler: Callable,
	description_template: String = "",
	validator: Callable = Callable(),
	is_lingering: bool = false
) -> void:
	"""
	Register a new effect handler with full metadata.

	Args:
		effect_type: The effect type identifier (e.g., "heal_team")
		handler: Callable with signature (effect_data: Dictionary, context: SkillContext) -> void
		description_template: Template string with {value}, {stat} placeholders
		validator: Optional validation callable (effect_data: Dictionary) -> bool
		is_lingering: Whether this effect persists beyond immediate execution
	"""
	if effect_type.is_empty():
		push_warning("SkillEffectRegistry: Cannot register empty effect type")
		return
	if not handler.is_valid():
		push_warning("SkillEffectRegistry: Cannot register invalid handler for: %s" % effect_type)
		return

	_effects[effect_type] = {
		"handler": handler,
		"description_template": description_template,
		"validator": validator,
		"is_lingering": is_lingering
	}
	_handlers[effect_type] = handler


func unregister(effect_type: String) -> bool:
	"""
	Unregister an effect handler.

	Args:
		effect_type: The effect type to unregister

	Returns:
		True if handler was found and removed, false otherwise
	"""
	if _handlers.has(effect_type):
		_handlers.erase(effect_type)
		return true
	return false


func execute(skill_data: Dictionary, context) -> bool:
	"""
	Execute a skill's effect using the registered handler.

	Args:
		skill_data: The full skill data dictionary from JSON
		context: SkillContext with run state references

	Returns:
		True if effect was executed successfully, false otherwise
	"""
	if not skill_data.has("effect"):
		push_warning("SkillEffectRegistry: Skill data missing 'effect' field")
		return false

	var effect = skill_data.get("effect", {})
	var effect_type = effect.get("type", "")

	if effect_type.is_empty():
		push_warning("SkillEffectRegistry: Effect missing 'type' field")
		return false

	if not _handlers.has(effect_type):
		push_warning("SkillEffectRegistry: Unknown skill effect type: %s" % effect_type)
		return false

	# Call the handler with the effect data and context
	_handlers[effect_type].call(effect, context)
	return true


func has_effect(effect_type: String) -> bool:
	"""
	Check if an effect handler is registered.

	Args:
		effect_type: The effect type to check

	Returns:
		True if handler exists, false otherwise
	"""
	return _handlers.has(effect_type)


func get_registered_effects() -> Array[String]:
	"""
	Get a list of all registered effect types.

	Returns:
		Array of effect type strings
	"""
	var result: Array[String] = []
	for key in _handlers.keys():
		result.append(key)
	return result


func clear() -> void:
	"""Remove all registered handlers."""
	_handlers.clear()


func get_handler_count() -> int:
	"""Get the number of registered handlers."""
	return _handlers.size()


# =============================================================================
# DESCRIPTION AND VALIDATION (Phase 4 Extension)
# =============================================================================

func get_effect_description(effect_data: Dictionary) -> String:
	"""
	Generate a human-readable description of an effect using the registered template.

	Args:
		effect_data: The effect dictionary with type, value, stat, etc.

	Returns:
		A description string for display, or "Unknown effect: {type}" if not registered
	"""
	var effect_type = effect_data.get("type", "")
	if not _effects.has(effect_type):
		return "Unknown effect: %s" % effect_type

	var template = _effects[effect_type].get("description_template", "")
	if template.is_empty():
		return "Unknown effect: %s" % effect_type

	# Interpolate placeholders
	var description = template
	var value = effect_data.get("value", 0)
	description = description.replace("{value}", str(value))

	# Handle stat placeholder if present
	if "{stat}" in description:
		var stat = effect_data.get("stat", "")
		var stat_name = _get_stat_display_name(stat)
		description = description.replace("{stat}", stat_name)

	return description


func is_valid_effect(effect_data: Dictionary) -> bool:
	"""
	Check if effect data is valid using the registered validator or default logic.

	Args:
		effect_data: The effect dictionary

	Returns:
		True if the effect is valid
	"""
	if not effect_data.has("type"):
		return false

	var effect_type = effect_data.get("type", "")

	# Effect type must be registered
	if not _effects.has(effect_type):
		return false

	# Use custom validator if provided
	var validator = _effects[effect_type].get("validator", Callable())
	if validator.is_valid():
		return validator.call(effect_data)

	# Default validation: check that value > 0 for most effects
	var value = effect_data.get("value", 0)
	return value > 0


func is_lingering_effect(effect_type: String) -> bool:
	"""
	Check if an effect type is a lingering effect (not instant).

	Args:
		effect_type: The effect type identifier

	Returns:
		True if the effect is marked as lingering
	"""
	if not _effects.has(effect_type):
		return false
	return _effects[effect_type].get("is_lingering", false)


func _get_stat_display_name(stat: String) -> String:
	"""Convert a stat key to a display-friendly name."""
	# Fallback mappings for common stats
	var stat_names = {
		"health": "Health",
		"mana": "Mana",
		"defendRate": "Defend Rate",
		"income": "Income",
		"itemSlots": "Item Slots",
		"startingItemSlots": "Starting Slots"
	}
	if stat_names.has(stat):
		return stat_names[stat]
	return stat.capitalize()
