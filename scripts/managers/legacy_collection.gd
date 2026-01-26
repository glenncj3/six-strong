class_name LegacyCollection
extends RefCounted
# LegacyCollection - Manages player's legacy collection at the account level
# Loads from JSON master data + account save data, handles persistence
# Follows Single Responsibility Principle - only manages legacy account state

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when a legacy is unlocked
signal legacy_unlocked(legacy_id: String)
## Emitted when a legacy gains prestige
signal legacy_prestige_up(legacy_id: String, new_prestige: int, unlocked_content: Dictionary)
## Emitted when a legacy's fame changes
signal legacy_fame_changed(legacy_id: String, new_fame: int)
## Emitted when a legacy's starting character selection changes
signal starting_character_changed(legacy_id: String, character_id: String)
## Emitted when a legacy's starting item selection changes
signal starting_item_changed(legacy_id: String, item_id: String)


# =============================================================================
# INTERNAL STATE
# =============================================================================

# Legacies stored as Dictionary for O(1) lookup: id -> LegacyData
var _legacies: Dictionary = {}

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
# INITIALIZATION
# =============================================================================

func initialize(master_data: Array, account_data: Array = []) -> void:
	"""
	Initialize collection from master data and optional account state.

	Args:
		master_data: Array of legacy definitions from legacies.json
		account_data: Optional array of account state from save file
	"""
	_legacies.clear()

	# Build account data lookup for quick access
	var account_lookup: Dictionary = {}
	for legacy_account in account_data:
		var legacy_id = legacy_account.get("id", "")
		if legacy_id:
			account_lookup[legacy_id] = legacy_account

	# Create LegacyData for each master definition
	for master in master_data:
		var legacy_id = master.get("id", "")
		if legacy_id.is_empty():
			continue

		var account = account_lookup.get(legacy_id, {})
		var legacy = LegacyData.from_dict(master, account)

		# Connect prestige tracker signals
		_connect_legacy_signals(legacy)

		_legacies[legacy_id] = legacy


func _connect_legacy_signals(legacy: LegacyData) -> void:
	"""Connect signals from legacy's prestige tracker."""
	var legacy_id = legacy.id

	legacy.prestige_tracker.fame_changed.connect(
		func(new_fame: int): _on_legacy_fame_changed(legacy_id, new_fame)
	)
	legacy.prestige_tracker.prestige_up.connect(
		func(new_prestige: int): _on_legacy_prestige_up_internal(legacy_id, new_prestige)
	)


func _on_legacy_fame_changed(legacy_id: String, new_fame: int) -> void:
	"""Handle fame change from prestige tracker."""
	legacy_fame_changed.emit(legacy_id, new_fame)
	_notify_change()


func _on_legacy_prestige_up_internal(legacy_id: String, new_prestige: int) -> void:
	"""Handle prestige up from prestige tracker (signal forwarding only)."""
	# Note: The actual unlocks are handled in add_legacy_fame()
	# This signal is for the raw prestige tracker event
	pass


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_array() -> Array:
	"""Serialize all legacy account states for saving."""
	var result = []
	for legacy_id in _legacies:
		var legacy: LegacyData = _legacies[legacy_id]
		result.append(legacy.to_account_dict())
	return result


static func from_array(master_data: Array, account_data: Array) -> LegacyCollection:
	"""Create LegacyCollection from master data and account save."""
	var collection = LegacyCollection.new()
	collection.initialize(master_data, account_data)
	return collection


# =============================================================================
# LEGACY QUERIES
# =============================================================================

func get_legacy(legacy_id: String) -> LegacyData:
	"""Get a legacy by ID. Returns null if not found."""
	return _legacies.get(legacy_id, null)


func get_all_legacies() -> Array[LegacyData]:
	"""Get all legacies as an array."""
	var result: Array[LegacyData] = []
	for legacy in _legacies.values():
		result.append(legacy)
	return result


func get_unlocked_legacies() -> Array[LegacyData]:
	"""Get all unlocked legacies."""
	var result: Array[LegacyData] = []
	for legacy in _legacies.values():
		if legacy.unlocked:
			result.append(legacy)
	return result


func get_unlocked_legacy_ids() -> Array[String]:
	"""Get IDs of all unlocked legacies."""
	var result: Array[String] = []
	for legacy_id in _legacies:
		var legacy: LegacyData = _legacies[legacy_id]
		if legacy.unlocked:
			result.append(legacy_id)
	return result


