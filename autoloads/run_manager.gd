extends Node
# RunManager Singleton
# Manages active run state - now delegates to focused managers
# Refactored to follow Single Responsibility Principle
#
# Phase 3 Additions:
# - Lingering effects tracking and triggers
# - Skill effect registry

const SaveDataValidatorScript = preload("res://scripts/utils/save_data_validator.gd")
const PlayerInventoryScript = preload("res://scripts/managers/player_inventory.gd")
const LingeringEffectsScript = preload("res://scripts/managers/lingering_effects.gd")
const SkillEffectRegistryScript = preload("res://scripts/skills/skill_effect_registry.gd")
const SkillContextScript = preload("res://scripts/skills/skill_context.gd")
const SkillEffectsScript = preload("res://scripts/skills/skill_effects.gd")

signal run_started
signal round_changed(new_round: int)
signal reputation_changed(new_reputation: int)
signal gold_changed(new_gold: int)
signal phase_changed(new_phase: String)
# Draft-specific signals (emitted by draft scene, listened by HUDs)
signal draft_character_added(char_instance: CharacterInstance)
signal draft_gold_updated(amount: int)
signal item_acquired(item: ItemInstance)
# Phase 3: Lingering effect signals
signal lingering_effect_added(effect: Dictionary)
signal lingering_effect_triggered(effect: Dictionary, trigger: String)

# Save file path
const SAVE_PATH = "user://active_run.json"

# Phase constants
const PHASE_ENCOUNTER = "encounter"
const PHASE_COMBAT = "combat"

# Run state
var is_run_active: bool = false
var run_id: String = ""

# Focused managers (Single Responsibility Principle)
var _team_manager: TeamManager = TeamManager.new()
var _combat_generator: CombatGenerator = CombatGenerator.new()
var _player_inventory = PlayerInventoryScript.new()
var _lingering_effects = LingeringEffectsScript.new()
var _skill_registry = SkillEffectRegistryScript.new()

# Progression (kept in RunManager as it's core run state)
var current_round: int = 0
var current_phase: String = PHASE_ENCOUNTER
var encounters_this_round: int = 0
var reputation: int = GameConstants.STARTING_REPUTATION
var wins: int = 0
var losses: int = 0
var starting_gold: int = 0
var current_gold: int = 0

# History (for statistics)
var encounter_history: Array = []


func _ready() -> void:
	# Initialize skill effect registry with built-in effects
	_init_skill_registry()

	# Connect lingering effect signals
	_lingering_effects.effect_added.connect(_on_lingering_effect_added)
	_lingering_effects.effect_triggered.connect(_on_lingering_effect_triggered)


func _init_skill_registry() -> void:
	"""Initialize the skill effect registry with all built-in effects."""
	_skill_registry.clear()
	SkillEffectsScript.register_all(_skill_registry)


func has_active_run() -> bool:
	"""Check if there's a saved run to resume."""
	return JsonPersistence.file_exists(SAVE_PATH)


func start_new_run(drafted_character_ids: Array) -> void:
	"""
	Start a new run with drafted characters.

	Args:
		drafted_character_ids: Array of character IDs from PlayerAccount
	"""
	if drafted_character_ids.size() != GameConstants.TEAM_SIZE:
		push_error("RunManager: Must draft exactly %d characters" % GameConstants.TEAM_SIZE)
		return

	# Generate run ID
	run_id = "run_%d" % Time.get_unix_time_from_system()

	# Initialize team via TeamManager
	_team_manager.clear()
	starting_gold = 0

	for char_id in drafted_character_ids:
		var char_data = PlayerAccount.get_character_data(char_id)
		if char_data.is_empty():
			push_error("RunManager: Character data not found: %s" % char_id)
			continue

		# Create runtime instance
		var char_instance = CharacterInstance.new(char_data)
		_team_manager.add_character(char_instance)

	# Calculate starting gold from team income
	starting_gold = _team_manager.calculate_total_income()

	# Initialize run state
	current_round = 0
	current_phase = PHASE_ENCOUNTER
	encounters_this_round = 0
	reputation = GameConstants.STARTING_REPUTATION
	wins = 0
	losses = 0
	current_gold = starting_gold
	encounter_history.clear()
	is_run_active = true

	# Clear lingering effects from any previous run
	_lingering_effects.clear()
	_player_inventory.clear()

	# Save initial state
	save_run_state()

	run_started.emit()


