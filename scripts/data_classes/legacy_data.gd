class_name LegacyData
extends RefCounted
# LegacyData - Runtime representation of a legacy
# Combines master data (from JSON) with account-level state (from save)
# Uses composition for prestige tracking (DIP - Dependency Inversion Principle)

# =============================================================================
# MASTER DATA (from JSON, immutable during runtime)
# =============================================================================

var id: String = ""
var legacy_name: String = ""  # 'name' is reserved in Godot
var description: String = ""
var image_path: String = ""
var income: int = 0

# Content pools (all possible content for this legacy)
var starting_character_options: Array[String] = []
var starting_item_options: Array[String] = []
var character_pool: Array[String] = []
var item_pool: Array[String] = []
var skill_pool: Array[String] = []
var unique_encounters: Array[String] = []
var prestige_rewards: Array = []  # Array of prestige reward dictionaries


# =============================================================================
# ACCOUNT-LEVEL STATE (persisted per-player)
# =============================================================================

var unlocked: bool = false
var prestige_tracker: PrestigeTracker  # Composition, not inheritance (DIP)

# Player's chosen starting selections
var selected_starting_character_id: String = ""
var selected_starting_item_id: String = ""

# Unlocked content (expanded by prestige)
var unlocked_starting_characters: Array[String] = []
var unlocked_starting_items: Array[String] = []
var unlocked_characters: Array[String] = []
var unlocked_items: Array[String] = []
var unlocked_item_upgrades: Array[String] = []
var unlocked_skills: Array[String] = []
var unlocked_encounters: Array[String] = []
var total_encounter_weight_bonus: int = 0


# =============================================================================
# ACCESSORS
# =============================================================================

func get_prestige() -> int:
	"""Get current prestige level."""
	return prestige_tracker.get_prestige()


func get_fame() -> int:
	"""Get current fame (progress toward next prestige)."""
	return prestige_tracker.get_fame()


func get_encounter_weight() -> int:
	"""Get encounter weight (base 100 + accumulated bonuses)."""
	return 100 + total_encounter_weight_bonus


func has_starting_item() -> bool:
	"""Check if this legacy has any starting item options."""
	return starting_item_options.size() > 0


func has_unlocked_starting_items() -> bool:
	"""Check if player has unlocked any starting items for this legacy."""
	return unlocked_starting_items.size() > 0


func get_available_starting_characters() -> Array[String]:
	"""Get starting characters that are unlocked for selection."""
	return unlocked_starting_characters


func get_available_starting_items() -> Array[String]:
	"""Get starting items that are unlocked for selection."""
	return unlocked_starting_items


# =============================================================================
# FACTORY METHODS
# =============================================================================

static func from_dict(master: Dictionary, account: Dictionary = {}) -> LegacyData:
	"""
	Create LegacyData from master JSON data and optional account state.

	Args:
		master: Master data from legacies.json
		account: Optional account state from player save

	Returns:
		Populated LegacyData instance
	"""
	var legacy = LegacyData.new()

	# Load master data
	legacy.id = master.get("id", "")
	legacy.legacy_name = master.get("name", "Unknown Legacy")
	legacy.description = master.get("description", "")
	legacy.image_path = master.get("image_path", "")
	legacy.income = master.get("income", 10)

	# Load pools as typed arrays
	legacy.starting_character_options = _to_string_array(master.get("starting_character_options", []))
	legacy.starting_item_options = _to_string_array(master.get("starting_item_options", []))
	legacy.character_pool = _to_string_array(master.get("character_pool", []))
	legacy.item_pool = _to_string_array(master.get("item_pool", []))
	legacy.skill_pool = _to_string_array(master.get("skill_pool", []))
	legacy.unique_encounters = _to_string_array(master.get("unique_encounters", []))
	legacy.prestige_rewards = master.get("prestige_rewards", [])

	# Load account state (if provided)
	if account.is_empty():
		# Initialize fresh account state
		legacy._initialize_fresh_state()
	else:
		legacy._load_account_state(account)

	return legacy


static func _to_string_array(arr: Array) -> Array[String]:
	"""Convert generic Array to typed Array[String]."""
	var result: Array[String] = []
	for item in arr:
		result.append(str(item))
	return result


func _initialize_fresh_state() -> void:
	"""Initialize fresh account state for a new legacy."""
	unlocked = false
	prestige_tracker = PrestigeTracker.new()
	selected_starting_character_id = ""
	selected_starting_item_id = ""
	unlocked_starting_characters = []
	unlocked_starting_items = []
	unlocked_characters = []
	unlocked_items = []
	unlocked_item_upgrades = []
	unlocked_skills = []
	unlocked_encounters = []
	total_encounter_weight_bonus = 0