func is_legacy_unlocked(legacy_id: String) -> bool:
	"""Check if a legacy is unlocked."""
	var legacy = get_legacy(legacy_id)
	return legacy != null and legacy.unlocked


func get_legacy_count() -> int:
	"""Get total number of legacies."""
	return _legacies.size()


func get_unlocked_count() -> int:
	"""Get number of unlocked legacies."""
	return get_unlocked_legacies().size()


# =============================================================================
# LEGACY MANAGEMENT
# =============================================================================

func unlock_legacy(legacy_id: String) -> bool:
	"""
	Unlock a legacy (call after spending gems).

	Returns:
		true if legacy was unlocked, false if already owned or invalid
	"""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		push_warning("LegacyCollection: Legacy not found: %s" % legacy_id)
		return false

	if legacy.unlocked:
		push_warning("LegacyCollection: Legacy already unlocked: %s" % legacy_id)
		return false

	legacy.unlock()
	legacy_unlocked.emit(legacy_id)
	_notify_change()
	return true


# =============================================================================
# FAME AND PRESTIGE
# =============================================================================

func add_legacy_fame(legacy_id: String, fame: int) -> Dictionary:
	"""
	Add fame to a legacy, potentially increasing prestige.

	Args:
		legacy_id: ID of legacy to add fame to
		fame: Amount of fame to add

	Returns:
		Dictionary with prestige info and unlocked content
	"""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		push_warning("LegacyCollection: Legacy not found: %s" % legacy_id)
		return {"prestige_increased": false}

	if not legacy.unlocked:
		push_warning("LegacyCollection: Cannot add fame to locked legacy: %s" % legacy_id)
		return {"prestige_increased": false}

	var result = legacy.add_fame(fame)

	if result.prestige_increased:
		legacy_prestige_up.emit(legacy_id, result.new_prestige, result.get("unlocked_content", {}))

	_notify_change()
	return result


func get_legacy_prestige(legacy_id: String) -> int:
	"""Get prestige level for a legacy."""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return 0
	return legacy.get_prestige()


func get_legacy_fame(legacy_id: String) -> int:
	"""Get current fame for a legacy."""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return 0
	return legacy.get_fame()


# =============================================================================
# STARTING SELECTION MANAGEMENT
# =============================================================================

func select_starting_character(legacy_id: String, character_id: String) -> bool:
	"""
	Select a starting character for a legacy.

	Returns:
		true if selection successful
	"""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return false

	if legacy.select_starting_character(character_id):
		starting_character_changed.emit(legacy_id, character_id)
		_notify_change()
		return true
	return false


func select_starting_item(legacy_id: String, item_id: String) -> bool:
	"""
	Select a starting item for a legacy.

	Returns:
		true if selection successful
	"""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return false

	if legacy.select_starting_item(item_id):
		starting_item_changed.emit(legacy_id, item_id)
		_notify_change()
		return true
	return false


func get_starting_character(legacy_id: String) -> String:
	"""Get selected starting character for a legacy."""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return ""
	return legacy.selected_starting_character_id


func get_starting_item(legacy_id: String) -> String:
	"""Get selected starting item for a legacy."""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return ""
	return legacy.selected_starting_item_id


# =============================================================================
# CONTENT QUERIES
# =============================================================================

func get_unlocked_characters(legacy_id: String) -> Array[String]:
	"""Get unlocked characters for a legacy."""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return []
	return legacy.unlocked_characters


func get_unlocked_items(legacy_id: String) -> Array[String]:
	"""Get unlocked items for a legacy."""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return []
	return legacy.unlocked_items


func get_unlocked_skills(legacy_id: String) -> Array[String]:
	"""Get unlocked skills for a legacy."""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return []
	return legacy.unlocked_skills


func get_unlocked_encounters(legacy_id: String) -> Array[String]:
	"""Get unlocked encounters for a legacy."""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return []
	return legacy.unlocked_encounters


func get_encounter_weight(legacy_id: String) -> int:
	"""Get encounter weight for a legacy (100 + bonuses)."""
	var legacy = get_legacy(legacy_id)
	if legacy == null:
		return 100
	return legacy.get_encounter_weight()
