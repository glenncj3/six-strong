extends Node
# EncounterFactory Singleton
# Generates random encounter options from JSON configuration
#
# Phase 2 Refactor:
# - Item availability now checks player inventory (not character equipment)
# - Skills are instant effects (no character tracking)
#
# Phase 6 Refactor:
# - Integrates with RunPool for content filtering (DRY)
# - Delegates all content picking to RunPool.pick_random()
# - Supports base encounters (always available) + legacy encounters (from run pool)
# - Encounter weighting: base = 100 (from JSON), legacy = 100 + prestige bonuses

const RunPoolScript = preload("res://scripts/managers/run_pool.gd")

signal encounter_generated(encounter_type: String)

var _encounter_types: Array = []
var _run_pool = null  # RunPool instance for filtering content

# Mapping from string constant names to their values (GDScript const members aren't reflectable)
var _constant_map: Dictionary = {
	"XP_REWARD_MIN": GameConstants.XP_REWARD_MIN,
	"XP_REWARD_MAX": GameConstants.XP_REWARD_MAX,
	"GOLD_REWARD_MIN": GameConstants.GOLD_REWARD_MIN,
	"GOLD_REWARD_MAX": GameConstants.GOLD_REWARD_MAX,
	"HEALTH_RESTORE_PERCENTAGE": GameConstants.HEALTH_RESTORE_PERCENTAGE,
	"SHOP_MIN_ITEMS": GameConstants.SHOP_MIN_ITEMS,
	"SHOP_MAX_ITEMS": GameConstants.SHOP_MAX_ITEMS,
	"SHOP_MIN_SKILLS": GameConstants.SHOP_MIN_SKILLS,
	"SHOP_MAX_SKILLS": GameConstants.SHOP_MAX_SKILLS,
}

var _generators: Dictionary = {}

# Cache for filtered pools (invalidated when round/team changes)
var _cache_round: int = -1
var _cache_max_level: int = 0
var _cached_items: Array = []  # Regular items from pool
var _cached_item_upgrades: Array = []  # Item upgrades available based on player inventory
var _cached_skills: Array = []
var _cached_characters: Array = []


func _ready() -> void:
	_generators = {
		"random_range": _gen_random_range,
		"constant": _gen_constant,
		"pick_items": _gen_pick_items,
		"pick_skills": _gen_pick_skills,
		"pick_learnable_skill": _gen_pick_learnable_skill,
		"pick_learnable_skills": _gen_pick_learnable_skills,
		"pick_shop_offerings": _gen_pick_shop_offerings,
		"pick_mystery_elements": _gen_pick_mystery_elements,
		"pick_characters": _gen_pick_characters,
	}

	# Use GameData's cached encounter types (single source of truth)
	_encounter_types = GameData.get_encounter_types()


# =============================================================================
# RUN POOL INTEGRATION (Phase 6)
# =============================================================================

func set_run_pool(pool) -> void:
	"""
	Set the RunPool for content filtering.
	Called by RunManager when a run starts with legacies.

	Args:
		pool: RunPool instance from drafted legacies
	"""
	_run_pool = pool
	# Invalidate cache when pool changes
	_cache_round = -1


func clear_run_pool() -> void:
	"""Clear the RunPool (called when run ends)."""
	_run_pool = null
	_cache_round = -1


func has_run_pool() -> bool:
	"""Check if a RunPool is set."""
	return _run_pool != null


func generate_encounter_options(count: int) -> Array:
	var options = []
	var used_types = []

	for i in range(count):
		var encounter_type = _select_weighted_encounter_type(used_types)
		used_types.append(encounter_type)

		var type_def = _get_type_def(encounter_type)
		var encounter_data = _create_encounter_data(type_def)
		options.append(encounter_data)

		encounter_generated.emit(encounter_type)

	return options


func get_type_def(type_name: String) -> Dictionary:
	return _get_type_def(type_name)


func get_all_type_defs() -> Array:
	return _encounter_types


func _select_weighted_encounter_type(excluded_types: Array) -> String:
	var available_types = []
	var available_weights = []

	for type_def in _encounter_types:
		var type_name = type_def["type"]
		if type_name not in excluded_types:
			available_types.append(type_name)
			available_weights.append(type_def.get("weight", 1.0))

	if available_types.is_empty():
		for type_def in _encounter_types:
			available_types.append(type_def["type"])
			available_weights.append(type_def.get("weight", 1.0))

	return _weighted_random_select(available_types, available_weights)