func save_run_state() -> void:
	"""Save current run state to file."""
	if not is_run_active:
		return

	var save_data = {
		"run_id": run_id,
		"round": current_round,
		"phase": current_phase,
		"encounters_this_round": encounters_this_round,
		"reputation": reputation,
		"wins": wins,
		"losses": losses,
		"starting_gold": starting_gold,
		"current_gold": current_gold,
		"team": _team_manager.to_array(),
		"inventory": _player_inventory.to_array(),
		"lingering_effects": _lingering_effects.to_array(),
		"encounter_history": encounter_history
	}

	JsonPersistence.save_json(SAVE_PATH, save_data)


func load_run_state() -> bool:
	"""Load run state from file, returns true if successful."""
	var raw_data = JsonPersistence.load_json(SAVE_PATH)
	if raw_data == null:
		return false

	# Validate save data against schema
	var save_data = SaveDataValidatorScript.validate_and_fix(raw_data, SaveDataValidatorScript.get_run_state_schema())
	if save_data.is_empty():
		push_error("RunManager: Save data validation failed, cannot load run")
		return false

	# Validate team members exist in PlayerAccount
	var team_data = save_data.get("team", [])
	if not _validate_team_data(team_data):
		push_error("RunManager: Team validation failed, save may be corrupt")
		return false

	# Restore run state
	run_id = save_data.get("run_id", "")
	current_round = save_data.get("round", 0)
	current_phase = save_data.get("phase", PHASE_ENCOUNTER)
	encounters_this_round = save_data.get("encounters_this_round", 0)
	reputation = save_data.get("reputation", GameConstants.STARTING_REPUTATION)
	wins = save_data.get("wins", 0)
	losses = save_data.get("losses", 0)
	starting_gold = save_data.get("starting_gold", 0)
	current_gold = save_data.get("current_gold", 0)
	encounter_history = save_data.get("encounter_history", [])

	# Restore team via TeamManager
	_team_manager.load_from_array(team_data)

	# Restore inventory (Phase 2)
	var inventory_data = save_data.get("inventory", [])
	_player_inventory.load_from_array(inventory_data)

	# Restore lingering effects (Phase 3)
	var lingering_data = save_data.get("lingering_effects", [])
	_lingering_effects.load_from_array(lingering_data)

	is_run_active = true

	return true


func _validate_team_data(team_data: Array) -> bool:
	"""Validate that team members reference valid characters."""
	for char_data in team_data:
		var char_id = char_data.get("base_character_id", "")
		if char_id.is_empty():
			push_warning("RunManager: Team member missing base_character_id")
			return false
		# Verify character exists in game data
		var master_data = GameData.get_character_by_id(char_id)
		if master_data.is_empty():
			push_warning("RunManager: Team member references unknown character: %s" % char_id)
			return false
	return true


func end_run(victory: bool) -> Dictionary:
	"""
	End the current run: calculate and apply rewards, then clear state.
	Returns a Dictionary with all run results data for display.

	Args:
		victory: True if player won (10 combats), false if defeated (0 reputation)

	Returns:
		Dictionary with run stats, reward amounts, and prestige changes
	"""
	var reward_data = _apply_end_of_run_rewards(victory)
	_clear_run_state()
	return reward_data


