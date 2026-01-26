class_name SkillEffectRegistry
extends RefCounted
## Registry for skill effects. New effects are added via register(), not by
## modifying this class. Follows Open/Closed Principle.
##
## Usage:
##   var registry = SkillEffectRegistry.new()
##   registry.register("heal_team", _effect_heal_team)
##   registry.execute(skill_data, context)
##
## Effect handlers have signature:
##   func(effect_data: Dictionary, context: SkillContext) -> void

# effect_type -> Callable(effect_data: Dictionary, context: SkillContext) -> void
var _handlers: Dictionary = {}


func register(effect_type: String, handler: Callable) -> void:
	"""
	Register a new effect handler.

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
