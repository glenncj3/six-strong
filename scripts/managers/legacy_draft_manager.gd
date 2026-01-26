class_name LegacyDraftManager
extends RefCounted
## Handles legacy draft logic and state for starting a run.
## Generates 3 legacy options per round (2 owned + 1 random).
## Tracks selections across 3 rounds and computes starting resources.
##
## Draft structure:
##   - 3 rounds, pick 1 legacy per round
##   - Each round: 2 owned legacies + 1 random (costs gems if not owned)
##   - Reroll tokens work the same way as character draft

const RunPoolScript = preload("res://scripts/managers/run_pool.gd")

# =============================================================================
# SIGNALS
# =============================================================================

signal draft_options_generated(options: Array)
signal legacy_drafted(legacy: LegacyData)
signal draft_completed(drafted_legacies: Array)
signal generation_failed(error_message: String)


# =============================================================================
# DRAFT STATE
# =============================================================================

# Drafted legacies (LegacyData objects)
var drafted_legacies: Array[LegacyData] = []

# Current options for selection
# Each option is: { legacy: LegacyData, is_owned: bool, unlock_cost: int }
var current_options: Array = []

# Selection counter
var selection_count: int = 0

# Total rounds in draft
const DRAFT_ROUNDS: int = 3


# =============================================================================
# INITIALIZATION
# =============================================================================

func reset() -> void:
	"""Reset all draft state for a new draft session."""
	drafted_legacies.clear()
	current_options.clear()
	selection_count = 0


# =============================================================================
# OPTION GENERATION
# =============================================================================

func generate_options() -> bool:
	"""
	Generate 3 unique legacy options (2 owned + 1 random).

	Returns:
		True on success, false on failure. Emits generation_failed signal on error.
	"""
	current_options.clear()

	# Get IDs of already drafted legacies
	var drafted_ids: Array[String] = []
	for legacy in drafted_legacies:
		drafted_ids.append(legacy.id)

	# Get owned legacies (excluding already drafted)
	var owned_legacies = PlayerAccount.get_unlocked_legacies()
	var available_owned: Array[LegacyData] = []
	for legacy in owned_legacies:
		if legacy.id not in drafted_ids:
			available_owned.append(legacy)

	# Get all legacies for random option
	var all_legacies = PlayerAccount.get_all_legacies()

	if available_owned.size() < GameConstants.DRAFT_OWNED_OPTIONS:
		var error_msg = "Not enough available owned legacies (need %d, have %d)" % [
			GameConstants.DRAFT_OWNED_OPTIONS,
			available_owned.size()
		]
		push_error("LegacyDraftManager: %s" % error_msg)
		generation_failed.emit(error_msg)
		return false

	# Shuffle owned pool
	available_owned.shuffle()

	# Track which legacy IDs we've added to options
	var option_ids: Array[String] = []

	# Generate owned options
	for i in range(GameConstants.DRAFT_OWNED_OPTIONS):
		if available_owned.size() > 0:
			var legacy = available_owned.pop_front()
			current_options.append({
				"legacy": legacy,
				"is_owned": true,
				"unlock_cost": 0
			})
			option_ids.append(legacy.id)

	# Generate 1 random option (must be unique from the 2 owned options and not already drafted)
	var all_shuffled: Array[LegacyData] = []
	for legacy in all_legacies:
		all_shuffled.append(legacy)
	all_shuffled.shuffle()

	var random_legacy: LegacyData = null
	for legacy in all_shuffled:
		if legacy.id not in option_ids and legacy.id not in drafted_ids:
			random_legacy = legacy
			break

	if random_legacy == null:
		var error_msg = "Could not find unique random legacy for draft options"
		push_error("LegacyDraftManager: %s" % error_msg)
		generation_failed.emit(error_msg)
		return false

	var is_owned = random_legacy.unlocked

	current_options.append({
		"legacy": random_legacy,
		"is_owned": is_owned,
		"unlock_cost": GameConstants.LEGACY_UNLOCK_COST if not is_owned else 0
	})

	draft_options_generated.emit(current_options)
	return true


