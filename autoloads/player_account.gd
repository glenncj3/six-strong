extends Node
# PlayerAccount Singleton
# Facade for player progression - delegates to focused manager classes
# Maintains backwards compatibility with existing API
# Phase 0: Added Legacy system support with clean slate detection

# =============================================================================
# SIGNALS
# =============================================================================

# Re-expose signals from managers for backwards compatibility
signal gems_changed(new_amount: int)
signal reroll_tokens_changed(new_amount: int)
signal character_unlocked(char_id: String)
signal character_prestige_up(char_id: String, new_prestige: int)

# Legacy system signals (Phase 0)
signal legacy_unlocked(legacy_id: String)
signal legacy_prestige_up(legacy_id: String, new_prestige: int, unlocked_content: Dictionary)
signal legacy_fame_changed(legacy_id: String, new_fame: int)


# =============================================================================
# CONSTANTS
# =============================================================================

# Save file path
const SAVE_PATH = "user://player_account.json"

# Save format version for clean slate detection
# Version 1: Old character-centric format
# Version 2: New legacy-centric format (Phase 0+)
const SAVE_FORMAT_VERSION = 2

# Default starting legacies to unlock
const STARTING_LEGACY_IDS = ["legacy_knight_order", "legacy_shadow_guild"]


# =============================================================================
# MANAGERS
# =============================================================================

# Focused managers (Single Responsibility Principle)
var _currency: CurrencyManager
var _collection: CharacterCollection
var _legacy_collection: LegacyCollection  # Phase 0: Legacy system

# Player ID
var _player_id: String = ""


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	load_account()


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_account() -> void:
	"""Save player account to local JSON file."""
	var save_data = {
		"format_version": SAVE_FORMAT_VERSION,
		"player_id": _player_id,
		"currencies": _currency.to_dict(),
		"characters": _collection.to_array(),
		"unlocked_character_ids": _collection.get_unlocked_character_ids(),
		"legacies": _legacy_collection.to_array()  # Phase 0: Legacy data
	}

	JsonPersistence.save_json(SAVE_PATH, save_data)


func load_account() -> void:
	"""Load player account from local JSON file."""
	if not JsonPersistence.file_exists(SAVE_PATH):
		_create_default_account()
		return

	var data = JsonPersistence.load_json(SAVE_PATH)
	if data == null:
		_create_default_account()
		return

	# Clean slate detection: Check if this is a valid new-format save
	if not _is_valid_save_format(data):
		print("PlayerAccount: Old or invalid save format detected. Creating fresh account.")
		_create_default_account()
		return

	_load_from_data(data)


func _is_valid_save_format(data: Dictionary) -> bool:
	"""
	Check if save data is in the new legacy-centric format.
	Returns false for old character-centric saves (triggers clean slate).
	"""
	# Must have format_version field
	if not data.has("format_version"):
		return false

	var version = data.get("format_version", 0)

	# Must be at least version 2 (legacy system)
	if version < 2:
		return false

	# Must have legacies array
	if not data.has("legacies"):
		return false

	return true


func _load_from_data(data: Dictionary) -> void:
	"""Initialize managers from loaded data."""
	_player_id = data.get("player_id", "")

	# Load currencies (support old and new format)
	if data.has("currencies"):
		_currency = CurrencyManager.from_dict(data["currencies"])
	else:
		_currency = CurrencyManager.new(GameConstants.STARTING_GEMS, GameConstants.STARTING_REROLL_TOKENS)

	# Load character collection (for backwards compatibility during transition)
	_collection = CharacterCollection.from_dict(data)

	# Load legacy collection (Phase 0)
	_load_legacy_collection(data.get("legacies", []))

	# Wire up managers
	_setup_manager_connections()


func _load_legacy_collection(account_data: Array) -> void:
	"""Initialize legacy collection from master data and account state."""
	var master_data = GameData.get_all_legacies()
	_legacy_collection = LegacyCollection.from_array(master_data, account_data)


