class_name SkillEffects
extends RefCounted
## Built-in skill effect implementations.
## Registers all standard effects with a SkillEffectRegistry.
##
## Usage:
##   var registry = SkillEffectRegistry.new()
##   SkillEffects.register_all(registry)
##
## Effect handler signature:
##   func(effect_data: Dictionary, context: SkillContext) -> void


static func register_all(registry) -> void:
	"""Register all built-in skill effects with the registry."""
	# Instant effects
	registry.register_effect(
		"heal_team",
		_effect_heal_team,
		"Heal all team members for {value} health",
		_validate_positive_value,
		false
	)
	registry.register_effect(
		"grant_gold",
		_effect_grant_gold,
		"Gain {value} gold",
		_validate_positive_value,
		false
	)
	registry.register_effect(
		"grant_xp",
		_effect_grant_xp,
		"Grant {value} XP to the player",
		_validate_positive_value,
		false
	)
	# Lingering effects
	registry.register_effect(
		"next_character_stat_boost",
		_effect_next_character_stat_boost,
		"Next character gains +{value} {stat}",
		_validate_stat_boost,
		true
	)


# =============================================================================
# INSTANT EFFECTS
# =============================================================================

static func _effect_heal_team(effect_data: Dictionary, context) -> void:
	"""
	Heal all team members by the specified value.

	Effect data:
		- value: int - Amount of health to restore
	"""
	var amount = effect_data.get("value", 0)
	if amount <= 0:
		push_warning("SkillEffects: heal_team called with non-positive value: %d" % amount)
		return

	context.heal_all_characters(amount)


static func _effect_grant_gold(effect_data: Dictionary, context) -> void:
	"""
	Add gold to the player's run total.

	Effect data:
		- value: int - Amount of gold to add
	"""
	var amount = effect_data.get("value", 0)
	if amount <= 0:
		push_warning("SkillEffects: grant_gold called with non-positive value: %d" % amount)
		return

	if context.add_gold.is_valid():
		context.add_gold.call(amount)
	else:
		push_warning("SkillEffects: grant_gold - context.add_gold not available")


static func _effect_grant_xp(effect_data: Dictionary, context) -> void:
	"""
	Grant XP to the player.

	Effect data:
		- value: int - Amount of XP to grant to the player
	"""
	var amount = effect_data.get("value", 0)
	if amount <= 0:
		push_warning("SkillEffects: grant_xp called with non-positive value: %d" % amount)
		return

	context.grant_xp_to_player(amount)


# =============================================================================
# LINGERING EFFECTS
# =============================================================================

static func _effect_next_character_stat_boost(effect_data: Dictionary, context) -> void:
	"""
	Queue a stat boost for the next acquired character.
	This effect is handled specially - it adds a lingering effect rather than
	executing immediately.

	Effect data:
		- stat: String - The stat to boost (health, mana, defend_rate, speed, damage, crit_chance)
		- value: int - Amount to boost

	Note: This is typically called when the skill is acquired, registering
	the effect in LingeringEffects. The actual application happens when
	"next_character_acquired" is triggered.
	"""
	if not context.has_lingering_access():
		push_warning("SkillEffects: next_character_stat_boost - lingering effects not available")
		return

	# Add as a lingering effect
	context.add_lingering_effect.call(effect_data)


# =============================================================================
# VALIDATORS (used during registration)
# =============================================================================

static func _validate_positive_value(effect_data: Dictionary) -> bool:
	"""Validate that effect has a positive value."""
	return effect_data.get("value", 0) > 0


static func _validate_stat_boost(effect_data: Dictionary) -> bool:
	"""Validate stat boost effect has stat and non-zero value."""
	var stat = effect_data.get("stat", "")
	var value = effect_data.get("value", 0)
	return not stat.is_empty() and value != 0


# =============================================================================
# EFFECT DESCRIPTIONS
# =============================================================================

# Global registry reference for static method access
static var _registry: SkillEffectRegistry = null

static func set_registry(registry: SkillEffectRegistry) -> void:
	"""Set the registry instance for static method access."""
	_registry = registry


static func get_effect_description(effect_data: Dictionary) -> String:
	"""
	Generate a human-readable description of an effect.
	Uses registry if available, otherwise falls back to hardcoded descriptions.

	Args:
		effect_data: The effect dictionary

	Returns:
		A description string for display
	"""
	# Use registry if available
	if _registry != null:
		return _registry.get_effect_description(effect_data)

	# Fallback to hardcoded descriptions for backwards compatibility
	var effect_type = effect_data.get("type", "")
	var value = effect_data.get("value", 0)

	match effect_type:
		"heal_team":
			return "Heal all team members for %d health" % value
		"grant_gold":
			return "Gain %d gold" % value
		"grant_xp":
			return "Grant %d XP to the player" % value
		"next_character_stat_boost":
			var stat = effect_data.get("stat", "health")
			var stat_name = _get_stat_display_name(stat)
			return "Next character gains +%d %s" % [value, stat_name]
		_:
			return "Unknown effect: %s" % effect_type


static func _get_stat_display_name(stat: String) -> String:
	"""Convert a stat key to a display-friendly name."""
	match stat:
		"health":
			return "Health"
		"mana":
			return "Mana"
		"defend_rate":
			return "Defend Rate"
		"speed":
			return "Speed"
		"damage":
			return "Damage"
		"crit_chance":
			return "Crit Chance"
		_:
			return stat.capitalize()


# =============================================================================
# VALIDATION
# =============================================================================

static func is_valid_effect(effect_data: Dictionary) -> bool:
	"""
	Check if effect data is valid and can be executed.
	Uses registry if available, otherwise falls back to hardcoded validation.

	Args:
		effect_data: The effect dictionary

	Returns:
		True if the effect is valid
	"""
	# Use registry if available
	if _registry != null:
		return _registry.is_valid_effect(effect_data)

	# Fallback to hardcoded validation for backwards compatibility
	if not effect_data.has("type"):
		return false

	var effect_type = effect_data.get("type", "")
	var value = effect_data.get("value", 0)

	match effect_type:
		"heal_team", "grant_gold", "grant_xp":
			return value > 0
		"next_character_stat_boost":
			var stat = effect_data.get("stat", "")
			return not stat.is_empty() and value != 0
		_:
			return false


static func get_effect_value(effect_data: Dictionary) -> int:
	"""Get the primary numeric value of an effect."""
	return effect_data.get("value", 0)


static func is_lingering_effect(effect_type: String) -> bool:
	"""Check if an effect type is a lingering effect (not instant)."""
	# Use registry if available
	if _registry != null:
		return _registry.is_lingering_effect(effect_type)
	# Fallback to hardcoded list
	return effect_type in ["next_character_stat_boost"]
