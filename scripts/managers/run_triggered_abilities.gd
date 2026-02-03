class_name RunTriggeredAbilities
extends RefCounted
## Processes triggered abilities during run-time (outside of combat).
## Handles on_recruit, on_ally_recruit, and other run-time triggers.

const GridBonusCalculatorScript = preload("res://scripts/utils/grid_bonus_calculator.gd")


static func process_recruit_triggers(recruited_char: CharacterInstance, all_characters: Array, run_manager) -> void:
	"""
	Process all recruit-related triggers when a character is acquired.

	Args:
		recruited_char: The character that was just recruited
		all_characters: All characters currently on the team (including recruited_char)
		run_manager: RunManager instance for context
	"""
	var game_data = _get_game_data()
	if game_data == null:
		return

	# 1. Process on_recruit triggers on the recruited character
	_process_character_triggers(recruited_char, "on_recruit", recruited_char, all_characters, run_manager, game_data)

	# 2. Process on_ally_recruit triggers on ALL characters (including the new one)
	for character in all_characters:
		_process_character_triggers(character, "on_ally_recruit", recruited_char, all_characters, run_manager, game_data)


static func _process_character_triggers(
	trigger_owner: CharacterInstance,
	trigger_type: String,
	recruited_char: CharacterInstance,
	all_characters: Array,
	run_manager,
	game_data
) -> void:
	"""Process triggered abilities on a character for a specific trigger type."""
	var char_master = game_data.get_character_by_id(trigger_owner.base_character_id)
	if char_master.is_empty():
		return

	var abilities = char_master.get("abilities", [])
	for entry in abilities:
		var parsed = GridBonusCalculatorScript.parse_ability_entry(entry)

		# Skip non-triggered abilities
		if parsed.get("type", "") != "triggered":
			continue

		# Skip if trigger doesn't match
		if parsed.get("trigger", "") != trigger_type:
			continue

		# Execute the triggered ability
		_execute_triggered_ability(trigger_owner, parsed, recruited_char, all_characters, run_manager)


static func _execute_triggered_ability(
	source: CharacterInstance,
	ability: Dictionary,
	recruited_char: CharacterInstance,
	all_characters: Array,
	run_manager
) -> void:
	"""Execute a run-time triggered ability."""
	var target_mode = ability.get("target_mode", "self")
	var action = ability.get("action", "buff_stat")

	# Resolve targets
	var targets = _resolve_targets(source, target_mode, recruited_char, all_characters)

	# Execute the action
	match action:
		"buff_stat":
			_action_buff_stat(source, ability, targets)
		"heal":
			_action_heal(source, ability, targets)
		"grant_gold":
			_action_grant_gold(ability, run_manager)
		"grant_xp":
			_action_grant_xp(ability, targets)


static func _resolve_targets(
	source: CharacterInstance,
	target_mode: String,
	recruited_char: CharacterInstance,
	all_characters: Array
) -> Array:
	"""Resolve targets for a run-time triggered ability."""
	match target_mode:
		"self":
			return [source]
		"recruited":
			return [recruited_char]
		"ally_all":
			return all_characters.duplicate()
		"ally_other":
			return all_characters.filter(func(c): return c != source)
		_:
			return [source]


static func _action_buff_stat(source: CharacterInstance, ability: Dictionary, targets: Array) -> void:
	"""Buff a stat on targets."""
	var stat = ability.get("buff_stat", "")
	var mod_type = ability.get("buff_modifier_type", "flat")
	var value = float(ability.get("buff_value", 0))

	if stat.is_empty() or value == 0:
		return

	for target in targets:
		if mod_type == "flat":
			target.stats[stat] = target.stats.get(stat, 0) + value
		elif mod_type == "percent":
			var current = float(target.stats.get(stat, 0))
			target.stats[stat] = current * (1.0 + value)

		# Special handling for health stat - also update current_health
		if stat == "health":
			target.current_health = min(target.current_health + int(value), target.stats.get("health", 0))


static func _action_heal(source: CharacterInstance, ability: Dictionary, targets: Array) -> void:
	"""Heal targets."""
	var heal_value: int
	var heal_from = ability.get("heal_from", "")
	if heal_from != "":
		heal_value = source.stats.get(heal_from, 0)
	else:
		heal_value = int(ability.get("heal_value", 0))

	if heal_value <= 0:
		return

	for target in targets:
		target.heal(heal_value)


static func _action_grant_gold(ability: Dictionary, run_manager) -> void:
	"""Grant gold to the player."""
	var gold_value = int(ability.get("gold_value", 0))
	if gold_value <= 0 or run_manager == null:
		return

	run_manager.add_gold(gold_value)


static func _action_grant_xp(ability: Dictionary, targets: Array) -> void:
	"""Grant XP to targets (for future use when characters have XP)."""
	var xp_value = int(ability.get("xp_value", 0))
	if xp_value <= 0:
		return

	# Currently characters don't have XP in CharacterInstance
	# This is a placeholder for future implementation
	pass


static func _get_game_data():
	"""Get GameData autoload."""
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("/root/GameData"):
		return tree.root.get_node("/root/GameData")
	return null
