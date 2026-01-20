extends Node
# EncounterFactory Singleton
# Generates random encounter options with difficulty scaling

signal encounter_generated(encounter_type: String)

# Weight system for encounter types
var encounter_weights: Dictionary = {
	"shop": 1.0,
	"xp_reward": 1.0,
	"gold_reward": 0.8,
	"health_restore": 0.6,
	"skill_trainer": 0.7,
	"gamble": 0.5,
	"elite_challenge": 0.4
}


func _ready() -> void:
	pass


func generate_encounter_options(count: int) -> Array:
	"""
	Generate random encounter options.

	Args:
		count: Number of options to generate (usually 3)

	Returns:
		Array of encounter option dictionaries
	"""
	var options = []
	var used_types = []  # Prevent duplicate types in same set

	for i in range(count):
		var encounter_type = _select_weighted_encounter_type(used_types)
		used_types.append(encounter_type)

		var encounter_data = _create_encounter_data(encounter_type)
		options.append(encounter_data)

		encounter_generated.emit(encounter_type)

	print("EncounterFactory: Generated %d encounter options" % options.size())
	return options


func _select_weighted_encounter_type(excluded_types: Array) -> String:
	"""Select a random encounter type using weights."""
	var available_types = []
	var available_weights = []

	for encounter_type in encounter_weights.keys():
		if encounter_type not in excluded_types:
			available_types.append(encounter_type)
			available_weights.append(encounter_weights[encounter_type])

	if available_types.is_empty():
		# Fallback: Allow duplicates if we've exhausted unique options
		available_types = encounter_weights.keys()
		available_weights.clear()
		for t in available_types:
			available_weights.append(encounter_weights[t])

	return _weighted_random_select(available_types, available_weights)


func _weighted_random_select(items: Array, weights: Array) -> Variant:
	"""Select a random item using weighted probabilities."""
	var total_weight = 0.0
	for w in weights:
		total_weight += w

	var random_value = randf() * total_weight
	var cumulative_weight = 0.0

	for i in range(items.size()):
		cumulative_weight += weights[i]
		if random_value <= cumulative_weight:
			return items[i]

	# Fallback
	return items[0] if items.size() > 0 else null


func _create_encounter_data(encounter_type: String) -> Dictionary:
	"""Create encounter data based on type."""
	var encounter_data = {
		"type": encounter_type,
		"name": "",
		"description": "",
		"image_path": "",
		"data": {}  # Type-specific data
	}

	match encounter_type:
		"shop":
			encounter_data["name"] = "Traveling Merchant"
			encounter_data["description"] = "A merchant offers their wares."
			encounter_data["image_path"] = "res://assets/encounters/merchant.png"
			encounter_data["data"] = _generate_shop_inventory()

		"xp_reward":
			encounter_data["name"] = "Training Dummy"
			encounter_data["description"] = "Practice your skills and gain experience."
			encounter_data["image_path"] = "res://assets/encounters/training.png"
			encounter_data["data"] = {
				"xp_amount": randi_range(GameConstants.XP_REWARD_MIN, GameConstants.XP_REWARD_MAX)
			}

		"gold_reward":
			encounter_data["name"] = "Treasure Chest"
			encounter_data["description"] = "You found a chest full of gold!"
			encounter_data["image_path"] = "res://assets/encounters/chest.png"
			encounter_data["data"] = {
				"gold_amount": randi_range(GameConstants.GOLD_REWARD_MIN, GameConstants.GOLD_REWARD_MAX)
			}

		"health_restore":
			encounter_data["name"] = "Healing Fountain"
			encounter_data["description"] = "Restore your team's health."
			encounter_data["image_path"] = "res://assets/encounters/fountain.png"
			encounter_data["data"] = {
				"heal_percentage": GameConstants.HEALTH_RESTORE_PERCENTAGE
			}

		"skill_trainer":
			encounter_data["name"] = "Skill Trainer"
			encounter_data["description"] = "Learn a random skill for free!"
			encounter_data["image_path"] = "res://assets/encounters/trainer.png"
			encounter_data["data"] = _generate_skill_trainer_data()

		"gamble":
			encounter_data["name"] = "Mysterious Gambler"
			encounter_data["description"] = "Risk gold for a chance at greater rewards."
			encounter_data["image_path"] = "res://assets/encounters/gambler.png"
			encounter_data["data"] = {
				"bet_amount": randi_range(20, 40),
				"win_multiplier": 3
			}

		"elite_challenge":
			encounter_data["name"] = "Elite Challenge"
			encounter_data["description"] = "A difficult trial with great rewards."
			encounter_data["image_path"] = "res://assets/encounters/elite.png"
			encounter_data["data"] = {
				"xp_reward": randi_range(80, 120),
				"gold_reward": randi_range(40, 60)
			}

	return encounter_data


