class_name CharacterCollection
extends RefCounted
# CharacterCollection - Manages player's character collection
# Split from PlayerAccount for Single Responsibility Principle
# Uses Dictionary for O(1) character lookups instead of Array

signal character_unlocked(char_id: String)
signal character_prestige_up(char_id: String, new_prestige: int)

# Characters stored as Dictionary for O(1) lookup: id -> character_data
var _characters: Dictionary = {}

# Callback for persistence (injected by PlayerAccount)
var _on_change_callback: Callable = Callable()


# =============================================================================
# PERSISTENCE INTEGRATION
# =============================================================================

func set_change_callback(callback: Callable) -> void:
	"""Set callback to be called when collection changes (for persistence)."""
	_on_change_callback = callback


func _notify_change() -> void:
	"""Notify that data changed (triggers save)."""
	if _on_change_callback.is_valid():
		_on_change_callback.call()


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize collection data for saving."""
	# Convert to array format for JSON compatibility with existing saves
	var characters_array = []
	for char_id in _characters:
		characters_array.append(_characters[char_id])

	return {
		"characters": characters_array,
		"unlocked_character_ids": _characters.keys()
	}


static func from_dict(data: Dictionary) -> CharacterCollection:
	"""Create CharacterCollection from saved data."""
	var collection = CharacterCollection.new()

	# Support both old array format and new dict format
	if data.has("characters"):
		for char_data in data["characters"]:
			if char_data.has("id"):
				collection._characters[char_data["id"]] = char_data

	return collection


func to_array() -> Array:
	"""Get all characters as an array (for compatibility)."""
	return _characters.values()


# =============================================================================
# CHARACTER QUERIES
# =============================================================================

func get_character_data(char_id: String) -> Dictionary:
	"""
	Get player's data for a specific character.
	O(1) lookup thanks to Dictionary storage.
	"""
	return _characters.get(char_id, {})


func get_unlocked_characters() -> Array:
	"""Get array of all unlocked character data."""
	var unlocked = []
	for char_data in _characters.values():
		if char_data.get("unlocked", false):
			unlocked.append(char_data)
	return unlocked


func get_unlocked_character_ids() -> Array:
	"""Get array of all unlocked character IDs."""
	return _characters.keys()


func is_character_unlocked(char_id: String) -> bool:
	"""Check if a character is unlocked."""
	return _characters.has(char_id) and _characters[char_id].get("unlocked", false)


func get_character_count() -> int:
	"""Get total number of unlocked characters."""
	return _characters.size()


# =============================================================================
# CHARACTER MANAGEMENT
# =============================================================================

func unlock_character(char_id: String) -> bool:
	"""
	Unlock a new character (call after spending gems).

	Returns:
		true if character was unlocked, false if already owned or invalid
	"""
	if is_character_unlocked(char_id):
		push_warning("CharacterCollection: Character already unlocked: %s" % char_id)
		return false

	# Create character data
	var char_data = _create_character_data(char_id)
	if char_data.is_empty():
		return false

	_characters[char_id] = char_data
	character_unlocked.emit(char_id)
	_notify_change()
	return true


func _create_character_data(char_id: String) -> Dictionary:
	"""Create initial character data entry."""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("CharacterCollection: Master data not found: %s" % char_id)
		return {}

	# Get prestige 1 unlocked items
	var unlocked_items: Array = []
	if char_master.has("prestige_rewards") and char_master["prestige_rewards"].size() > 0:
		var prestige_1_rewards = char_master["prestige_rewards"][0]
		if prestige_1_rewards.has("rewards"):
			for reward in prestige_1_rewards["rewards"]:
				if reward.get("type") == "item":
					unlocked_items.append(reward["id"])

	return {
		"id": char_id,
		"unlocked": true,
		"prestige": 1,
		"fame": 0,
		"equipped_items": unlocked_items.duplicate(),  # Auto-equip starting items
		"unlocked_items": unlocked_items,
		"unlocked_item_upgrades": [],
		"unlocked_skills": []
	}


# =============================================================================
# PROGRESSION
# =============================================================================

func add_character_fame(char_id: String, fame: int) -> void:
	"""Add fame to a character, may increase prestige."""
	if not _characters.has(char_id):
		push_warning("CharacterCollection: Character not found: %s" % char_id)
		return

	var char_data = _characters[char_id]
	char_data["fame"] += fame

	# Check for prestige increase
	while char_data["fame"] >= GameConstants.FAME_PER_PRESTIGE:
		char_data["fame"] -= GameConstants.FAME_PER_PRESTIGE
		char_data["prestige"] += 1
		print("CharacterCollection: %s prestige increased to %d!" % [char_id, char_data["prestige"]])
		_apply_prestige_rewards(char_id, char_data["prestige"])
		character_prestige_up.emit(char_id, char_data["prestige"])

	_notify_change()


func _apply_prestige_rewards(char_id: String, new_prestige: int) -> void:
	"""Apply rewards for reaching a new prestige level."""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		return

	var char_data = _characters[char_id]

	if not char_master.has("prestige_rewards"):
		return

	for prestige_reward in char_master["prestige_rewards"]:
		if prestige_reward.get("prestige") == new_prestige:
			print("CharacterCollection: Applying prestige %d rewards for %s" % [new_prestige, char_id])

			if prestige_reward.has("rewards"):
				for reward in prestige_reward["rewards"]:
					_apply_reward(char_data, reward)
			break


func _apply_reward(char_data: Dictionary, reward: Dictionary) -> void:
	"""Apply a single reward to character data."""
	var reward_type = reward.get("type", "")
	var reward_id = reward.get("id", "")

	match reward_type:
		"item":
			if reward_id not in char_data["unlocked_items"]:
				char_data["unlocked_items"].append(reward_id)
				print("  - Unlocked item: %s" % reward_id)
		"item_upgrade":
			if reward_id not in char_data["unlocked_item_upgrades"]:
				char_data["unlocked_item_upgrades"].append(reward_id)
				print("  - Unlocked item upgrade: %s" % reward_id)
		"skill":
			if reward_id not in char_data["unlocked_skills"]:
				char_data["unlocked_skills"].append(reward_id)
				print("  - Unlocked skill: %s" % reward_id)
		_:
			push_warning("CharacterCollection: Unknown reward type: %s" % reward_type)


# =============================================================================
# EQUIPMENT MANAGEMENT
# =============================================================================

func equip_item(char_id: String, item_id: String) -> bool:
	"""Equip an item to a character."""
	if not _characters.has(char_id):
		return false

	var char_data = _characters[char_id]

	# Check if item is unlocked
	if item_id not in char_data["unlocked_items"]:
		push_warning("CharacterCollection: Item not unlocked: %s" % item_id)
		return false

	# Check if already equipped
	if item_id in char_data["equipped_items"]:
		return true

	char_data["equipped_items"].append(item_id)
	_notify_change()
	return true


func unequip_item(char_id: String, item_id: String) -> bool:
	"""Unequip an item from a character."""
	if not _characters.has(char_id):
		return false

	var char_data = _characters[char_id]

	if item_id in char_data["equipped_items"]:
		char_data["equipped_items"].erase(item_id)
		_notify_change()
		return true

	return false


func unlock_content(char_id: String, content_type: String, content_id: String) -> bool:
	"""Unlock content (item, skill, upgrade) for a character."""
	if not _characters.has(char_id):
		return false

	var char_data = _characters[char_id]

	match content_type:
		"item":
			if content_id not in char_data["unlocked_items"]:
				char_data["unlocked_items"].append(content_id)
		"item_upgrade":
			if content_id not in char_data["unlocked_item_upgrades"]:
				char_data["unlocked_item_upgrades"].append(content_id)
		"skill":
			if content_id not in char_data["unlocked_skills"]:
				char_data["unlocked_skills"].append(content_id)
		_:
			push_error("CharacterCollection: Unknown content type: %s" % content_type)
			return false

	_notify_change()
	return true