func _create_default_account() -> void:
	"""Create a new player account with starting content unlocked."""

	_player_id = "player_%d" % Time.get_unix_time_from_system()

	# Create managers with defaults
	_currency = CurrencyManager.new(GameConstants.STARTING_GEMS, GameConstants.STARTING_REROLL_TOKENS)
	_collection = CharacterCollection.new()

	# Initialize legacy collection with master data (Phase 0)
	var master_data = GameData.get_all_legacies()
	_legacy_collection = LegacyCollection.new()
	_legacy_collection.initialize(master_data, [])

	# Wire up managers
	_setup_manager_connections()

	# Unlock starting characters (for backwards compatibility during transition)
	var starting_chars = ["char_warrior_001", "char_mage_001", "char_rogue_001", "char_cleric_001", "char_ranger_001"]
	for char_id in starting_chars:
		_collection.unlock_character(char_id)

	# Unlock starting legacies (Phase 0)
	for legacy_id in STARTING_LEGACY_IDS:
		_legacy_collection.unlock_legacy(legacy_id)

	save_account()


func _setup_manager_connections() -> void:
	"""Connect manager signals and callbacks."""
	# Set save callbacks
	_currency.set_change_callback(save_account)
	_collection.set_change_callback(save_account)
	_legacy_collection.set_change_callback(save_account)

	# Forward currency signals
	_safe_connect(_currency.gems_changed, _on_gems_changed)
	_safe_connect(_currency.reroll_tokens_changed, _on_reroll_tokens_changed)

	# Forward character collection signals
	_safe_connect(_collection.character_unlocked, _on_character_unlocked)
	_safe_connect(_collection.character_prestige_up, _on_character_prestige_up)

	# Forward legacy collection signals (Phase 0)
	_safe_connect(_legacy_collection.legacy_unlocked, _on_legacy_unlocked)
	_safe_connect(_legacy_collection.legacy_prestige_up, _on_legacy_prestige_up)
	_safe_connect(_legacy_collection.legacy_fame_changed, _on_legacy_fame_changed)


func _safe_connect(sig: Signal, handler: Callable) -> void:
	"""Connect a signal only if not already connected (DRY helper)."""
	if not sig.is_connected(handler):
		sig.connect(handler)


# Signal forwarding handlers
func _on_gems_changed(amount: int) -> void:
	gems_changed.emit(amount)

func _on_reroll_tokens_changed(amount: int) -> void:
	reroll_tokens_changed.emit(amount)

func _on_character_unlocked(char_id: String) -> void:
	character_unlocked.emit(char_id)

func _on_character_prestige_up(char_id: String, new_prestige: int) -> void:
	character_prestige_up.emit(char_id, new_prestige)

func _on_legacy_unlocked(legacy_id: String) -> void:
	legacy_unlocked.emit(legacy_id)

func _on_legacy_prestige_up(legacy_id: String, new_prestige: int, unlocked_content: Dictionary) -> void:
	legacy_prestige_up.emit(legacy_id, new_prestige, unlocked_content)

func _on_legacy_fame_changed(legacy_id: String, new_fame: int) -> void:
	legacy_fame_changed.emit(legacy_id, new_fame)


# =============================================================================
# CURRENCY API (Delegated to CurrencyManager)
# =============================================================================

func get_gems() -> int:
	return _currency.get_gems()


func get_reroll_tokens() -> int:
	return _currency.get_reroll_tokens()


func add_gems(amount: int) -> void:
	_currency.add_gems(amount)


func spend_gems(amount: int) -> bool:
	return _currency.spend_gems(amount)


func add_reroll_token() -> void:
	_currency.add_reroll_token()


func spend_reroll_token() -> bool:
	return _currency.spend_reroll_token()


# =============================================================================
# CHARACTER COLLECTION API (Delegated to CharacterCollection)
# =============================================================================

func get_unlocked_characters() -> Array:
	return _collection.get_unlocked_characters()


func get_character_data(char_id: String) -> Dictionary:
	return _collection.get_character_data(char_id)


func is_character_unlocked(char_id: String) -> bool:
	return _collection.is_character_unlocked(char_id)


func unlock_character(char_id: String, cost: int) -> bool:
	"""Unlock a character by spending gems."""
	if is_character_unlocked(char_id):
		push_warning("PlayerAccount: Character already unlocked: %s" % char_id)
		return false

	if not _currency.spend_gems(cost):
		push_warning("PlayerAccount: Not enough gems to unlock character")
		return false

	return _collection.unlock_character(char_id)


