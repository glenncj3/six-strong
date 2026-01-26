class_name RunPool
extends RefCounted
## Composes content pools from drafted legacies' unlocked content.
## Single source of truth for level gating and content picking (DRY principle).
##
## Content from multiple legacies is merged with deduplication.
## Encounters from legacies have weighted selection based on prestige bonuses.
##
## Item types:
## - Items: Regular items that go directly into the pool
## - Item Upgrades: Conditional items that only appear if player owns the base item
##
## Usage:
##   var pool = RunPool.from_legacies(drafted_legacies)
##   var items = pool.pick_random(RunPool.ContentType.ITEM, 3, max_level)
##   var upgrades = pool.get_available_item_upgrades(player_inventory, max_level)

# =============================================================================
# CONTENT TYPE ENUM
# =============================================================================

enum ContentType {
	CHARACTER,
	ITEM,
	ITEM_UPGRADE,
	SKILL,
	ENCOUNTER
}

# =============================================================================
# INTERNAL POOLS
# =============================================================================

# Pools map content_id -> level_requirement
var _character_pool: Dictionary = {}  # { "knight": 1, "paladin": 3 }
var _item_pool: Dictionary = {}  # Regular items: { "item_rusty_sword": 1 }
var _item_upgrade_pool: Dictionary = {}  # { "itemup_flaming_sword": { "level": 4, "upgrades_item": "item_rusty_sword" } }
var _skill_pool: Dictionary = {}

# Encounter pool stores weight and level
var _encounter_pool: Dictionary = {}  # { "knight_tournament": { "weight": 110, "level": 2 } }

# Track which legacies contributed to this pool (for debugging/display)
var _source_legacy_ids: Array[String] = []


# =============================================================================
# FACTORY METHODS
# =============================================================================

static func from_legacies(legacies: Array, game_data = null):
	"""
	Create a RunPool from drafted legacies.

	Args:
		legacies: Array of LegacyData objects
		game_data: Optional GameData reference (defaults to autoload)

	Returns:
		Populated RunPool with content from all legacies (deduplicated)
	"""
	var script = load("res://scripts/managers/run_pool.gd")
	var pool = script.new()
	var gd = game_data if game_data != null else _get_game_data_autoload()

	for legacy in legacies:
		pool._add_legacy_content(legacy, gd)
		pool._source_legacy_ids.append(legacy.id)

	return pool


static func _get_game_data_autoload():
	"""Get GameData autoload (for static context)."""
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("/root/GameData"):
		return tree.root.get_node("/root/GameData")
	return null


# =============================================================================
# CONTENT ADDITION
# =============================================================================

func _add_legacy_content(legacy: LegacyData, game_data) -> void:
	"""Add all unlocked content from a legacy to the pool."""
	if game_data == null:
		push_warning("RunPool: GameData not available")
		return

	# Add unlocked characters with level requirements from master data
	for char_id in legacy.unlocked_characters:
		if _character_pool.has(char_id):
			continue  # Already added from another legacy (deduplication)
		var char_data = game_data.get_character_by_id(char_id)
		var level_req = char_data.get("level_requirement", 1)
		_character_pool[char_id] = level_req

	# Add unlocked items (regular items go directly into pool)
	for item_id in legacy.unlocked_items:
		if _item_pool.has(item_id):
			continue
		var item_data = game_data.get_item_by_id(item_id)
		if item_data.is_empty():
			push_warning("RunPool: Item not found: %s" % item_id)
			continue
		var level_req = item_data.get("level_requirement", 1)
		_item_pool[item_id] = level_req

	# Add unlocked item upgrades (conditional on owning base item)
	for upgrade_id in legacy.unlocked_item_upgrades:
		if _item_upgrade_pool.has(upgrade_id):
			continue
		var upgrade_data = game_data.get_item_upgrade_by_id(upgrade_id)
		if upgrade_data.is_empty():
			push_warning("RunPool: Item upgrade not found: %s" % upgrade_id)
			continue
		var level_req = upgrade_data.get("level_requirement", 1)
		var upgrades_item = upgrade_data.get("upgrades_item", "")
		_item_upgrade_pool[upgrade_id] = {
			"level": level_req,
			"upgrades_item": upgrades_item
		}

	# Add unlocked skills
	for skill_id in legacy.unlocked_skills:
		if _skill_pool.has(skill_id):
			continue
		var skill_data = game_data.get_skill_by_id(skill_id)
		var level_req = skill_data.get("level_requirement", 1)
		_skill_pool[skill_id] = level_req

	# Add unlocked encounters with calculated weight
	for enc_id in legacy.unlocked_encounters:
		var enc_data = game_data.get_encounter_by_id(enc_id) if game_data.has_method("get_encounter_by_id") else {}
		var level_req = enc_data.get("level_requirement", 1) if not enc_data.is_empty() else 1

		if _encounter_pool.has(enc_id):
			# If already added, use the higher weight (from higher prestige legacy)
			var current_weight = _encounter_pool[enc_id].get("weight", 100)
			var new_weight = legacy.get_encounter_weight()
			if new_weight > current_weight:
				_encounter_pool[enc_id]["weight"] = new_weight
		else:
			_encounter_pool[enc_id] = {
				"weight": legacy.get_encounter_weight(),
				"level": level_req
			}


