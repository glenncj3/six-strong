class_name StatModifier
extends RefCounted
## Single stat modification primitive.
## Supports flat (additive) and percent (multiplicative) modifiers.
##
## Usage:
##   var modifier = StatModifier.from_dict({"stat": "health", "modifier_type": "flat", "value": 15})
##   modifier.apply_to(character)
##
## JSON format:
##   { "stat": "health", "modifier_type": "flat", "value": 15 }
##   { "stat": "damage", "modifier_type": "percent", "value": 0.2 }

## The stat to modify (e.g., "health", "damage", "agility")
var stat: String = ""

## Type of modification: "flat" (additive) or "percent" (multiplicative)
var modifier_type: String = "flat"

## The modification value (for percent, use decimal: 0.2 = 20%)
var value: float = 0.0


# =============================================================================
# FACTORY
# =============================================================================

static func from_dict(data: Dictionary) -> StatModifier:
	"""
	Create a StatModifier from a dictionary.

	Args:
		data: Dictionary with "stat", "modifier_type", and "value" keys

	Returns:
		Configured StatModifier instance
	"""
	var modifier = StatModifier.new()
	modifier.stat = data.get("stat", "")
	modifier.modifier_type = data.get("modifier_type", "flat")
	modifier.value = float(data.get("value", 0))
	return modifier


# =============================================================================
# APPLICATION
# =============================================================================

func apply_to(character) -> void:
	"""
	Apply this modifier permanently to a character's stats.

	Args:
		character: CharacterInstance to modify
	"""
	if stat.is_empty():
		push_warning("StatModifier: Cannot apply modifier with empty stat name")
		return

	if character == null:
		push_warning("StatModifier: Cannot apply modifier to null character")
		return

	var current_value = character.stats.get(stat, 0)

	var new_value: int
	if modifier_type == "percent":
		# Percent modifier: new = current * (1 + percent)
		new_value = int(current_value * (1.0 + value))
	else:
		# Flat modifier: new = current + flat
		new_value = int(current_value + value)

	character.stats[stat] = new_value

	# Special handling for health: also increase current_health if max increased
	if stat == "health" and new_value > current_value:
		var health_increase = new_value - current_value
		character.current_health += health_increase


# =============================================================================
# DESCRIPTION
# =============================================================================

func get_description() -> String:
	"""
	Get a human-readable description of this modifier.

	Returns:
		String like "+15 Health" or "+20% Damage"
	"""
	var stat_display = StatRegistry.get_display_name(stat)

	if modifier_type == "percent":
		var percent_value = int(value * 100)
		if value >= 0:
			return "+%d%% %s" % [percent_value, stat_display]
		else:
			return "%d%% %s" % [percent_value, stat_display]
	else:
		if value >= 0:
			return "+%d %s" % [int(value), stat_display]
		else:
			return "%d %s" % [int(value), stat_display]


# =============================================================================
# VALIDATION
# =============================================================================

func is_valid() -> bool:
	"""Check if this modifier is valid."""
	if stat.is_empty():
		return false
	if modifier_type not in ["flat", "percent"]:
		return false
	return true


static func validate_dict(data: Dictionary) -> bool:
	"""Validate a modifier dictionary."""
	if not data.has("stat") or data.get("stat", "").is_empty():
		return false
	var mod_type = data.get("modifier_type", "flat")
	if mod_type not in ["flat", "percent"]:
		return false
	return true