func _weighted_random_select(items: Array, weights: Array) -> Variant:
	var total_weight = 0.0
	for w in weights:
		total_weight += w

	var random_value = randf() * total_weight
	var cumulative_weight = 0.0

	for i in range(items.size()):
		cumulative_weight += weights[i]
		if random_value <= cumulative_weight:
			return items[i]

	return items[0] if items.size() > 0 else null


func _create_encounter_data(type_def: Dictionary) -> Dictionary:
	var encounter_data = {
		"type": type_def["type"],
		"name": type_def["name"],
		"description": type_def["description"],
		"image_path": type_def["image_path"],
		"bg_color": type_def["colors"]["bg"],
		"hover_color": type_def["colors"]["hover"],
		"pressed_color": type_def["colors"]["pressed"],
		"border_color": type_def["colors"]["border"],
		"data": {}
	}

	var generation = type_def.get("generation", {})
	var data_fields = generation.get("data_fields", {})

	for field_name in data_fields:
		var field_def = data_fields[field_name]
		var generator_name = field_def["generator"]
		if _generators.has(generator_name):
			encounter_data["data"][field_name] = _generators[generator_name].call(field_def)
		else:
			push_error("EncounterFactory: Unknown generator: %s" % generator_name)

	if generation.get("scales_with_round", false):
		_apply_scaling(encounter_data)

	return encounter_data


func _apply_scaling(encounter_data: Dictionary) -> void:
	var round_num = RunManager.current_round
	var scale_factor = 1.0 + (round_num * GameConstants.ROUND_SCALE_FACTOR)

	for key in encounter_data["data"]:
		var val = encounter_data["data"][key]
		if val is int:
			encounter_data["data"][key] = int(val * scale_factor)
		elif val is float:
			encounter_data["data"][key] = val * scale_factor


func _get_type_def(type_name: String) -> Dictionary:
	for type_def in _encounter_types:
		if type_def["type"] == type_name:
			return type_def
	return {}


func _resolve_value(val: Variant) -> Variant:
	if val is String and _constant_map.has(val):
		return _constant_map[val]
	return val


# --- Generator functions ---

func _gen_random_range(params: Dictionary) -> int:
	var min_val = _resolve_value(params.get("min", 0))
	var max_val = _resolve_value(params.get("max", 0))
	return randi_range(int(min_val), int(max_val))


func _gen_constant(params: Dictionary) -> Variant:
	return _resolve_value(params.get("value", 0))


func _gen_pick_items(params: Dictionary) -> Array:
	return _gen_pick_from_pool(params, GameData.get_all_item_upgrades(), 1, 3, GameConstants.SHOP_ITEM_MIN_COST, GameConstants.SHOP_ITEM_MAX_COST)


func _gen_pick_skills(params: Dictionary) -> Array:
	return _gen_pick_from_pool(params, GameData.get_all_skills(), 0, 2, GameConstants.SHOP_SKILL_MIN_COST, GameConstants.SHOP_SKILL_MAX_COST)


func _gen_pick_from_pool(params: Dictionary, pool: Array, default_min: int, default_max: int, min_cost: int, max_cost: int) -> Array:
	var count = randi_range(
		int(_resolve_value(params.get("count_min", default_min))),
		int(_resolve_value(params.get("count_max", default_max)))
	)
	pool.shuffle()
	var result = []
	for i in range(mini(count, pool.size())):
		result.append({
			"id": pool[i]["id"],
			"cost": randi_range(min_cost, max_cost)
		})
	return result


func _get_team_max_level() -> int:
	"""Get the player's current level (gates content availability)."""
	return RunManager.get_player_level()


func _filter_pool_by_level(pool: Array, max_level: int) -> Array:
	"""Filter a pool of items/skills by level_requirement."""
	var filtered: Array = []
	for entry in pool:
		var level_req = entry.get("level_requirement", 1)
		if max_level >= level_req:
			filtered.append(entry)
	return filtered


