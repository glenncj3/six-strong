class_name RewardDefinition
extends RefCounted
## Data class for reward definitions.
## Describes what a reward contains and how it should be applied.


## The type of reward (from RewardTypes.RewardType enum)
var type: int = RewardTypes.RewardType.GOLD

## Type-specific parameters
## GOLD: { "amount": int }
## HEALTH: { "amount": int } or { "percentage": float }
## XP: { "amount": int }
## ITEM: { "item_id": String }
## SKILL: { "skill_id": String }
## ITEM_RANDOM: { "max_cost": int, "max_level": int } (optional filters)
## SKILL_RANDOM: { "max_cost": int, "max_level": int } (optional filters)
var params: Dictionary = {}

## Who receives the reward (from RewardTypes.RewardTarget enum)
var target: int = RewardTypes.RewardTarget.SINGLE

## Display information for UI
## { "label": String, "icon_path": String, "color": Color }
var display: Dictionary = {}

## Unique identifier for tracking (e.g., segment index on wheel)
var uid: String = ""


func _init(
	p_type: int = RewardTypes.RewardType.GOLD,
	p_params: Dictionary = {},
	p_target: int = RewardTypes.RewardTarget.SINGLE,
	p_display: Dictionary = {}
) -> void:
	type = p_type
	params = p_params
	target = p_target
	display = p_display
	uid = _generate_uid()


func _generate_uid() -> String:
	return "%d_%d_%d" % [Time.get_ticks_msec(), randi(), type]


## Get display label for this reward
func get_label() -> String:
	if display.has("label"):
		return display["label"]

	# Generate default label based on type
	match type:
		RewardTypes.RewardType.GOLD:
			return "+%d Gold" % params.get("amount", 0)
		RewardTypes.RewardType.HEALTH:
			if params.has("percentage"):
				return "+%d%% Health" % int(params["percentage"] * 100)
			return "+%d Health" % params.get("amount", 0)
		RewardTypes.RewardType.XP:
			return "+%d XP" % params.get("amount", 0)
		RewardTypes.RewardType.ITEM, RewardTypes.RewardType.ITEM_RANDOM:
			var item_id = params.get("item_id", "")
			if item_id:
				var item_data = GameData.get_item_upgrade_by_id(item_id)
				return item_data.get("name", "Item")
			return "Random Item"
		RewardTypes.RewardType.SKILL, RewardTypes.RewardType.SKILL_RANDOM:
			var skill_id = params.get("skill_id", "")
			if skill_id:
				var skill_data = GameData.get_skill_by_id(skill_id)
				return skill_data.get("name", "Skill")
			return "Random Skill"

	return "Reward"


## Get icon path for this reward
func get_icon_path() -> String:
	if display.has("icon_path"):
		return display["icon_path"]

	# Return item/skill icon if available
	match type:
		RewardTypes.RewardType.ITEM:
			var item_id = params.get("item_id", "")
			if item_id:
				var item_data = GameData.get_item_upgrade_by_id(item_id)
				return item_data.get("image_path", "")
		RewardTypes.RewardType.SKILL:
			var skill_id = params.get("skill_id", "")
			if skill_id:
				var skill_data = GameData.get_skill_by_id(skill_id)
				return skill_data.get("image_path", "")

	return ""


## Get display color for this reward
func get_color() -> Color:
	if display.has("color"):
		return display["color"]
	return RewardTypes.REWARD_TYPE_COLORS.get(type, GameConstants.COLOR_TEXT_LIGHT)


## Check if this reward requires character selection
func requires_target_selection() -> bool:
	# Gold is always applied to the team pool
	if type == RewardTypes.RewardType.GOLD:
		return false
	# All and random targets don't need selection
	if target != RewardTypes.RewardTarget.SINGLE:
		return false
	return true


## Convert to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"type": type,
		"params": params,
		"target": target,
		"display": display,
		"uid": uid
	}


## Create from dictionary
static func from_dict(data: Dictionary) -> RewardDefinition:
	var reward = RewardDefinition.new(
		data.get("type", RewardTypes.RewardType.GOLD),
		data.get("params", {}),
		data.get("target", RewardTypes.RewardTarget.SINGLE),
		data.get("display", {})
	)
	if data.has("uid"):
		reward.uid = data["uid"]
	return reward


## Create a simple gold reward
static func create_gold(amount: int) -> RewardDefinition:
	return RewardDefinition.new(
		RewardTypes.RewardType.GOLD,
		{"amount": amount},
		RewardTypes.RewardTarget.ALL,
		{"label": "+%d Gold" % amount}
	)


## Create a simple health reward
static func create_health(amount: int, p_target: int = RewardTypes.RewardTarget.SINGLE) -> RewardDefinition:
	return RewardDefinition.new(
		RewardTypes.RewardType.HEALTH,
		{"amount": amount},
		p_target,
		{"label": "+%d Health" % amount}
	)


## Create a percentage health reward
static func create_health_percent(percentage: float, p_target: int = RewardTypes.RewardTarget.ALL) -> RewardDefinition:
	return RewardDefinition.new(
		RewardTypes.RewardType.HEALTH,
		{"percentage": percentage},
		p_target,
		{"label": "+%d%% Health" % int(percentage * 100)}
	)


## Create an XP reward
static func create_xp(amount: int, p_target: int = RewardTypes.RewardTarget.ALL) -> RewardDefinition:
	return RewardDefinition.new(
		RewardTypes.RewardType.XP,
		{"amount": amount},
		p_target,
		{"label": "+%d XP" % amount}
	)


## Create a specific item reward
static func create_item(item_id: String) -> RewardDefinition:
	var item_data = GameData.get_item_upgrade_by_id(item_id)
	return RewardDefinition.new(
		RewardTypes.RewardType.ITEM,
		{"item_id": item_id},
		RewardTypes.RewardTarget.SINGLE,
		{
			"label": item_data.get("name", "Item"),
			"icon_path": item_data.get("image_path", "")
		}
	)


## Create a specific skill reward
static func create_skill(skill_id: String) -> RewardDefinition:
	var skill_data = GameData.get_skill_by_id(skill_id)
	return RewardDefinition.new(
		RewardTypes.RewardType.SKILL,
		{"skill_id": skill_id},
		RewardTypes.RewardTarget.SINGLE,
		{
			"label": skill_data.get("name", "Skill"),
			"icon_path": skill_data.get("image_path", "")
		}
	)


## Create a random item reward
static func create_random_item(max_cost: int = 0, max_level: int = 0) -> RewardDefinition:
	var params_dict = {}
	if max_cost > 0:
		params_dict["max_cost"] = max_cost
	if max_level > 0:
		params_dict["max_level"] = max_level
	return RewardDefinition.new(
		RewardTypes.RewardType.ITEM_RANDOM,
		params_dict,
		RewardTypes.RewardTarget.SINGLE,
		{"label": "Random Item"}
	)


## Create a random skill reward
static func create_random_skill(max_cost: int = 0, max_level: int = 0) -> RewardDefinition:
	var params_dict = {}
	if max_cost > 0:
		params_dict["max_cost"] = max_cost
	if max_level > 0:
		params_dict["max_level"] = max_level
	return RewardDefinition.new(
		RewardTypes.RewardType.SKILL_RANDOM,
		params_dict,
		RewardTypes.RewardTarget.SINGLE,
		{"label": "Random Skill"}
	)
