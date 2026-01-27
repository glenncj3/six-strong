extends Node
## RunManager Singleton
## Manages active run state - delegates to RunState composite for state ownership
## Follows Single Responsibility Principle - orchestrates run flow, doesn't own state
##
## Phase 4 Refactor:
## - State delegated to RunState composite (SRP fix)
## - Support for legacy-based runs via start_new_run_with_legacies()
## - RunPool created from drafted legacies

const SaveDataValidatorScript = preload("res://scripts/utils/save_data_validator.gd")
const RunStateScript = preload("res://scripts/managers/run_state.gd")
const RunPoolScript = preload("res://scripts/managers/run_pool.gd")
const SkillEffectRegistryScript = preload("res://scripts/skills/skill_effect_registry.gd")
const SkillContextScript = preload("res://scripts/skills/skill_context.gd")
const SkillEffectsScript = preload("res://scripts/skills/skill_effects.gd")

# =============================================================================
# SIGNALS
# =============================================================================

signal run_started
signal round_changed(new_round: int)
signal reputation_changed(new_reputation: int)
signal gold_changed(new_gold: int)
signal phase_changed(new_phase: String)
signal player_level_changed(new_level: int)
signal player_xp_changed(new_xp: int)

# Draft-specific signals (emitted by draft scene, listened by HUDs)
signal draft_gold_updated(amount: int)
signal item_acquired(item: ItemInstance)

# Phase 3: Lingering effect signals
signal lingering_effect_added(effect: Dictionary)
signal lingering_effect_triggered(effect: Dictionary, trigger: String)

# =============================================================================
# CONSTANTS
# =============================================================================

const SAVE_PATH = "user://active_run.json"
const PHASE_ENCOUNTER = "encounter"
const PHASE_COMBAT = "combat"

# =============================================================================
# STATE
# =============================================================================

var is_run_active: bool = false

# RunState composite owns all run data (Phase 4 - SRP fix)
var _run_state = null  # RunStateScript instance

# Skill registry (managed here as it's a singleton-like resource)
var _skill_registry = SkillEffectRegistryScript.new()



# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_init_skill_registry()


func _init_skill_registry() -> void:
	"""Initialize the skill effect registry with all built-in effects."""
	_skill_registry.clear()
	SkillEffectsScript.register_all(_skill_registry)


# =============================================================================
# RUN STATE ACCESS
# =============================================================================

func get_run_state():
	"""Get the current run state (or null if no active run)."""
	return _run_state


# =============================================================================
# RUN LIFECYCLE - LEGACY SYSTEM (Phase 4)
# =============================================================================

func start_new_run_with_legacies(drafted_legacies: Array) -> void:
	"""
	Start a new run with drafted legacies.

	Args:
		drafted_legacies: Array of LegacyData objects from draft phase
	"""
	if drafted_legacies.size() == 0:
		push_error("RunManager: Must draft at least one legacy")
		return

	# Create new RunState
	_run_state = RunStateScript.new()
	_run_state.run_id = "run_%d" % Time.get_unix_time_from_system()

	# Store drafted legacy IDs for fame distribution at run end
	for legacy in drafted_legacies:
		_run_state.drafted_legacy_ids.append(legacy.id)

	# Create RunPool from drafted legacies
	_run_state.pool = RunPoolScript.from_legacies(drafted_legacies)

	# Phase 6: Set RunPool on EncounterFactory for content filtering
	if EncounterFactory:
		EncounterFactory.set_run_pool(_run_state.pool)

	# Calculate starting gold from legacy incomes
	var total_starting_gold = 0
	for legacy in drafted_legacies:
		total_starting_gold += legacy.income
	_run_state.starting_gold = total_starting_gold
	_run_state.current_gold = total_starting_gold

	# Add starting characters from each legacy
	for legacy in drafted_legacies:
		var starting_char_id = legacy.selected_starting_character_id
		if not starting_char_id.is_empty():
			var char_instance = CharacterInstance.from_master_data(starting_char_id)
			if char_instance:
				_run_state.add_character(char_instance)

	# Add starting items to inventory from each legacy
	for legacy in drafted_legacies:
		var starting_item_id = legacy.selected_starting_item_id
		if not starting_item_id.is_empty():
			_run_state.inventory.add_item_by_id(starting_item_id, false)

	# Connect lingering effect signals
	_run_state.lingering_effects.effect_added.connect(_on_lingering_effect_added)
	_run_state.lingering_effects.effect_triggered.connect(_on_lingering_effect_triggered)

	# Round 1 starts with combat immediately after draft (no encounter phase)
	_run_state.set_phase(PHASE_COMBAT)

	is_run_active = true

	save_run_state()
	run_started.emit()