func _generate_shop_inventory() -> Dictionary:
	"""Generate random shop inventory."""
	var inventory = {
		"items": [],
		"skills": []
	}

	# Add random item upgrades for sale
	var all_item_upgrades = GameData.get_all_item_upgrades()
	all_item_upgrades.shuffle()
	var item_count = randi_range(GameConstants.SHOP_MIN_ITEMS, GameConstants.SHOP_MAX_ITEMS)
	for i in range(mini(item_count, all_item_upgrades.size())):
		inventory["items"].append({
			"id": all_item_upgrades[i]["id"],
			"cost": randi_range(GameConstants.SHOP_ITEM_MIN_COST, GameConstants.SHOP_ITEM_MAX_COST)
		})

	# Add random skills for sale
	var all_skills = GameData.get_all_skills()
	all_skills.shuffle()
	var skill_count = randi_range(GameConstants.SHOP_MIN_SKILLS, GameConstants.SHOP_MAX_SKILLS)
	for i in range(mini(skill_count, all_skills.size())):
		inventory["skills"].append({
			"id": all_skills[i]["id"],
			"cost": randi_range(GameConstants.SHOP_SKILL_MIN_COST, GameConstants.SHOP_SKILL_MAX_COST)
		})

	return inventory


func apply_scaling(encounter_data: Dictionary, round_num: int) -> void:
	"""Apply difficulty/reward scaling based on round number."""
	# Scale rewards based on how far into the run the player is
	var scale_factor = 1.0 + (round_num * GameConstants.ROUND_SCALE_FACTOR)

	match encounter_data["type"]:
		"xp_reward":
			encounter_data["data"]["xp_amount"] = int(encounter_data["data"]["xp_amount"] * scale_factor)
		"gold_reward":
			encounter_data["data"]["gold_amount"] = int(encounter_data["data"]["gold_amount"] * scale_factor)
		"elite_challenge":
			encounter_data["data"]["xp_reward"] = int(encounter_data["data"]["xp_reward"] * scale_factor)
			encounter_data["data"]["gold_reward"] = int(encounter_data["data"]["gold_reward"] * scale_factor)


func _generate_skill_trainer_data() -> Dictionary:
	"""Generate a random skill for the trainer to offer that at least one team member can learn."""
	var all_skills = GameData.get_all_skills()
	var team = RunManager.get_team()

	# Filter to skills that at least one team member can learn
	var learnable_skills: Array = []
	for skill in all_skills:
		var skill_id = skill["id"]
		var level_req = skill.get("level_requirement", 1)

		for char_instance in team:
			# Check if character can learn this skill (not already known + meets level req)
			if skill_id not in char_instance.learned_skills and char_instance.level >= level_req:
				learnable_skills.append(skill)
				break  # At least one character can learn it, move to next skill

	learnable_skills.shuffle()

	if learnable_skills.size() > 0:
		return {"skill_id": learnable_skills[0]["id"]}
	return {"skill_id": ""}