func _apply_end_of_run_rewards(victory: bool) -> Dictionary:
	"""Calculate and apply end-of-run rewards. Returns display data."""
	var wins_count = wins
	var rep = reputation
	var team_data = capture_team_data()

	# Calculate rewards
	var gem_reward = RewardCalculator.calculate_gem_reward(victory, wins_count, rep)
	var fame_reward = RewardCalculator.calculate_character_fame_reward(victory, wins_count)

	# Apply gem reward
	PlayerAccount.add_gems(gem_reward)

	# Apply fame and track prestige changes
	var prestige_ups_list = []
	for char_data in team_data:
		var char_id = char_data["id"]
		var old_data = PlayerAccount.get_character_data(char_id)
		var old_prestige = old_data.get("prestige", 1)

		PlayerAccount.add_character_fame(char_id, fame_reward)

		var new_data = PlayerAccount.get_character_data(char_id)
		var new_prestige = new_data.get("prestige", 1)
		if new_prestige > old_prestige:
			prestige_ups_list.append({
				"name": char_data["name"],
				"old_prestige": old_prestige,
				"new_prestige": new_prestige,
				"id": char_id
			})

	return {
		"victory": victory,
		"round": current_round,
		"wins": wins_count,
		"losses": losses,
		"gold": current_gold,
		"reputation": rep,
		"starting_gold": starting_gold,
		"team": team_data,
		"gem_reward": gem_reward,
		"fame_reward": fame_reward,
		"prestige_ups": prestige_ups_list
	}


func _clear_run_state() -> void:
	"""Clear all run state and delete save file."""
	is_run_active = false
	run_id = ""
	_team_manager.clear()
	_player_inventory.clear()
	_lingering_effects.clear()
	current_round = 0
	current_phase = PHASE_ENCOUNTER
	encounters_this_round = 0
	reputation = GameConstants.STARTING_REPUTATION
	wins = 0
	losses = 0
	starting_gold = 0
	current_gold = 0
	encounter_history.clear()

	# Delete save file
	JsonPersistence.delete_file(SAVE_PATH)


# =============================================================================
# GETTERS - Delegated to TeamManager where appropriate
# =============================================================================

func get_team() -> Array[CharacterInstance]:
	return _team_manager.get_team()


func get_round() -> int:
	return current_round


func get_reputation() -> int:
	return reputation


func get_wins() -> int:
	return wins


func get_losses() -> int:
	return losses


func get_gold() -> int:
	return current_gold


func get_phase() -> String:
	return current_phase


func is_encounter_phase() -> bool:
	return current_phase == PHASE_ENCOUNTER


func is_combat_phase() -> bool:
	return current_phase == PHASE_COMBAT


# =============================================================================
# PLAYER INVENTORY (Phase 2)
# =============================================================================

func get_player_inventory():
	"""Get the player's item inventory."""
	return _player_inventory


func get_player_items() -> Array:
	"""Get all items in the player's inventory."""
	return _player_inventory.get_all_items()


func add_item_to_inventory(item_id: String, is_upgrade: bool = true) -> ItemInstance:
	"""
	Add an item to the player's inventory by ID.

	Args:
		item_id: ID of the item in GameData
		is_upgrade: True for item upgrades (default), false for regular items

	Returns:
		The created ItemInstance, or null if invalid
	"""
	var item = _player_inventory.add_item_by_id(item_id, is_upgrade)
	if item != null:
		item_acquired.emit(item)
		save_run_state()
	return item


func has_item_in_inventory(item_id: String) -> bool:
	"""Check if the player has an item with the given ID."""
	return _player_inventory.has_item(item_id)


func get_inventory_stat_modifier(stat_name: String) -> int:
	"""Get the total modifier for a stat from all player items."""
	return _player_inventory.get_total_stat_modifier(stat_name)


# =============================================================================
# LINGERING EFFECTS (Phase 3)
# =============================================================================

func get_skill_registry():
	"""Get the skill effect registry."""
	return _skill_registry


func get_lingering_effects():
	"""Get the lingering effects manager."""
	return _lingering_effects