func _refresh_cache_if_needed() -> void:
	"""Refresh cached filtered pools if round or team changed."""
	var current_round = RunManager.current_round
	var max_level = _get_team_max_level()

	if current_round != _cache_round or max_level != _cache_max_level:
		_cache_round = current_round
		_cache_max_level = max_level

		# Phase 6: If RunPool is available, use it for filtering (DRY)
		if _run_pool != null:
			# Get regular items from RunPool (items go directly into pool)
			var item_ids = _run_pool.pick_random(RunPoolScript.ContentType.ITEM, 999, max_level)
			_cached_items = []
			for item_id in item_ids:
				var item_data = GameData.get_item_by_id(item_id)
				if not item_data.is_empty():
					_cached_items.append(item_data)

			# Get item upgrades that are available based on player's inventory
			# Item upgrades only appear if player owns the base item
			var player_inventory = RunManager.get_inventory()
			var upgrade_ids = _run_pool.get_available_item_upgrades(player_inventory, max_level)
			_cached_item_upgrades = []
			for upgrade_id in upgrade_ids:
				var upgrade_data = GameData.get_item_upgrade_by_id(upgrade_id)
				if not upgrade_data.is_empty():
					_cached_item_upgrades.append(upgrade_data)

			var skill_ids = _run_pool.pick_random(RunPoolScript.ContentType.SKILL, 999, max_level)
			_cached_skills = []
			for skill_id in skill_ids:
				var skill_data = GameData.get_skill_by_id(skill_id)
				if not skill_data.is_empty():
					_cached_skills.append(skill_data)

			var char_ids = _run_pool.pick_random(RunPoolScript.ContentType.CHARACTER, 999, max_level)
			_cached_characters = []
			for char_id in char_ids:
				var char_data = GameData.get_character_by_id(char_id)
				if not char_data.is_empty():
					_cached_characters.append(char_data)
		else:
			# Fallback to filtering all content by level (legacy behavior)
			_cached_items = _filter_pool_by_level(GameData.get_all_items(), max_level)
			_cached_item_upgrades = _filter_pool_by_level(GameData.get_all_item_upgrades(), max_level)
			_cached_skills = _filter_pool_by_level(GameData.get_all_skills(), max_level)
			_cached_characters = _filter_pool_by_level(GameData.get_all_characters(), max_level)


func _get_cached_items() -> Array:
	"""Get level-filtered regular items from cache."""
	_refresh_cache_if_needed()
	return _cached_items


func _get_cached_item_upgrades() -> Array:
	"""Get item upgrades available based on player inventory."""
	_refresh_cache_if_needed()
	return _cached_item_upgrades


func _get_cached_skills() -> Array:
	"""Get level-filtered skills from cache."""
	_refresh_cache_if_needed()
	return _cached_skills


func _get_cached_characters() -> Array:
	"""Get level-filtered characters from cache (Phase 6)."""
	_refresh_cache_if_needed()
	return _cached_characters


func _gen_pick_learnable_skill(_params: Dictionary) -> String:
	"""Pick a random skill (Phase 2: skills are instant effects, always available)."""
	var all_skills = _get_cached_skills()

	if all_skills.is_empty():
		return ""

	all_skills.shuffle()
	return all_skills[0]["id"]


func _gen_pick_learnable_skills(params: Dictionary) -> Array:
	"""Pick multiple skills (Phase 2: skills are instant effects, always available)."""
	var count = int(params.get("count", 3))
	var all_skills = _get_cached_skills()

	if all_skills.is_empty():
		return []

	all_skills.shuffle()
	var result: Array = []
	for i in range(mini(count, all_skills.size())):
		result.append(all_skills[i]["id"])
	return result