# =============================================================================
# CONTENT PICKING (Single Method - DRY)
# =============================================================================

func pick_random(type: ContentType, count: int, max_level: int = 999) -> Array[String]:
	"""
	Pick random content IDs from the pool, filtered by level.

	Args:
		type: ContentType enum value
		count: Number of items to pick
		max_level: Maximum level requirement to include

	Returns:
		Array of content IDs (may be fewer than count if pool is small)
	"""
	var pool = _get_pool_for_type(type)
	var available: Array[String] = []

	for id in pool:
		var level_req = pool[id].get("level", 1) if pool[id] is Dictionary else int(pool[id])
		if level_req <= max_level:
			available.append(id)

	available.shuffle()
	var result_count = min(count, available.size())

	var result: Array[String] = []
	for i in range(result_count):
		result.append(available[i])

	return result


func get_available_item_upgrades(player_inventory, max_level: int = 999) -> Array[String]:
	"""
	Get item upgrades that are available based on player's current inventory.

	Item upgrades only appear if the player owns the base item they upgrade.

	Args:
		player_inventory: PlayerInventory instance with player's current items
		max_level: Maximum level requirement to include

	Returns:
		Array of item upgrade IDs that the player can currently acquire
	"""
	var available: Array[String] = []

	if player_inventory == null:
		return available

	for upgrade_id in _item_upgrade_pool:
		var upgrade_data = _item_upgrade_pool[upgrade_id]
		var level_req = upgrade_data.get("level", 1)
		var base_item_id = upgrade_data.get("upgrades_item", "")

		# Check level requirement
		if level_req > max_level:
			continue

		# Check if player owns the base item
		if base_item_id.is_empty():
			continue

		if player_inventory.has_item(base_item_id):
			available.append(upgrade_id)

	return available


func pick_random_item_upgrades(player_inventory, count: int, max_level: int = 999) -> Array[String]:
	"""
	Pick random item upgrades that are available based on player's inventory.

	Args:
		player_inventory: PlayerInventory instance
		count: Number of upgrades to pick
		max_level: Maximum level requirement

	Returns:
		Array of item upgrade IDs (may be fewer than count)
	"""
	var available = get_available_item_upgrades(player_inventory, max_level)
	available.shuffle()

	var result: Array[String] = []
	var result_count = min(count, available.size())
	for i in range(result_count):
		result.append(available[i])

	return result


func pick_weighted_encounters(count: int, max_level: int = 999) -> Array[String]:
	"""
	Pick encounters using weighted selection.

	Args:
		count: Number of encounters to pick
		max_level: Maximum level requirement to include

	Returns:
		Array of encounter IDs (weighted selection, no duplicates)
	"""
	var available: Array[String] = []
	var weights: Array[int] = []

	for enc_id in _encounter_pool:
		var data = _encounter_pool[enc_id]
		if data.get("level", 1) <= max_level:
			available.append(enc_id)
			weights.append(data.get("weight", 100))

	return _weighted_sample(available, weights, count)


func _weighted_sample(items: Array[String], weights: Array[int], count: int) -> Array[String]:
	"""
	Sample items without replacement using weights.

	Higher weight = higher probability of selection.
	"""
	if items.is_empty() or count <= 0:
		return []

	var result: Array[String] = []
	var remaining_items = items.duplicate()
	var remaining_weights = weights.duplicate()

	for i in range(min(count, items.size())):
		var total_weight = 0
		for w in remaining_weights:
			total_weight += w

		if total_weight <= 0:
			break

		var roll = randi() % total_weight
		var cumulative = 0

		for j in range(remaining_items.size()):
			cumulative += remaining_weights[j]
			if roll < cumulative:
				result.append(remaining_items[j])
				remaining_items.remove_at(j)
				remaining_weights.remove_at(j)
				break

	return result