# =============================================================================
# EQUIPMENT API (Delegated to CharacterCollection)
# =============================================================================

func equip_item(char_id: String, item_id: String) -> bool:
	return _collection.equip_item(char_id, item_id)


func unequip_item(char_id: String, item_id: String) -> bool:
	return _collection.unequip_item(char_id, item_id)


# =============================================================================
# PROGRESSION API (Delegated to CharacterCollection)
# =============================================================================

func add_character_fame(char_id: String, fame: int) -> void:
	_collection.add_character_fame(char_id, fame)


func unlock_content_for_character(char_id: String, content_type: String, content_id: String, cost: int) -> bool:
	"""Unlock content for a character by spending gems."""
	if not _currency.spend_gems(cost):
		return false

	return _collection.unlock_content(char_id, content_type, content_id)


# =============================================================================
# LEGACY COLLECTION API (Phase 0)
# =============================================================================

func get_legacy_data(legacy_id: String) -> LegacyData:
	"""Get a legacy's data by ID."""
	return _legacy_collection.get_legacy(legacy_id)


func get_all_legacies() -> Array[LegacyData]:
	"""Get all legacies."""
	return _legacy_collection.get_all_legacies()


func get_unlocked_legacies() -> Array[LegacyData]:
	"""Get all unlocked legacies."""
	return _legacy_collection.get_unlocked_legacies()


func get_unlocked_legacy_ids() -> Array[String]:
	"""Get IDs of all unlocked legacies."""
	return _legacy_collection.get_unlocked_legacy_ids()


func is_legacy_unlocked(legacy_id: String) -> bool:
	"""Check if a legacy is unlocked."""
	return _legacy_collection.is_legacy_unlocked(legacy_id)


func unlock_legacy(legacy_id: String, cost: int) -> bool:
	"""Unlock a legacy by spending gems."""
	if is_legacy_unlocked(legacy_id):
		push_warning("PlayerAccount: Legacy already unlocked: %s" % legacy_id)
		return false

	if not _currency.spend_gems(cost):
		push_warning("PlayerAccount: Not enough gems to unlock legacy")
		return false

	return _legacy_collection.unlock_legacy(legacy_id)


func award_legacy_fame(legacy_id: String, fame: int) -> Dictionary:
	"""
	Award fame to a legacy (typically at end of run).

	Returns:
		Dictionary with prestige info and any unlocked content
	"""
	return _legacy_collection.add_legacy_fame(legacy_id, fame)


func get_legacy_prestige(legacy_id: String) -> int:
	"""Get prestige level for a legacy."""
	return _legacy_collection.get_legacy_prestige(legacy_id)


func get_legacy_fame(legacy_id: String) -> int:
	"""Get current fame for a legacy."""
	return _legacy_collection.get_legacy_fame(legacy_id)


func select_legacy_starting_character(legacy_id: String, character_id: String) -> bool:
	"""Select a starting character for a legacy."""
	return _legacy_collection.select_starting_character(legacy_id, character_id)


func select_legacy_starting_item(legacy_id: String, item_id: String) -> bool:
	"""Select a starting item for a legacy."""
	return _legacy_collection.select_starting_item(legacy_id, item_id)


func get_legacy_starting_character(legacy_id: String) -> String:
	"""Get selected starting character for a legacy."""
	return _legacy_collection.get_starting_character(legacy_id)


func get_legacy_starting_item(legacy_id: String) -> String:
	"""Get selected starting item for a legacy."""
	return _legacy_collection.get_starting_item(legacy_id)


# =============================================================================
# DIRECT MANAGER ACCESS (for advanced use cases)
# =============================================================================

func get_currency_manager() -> CurrencyManager:
	"""Get direct access to currency manager."""
	return _currency


func get_character_collection() -> CharacterCollection:
	"""Get direct access to character collection."""
	return _collection


func get_legacy_collection() -> LegacyCollection:
	"""Get direct access to legacy collection (Phase 0)."""
	return _legacy_collection
