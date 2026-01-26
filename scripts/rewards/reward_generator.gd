class_name RewardGenerator
extends RefCounted
## Generate random rewards for encounters.
## Includes wheel segment generation and random item/skill resolution.
##
## Phase 2 Refactor:
## - Items are checked against player inventory (not character equipment)
## - Skills will be instant effects in Phase 3


## Generate a random item reward
## Returns RewardDefinition with type ITEM (resolved) or GOLD (fallback)
static func generate_random_item(max_cost: int = 0, max_level: int = 0) -> RewardDefinition:
	var team_max_level = _get_team_max_level()

	if max_level <= 0:
		max_level = team_max_level

	# Get all items filtered by level
	var all_items = GameData.get_all_item_upgrades()
	var available_items: Array = []

	for item in all_items:
		var level_req = item.get("level_requirement", 1)
		if level_req > max_level:
			continue
		if max_cost > 0 and item.get("cost", 0) > max_cost:
			continue

		# Check if player already has this item in inventory
		var item_id = item["id"]
		if RunManager.has_item_in_inventory(item_id):
			continue

		available_items.append(item)

	if available_items.is_empty():
		# Fallback to gold
		return RewardDefinition.create_gold(randi_range(20, 35))

	available_items.shuffle()
	var chosen_item = available_items[0]
	return RewardDefinition.create_item(chosen_item["id"])


## Generate a random skill reward
## Returns RewardDefinition with type SKILL (resolved) or GOLD (fallback)
## Note: In Phase 3, skills will be instant effects. For now, we just pick a skill.
static func generate_random_skill(max_cost: int = 0, max_level: int = 0) -> RewardDefinition:
	var team_max_level = _get_team_max_level()

	if max_level <= 0:
		max_level = team_max_level

	# Get all skills filtered by level
	var all_skills = GameData.get_all_skills()
	var available_skills: Array = []

	for skill in all_skills:
		var level_req = skill.get("level_requirement", 1)
		if level_req > max_level:
			continue
		if max_cost > 0 and skill.get("cost", 0) > max_cost:
			continue

		# Phase 3: Skills are instant effects, so we don't track "learned" skills
		# For now, allow any skill that passes level/cost filters
		available_skills.append(skill)

	if available_skills.is_empty():
		# Fallback to gold
		return RewardDefinition.create_gold(randi_range(25, 40))

	available_skills.shuffle()
	var chosen_skill = available_skills[0]
	return RewardDefinition.create_skill(chosen_skill["id"])


## Resolve a random reward to a concrete one
## Converts ITEM_RANDOM -> ITEM, SKILL_RANDOM -> SKILL
static func resolve_reward(definition: RewardDefinition) -> RewardDefinition:
	match definition.type:
		RewardTypes.RewardType.ITEM_RANDOM:
			return generate_random_item(
				definition.params.get("max_cost", 0),
				definition.params.get("max_level", 0)
			)
		RewardTypes.RewardType.SKILL_RANDOM:
			return generate_random_skill(
				definition.params.get("max_cost", 0),
				definition.params.get("max_level", 0)
			)

	# Already concrete, return as-is
	return definition


## Generate wheel segments for the Wheel of Fortune encounter
## Returns Array[RewardDefinition] with 6 segments
static func generate_wheel_segments(round_num: int = 1) -> Array:
	var segments: Array = []
	var scale_factor = 1.0 + (round_num * GameConstants.ROUND_SCALE_FACTOR)

	# Segment distribution:
	# - 2 gold rewards (varied amounts)
	# - 1 random skill
	# - 1 random item
	# - 1 XP reward (all characters)
	# - 1 health restore (all characters)

	# Gold segment 1 (smaller)
	var small_gold = int(randi_range(15, 30) * scale_factor)
	segments.append(RewardDefinition.new(
		RewardTypes.RewardType.GOLD,
		{"amount": small_gold},
		RewardTypes.RewardTarget.ALL,
		{"label": "+%d Gold" % small_gold, "color": GameConstants.COLOR_GOLD}
	))

	# Gold segment 2 (larger)
	var big_gold = int(randi_range(40, 70) * scale_factor)
	segments.append(RewardDefinition.new(
		RewardTypes.RewardType.GOLD,
		{"amount": big_gold},
		RewardTypes.RewardTarget.ALL,
		{"label": "+%d Gold" % big_gold, "color": GameConstants.COLOR_GOLD}
	))

	# Random skill
	var skill_reward = generate_random_skill()
	segments.append(skill_reward)

	# Random item
	var item_reward = generate_random_item()
	segments.append(item_reward)

	# XP reward (all characters)
	var xp_amount = int(randi_range(20, 40) * scale_factor)
	segments.append(RewardDefinition.new(
		RewardTypes.RewardType.XP,
		{"amount": xp_amount},
		RewardTypes.RewardTarget.ALL,
		{"label": "+%d XP" % xp_amount, "color": Color("#4A6AAA")}
	))

	# Health restore (all characters, percentage)
	var heal_percent = 0.25 + randf() * 0.25  # 25-50%
	segments.append(RewardDefinition.new(
		RewardTypes.RewardType.HEALTH,
		{"percentage": heal_percent},
		RewardTypes.RewardTarget.ALL,
		{"label": "+%d%% HP" % int(heal_percent * 100), "color": GameConstants.COLOR_EMERALD}
	))

	# Shuffle for variety
	segments.shuffle()

	return segments


## Generate segment weights (optional, for weighted wheel spins)
## Returns Array[float] matching segment indices
static func generate_segment_weights(segments: Array) -> Array:
	var weights: Array = []

	for segment in segments:
		var weight = 1.0

		# Adjust weight based on reward type
		match segment.type:
			RewardTypes.RewardType.GOLD:
				# Gold amount affects weight (bigger = rarer)
				var amount = segment.params.get("amount", 0)
				if amount > 50:
					weight = 0.7
				elif amount < 25:
					weight = 1.3
			RewardTypes.RewardType.SKILL:
				weight = 0.8  # Skills slightly rarer
			RewardTypes.RewardType.ITEM:
				weight = 0.8  # Items slightly rarer
			RewardTypes.RewardType.XP:
				weight = 1.0  # Standard weight
			RewardTypes.RewardType.HEALTH:
				weight = 1.1  # Health slightly more common

		weights.append(weight)

	return weights


## Get team max level helper
static func _get_team_max_level() -> int:
	var team = RunManager.get_team()
	var max_level = 1
	for char_instance in team:
		max_level = maxi(max_level, char_instance.level)
	return max_level