func add_lingering_effect(skill_data: Dictionary) -> bool:
	"""
	Add a lingering effect from skill data.

	Args:
		skill_data: The full skill data dictionary containing effect and trigger

	Returns:
		True if effect was added successfully
	"""
	var effect_id = _lingering_effects.add_effect(skill_data, current_round)
	if effect_id > 0:
		save_run_state()
		return true
	return false


func trigger_lingering_effects(trigger_type: String) -> Array[Dictionary]:
	"""
	Trigger all lingering effects matching the trigger type.

	Args:
		trigger_type: The trigger to match (e.g., "next_combat")

	Returns:
		Array of triggered effect entries
	"""
	var context = _create_skill_context()
	var triggered = _lingering_effects.trigger(trigger_type, context, _skill_registry)
	if triggered.size() > 0:
		save_run_state()
	return triggered


func trigger_character_acquired_effects(character: CharacterInstance) -> Array[Dictionary]:
	"""
	Trigger lingering effects for a newly acquired character.

	Args:
		character: The newly acquired character

	Returns:
		Array of triggered effect entries
	"""
	var context = _create_skill_context()
	var triggered = _lingering_effects.trigger_for_character(
		"next_character_acquired",
		character,
		context
	)
	if triggered.size() > 0:
		save_run_state()
	return triggered


func has_pending_effects(trigger_type: String) -> bool:
	"""Check if there are any lingering effects waiting for a trigger."""
	return _lingering_effects.has_effects_for_trigger(trigger_type)


func get_pending_effects(trigger_type: String) -> Array[Dictionary]:
	"""Get all pending effects for a trigger type."""
	return _lingering_effects.get_effects_by_trigger(trigger_type)


func _create_skill_context():
	"""Create a SkillContext for effect execution."""
	return SkillContextScript.from_run_manager(self)


func _on_lingering_effect_added(effect: Dictionary) -> void:
	"""Handle lingering effect added event."""
	lingering_effect_added.emit(effect)


func _on_lingering_effect_triggered(effect: Dictionary, trigger: String) -> void:
	"""Handle lingering effect triggered event."""
	lingering_effect_triggered.emit(effect, trigger)


# =============================================================================
# RUN PROGRESSION
# =============================================================================

func advance_round() -> void:
	"""Move to next round (after encounter + combat)."""
	current_round += 1
	current_phase = PHASE_ENCOUNTER
	encounters_this_round = 0

	# Trigger any "next_round" lingering effects
	trigger_lingering_effects("next_round")

	round_changed.emit(current_round)
	phase_changed.emit(current_phase)
	save_run_state()


func set_phase(phase: String) -> void:
	"""Set the current phase."""
	if phase != PHASE_ENCOUNTER and phase != PHASE_COMBAT:
		push_error("RunManager: Invalid phase: %s" % phase)
		return
	current_phase = phase
	phase_changed.emit(current_phase)
	save_run_state()


func complete_encounter() -> void:
	"""Complete encounter phase. Switches to combat after ENCOUNTERS_PER_ROUND encounters."""
	encounters_this_round += 1

	# Trigger any "next_encounter" lingering effects for next encounter
	# (but not when switching to combat)
	if encounters_this_round < GameConstants.ENCOUNTERS_PER_ROUND:
		trigger_lingering_effects("next_encounter")

	if encounters_this_round >= GameConstants.ENCOUNTERS_PER_ROUND:
		current_phase = PHASE_COMBAT
	phase_changed.emit(current_phase)
	save_run_state()


func add_gold(amount: int) -> void:
	"""Add gold (from combat rewards, etc.)."""
	current_gold += amount
	gold_changed.emit(current_gold)
	save_run_state()


func spend_gold(amount: int) -> bool:
	"""Spend gold (returns false if not enough)."""
	if current_gold >= amount:
		current_gold -= amount
		gold_changed.emit(current_gold)
		save_run_state()
		return true
	return false