# =============================================================================
# SELECTION
# =============================================================================

func is_legacy_drafted(legacy_id: String) -> bool:
	"""Check if legacy is already in drafted array."""
	for legacy in drafted_legacies:
		if legacy.id == legacy_id:
			return true
	return false


func select_legacy(legacy: LegacyData) -> bool:
	"""
	Select an owned legacy to add to the draft.

	Returns:
		True if selection was successful
	"""
	if is_legacy_drafted(legacy.id):
		return false

	if drafted_legacies.size() >= DRAFT_ROUNDS:
		return false

	drafted_legacies.append(legacy)
	selection_count += 1

	legacy_drafted.emit(legacy)

	if is_draft_complete():
		draft_completed.emit(drafted_legacies)

	return true


func unlock_and_select(legacy: LegacyData, cost: int) -> bool:
	"""
	Unlock a legacy by spending gems, then select it.

	Returns:
		True if unlock and selection were successful
	"""
	if drafted_legacies.size() >= DRAFT_ROUNDS:
		return false

	# Attempt to unlock
	var success = PlayerAccount.unlock_legacy(legacy.id, cost)
	if not success:
		return false

	# Refresh the legacy data since it's now unlocked
	var unlocked_legacy = PlayerAccount.get_legacy_data(legacy.id)
	if unlocked_legacy == null:
		push_error("LegacyDraftManager: Failed to get unlocked legacy data")
		return false

	return select_legacy(unlocked_legacy)


# =============================================================================
# DRAFT COMPLETION
# =============================================================================

func is_draft_complete() -> bool:
	"""Check if the draft is complete (all legacies selected)."""
	return selection_count >= DRAFT_ROUNDS


func get_drafted_legacies() -> Array[LegacyData]:
	"""Get the drafted legacies."""
	return drafted_legacies


func get_drafted_legacy_ids() -> Array[String]:
	"""Get IDs of all drafted legacies."""
	var ids: Array[String] = []
	for legacy in drafted_legacies:
		ids.append(legacy.id)
	return ids


# =============================================================================
# STARTING RESOURCES COMPUTATION
# =============================================================================

func calculate_starting_gold() -> int:
	"""
	Calculate starting gold from drafted legacies' incomes.

	Returns:
		Sum of all drafted legacies' income values
	"""
	var total = 0
	for legacy in drafted_legacies:
		total += legacy.income
	return total


func get_starting_characters() -> Array[String]:
	"""
	Get starting character IDs from drafted legacies.

	Returns:
		Array of character IDs (one per legacy, from selected_starting_character_id)
	"""
	var characters: Array[String] = []
	for legacy in drafted_legacies:
		if not legacy.selected_starting_character_id.is_empty():
			characters.append(legacy.selected_starting_character_id)
	return characters


func get_starting_items() -> Array[String]:
	"""
	Get starting item IDs from drafted legacies.

	Returns:
		Array of item IDs (one per legacy if they have a starting item)
	"""
	var items: Array[String] = []
	for legacy in drafted_legacies:
		if not legacy.selected_starting_item_id.is_empty():
			items.append(legacy.selected_starting_item_id)
	return items


# =============================================================================
# RUN POOL CREATION
# =============================================================================

func create_run_pool():
	"""
	Create a RunPool from the drafted legacies' unlocked content.

	Returns:
		RunPool containing all content available for this run
	"""
	return RunPoolScript.from_legacies(drafted_legacies)


# =============================================================================
# UTILITY
# =============================================================================

func get_current_selection_number() -> int:
	"""Get the current selection number (1-indexed for display)."""
	return selection_count + 1


func get_option_at(index: int) -> Dictionary:
	"""Get option at the given index."""
	if index >= 0 and index < current_options.size():
		return current_options[index]
	return {}


func get_total_rounds() -> int:
	"""Get total number of draft rounds."""
	return DRAFT_ROUNDS
