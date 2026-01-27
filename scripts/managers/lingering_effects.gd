class_name LingeringEffects
extends RefCounted
## Tracks lingering skill effects that persist until triggered.
## Effects are applied when their trigger condition is met, then removed.
##
## Supported triggers:
##   - "next_character_acquired": Triggered when a new character joins the team
##   - "next_combat": Triggered when combat starts
##   - "next_encounter": Triggered when an encounter starts
##   - "next_round": Triggered at the start of the next round
##
## Usage:
##   var effects = LingeringEffects.new()
##   effects.add_effect(skill_data)
##   effects.trigger("next_combat", context)

signal effect_added(effect: Dictionary)
signal effect_triggered(effect: Dictionary, trigger: String)
signal effect_removed(effect: Dictionary)

# Array of lingering effect dictionaries
# Each contains: { id, skill_id, effect, trigger, added_round }
var _effects: Array[Dictionary] = []

# Counter for unique effect IDs
var _next_id: int = 1


func add_effect(skill_data: Dictionary, current_round: int = 0) -> int:
	"""
	Add a lingering effect from skill data.

	Args:
		skill_data: The full skill data dictionary containing effect and trigger
		current_round: The round when the effect was added

	Returns:
		The unique ID of the added effect, or -1 if invalid
	"""
	if not skill_data.has("effect"):
		push_warning("LingeringEffects: Skill data missing 'effect' field")
		return -1

	var effect_trigger = skill_data.get("trigger", "")
	if effect_trigger.is_empty():
		push_warning("LingeringEffects: Lingering skill missing 'trigger' field")
		return -1

	var effect_id = _next_id
	_next_id += 1

	var effect_entry = {
		"id": effect_id,
		"skill_id": skill_data.get("id", "unknown"),
		"skill_name": skill_data.get("name", "Unknown Skill"),
		"effect": skill_data.get("effect", {}),
		"trigger": effect_trigger,
		"added_round": current_round
	}

	_effects.append(effect_entry)
	effect_added.emit(effect_entry)

	return effect_id


func add_effect_direct(effect_data: Dictionary, effect_trigger: String, skill_id: String = "", current_round: int = 0) -> int:
	"""
	Add a lingering effect directly (without full skill data).

	Args:
		effect_data: The effect dictionary (type, value, etc.)
		trigger: The trigger condition
		skill_id: Optional skill ID for tracking
		current_round: The round when the effect was added

	Returns:
		The unique ID of the added effect
	"""
	var effect_id = _next_id
	_next_id += 1

	var effect_entry = {
		"id": effect_id,
		"skill_id": skill_id,
		"skill_name": "",
		"effect": effect_data,
		"trigger": effect_trigger,
		"added_round": current_round
	}

	_effects.append(effect_entry)
	effect_added.emit(effect_entry)

	return effect_id


func trigger(trigger_type: String, context, effect_registry = null) -> Array[Dictionary]:
	"""
	Trigger all effects matching the trigger type.

	Args:
		trigger_type: The trigger to match (e.g., "next_combat")
		context: SkillContext for executing effects
		effect_registry: Optional registry for executing effects

	Returns:
		Array of triggered effect entries
	"""
	var triggered: Array[Dictionary] = []
	var to_remove: Array[int] = []

	for i in range(_effects.size()):
		var effect_entry = _effects[i]
		if effect_entry.get("trigger") == trigger_type:
			# Execute the effect
			if effect_registry != null:
				var skill_data = { "effect": effect_entry.get("effect", {}) }
				effect_registry.execute(skill_data, context)
			else:
				# Try to execute via context if no registry provided
				_execute_effect_directly(effect_entry.get("effect", {}), context)

			triggered.append(effect_entry)
			to_remove.append(i)
			effect_triggered.emit(effect_entry, trigger_type)

	# Remove triggered effects (iterate backwards to preserve indices)
	for i in range(to_remove.size() - 1, -1, -1):
		var removed = _effects[to_remove[i]]
		_effects.remove_at(to_remove[i])
		effect_removed.emit(removed)

	return triggered