# =============================================================================
# RUN LIFECYCLE - LEGACY SUPPORT (backwards compatibility)
# =============================================================================

func has_active_run() -> bool:
	"""Check if there's a saved run to resume."""
	return JsonPersistence.file_exists(SAVE_PATH)


func start_new_run(drafted_character_ids: Array) -> void:
	"""
	Start a new run with drafted characters (legacy method).
	DEPRECATED: Use start_new_run_with_legacies() for new code.

	Args:
		drafted_character_ids: Array of character IDs from PlayerAccount
	"""
	if drafted_character_ids.size() != GameConstants.TEAM_SIZE:
		push_error("RunManager: Must draft exactly %d characters" % GameConstants.TEAM_SIZE)
		return

	# Create new RunState
	_run_state = RunStateScript.new()
	_run_state.run_id = "run_%d" % Time.get_unix_time_from_system()

	for char_id in drafted_character_ids:
		var char_data = PlayerAccount.get_character_data(char_id)
		if char_data.is_empty():
			push_error("RunManager: Character data not found: %s" % char_id)
			continue

		var char_instance = CharacterInstance.new(char_data)
		_run_state.add_character(char_instance)

	# Calculate starting gold from team income
	var total_income = _run_state.calculate_total_income()
	_run_state.starting_gold = total_income
	_run_state.current_gold = total_income

	# Connect lingering effect signals
	_run_state.lingering_effects.effect_added.connect(_on_lingering_effect_added)
	_run_state.lingering_effects.effect_triggered.connect(_on_lingering_effect_triggered)

	# Round 1 starts with combat immediately after draft (no encounter phase)
	_run_state.set_phase(PHASE_COMBAT)

	is_run_active = true

	save_run_state()
	run_started.emit()


# =============================================================================
# SAVE / LOAD
# =============================================================================

func save_run_state() -> void:
	"""Save current run state to file."""
	if not is_run_active or _run_state == null:
		return

	# Phase 5: No longer need to sync team manager - RunState owns grid directly
	var save_data = _run_state.to_dict()
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

	# Validate team members exist
	var team_data = save_data.get("team", [])
	if not _validate_team_data(team_data):
		push_error("RunManager: Team validation failed, save may be corrupt")
		return false

	# Restore RunState from saved data
	_run_state = RunStateScript.from_dict(save_data)

	# Reconnect lingering effect signals
	_run_state.lingering_effects.effect_added.connect(_on_lingering_effect_added)
	_run_state.lingering_effects.effect_triggered.connect(_on_lingering_effect_triggered)

	# Phase 6: Restore RunPool on EncounterFactory if pool exists
	if _run_state.pool != null and EncounterFactory:
		EncounterFactory.set_run_pool(_run_state.pool)

	is_run_active = true

	return true


func _validate_team_data(team_data: Array) -> bool:
	"""Validate that team members reference valid characters."""
	for char_data in team_data:
		var char_id = char_data.get("base_character_id", "")
		if char_id.is_empty():
			push_warning("RunManager: Team member missing base_character_id")
			return false
		var master_data = GameData.get_character_by_id(char_id)
		if master_data.is_empty():
			push_warning("RunManager: Team member references unknown character: %s" % char_id)
			return false
	return true


# =============================================================================
# END RUN
# =============================================================================

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
	clear_run_state()
	return reward_data


