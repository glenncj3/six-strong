class_name RewardHandlerRegistry
extends RefCounted
## Registry for reward application handlers.
## Replaces match statements with pluggable handler registration.
## Follows the same pattern as SkillEffectRegistry and EncounterRegistry.
##
## Code Quality Refactor (Phase 3):
## - Enables extensibility without modifying RewardApplicator
## - Each reward type has its own handler + validator
## - New reward types can be added via registration


## Handler signature: func(definition: RewardDefinition, context: Dictionary, target_char: Variant) -> RewardApplicator.ApplyResult
## Validator signature: func(definition: RewardDefinition, target_char: Variant) -> Dictionary{"valid": bool, "reason": String}

var _handlers: Dictionary = {}  # reward_type (int) -> Callable
var _validators: Dictionary = {}  # reward_type (int) -> Callable


func register(reward_type: int, handler: Callable, validator: Callable = Callable()) -> void:
	"""
	Register a handler (and optional validator) for a reward type.

	Args:
		reward_type: RewardTypes.RewardType enum value
		handler: Callable(definition, context, target_char) -> ApplyResult
		validator: Callable(definition, target_char) -> Dictionary (optional)
	"""
	_handlers[reward_type] = handler
	if validator.is_valid():
		_validators[reward_type] = validator


func execute(
	definition: RewardDefinition,
	context: Dictionary = {},
	target_char: Variant = null
) -> RewardApplicator.ApplyResult:
	"""
	Execute a reward using the registered handler.

	Args:
		definition: The reward to apply
		context: Optional callbacks dictionary
		target_char: Target character for health/XP rewards (optional)

	Returns:
		ApplyResult with success status and message
	"""
	if not _handlers.has(definition.type):
		return RewardApplicator.ApplyResult.new(false, "Unknown reward type: %d" % definition.type)

	return _handlers[definition.type].call(definition, context, target_char)


func validate(definition: RewardDefinition, target_char: Variant = null) -> Dictionary:
	"""
	Validate a reward can be applied using the registered validator.

	Args:
		definition: The reward to validate
		target_char: Target character (optional)

	Returns:
		Dictionary with "valid": bool, "reason": String
	"""
	if not _validators.has(definition.type):
		# No validator = always valid
		return {"valid": true, "reason": ""}

	return _validators[definition.type].call(definition, target_char)


func has_handler(reward_type: int) -> bool:
	"""Check if a handler is registered for the given reward type."""
	return _handlers.has(reward_type)


func get_registered_types() -> Array:
	"""Get all registered reward types."""
	return _handlers.keys()
