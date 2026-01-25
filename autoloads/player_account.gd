extends Node
# PlayerAccount Singleton
# Facade for player progression - delegates to focused manager classes
# Maintains backwards compatibility with existing API

# Re-expose signals from managers for backwards compatibility
signal gems_changed(new_amount: int)
signal reroll_tokens_changed(new_amount: int)
signal character_unlocked(char_id: String)
signal character_prestige_up(char_id: String, new_prestige: int)

# Save file path
const SAVE_PATH = "user://player_account.json"

# Focused managers (Single Responsibility Principle)
var _currency: CurrencyManager
var _collection: CharacterCollection

# Player ID
var _player_id: String = ""


func _ready() -> void:
	load_account()


# =============================================================================
# PERSISTENCE
# =============================================================================

func save_account() -> void:
	"""Save player account to local JSON file."""
	var save_data = {
		"player_id": _player_id,
		"currencies": _currency.to_dict(),
		"characters": _collection.to_array(),
		"unlocked_character_ids": _collection.get_unlocked_character_ids()
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

	_load_from_data(data)


func _load_from_data(data: Dictionary) -> void:
	"""Initialize managers from loaded data."""
	_player_id = data.get("player_id", "")

	# Load currencies (support old and new format)
	if data.has("currencies"):
		_currency = CurrencyManager.from_dict(data["currencies"])
	else:
		_currency = CurrencyManager.new(GameConstants.STARTING_GEMS, GameConstants.STARTING_REROLL_TOKENS)

	# Load collection
	_collection = CharacterCollection.from_dict(data)

	# Wire up managers
	_setup_manager_connections()


func _create_default_account() -> void:
	"""Create a new player account with starting characters unlocked."""

	_player_id = "player_%d" % Time.get_unix_time_from_system()

	# Create managers with defaults
	_currency = CurrencyManager.new(GameConstants.STARTING_GEMS, GameConstants.STARTING_REROLL_TOKENS)
	_collection = CharacterCollection.new()

	# Wire up managers
	_setup_manager_connections()

	# Unlock 5 starting characters
	var starting_chars = ["char_warrior_001", "char_mage_001", "char_rogue_001", "char_cleric_001", "char_ranger_001"]
	for char_id in starting_chars:
		_collection.unlock_character(char_id)

	save_account()


func _setup_manager_connections() -> void:
	"""Connect manager signals and callbacks."""
	# Set save callbacks
	_currency.set_change_callback(save_account)
	_collection.set_change_callback(save_account)

	# Forward signals using safe connect helper
	_safe_connect(_currency.gems_changed, _on_gems_changed)
	_safe_connect(_currency.reroll_tokens_changed, _on_reroll_tokens_changed)
	_safe_connect(_collection.character_unlocked, _on_character_unlocked)
	_safe_connect(_collection.character_prestige_up, _on_character_prestige_up)


func _safe_connect(sig: Signal, handler: Callable) -> void:
	"""Connect a signal only if not already connected (DRY helper)."""
	if not sig.is_connected(handler):
		sig.connect(handler)


func _on_gems_changed(amount: int) -> void:
	gems_changed.emit(amount)

func _on_reroll_tokens_changed(amount: int) -> void:
	reroll_tokens_changed.emit(amount)

func _on_character_unlocked(char_id: String) -> void:
	character_unlocked.emit(char_id)

func _on_character_prestige_up(char_id: String, new_prestige: int) -> void:
	character_prestige_up.emit(char_id, new_prestige)


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
# DIRECT MANAGER ACCESS (for advanced use cases)
# =============================================================================

func get_currency_manager() -> CurrencyManager:
	"""Get direct access to currency manager."""
	return _currency


func get_character_collection() -> CharacterCollection:
	"""Get direct access to character collection."""
	return _collection