func _apply_end_of_run_rewards(victory: bool) -> Dictionary:
	"""Calculate and apply end-of-run rewards. Returns display data."""
	var wins_count = _run_state.wins if _run_state else 0
	var rep = _run_state.reputation if _run_state else 0
	var team_data = capture_team_data()

	# Calculate rewards
	var gem_reward = RewardCalculator.calculate_gem_reward(victory, wins_count, rep)

	# Apply gem reward
	PlayerAccount.add_gems(gem_reward)

	# Apply fame to drafted legacies (Phase 7 - legacy fame distribution)
	var prestige_ups_list = []
	var fame_reward = 0

	if _run_state and _run_state.drafted_legacy_ids.size() > 0:
		# Use legacy fame formula (Phase 7)
		fame_reward = RewardCalculator.calculate_legacy_fame_reward(victory, wins_count)

		# Distribute fame to all drafted legacies equally
		for legacy_id in _run_state.drafted_legacy_ids:
			var result = PlayerAccount.award_legacy_fame(legacy_id, fame_reward)
			if result.get("prestige_increased", false):
				var legacy = PlayerAccount.get_legacy_data(legacy_id)
				prestige_ups_list.append({
					"name": legacy.legacy_name if legacy else legacy_id,
					"old_prestige": result.get("new_prestige", 1) - result.get("levels_gained", 1),
					"new_prestige": result.get("new_prestige", 1),
					"id": legacy_id,
					"type": "legacy"
				})
	else:
		# Fallback to character fame for backwards compatibility
		fame_reward = RewardCalculator.calculate_character_fame_reward(victory, wins_count)
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
					"id": char_id,
					"type": "character"
				})

	return {
		"victory": victory,
		"round": _run_state.current_round if _run_state else 0,
		"wins": wins_count,
		"losses": _run_state.losses if _run_state else 0,
		"gold": _run_state.current_gold if _run_state else 0,
		"reputation": rep,
		"starting_gold": _run_state.starting_gold if _run_state else 0,
		"team": team_data,
		"gem_reward": gem_reward,
		"fame_reward": fame_reward,
		"prestige_ups": prestige_ups_list,
		"drafted_legacy_ids": _run_state.drafted_legacy_ids.duplicate() if _run_state else []
	}


func clear_run_state() -> void:
	"""Clear all run state and delete save file."""
	is_run_active = false
	_run_state = null

	# Phase 6: Clear RunPool from EncounterFactory
	if EncounterFactory:
		EncounterFactory.clear_run_pool()

	JsonPersistence.delete_file(SAVE_PATH)


# =============================================================================
# GETTERS (Delegate to RunState where appropriate)
# =============================================================================

func get_team() -> Array[CharacterInstance]:
	if not _run_state:
		return []
	var team: Array[CharacterInstance] = []
	for character in _run_state.get_team():
		team.append(character)
	return team


func get_round() -> int:
	return _run_state.current_round if _run_state else 0


func get_reputation() -> int:
	return _run_state.reputation if _run_state else 0


func get_wins() -> int:
	return _run_state.wins if _run_state else 0


func get_losses() -> int:
	return _run_state.losses if _run_state else 0


func get_gold() -> int:
	return _run_state.current_gold if _run_state else 0


func get_phase() -> String:
	return _run_state.current_phase if _run_state else PHASE_ENCOUNTER


func is_encounter_phase() -> bool:
	return get_phase() == PHASE_ENCOUNTER


func is_combat_phase() -> bool:
	return get_phase() == PHASE_COMBAT


func get_run_pool():
	"""Get the run's content pool (or null if no active run)."""
	return _run_state.pool if _run_state else null


func get_drafted_legacy_ids() -> Array[String]:
	"""Get the IDs of legacies drafted for this run (for fame distribution)."""
	if _run_state:
		return _run_state.drafted_legacy_ids
	return []


# =============================================================================
# PLAYER INVENTORY (Phase 2)
# =============================================================================

func get_player_inventory():
	"""Get the player's item inventory."""
	return _run_state.inventory if _run_state else null


func get_player_items() -> Array:
	"""Get all items in the player's inventory."""
	if _run_state:
		return _run_state.inventory.get_all_items()
	return []


func add_item_to_inventory(item_id: String, is_upgrade: bool = true) -> ItemInstance:
	"""
	Add an item to the player's inventory by ID.

	Args:
		item_id: ID of the item in GameData
		is_upgrade: True for item upgrades (default), false for regular items

	Returns:
		The created ItemInstance, or null if invalid
	"""
	if not _run_state:
		return null
	var item = _run_state.inventory.add_item_by_id(item_id, is_upgrade)
	if item != null:
		item_acquired.emit(item)
		save_run_state()
	return item


