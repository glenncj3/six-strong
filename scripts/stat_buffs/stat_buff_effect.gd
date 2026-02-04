class_name StatBuffEffect
extends RefCounted
## Composite stat buff effect that combines target resolution with stat modifiers.
## Executes multiple stat modifications on resolved targets.
##
## Usage:
##   var effect = StatBuffEffect.from_dict(effect_data)
##   effect.execute(drop_target, context)
##
## JSON format:
##   {
##     "type": "stat_buff",
##     "target_mode": "dropped",
##     "modifiers": [
##       { "stat": "health", "modifier_type": "flat", "value": 15 },
##       { "stat": "agility", "modifier_type": "flat", "value": 5 }
##     ]
##   }

## How to select targets based on drop target
var target_mode: String = "dropped"

## List of StatModifier instances to apply
var modifiers: Array = []  # Array[StatModifier]


# =============================================================================
# FACTORY
# =============================================================================

static func from_dict(data: Dictionary) -> StatBuffEffect:
	"""
	Create a StatBuffEffect from effect data dictionary.

	Args:
		data: Effect dictionary with target_mode and modifiers

	Returns:
		Configured StatBuffEffect instance
	"""
	var effect = StatBuffEffect.new()
	effect.target_mode = data.get("target_mode", "dropped")

	var modifiers_data = data.get("modifiers", [])
	for mod_data in modifiers_data:
		if mod_data is Dictionary:
			var modifier = StatModifier.from_dict(mod_data)
			if modifier.is_valid():
				effect.modifiers.append(modifier)

	return effect


# =============================================================================
# EXECUTION
# =============================================================================

func execute(drop_target, context) -> bool:
	"""
	Execute this effect, applying all modifiers to resolved targets.

	Args:
		drop_target: CharacterInstance that was dropped on (may be null for "all")
		context: SkillContext with team access

	Returns:
		True if effect executed successfully
	"""
	if modifiers.is_empty():
		push_warning("StatBuffEffect: No modifiers to apply")
		return false

	# Resolve targets
	var targets = SkillTargetResolver.resolve(target_mode, drop_target, context)

	if targets.is_empty():
		push_warning("StatBuffEffect: No targets resolved for mode '%s'" % target_mode)
		return false

	# Apply all modifiers to all targets
	for target in targets:
		for modifier in modifiers:
			modifier.apply_to(target)

	return true


func validate_target(drop_target, context, effect_data: Dictionary = {}) -> bool:
	"""
	Validate if the drop target is valid for this effect.

	Args:
		drop_target: CharacterInstance that was dropped on
		context: SkillContext with team access
		effect_data: Optional original effect data with restrictions

	Returns:
		True if target is valid
	"""
	# Merge target_mode into effect_data for validation
	var validation_data = effect_data.duplicate()
	validation_data["target_mode"] = target_mode

	return SkillTargetValidator.is_valid_target(validation_data, drop_target, context)


func get_validation_error(drop_target, context, effect_data: Dictionary = {}) -> String:
	"""
	Get validation error message for an invalid target.

	Args:
		drop_target: CharacterInstance that was dropped on
		context: SkillContext with team access
		effect_data: Optional original effect data with restrictions

	Returns:
		Error message, or empty string if valid
	"""
	var validation_data = effect_data.duplicate()
	validation_data["target_mode"] = target_mode

	return SkillTargetValidator.get_validation_error(validation_data, drop_target, context)


# =============================================================================
# DESCRIPTION
# =============================================================================

func get_description() -> String:
	"""
	Get a human-readable description of this effect.

	Returns:
		String like "Target character gains +15 Health, +5 Defend Rate"
	"""
	if modifiers.is_empty():
		return "No effect"

	var target_desc = SkillTargetResolver.get_mode_description(target_mode)
	target_desc = target_desc.capitalize()

	var modifier_descs: Array[String] = []
	for modifier in modifiers:
		modifier_descs.append(modifier.get_description())

	var modifiers_str = ", ".join(modifier_descs)

	# Format based on whether it affects one or multiple characters
	if target_mode == "dropped":
		return "%s gains %s" % [target_desc, modifiers_str]
	else:
		return "%s gain %s" % [target_desc, modifiers_str]


static func get_effect_description(effect_data: Dictionary) -> String:
	"""
	Static method to get description from effect data without creating instance.

	Args:
		effect_data: The effect dictionary

	Returns:
		Description string
	"""
	var effect = from_dict(effect_data)
	return effect.get_description()


# =============================================================================
# VALIDATION
# =============================================================================

func is_valid() -> bool:
	"""Check if this effect is valid and can be executed."""
	return not modifiers.is_empty()


static func validate_effect_data(data: Dictionary) -> bool:
	"""
	Validate effect data dictionary.

	Args:
		data: Effect dictionary to validate

	Returns:
		True if data is valid
	"""
	var modifiers_data = data.get("modifiers", [])
	if modifiers_data.is_empty():
		return false

	for mod_data in modifiers_data:
		if not mod_data is Dictionary:
			return false
		if not StatModifier.validate_dict(mod_data):
			return false

	return true
