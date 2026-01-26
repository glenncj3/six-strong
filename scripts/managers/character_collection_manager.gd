class_name CharacterCollection
extends RefCounted
# CharacterCollection - DEPRECATED (Phase 1)
# This class is retained as a minimal stub for backwards compatibility.
# All prestige/fame tracking has moved to LegacyCollection.
# Characters are now run-time acquisitions, not meta-progression anchors.
#
# TODO (Phase 4+): Remove this class entirely once draft system uses legacies.

signal character_unlocked(char_id: String)

# Minimal storage for backwards compatibility
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
# SERIALIZATION (Minimal for backwards compatibility)
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize collection data for saving."""
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

	if data.has("characters"):
		for char_data in data["characters"]:
			if char_data.has("id"):
				collection._characters[char_data["id"]] = char_data

	return collection


func to_array() -> Array:
	"""Get all characters as an array (for compatibility)."""
	return _characters.values()


# =============================================================================
# CHARACTER QUERIES (Minimal stubs)
# =============================================================================

func get_character_data(char_id: String) -> Dictionary:
	"""Get player's data for a specific character."""
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
# CHARACTER MANAGEMENT (Minimal for backwards compatibility)
# =============================================================================

func unlock_character(char_id: String) -> bool:
	"""
	Unlock a new character.
	DEPRECATED: Characters are now acquired during runs, not unlocked in account.
	This is kept for backwards compatibility during transition.
	"""
	if is_character_unlocked(char_id):
		return false

	var char_data = _create_character_data(char_id)
	if char_data.is_empty():
		return false

	_characters[char_id] = char_data
	character_unlocked.emit(char_id)
	_notify_change()
	return true


func _create_character_data(char_id: String) -> Dictionary:
	"""Create minimal character data entry."""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("CharacterCollection: Master data not found: %s" % char_id)
		return {}

	# Minimal data - no prestige, no items, no skills
	return {
		"id": char_id,
		"unlocked": true
	}


# =============================================================================
# DEPRECATED METHODS (No-ops for backwards compatibility)
# =============================================================================

func add_character_fame(_char_id: String, _fame: int) -> void:
	"""DEPRECATED: Fame is now awarded to Legacies, not characters."""
	push_warning("CharacterCollection.add_character_fame is deprecated. Use LegacyCollection.add_legacy_fame instead.")


func equip_item(_char_id: String, _item_id: String) -> bool:
	"""DEPRECATED: Items are now in player inventory, not on characters."""
	push_warning("CharacterCollection.equip_item is deprecated. Items belong to player inventory now.")
	return false


func unequip_item(_char_id: String, _item_id: String) -> bool:
	"""DEPRECATED: Items are now in player inventory, not on characters."""
	push_warning("CharacterCollection.unequip_item is deprecated. Items belong to player inventory now.")
	return false


func unlock_content(_char_id: String, _content_type: String, _content_id: String) -> bool:
	"""DEPRECATED: Content unlocks are now on Legacies, not characters."""
	push_warning("CharacterCollection.unlock_content is deprecated. Use LegacyCollection instead.")
	return false