func has_item_in_inventory(item_id: String) -> bool:
	"""Check if the player has an item with the given ID."""
	if not _run_state:
		return false
	return _run_state.inventory.has_item(item_id)


func get_inventory():
	"""Get the player's inventory (for item upgrade availability checks)."""
	if not _run_state:
		return null
	return _run_state.inventory


func get_inventory_stat_modifier(stat_name: String) -> int:
	"""Get the total modifier for a stat from all player items."""
	if not _run_state:
		return 0
	return _run_state.inventory.get_total_stat_modifier(stat_name)


func apply_item_upgrade(upgrade_id: String, base_item_id: String) -> ItemInstance:
	"""
	Apply an item upgrade, replacing the base item with the upgrade.

	Args:
		upgrade_id: ID of the item upgrade to apply
		base_item_id: ID of the base item being replaced

	Returns:
		The new ItemInstance if successful, null if failed
	"""
	if not _run_state:
		return null

	var upgrade_item = _run_state.inventory.replace_item_with_upgrade(base_item_id, upgrade_id)
	if upgrade_item != null:
		item_acquired.emit(upgrade_item)
		save_run_state()

	return upgrade_item


# =============================================================================
# CHARACTER ACQUISITION (Phase 5)
# =============================================================================

signal character_acquired(character: CharacterInstance)
signal grid_full_character_pending(character: CharacterInstance)

var _pending_character: CharacterInstance = null


func acquire_character(char_id: String) -> Dictionary:
	"""
	Acquire a new character during the run.

	If the grid has space, the character is placed immediately.
	If the grid is full, the character becomes pending and grid_full_character_pending
	is emitted. The UI should show the replacement popup.

	Args:
		char_id: ID of the character to acquire

	Returns:
		Dictionary with:
		- "success": bool - whether acquisition started
		- "placed": bool - whether character was immediately placed
		- "grid_full": bool - whether replacement is needed
		- "character": CharacterInstance - the acquired character
		- "error": String - error message if failed
	"""
	if not _run_state:
		return {"success": false, "error": "no_active_run", "placed": false, "grid_full": false, "character": null}

	var char_instance = CharacterInstance.from_master_data(char_id)
	if not char_instance:
		return {"success": false, "error": "invalid_character_id", "placed": false, "grid_full": false, "character": null}

	# Try to place in grid
	if _run_state.add_character(char_instance):
		# Placed successfully
		character_acquired.emit(char_instance)
		trigger_character_acquired_effects(char_instance)
		save_run_state()
		return {"success": true, "placed": true, "grid_full": false, "character": char_instance, "error": ""}
	else:
		# Grid is full - store as pending
		_pending_character = char_instance
		grid_full_character_pending.emit(char_instance)
		return {"success": true, "placed": false, "grid_full": true, "character": char_instance, "error": ""}


func get_pending_character() -> CharacterInstance:
	"""Get the character waiting for replacement (if any)."""
	return _pending_character


func is_grid_full() -> bool:
	"""Check if the character grid is full."""
	if not _run_state:
		return false
	return _run_state.is_team_full()


func get_character_grid():
	"""Get the character grid (for UI binding)."""
	if not _run_state:
		return null
	return _run_state.get_grid()


func replace_character_at(row: int, col: int, new_character: CharacterInstance = null) -> CharacterInstance:
	"""
	Replace the character at a grid position.

	If new_character is null, uses the pending character.

	Args:
		row: Grid row (0 = front, 1 = back)
		col: Grid column (0-2)
		new_character: Character to place (or null to use pending)

	Returns:
		The removed character, or null if failed
	"""
	if not _run_state:
		return null

	var char_to_place = new_character if new_character else _pending_character
	if not char_to_place:
		return null

	# Remove existing character
	var removed = _run_state.remove_character(row, col)

	# Place new character
	if _run_state.add_character_at(char_to_place, row, col):
		# Clear pending if we used it
		if char_to_place == _pending_character:
			_pending_character = null

		character_acquired.emit(char_to_place)
		trigger_character_acquired_effects(char_to_place)
		save_run_state()

	return removed


func cancel_pending_character() -> void:
	"""Cancel acquisition of the pending character."""
	_pending_character = null


