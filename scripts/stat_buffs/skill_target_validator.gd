class_name SkillTargetValidator
extends RefCounted
## Validates if a drop target is valid for an effect.
## Extensible system for adding targeting restrictions.
##
## Usage:
##   if SkillTargetValidator.is_valid_target(effect_data, target, context):
##       # Target is valid, proceed with effect
##   else:
##       var error = SkillTargetValidator.get_validation_error(effect_data, target, context)
##       # Show error to user
##
## Supported restrictions (future):
##   - "requires_front_row": true
##   - "requires_back_row": true
##   - "requires_stat_below": {"stat": "health", "percent": 50}
##   - "requires_stat_above": {"stat": "health", "value": 10}
##   - "requires_alive": true (default)


# =============================================================================
# VALIDATION
# =============================================================================

static func is_valid_target(effect_data: Dictionary, target, context) -> bool:
	"""
	Check if a drop target is valid for the given effect.

	Args:
		effect_data: Effect dictionary with optional restrictions
		target: CharacterInstance that was dropped on
		context: SkillContext with team access

	Returns:
		True if target is valid, false otherwise
	"""
	# Null target is never valid for targeted effects
	if target == null:
		var target_mode = effect_data.get("target_mode", "dropped")
		return not SkillTargetResolver.requires_drop_target(target_mode)

	# Check requires_alive (default true)
	if effect_data.get("requires_alive", true):
		if not target.is_alive():
			return false

	# Check requires_front_row
	if effect_data.get("requires_front_row", false):
		if not target.is_in_grid() or not target.is_front_row():
			return false

	# Check requires_back_row
	if effect_data.get("requires_back_row", false):
		if not target.is_in_grid() or not target.is_back_row():
			return false

	# Check requires_in_grid
	if effect_data.get("requires_in_grid", false):
		if not target.is_in_grid():
			return false

	# Check requires_stat_below
	var stat_below = effect_data.get("requires_stat_below", {})
	if not stat_below.is_empty():
		if not _check_stat_below(target, stat_below):
			return false

	# Check requires_stat_above
	var stat_above = effect_data.get("requires_stat_above", {})
	if not stat_above.is_empty():
		if not _check_stat_above(target, stat_above):
			return false

	return true


static func _check_stat_below(target, requirement: Dictionary) -> bool:
	"""Check if target's stat is below threshold."""
	var stat_name = requirement.get("stat", "")
	if stat_name.is_empty():
		return true

	var current_value = target.stats.get(stat_name, 0)

	# Check percent threshold (of max)
	if requirement.has("percent"):
		var max_value = target.stats.get(stat_name, 1)  # Avoid div by zero
		if max_value <= 0:
			return true
		var percent = float(current_value) / float(max_value) * 100
		return percent < requirement.get("percent", 100)

	# Check absolute value threshold
	if requirement.has("value"):
		return current_value < requirement.get("value", 0)

	return true


static func _check_stat_above(target, requirement: Dictionary) -> bool:
	"""Check if target's stat is above threshold."""
	var stat_name = requirement.get("stat", "")
	if stat_name.is_empty():
		return true

	var current_value = target.stats.get(stat_name, 0)

	# Check percent threshold (of max)
	if requirement.has("percent"):
		var max_value = target.stats.get(stat_name, 1)  # Avoid div by zero
		if max_value <= 0:
			return false
		var percent = float(current_value) / float(max_value) * 100
		return percent > requirement.get("percent", 0)

	# Check absolute value threshold
	if requirement.has("value"):
		return current_value > requirement.get("value", 0)

	return true


# =============================================================================
# ERROR MESSAGES
# =============================================================================

static func get_validation_error(effect_data: Dictionary, target, _context) -> String:
	"""
	Get a human-readable error message explaining why the target is invalid.

	Args:
		effect_data: Effect dictionary with optional restrictions
		target: CharacterInstance that was dropped on
		_context: SkillContext with team access

	Returns:
		Error message string, or empty string if target is valid
	"""
	if target == null:
		var target_mode = effect_data.get("target_mode", "dropped")
		if SkillTargetResolver.requires_drop_target(target_mode):
			return "This skill requires a target character"
		return ""

	if effect_data.get("requires_alive", true):
		if not target.is_alive():
			return "Target must be alive"

	if effect_data.get("requires_front_row", false):
		if not target.is_in_grid():
			return "Target must be placed in the grid"
		if not target.is_front_row():
			return "Target must be in the front row"

	if effect_data.get("requires_back_row", false):
		if not target.is_in_grid():
			return "Target must be placed in the grid"
		if not target.is_back_row():
			return "Target must be in the back row"

	if effect_data.get("requires_in_grid", false):
		if not target.is_in_grid():
			return "Target must be placed in the grid"

	var stat_below = effect_data.get("requires_stat_below", {})
	if not stat_below.is_empty():
		if not _check_stat_below(target, stat_below):
			var stat_name = StatRegistry.get_display_name(stat_below.get("stat", ""))
			if stat_below.has("percent"):
				return "Target's %s must be below %d%%" % [stat_name, stat_below.get("percent", 0)]
			else:
				return "Target's %s must be below %d" % [stat_name, stat_below.get("value", 0)]

	var stat_above = effect_data.get("requires_stat_above", {})
	if not stat_above.is_empty():
		if not _check_stat_above(target, stat_above):
			var stat_name = StatRegistry.get_display_name(stat_above.get("stat", ""))
			if stat_above.has("percent"):
				return "Target's %s must be above %d%%" % [stat_name, stat_above.get("percent", 0)]
			else:
				return "Target's %s must be above %d" % [stat_name, stat_above.get("value", 0)]

	return ""
