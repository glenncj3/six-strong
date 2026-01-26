class_name RewardTypes
extends RefCounted
## Constants and enums for the reward system.
## Provides standard types for rewards across all encounters.


## Type of reward being granted
enum RewardType {
	GOLD,           ## Gold currency
	HEALTH,         ## Health restore
	XP,             ## Experience points
	ITEM,           ## Specific named item upgrade
	SKILL,          ## Specific named skill
	ITEM_RANDOM,    ## Random item by criteria
	SKILL_RANDOM    ## Random skill by criteria
}


## Who receives the reward
enum RewardTarget {
	SINGLE,    ## Requires character selection
	ALL,       ## All team members
	RANDOM     ## Random team member
}


## String representations for display
const REWARD_TYPE_NAMES := {
	RewardType.GOLD: "Gold",
	RewardType.HEALTH: "Health",
	RewardType.XP: "XP",
	RewardType.ITEM: "Item",
	RewardType.SKILL: "Skill",
	RewardType.ITEM_RANDOM: "Random Item",
	RewardType.SKILL_RANDOM: "Random Skill"
}


const REWARD_TARGET_NAMES := {
	RewardTarget.SINGLE: "Single",
	RewardTarget.ALL: "All",
	RewardTarget.RANDOM: "Random"
}


## Default icons for reward types (emoji fallbacks)
const REWARD_TYPE_ICONS := {
	RewardType.GOLD: "gold_coin",
	RewardType.HEALTH: "heart",
	RewardType.XP: "star",
	RewardType.ITEM: "chest",
	RewardType.SKILL: "scroll",
	RewardType.ITEM_RANDOM: "chest",
	RewardType.SKILL_RANDOM: "scroll"
}


## Colors associated with reward types
const REWARD_TYPE_COLORS := {
	RewardType.GOLD: Color("#FFD700"),      # Gold
	RewardType.HEALTH: Color("#2A7A4A"),    # Emerald
	RewardType.XP: Color("#4A6AAA"),        # Blue
	RewardType.ITEM: Color("#8A6A21"),      # Brown/Gold
	RewardType.SKILL: Color("#6A3A8A"),     # Purple
	RewardType.ITEM_RANDOM: Color("#8A6A21"),
	RewardType.SKILL_RANDOM: Color("#6A3A8A")
}