func _load_account_state(account: Dictionary) -> void:
	"""Load account state from saved data."""
	unlocked = account.get("unlocked", false)

	# Load prestige tracker
	if account.has("prestige"):
		prestige_tracker = PrestigeTracker.from_dict({
			"prestige": account.get("prestige", 1),
			"fame": account.get("fame", 0)
		})
	else:
		prestige_tracker = PrestigeTracker.new()

	# Load selections
	selected_starting_character_id = account.get("selected_starting_character_id", "")
	selected_starting_item_id = account.get("selected_starting_item_id", "")

	# Load unlocked content
	unlocked_starting_characters = _to_string_array(account.get("unlocked_starting_characters", []))
	unlocked_starting_items = _to_string_array(account.get("unlocked_starting_items", []))
	unlocked_characters = _to_string_array(account.get("unlocked_characters", []))
	unlocked_items = _to_string_array(account.get("unlocked_items", []))
	unlocked_item_upgrades = _to_string_array(account.get("unlocked_item_upgrades", []))
	unlocked_skills = _to_string_array(account.get("unlocked_skills", []))
	unlocked_encounters = _to_string_array(account.get("unlocked_encounters", []))
	total_encounter_weight_bonus = account.get("total_encounter_weight_bonus", 0)


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_account_dict() -> Dictionary:
	"""Serialize account-level state for saving (not master data)."""
	return {
		"id": id,
		"unlocked": unlocked,
		"prestige": prestige_tracker.get_prestige(),
		"fame": prestige_tracker.get_fame(),
		"selected_starting_character_id": selected_starting_character_id,
		"selected_starting_item_id": selected_starting_item_id,
		"unlocked_starting_characters": Array(unlocked_starting_characters),
		"unlocked_starting_items": Array(unlocked_starting_items),
		"unlocked_characters": Array(unlocked_characters),
		"unlocked_items": Array(unlocked_items),
		"unlocked_item_upgrades": Array(unlocked_item_upgrades),
		"unlocked_skills": Array(unlocked_skills),
		"unlocked_encounters": Array(unlocked_encounters),
		"total_encounter_weight_bonus": total_encounter_weight_bonus
	}


# =============================================================================
# UNLOCK OPERATIONS
# =============================================================================

func unlock() -> void:
	"""Unlock this legacy for the player."""
	if not unlocked:
		unlocked = true
		# Apply prestige 1 rewards on unlock
		_apply_prestige_rewards(1)
		# Auto-select first starting character if none selected
		if selected_starting_character_id.is_empty() and unlocked_starting_characters.size() > 0:
			selected_starting_character_id = unlocked_starting_characters[0]
		# Auto-select first starting item if available and none selected
		if selected_starting_item_id.is_empty() and unlocked_starting_items.size() > 0:
			selected_starting_item_id = unlocked_starting_items[0]


func add_fame(amount: int) -> Dictionary:
	"""
	Add fame to this legacy, potentially increasing prestige.

	Returns:
		Dictionary with prestige_increased, new_prestige, unlocked_content
	"""
	var result = prestige_tracker.add_fame(amount)

	# Apply new prestige rewards if prestige increased
	if result.prestige_increased:
		var unlocked_content = _apply_prestige_rewards(result.new_prestige)
		result.unlocked_content = unlocked_content

	return result


func _apply_prestige_rewards(target_prestige: int) -> Dictionary:
	"""
	Apply rewards for reaching a prestige level.

	Args:
		target_prestige: The prestige level to apply rewards for

	Returns:
		Dictionary of newly unlocked content
	"""
	var unlocked_content = {
		"starting_characters": [],
		"starting_items": [],
		"characters": [],
		"items": [],
		"item_upgrades": [],
		"skills": [],
		"encounters": []
	}

	for reward in prestige_rewards:
		if reward.get("prestige", 0) == target_prestige:
			var unlocks = reward.get("unlocks", {})

			# Unlock starting characters
			for char_id in unlocks.get("starting_characters", []):
				if char_id not in unlocked_starting_characters:
					unlocked_starting_characters.append(char_id)
					unlocked_content.starting_characters.append(char_id)

			# Unlock starting items
			for item_id in unlocks.get("starting_items", []):
				if item_id not in unlocked_starting_items:
					unlocked_starting_items.append(item_id)
					unlocked_content.starting_items.append(item_id)

			# Unlock characters
			for char_id in unlocks.get("characters", []):
				if char_id not in unlocked_characters:
					unlocked_characters.append(char_id)
					unlocked_content.characters.append(char_id)

			# Unlock items (regular items for the run pool)
			for item_id in unlocks.get("items", []):
				if item_id not in unlocked_items:
					unlocked_items.append(item_id)
					unlocked_content.items.append(item_id)

			# Unlock item upgrades (conditional on owning base item during run)
			for upgrade_id in unlocks.get("item_upgrades", []):
				if upgrade_id not in unlocked_item_upgrades:
					unlocked_item_upgrades.append(upgrade_id)
					unlocked_content.item_upgrades.append(upgrade_id)

			# Unlock skills
			for skill_id in unlocks.get("skills", []):
				if skill_id not in unlocked_skills:
					unlocked_skills.append(skill_id)
					unlocked_content.skills.append(skill_id)

			# Unlock encounters
			for enc_id in unlocks.get("encounters", []):
				if enc_id not in unlocked_encounters:
					unlocked_encounters.append(enc_id)
					unlocked_content.encounters.append(enc_id)

			# Add encounter weight bonus
			var weight_bonus = unlocks.get("encounter_weight_bonus", 0)
			if weight_bonus > 0:
				total_encounter_weight_bonus += weight_bonus

			break  # Found the matching prestige level

	return unlocked_content


# =============================================================================
# SELECTION OPERATIONS
# =============================================================================

func select_starting_character(char_id: String) -> bool:
	"""
	Select a starting character for this legacy.

	Args:
		char_id: Character ID to select (must be in unlocked_starting_characters)

	Returns:
		true if selection successful
	"""
	if char_id in unlocked_starting_characters:
		selected_starting_character_id = char_id
		return true
	return false


func select_starting_item(item_id: String) -> bool:
	"""
	Select a starting item for this legacy.

	Args:
		item_id: Item ID to select (must be in unlocked_starting_items)

	Returns:
		true if selection successful
	"""
	if item_id in unlocked_starting_items:
		selected_starting_item_id = item_id
		return true
	# Allow clearing selection
	if item_id.is_empty():
		selected_starting_item_id = ""
		return true
	return false
