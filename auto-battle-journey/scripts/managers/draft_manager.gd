class_name DraftManager
extends RefCounted
# DraftManager - Handles character draft logic and state
# Extracted from draft.gd for Single Responsibility Principle
# The UI scene (draft.gd) handles display; this class handles business logic

signal options_generated(options: Array, instances: Array)
signal character_drafted(char_data: Dictionary, char_instance: CharacterInstance)
signal draft_complete(team: Array)

# Draft state
var drafted_characters: Array = []  # Character data dictionaries
var drafted_instances: Array[CharacterInstance] = []  # CharacterInstance objects for team
var current_options: Array = []  # Option dictionaries with char_data, is_owned, unlock_cost
var option_instances: Array[CharacterInstance] = []  # CharacterInstance objects for options
var selection_count: int = 0


func reset() -> void:
	"""Reset all draft state for a new draft session."""
	drafted_characters.clear()
	drafted_instances.clear()
	current_options.clear()
	option_instances.clear()
	selection_count = 0


func generate_options() -> void:
	"""Generate 3 unique character options (2 owned, 1 random)."""
	current_options.clear()
	option_instances.clear()

	# Get IDs of already drafted characters
	var drafted_ids: Array[String] = []
	for char_data in drafted_characters:
		drafted_ids.append(char_data.get("id", ""))

	# Get owned characters (excluding already drafted)
	var owned_chars = PlayerAccount.get_unlocked_characters()
	var available_owned: Array = []
	for char_data in owned_chars:
		if char_data.get("id", "") not in drafted_ids:
			available_owned.append(char_data)

	# Get all characters for random option
	var all_chars = GameData.get_all_characters()

	if available_owned.size() < 2:
		push_error("DraftManager: Not enough available owned characters")
		return

	# Shuffle owned pool
	available_owned.shuffle()

	# Track which character IDs we've added to options
	var option_ids: Array[String] = []

	# Generate 2 owned options
	for i in range(2):
		if available_owned.size() > 0:
			var char_data = available_owned.pop_front()
			current_options.append({
				"char_data": char_data,
				"is_owned": true,
				"unlock_cost": 0
			})
			option_ids.append(char_data.get("id", ""))

	# Generate 1 random option (must be unique from the 2 owned options)
	all_chars.shuffle()
	var random_char = null
	for character in all_chars:
		var char_id = character.get("id", "")
		if char_id not in option_ids and char_id not in drafted_ids:
			random_char = character
			break

	if random_char == null:
		push_error("DraftManager: Could not find unique random character")
		return

	var random_char_id = random_char.get("id", "")
	var is_owned = PlayerAccount.is_character_unlocked(random_char_id)

	# Get character data
	var random_char_data = null
	if is_owned:
		random_char_data = PlayerAccount.get_character_data(random_char_id)
	else:
		# Create temporary data for display
		random_char_data = {
			"id": random_char_id,
			"unlocked": false,
			"prestige": 1,
			"fame": 0,
			"equipped_items": [],
			"unlocked_items": [],
			"unlocked_item_upgrades": [],
			"unlocked_skills": []
		}

	current_options.append({
		"char_data": random_char_data,
		"is_owned": is_owned,
		"unlock_cost": GameConstants.CHARACTER_UNLOCK_COST
	})

	# Create CharacterInstance objects for the options display
	for option in current_options:
		var char_instance = CharacterInstance.new(option["char_data"])
		option_instances.append(char_instance)

	print("DraftManager: Generated %d unique options" % current_options.size())

	options_generated.emit(current_options, option_instances)


func is_character_drafted(char_id: String) -> bool:
	"""Check if character is already in drafted array."""
	for char_data in drafted_characters:
		if char_data.get("id", "") == char_id:
			return true
	return false


func select_character(char_data: Dictionary) -> bool:
	"""
	Select an owned character to add to the draft.
	Returns true if selection was successful.
	"""
	var char_id = char_data.get("id", "")

	if is_character_drafted(char_id):
		print("DraftManager: Character already selected")
		return false

	if drafted_characters.size() >= GameConstants.TEAM_SIZE:
		print("DraftManager: Already have %d characters" % GameConstants.TEAM_SIZE)
		return false

	drafted_characters.append(char_data)

	# Create a CharacterInstance for the team
	var char_instance = CharacterInstance.new(char_data)
	drafted_instances.append(char_instance)

	selection_count += 1

	print("DraftManager: Selected %s (%d/%d)" % [char_id, selection_count, GameConstants.TEAM_SIZE])

	character_drafted.emit(char_data, char_instance)

	if is_draft_complete():
		draft_complete.emit(drafted_instances)

	return true


func unlock_and_select(char_data: Dictionary, cost: int) -> bool:
	"""
	Unlock a character and then select it.
	Returns true if unlock and selection were successful.
	"""
	if drafted_characters.size() >= GameConstants.TEAM_SIZE:
		print("DraftManager: Already have %d characters" % GameConstants.TEAM_SIZE)
		return false

	var char_id = char_data.get("id", "")

	# Attempt to unlock
	var success = PlayerAccount.unlock_character(char_id, cost)
	if not success:
		print("DraftManager: Failed to unlock character (not enough gems)")
		return false

	# Now select the newly unlocked character
	var unlocked_char_data = PlayerAccount.get_character_data(char_id)
	return select_character(unlocked_char_data)


func is_draft_complete() -> bool:
	"""Check if the draft is complete (all characters selected)."""
	return selection_count >= GameConstants.TEAM_SIZE


func get_drafted_team() -> Array[CharacterInstance]:
	"""Get the drafted team as CharacterInstance array."""
	return drafted_instances


func get_drafted_character_ids() -> Array[String]:
	"""Get IDs of all drafted characters."""
	var ids: Array[String] = []
	for char_data in drafted_characters:
		ids.append(char_data.get("id", ""))
	return ids


func get_current_selection_number() -> int:
	"""Get the current selection number (1-indexed for display)."""
	return selection_count + 1


func get_option_at(index: int) -> Dictionary:
	"""Get option at the given index."""
	if index >= 0 and index < current_options.size():
		return current_options[index]
	return {}