func attempt_purchase(cost: int, char_index: int, action: Callable) -> Dictionary:
	"""
	Attempt a gold purchase with character selection and action.
	Handles gold spending, character lookup, action execution, and refund on failure.

	Args:
		cost: Gold cost of the purchase
		char_index: Index of the selected character (0-based, -1 means none selected)
		action: Callable(char_instance: CharacterInstance) -> bool

	Returns:
		Dictionary with "success" (bool) and "error" (String)
	"""
	if char_index < 0:
		return {"success": false, "error": "no_character_selected"}
	if not spend_gold(cost):
		return {"success": false, "error": "insufficient_gold"}
	var team = get_team()
	if char_index >= team.size():
		add_gold(cost)
		return {"success": false, "error": "invalid_character"}
	var char_instance = team[char_index]
	if not action.call(char_instance):
		add_gold(cost)  # refund
		return {"success": false, "error": "action_failed"}
	return {"success": true, "error": ""}


func add_win() -> void:
	"""Record a combat victory (rewards handled by apply_combat_rewards)."""
	wins += 1
	save_run_state()


func add_loss() -> void:
	"""Record a combat loss."""
	losses += 1
	save_run_state()


func lose_reputation(amount: int) -> void:
	"""Lose reputation (from combat loss)."""
	reputation = max(0, reputation - amount)
	reputation_changed.emit(reputation)
	save_run_state()


func is_run_over() -> bool:
	"""Check if run is over (win or loss condition met)."""
	if wins >= GameConstants.WINS_FOR_VICTORY:
		return true  # Victory
	if reputation <= 0:
		return true  # Defeat
	return false


func did_player_win() -> bool:
	"""Check if player won (only valid if is_run_over() is true)."""
	return wins >= GameConstants.WINS_FOR_VICTORY


# =============================================================================
# UTILITY METHODS - Delegated to TeamManager
# =============================================================================

func get_phase_name() -> String:
	"""Get current phase name for display."""
	return current_phase


func get_team_summary() -> Dictionary:
	"""Get summary stats for the team."""
	return _team_manager.get_summary()


func get_character_by_index(index: int) -> CharacterInstance:
	"""Get a team member by index (0-2)."""
	return _team_manager.get_character_by_index(index)


func capture_team_data() -> Array:
	"""Capture team member data as an Array of Dictionaries (id, name, level)."""
	var team_data = []
	for char_instance in _team_manager.get_team():
		team_data.append({
			"id": char_instance.base_character_id,
			"name": char_instance.get_character_name(),
			"level": char_instance.level
		})
	return team_data


# =============================================================================
# DRAFT EVENTS - Forwarded from draft scene to HUDs
# =============================================================================

func notify_draft_character_added(char_instance: CharacterInstance) -> void:
	"""Called by draft scene when a character is drafted. Notifies HUDs."""
	draft_character_added.emit(char_instance)


func notify_draft_gold_updated(amount: int) -> void:
	"""Called by draft scene when draft gold total changes. Notifies HUDs."""
	draft_gold_updated.emit(amount)


# =============================================================================
# COMBAT GENERATION - Delegated to CombatGenerator
# =============================================================================

func generate_combat_options(count: int) -> Array:
	"""
	Generate random combat options (AI enemies or Player Ghosts).

	Args:
		count: Number of options to generate (usually 3)

	Returns:
		Array of combat option dictionaries
	"""
	return _combat_generator.generate_options_as_dicts(count)


# =============================================================================
# REWARDS - Delegated to RewardCalculator
# =============================================================================

func apply_combat_rewards(won: bool, combat_data: Dictionary) -> void:
	"""
	Apply combat rewards or penalties.

	Args:
		won: True if player won, false if lost
		combat_data: The combat option data
	"""
	# Trigger "next_combat" lingering effects before combat resolves
	trigger_lingering_effects("next_combat")

	if won:
		RewardCalculator.apply_combat_victory_rewards(_team_manager, add_gold, combat_data)
	else:
		# Lose reputation equal to round number
		var reputation_loss = RewardCalculator.calculate_reputation_loss(current_round)
		lose_reputation(reputation_loss)