func _get_pool_for_type(type: ContentType) -> Dictionary:
	"""Get the internal pool dictionary for a content type."""
	match type:
		ContentType.CHARACTER:
			return _character_pool
		ContentType.ITEM:
			return _item_pool
		ContentType.ITEM_UPGRADE:
			return _item_upgrade_pool
		ContentType.SKILL:
			return _skill_pool
		ContentType.ENCOUNTER:
			return _encounter_pool
	return {}


# =============================================================================
# QUERIES
# =============================================================================

func has_content(type: ContentType, id: String) -> bool:
	"""Check if a content ID is in the pool."""
	return _get_pool_for_type(type).has(id)


func get_all(type: ContentType, max_level: int = 999) -> Array[String]:
	"""Get all content IDs of a type, filtered by level."""
	var pool = _get_pool_for_type(type)
	var result: Array[String] = []

	for id in pool:
		var level_req = pool[id].get("level", 1) if pool[id] is Dictionary else int(pool[id])
		if level_req <= max_level:
			result.append(id)

	return result


func get_upgrade_base_item(upgrade_id: String) -> String:
	"""Get the base item ID that an upgrade replaces."""
	if _item_upgrade_pool.has(upgrade_id):
		return _item_upgrade_pool[upgrade_id].get("upgrades_item", "")
	return ""


func get_encounter_weight(enc_id: String) -> int:
	"""Get the weight for a specific encounter."""
	if _encounter_pool.has(enc_id):
		return _encounter_pool[enc_id].get("weight", 100)
	return 100  # Default base weight


func get_pool_size(type: ContentType) -> int:
	"""Get the total size of a content pool."""
	return _get_pool_for_type(type).size()


func get_source_legacy_ids() -> Array[String]:
	"""Get the IDs of legacies that contributed to this pool."""
	return _source_legacy_ids


# =============================================================================
# MANUAL CONTENT ADDITION (for testing or special cases)
# =============================================================================

func add_character(char_id: String, level_requirement: int = 1) -> void:
	"""Manually add a character to the pool."""
	_character_pool[char_id] = level_requirement


func add_item(item_id: String, level_requirement: int = 1) -> void:
	"""Manually add a regular item to the pool."""
	_item_pool[item_id] = level_requirement


func add_item_upgrade(upgrade_id: String, upgrades_item: String, level_requirement: int = 1) -> void:
	"""Manually add an item upgrade to the pool."""
	_item_upgrade_pool[upgrade_id] = {
		"level": level_requirement,
		"upgrades_item": upgrades_item
	}


func add_skill(skill_id: String, level_requirement: int = 1) -> void:
	"""Manually add a skill to the pool."""
	_skill_pool[skill_id] = level_requirement


func add_encounter(enc_id: String, weight: int = 100, level_requirement: int = 1) -> void:
	"""Manually add an encounter to the pool."""
	_encounter_pool[enc_id] = {"weight": weight, "level": level_requirement}


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize pool for saving."""
	return {
		"character_pool": _character_pool.duplicate(),
		"item_pool": _item_pool.duplicate(),
		"item_upgrade_pool": _item_upgrade_pool.duplicate(),
		"skill_pool": _skill_pool.duplicate(),
		"encounter_pool": _encounter_pool.duplicate(),
		"source_legacy_ids": Array(_source_legacy_ids)
	}


static func from_dict(data: Dictionary):
	"""Deserialize pool from saved data."""
	var script = load("res://scripts/managers/run_pool.gd")
	var pool = script.new()

	pool._character_pool = data.get("character_pool", {}).duplicate()
	pool._item_pool = data.get("item_pool", {}).duplicate()
	pool._item_upgrade_pool = data.get("item_upgrade_pool", {}).duplicate()
	pool._skill_pool = data.get("skill_pool", {}).duplicate()
	pool._encounter_pool = data.get("encounter_pool", {}).duplicate()

	var source_ids = data.get("source_legacy_ids", [])
	for id in source_ids:
		pool._source_legacy_ids.append(id)

	return pool