func trigger_for_character(trigger_type: String, character, _context) -> Array[Dictionary]:
	"""
	Trigger effects that apply to a specific character (e.g., next_character_acquired).

	Args:
		trigger_type: The trigger to match
		character: The character to apply effects to
		context: SkillContext (may be partially used)

	Returns:
		Array of triggered effect entries
	"""
	var triggered: Array[Dictionary] = []
	var to_remove: Array[int] = []

	for i in range(_effects.size()):
		var effect_entry = _effects[i]
		if effect_entry.get("trigger") == trigger_type:
			var effect = effect_entry.get("effect", {})
			_apply_character_effect(effect, character)
			triggered.append(effect_entry)
			to_remove.append(i)
			effect_triggered.emit(effect_entry, trigger_type)

	# Remove triggered effects
	for i in range(to_remove.size() - 1, -1, -1):
		var removed = _effects[to_remove[i]]
		_effects.remove_at(to_remove[i])
		effect_removed.emit(removed)

	return triggered


func _apply_character_effect(effect: Dictionary, character) -> void:
	"""Apply an effect to a specific character."""
	var effect_type = effect.get("type", "")

	if effect_type == "next_character_stat_boost":
		var stat = effect.get("stat", "")
		var value = effect.get("value", 0)
		if stat == "health":
			character.max_health += value
			character.current_health += value
		elif stat == "mana":
			character.mana += value
		elif stat == "defend_rate":
			character.defend_rate += value
		elif stat == "speed":
			character.speed += value
		elif stat == "damage":
			character.damage += value
		elif stat == "crit_chance":
			character.crit_chance += value


func _execute_effect_directly(effect: Dictionary, context) -> void:
	"""Execute an effect directly without a registry."""
	var effect_type = effect.get("type", "")
	var value = effect.get("value", 0)

	match effect_type:
		"heal_team":
			if context != null and context.has_method("heal_all_characters"):
				context.heal_all_characters(value)
		"grant_gold":
			if context != null and context.add_gold.is_valid():
				context.add_gold.call(value)
		"grant_xp":
			if context != null and context.has_method("grant_xp_to_all"):
				context.grant_xp_to_all(value)


func remove_effect(effect_id: int) -> bool:
	"""
	Remove a specific effect by ID.

	Args:
		effect_id: The unique effect ID

	Returns:
		True if effect was found and removed
	"""
	for i in range(_effects.size()):
		if _effects[i].get("id") == effect_id:
			var removed = _effects[i]
			_effects.remove_at(i)
			effect_removed.emit(removed)
			return true
	return false


func get_effects_by_trigger(trigger_type: String) -> Array[Dictionary]:
	"""Get all effects matching a trigger type."""
	var result: Array[Dictionary] = []
	for effect_entry in _effects:
		if effect_entry.get("trigger") == trigger_type:
			result.append(effect_entry)
	return result


func get_all_effects() -> Array[Dictionary]:
	"""Get all active lingering effects."""
	return _effects.duplicate()


func get_effect_count() -> int:
	"""Get the number of active lingering effects."""
	return _effects.size()


func has_effects_for_trigger(trigger_type: String) -> bool:
	"""Check if there are any effects for a trigger type."""
	for effect_entry in _effects:
		if effect_entry.get("trigger") == trigger_type:
			return true
	return false


func clear() -> void:
	"""Remove all lingering effects."""
	_effects.clear()


func clear_by_trigger(trigger_type: String) -> int:
	"""
	Remove all effects with a specific trigger.

	Returns:
		Number of effects removed
	"""
	var removed_count = 0
	var i = _effects.size() - 1
	while i >= 0:
		if _effects[i].get("trigger") == trigger_type:
			var removed = _effects[i]
			_effects.remove_at(i)
			effect_removed.emit(removed)
			removed_count += 1
		i -= 1
	return removed_count


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize to dictionary for saving."""
	var effects_data: Array = []
	for effect_entry in _effects:
		effects_data.append(effect_entry.duplicate())
	return {
		"effects": effects_data,
		"next_id": _next_id
	}


func to_array() -> Array:
	"""Serialize to array format (alternative)."""
	var result: Array = []
	for effect_entry in _effects:
		result.append(effect_entry.duplicate())
	return result


static func from_dict(data: Dictionary):
	"""Deserialize from saved data."""
	var script = load("res://scripts/managers/lingering_effects.gd")
	var effects = script.new()
	var effects_data = data.get("effects", [])
	for effect_entry in effects_data:
		effects._effects.append(effect_entry)
	effects._next_id = data.get("next_id", effects_data.size() + 1)
	return effects


func load_from_array(data: Array) -> void:
	"""Load from array format."""
	_effects.clear()
	var max_id = 0
	for effect_entry in data:
		_effects.append(effect_entry)
		var effect_id = effect_entry.get("id", 0)
		if effect_id > max_id:
			max_id = effect_id
	_next_id = max_id + 1