func swap_grid_positions(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	"""
	Swap characters between two grid positions.

	Args:
		from_row, from_col: First position
		to_row, to_col: Second position

	Returns:
		True if swap succeeded
	"""
	if not _run_state:
		return false
	if _run_state.swap_characters(from_row, from_col, to_row, to_col):
		save_run_state()
		return true
	return false


func get_character_at_grid(row: int, col: int) -> CharacterInstance:
	"""Get character at a specific grid position."""
	if not _run_state:
		return null
	return _run_state.get_character_at(row, col)


func get_grid_empty_slots() -> Array[Vector2i]:
	"""Get all empty grid positions."""
	if not _run_state:
		return []
	return _run_state.get_empty_slots()


# =============================================================================
# LINGERING EFFECTS (Phase 3)
# =============================================================================

func get_skill_registry():
	"""Get the skill effect registry."""
	return _skill_registry


func get_lingering_effects():
	"""Get the lingering effects manager."""
	return _run_state.lingering_effects if _run_state else null


func add_lingering_effect(skill_data: Dictionary) -> bool:
	"""
	Add a lingering effect from skill data.

	Args:
		skill_data: The full skill data dictionary containing effect and trigger

	Returns:
		True if effect was added successfully
	"""
	if not _run_state:
		return false
	var effect_id = _run_state.lingering_effects.add_effect(skill_data, _run_state.current_round)
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
	if not _run_state:
		return []
	var context = _create_skill_context()
	var triggered = _run_state.lingering_effects.trigger(trigger_type, context, _skill_registry)
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
	if not _run_state:
		return []
	var context = _create_skill_context()
	var triggered = _run_state.lingering_effects.trigger_for_character(
		"next_character_acquired",
		character,
		context
	)
	if triggered.size() > 0:
		save_run_state()
	return triggered


func has_pending_effects(trigger_type: String) -> bool:
	"""Check if there are any lingering effects waiting for a trigger."""
	if not _run_state:
		return false
	return _run_state.lingering_effects.has_effects_for_trigger(trigger_type)


func get_pending_effects(trigger_type: String) -> Array[Dictionary]:
	"""Get all pending effects for a trigger type."""
	if not _run_state:
		return []
	return _run_state.lingering_effects.get_effects_by_trigger(trigger_type)


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
	if not _run_state:
		return
	_run_state.advance_round()

	# Trigger any "next_round" lingering effects
	trigger_lingering_effects("next_round")

	round_changed.emit(_run_state.current_round)
	phase_changed.emit(_run_state.current_phase)
	save_run_state()


func set_phase(phase: String) -> void:
	"""Set the current phase."""
	if not _run_state:
		return
	if phase != PHASE_ENCOUNTER and phase != PHASE_COMBAT:
		push_error("RunManager: Invalid phase: %s" % phase)
		return
	_run_state.set_phase(phase)
	phase_changed.emit(_run_state.current_phase)
	save_run_state()


func complete_encounter() -> void:
	"""Complete encounter phase. Switches to combat after ENCOUNTERS_PER_ROUND encounters."""
	if not _run_state:
		return
	_run_state.complete_encounter()

	# Trigger any "next_encounter" lingering effects for next encounter
	if _run_state.encounters_this_round < GameConstants.ENCOUNTERS_PER_ROUND:
		trigger_lingering_effects("next_encounter")

	phase_changed.emit(_run_state.current_phase)
	save_run_state()


func add_gold(amount: int) -> void:
	"""Add gold (from combat rewards, etc.)."""
	if not _run_state:
		return
	_run_state.add_gold(amount)
	gold_changed.emit(_run_state.current_gold)
	save_run_state()


func spend_gold(amount: int) -> bool:
	"""Spend gold (returns false if not enough)."""
	if not _run_state:
		return false
	if _run_state.spend_gold(amount):
		gold_changed.emit(_run_state.current_gold)
		save_run_state()
		return true
	return false


# =============================================================================
# PLAYER LEVEL PROGRESSION
# =============================================================================

func add_player_xp(amount: int) -> bool:
	"""
	Add XP to the player. Player level gates what content is available.

	Args:
		amount: XP to add

	Returns:
		True if player leveled up
	"""
	if not _run_state:
		return false
	var leveled_up = _run_state.add_player_xp(amount)
	player_xp_changed.emit(_run_state.player_xp)
	if leveled_up:
		player_level_changed.emit(_run_state.player_level)
	save_run_state()
	return leveled_up


func get_player_level() -> int:
	"""Get current player level (1-5)."""
	return _run_state.get_player_level() if _run_state else 1


func get_player_xp() -> int:
	"""Get current XP progress toward next level."""
	return _run_state.get_player_xp() if _run_state else 0


func get_player_xp_progress() -> float:
	"""Get XP progress as percentage (0.0 to 1.0)."""
	return _run_state.get_xp_progress() if _run_state else 0.0


func is_player_max_level() -> bool:
	"""Check if player has reached maximum level."""
	return _run_state.is_max_level() if _run_state else false


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
	if not _run_state:
		return
	_run_state.add_win()
	save_run_state()


func add_loss() -> void:
	"""Record a combat loss."""
	if not _run_state:
		return
	_run_state.add_loss()
	save_run_state()


func lose_reputation(amount: int) -> void:
	"""Lose reputation (from combat loss)."""
	if not _run_state:
		return
	_run_state.lose_reputation(amount)
	reputation_changed.emit(_run_state.reputation)
	save_run_state()


func is_run_over() -> bool:
	"""Check if run is over (win or loss condition met)."""
	if not _run_state:
		return false
	return _run_state.is_run_over()


func did_player_win() -> bool:
	"""Check if player won (only valid if is_run_over() is true)."""
	if not _run_state:
		return false
	return _run_state.is_victory()


# =============================================================================
# UTILITY METHODS
# =============================================================================

func get_phase_name() -> String:
	"""Get current phase name for display."""
	return get_phase()


func get_team_summary() -> Dictionary:
	"""Get summary stats for the team."""
	var summary = {
		"total_health": 0,
		"max_health": 0,
		"total_mana": 0
	}

	var team = get_team()
	if team.is_empty():
		return summary

	for char_instance in team:
		summary["total_health"] += char_instance.current_health
		summary["max_health"] += char_instance.max_health
		summary["total_mana"] += char_instance.mana

	return summary


func get_character_by_index(index: int) -> CharacterInstance:
	"""Get a team member by index (0-based)."""
	var team = get_team()
	if index >= 0 and index < team.size():
		return team[index]
	return null


func capture_team_data() -> Array:
	"""Capture team member data as an Array of Dictionaries (id, name)."""
	var team_data = []
	for char_instance in get_team():
		team_data.append({
			"id": char_instance.base_character_id,
			"name": char_instance.get_character_name()
		})
	return team_data


# =============================================================================
# DRAFT EVENTS - Forwarded from draft scene to HUDs
# =============================================================================

func notify_draft_character_added(char_instance: CharacterInstance) -> void:
	"""Called by draft scene when a character is drafted. Notifies HUDs."""
	character_acquired.emit(char_instance)


func notify_draft_gold_updated(amount: int) -> void:
	"""Called by draft scene when draft gold total changes. Notifies HUDs."""
	draft_gold_updated.emit(amount)


# =============================================================================
# COMBAT GENERATION - Delegated to CombatGenerator
# =============================================================================

var _combat_generator: CombatGenerator = CombatGenerator.new()

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
		RewardCalculator.apply_combat_victory_rewards(add_gold, add_player_xp, combat_data)
	else:
		# Lose reputation equal to round number
		var reputation_loss = RewardCalculator.calculate_reputation_loss(get_round())
		lose_reputation(reputation_loss)


# =============================================================================
# DEPRECATED ACCESSORS (kept for backwards compatibility)
# =============================================================================

var run_id: String:
	get: return _run_state.run_id if _run_state else ""

var current_round: int:
	get: return get_round()

var current_phase: String:
	get: return get_phase()

var encounters_this_round: int:
	get: return _run_state.encounters_this_round if _run_state else 0

var reputation: int:
	get: return get_reputation()

var wins: int:
	get: return get_wins()

var losses: int:
	get: return get_losses()

var starting_gold: int:
	get: return _run_state.starting_gold if _run_state else 0

var current_gold: int:
	get: return get_gold()

var encounter_history: Array:
	get: return []  # Deprecated - no longer tracked in RunState
