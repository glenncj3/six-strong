extends Node
# EncounterFactory Singleton
# Generates random encounter options from JSON configuration

signal encounter_generated(encounter_type: String)

var _encounter_types: Array = []

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
	}

	# Use GameData's cached encounter types (single source of truth)
	_encounter_types = GameData.get_encounter_types()


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
	"""Get the highest level among team members."""
	var team = RunManager.get_team()
	var max_level = 1
	for char_instance in team:
		max_level = maxi(max_level, char_instance.level)
	return max_level


func _filter_pool_by_level(pool: Array, max_level: int) -> Array:
	"""Filter a pool of items/skills by level_requirement."""
	var filtered: Array = []
	for entry in pool:
		var level_req = entry.get("level_requirement", 1)
		if max_level >= level_req:
			filtered.append(entry)
	return filtered


func _gen_pick_learnable_skill(_params: Dictionary) -> String:
	var all_skills = _filter_pool_by_level(GameData.get_all_skills(), _get_team_max_level())
	var team = RunManager.get_team()

	var learnable_skills: Array = []
	for skill in all_skills:
		var skill_id = skill["id"]
		for char_instance in team:
			if skill_id not in char_instance.learned_skills:
				learnable_skills.append(skill)
				break

	learnable_skills.shuffle()

	if learnable_skills.size() > 0:
		return learnable_skills[0]["id"]
	return ""


func _gen_pick_learnable_skills(params: Dictionary) -> Array:
	"""Pick multiple learnable skills for the team."""
	var count = int(params.get("count", 3))
	var all_skills = _filter_pool_by_level(GameData.get_all_skills(), _get_team_max_level())
	var team = RunManager.get_team()

	var learnable_skills: Array = []
	for skill in all_skills:
		var skill_id = skill["id"]
		# Check if at least one character can learn this skill
		for char_instance in team:
			var already_learned = skill_id in char_instance.learned_skills
			var max_skills_reached = char_instance.learned_skills.size() >= GameConstants.MAX_RUN_SKILLS
			if not already_learned and not max_skills_reached:
				learnable_skills.append(skill["id"])
				break

	learnable_skills.shuffle()
	return learnable_skills.slice(0, count)


func _gen_pick_shop_offerings(params: Dictionary) -> Array:
	"""Pick a mix of items and skills for the shop (max 3 total)."""
	var count = int(params.get("count", 3))
	var offerings: Array = []
	var team_max_level = _get_team_max_level()
	var team = RunManager.get_team()

	var available_items = _filter_pool_by_level(GameData.get_all_item_upgrades(), team_max_level)
	var available_skills = _filter_pool_by_level(GameData.get_all_skills(), team_max_level)

	# Mix items and skills randomly, filtering to only include acquirable ones
	var pool: Array = []

	for item in available_items:
		var item_id = item["id"]
		# Check if at least one character can equip this item
		for char_instance in team:
			var already_equipped = item_id in char_instance.equipped_item_upgrades
			var total_items = char_instance.equipped_items.size() + char_instance.equipped_item_upgrades.size()
			var max_items_reached = total_items >= GameConstants.MAX_RUN_ITEMS
			if not already_equipped and not max_items_reached:
				pool.append({"type": "item", "data": item})
				break

	for skill in available_skills:
		var skill_id = skill["id"]
		# Check if at least one character can learn this skill
		for char_instance in team:
			var already_learned = skill_id in char_instance.learned_skills
			var max_skills_reached = char_instance.learned_skills.size() >= GameConstants.MAX_RUN_SKILLS
			if not already_learned and not max_skills_reached:
				pool.append({"type": "skill", "data": skill})
				break

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
			"level_requirement": data.get("level_requirement", 1)
		})

	return offerings


func _gen_pick_mystery_elements(params: Dictionary) -> Array:
	"""Pick mystery item options with different elements for treasure chest."""
	var count = int(params.get("count", 3))
	var team_max_level = _get_team_max_level()
	var team = RunManager.get_team()

	# Get all available item upgrades that at least one character can equip
	var available_items = _filter_pool_by_level(GameData.get_all_item_upgrades(), team_max_level)
	var equippable_items: Array = []

	for item in available_items:
		var item_id = item["id"]
		for char_instance in team:
			var already_equipped = item_id in char_instance.equipped_item_upgrades
			var total_items = char_instance.equipped_items.size() + char_instance.equipped_item_upgrades.size()
			var max_items_reached = total_items >= GameConstants.MAX_RUN_ITEMS
			if not already_equipped and not max_items_reached:
				equippable_items.append(item)
				break

	# Group items by element
	var items_by_element: Dictionary = {}
	for item in equippable_items:
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