func _gen_pick_shop_offerings(params: Dictionary) -> Array:
	"""Pick a mix of items, item upgrades, and skills for the shop."""
	var count = int(params.get("count", 3))
	var offerings: Array = []

	var available_items = _get_cached_items()
	var available_upgrades = _get_cached_item_upgrades()
	var available_skills = _get_cached_skills()

	# Mix items, upgrades, and skills randomly
	var pool: Array = []

	# Regular items: player can buy if they don't already own it
	for item in available_items:
		var item_id = item["id"]
		if not RunManager.has_item_in_inventory(item_id):
			pool.append({"type": "item", "data": item})

	# Item upgrades: available because player owns the base item (pre-filtered)
	# Player can buy to replace their base item with the upgrade
	for upgrade in available_upgrades:
		pool.append({"type": "item_upgrade", "data": upgrade})

	# Skills are instant effects, always available
	for skill in available_skills:
		pool.append({"type": "skill", "data": skill})

	pool.shuffle()

	# Pick up to count offerings
	for i in range(mini(count, pool.size())):
		var entry = pool[i]
		var data = entry["data"]
		offerings.append({
			"offering_type": entry["type"],
			"id": data.get("id", ""),
			"name": data.get("name", "Unknown"),
			"description": data.get("description", ""),
			"image_path": data.get("image_path", ""),
			"cost": data.get("cost", 20),
			"level_requirement": data.get("level_requirement", 1),
			"upgrades_item": data.get("upgrades_item", "")  # For item upgrades
		})

	return offerings


func _gen_pick_mystery_elements(params: Dictionary) -> Array:
	"""Pick mystery item options with different elements for treasure chest."""
	var count = int(params.get("count", 3))

	# Combine regular items and available item upgrades
	var available_items = _get_cached_items()
	var available_upgrades = _get_cached_item_upgrades()
	var acquirable: Array = []

	# Regular items player doesn't own
	for item in available_items:
		var item_id = item["id"]
		if not RunManager.has_item_in_inventory(item_id):
			acquirable.append(item)

	# Item upgrades (already filtered to those player can use)
	for upgrade in available_upgrades:
		acquirable.append(upgrade)

	# Group by element
	var items_by_element: Dictionary = {}
	for item in acquirable:
		var element = item.get("element", "neutral")
		if not items_by_element.has(element):
			items_by_element[element] = []
		items_by_element[element].append(item)

	# Get available elements (those with at least one item)
	var available_elements = items_by_element.keys()
	available_elements.shuffle()

	# Build mystery options with different elements
	var options: Array = []
	for i in range(mini(count, available_elements.size())):
		var element = available_elements[i]
		options.append({
			"element": element,
			"display_name": _get_element_display_name(element)
		})

	return options


func _get_element_display_name(element: String) -> String:
	"""Get capitalized display name for an element."""
	return element.capitalize()


# =============================================================================
# CHARACTER PICKING (Phase 6)
# =============================================================================

func _gen_pick_characters(params: Dictionary) -> Array:
	"""
	Pick characters for character shop encounter.
	Uses RunPool for filtering if available (DRY), otherwise falls back to all characters.

	Args:
		params: { "count": int }

	Returns:
		Array of character offering dictionaries with:
		- id, name, description, image_path, cost, level_requirement, base_stats
	"""
	var count = int(params.get("count", 3))
	var offerings: Array = []

	var available_chars = _get_cached_characters()
	if available_chars.is_empty():
		return offerings

	# Shuffle and pick
	available_chars = available_chars.duplicate()
	available_chars.shuffle()

	for i in range(mini(count, available_chars.size())):
		var char_data = available_chars[i]
		offerings.append({
			"offering_type": "character",
			"id": char_data.get("id", ""),
			"name": char_data.get("name", "Unknown"),
			"description": char_data.get("description", ""),
			"image_path": char_data.get("image_path", ""),
			"cost": char_data.get("cost", 40),
			"level_requirement": char_data.get("level_requirement", 1),
			"base_stats": char_data.get("base_stats", {})
		})

	return offerings


func pick_characters_for_encounter(count: int, max_level: int = 999) -> Array:
	"""
	Public method to pick characters for any encounter that can reward characters.
	Delegates to RunPool if available for proper pool filtering.

	Args:
		count: Number of characters to pick
		max_level: Maximum level requirement

	Returns:
		Array of character data dictionaries
	"""
	if _run_pool != null:
		# Use RunPool for proper filtering (DRY)
		var char_ids = _run_pool.pick_random(RunPoolScript.ContentType.CHARACTER, count, max_level)
		var result: Array = []
		for char_id in char_ids:
			var char_data = GameData.get_character_by_id(char_id)
			if not char_data.is_empty():
				result.append(char_data)
		return result
	else:
		# Fallback: filter all characters by level
		var all_chars = GameData.get_all_characters()
		var filtered = _filter_pool_by_level(all_chars, max_level)
		filtered.shuffle()
		return filtered.slice(0, mini(count, filtered.size()))
