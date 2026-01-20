class_name CombatOption
extends RefCounted
# CombatOption - Typed data class for combat options
# Replaces untyped Dictionary returns for better type safety and IDE support

var type: String = ""  # "ai" or "ghost"
var name: String = ""
var description: String = ""
var image_path: String = ""
var reward_gold: int = 0
var reward_xp: int = 0

# AI-specific
var difficulty: String = ""  # "Easy", "Medium", "Hard"

# Ghost-specific
var rank: int = 0


static func create_ai(
	p_name: String,
	p_description: String,
	p_image_path: String,
	p_difficulty: String,
	p_reward_gold: int,
	p_reward_xp: int
) -> CombatOption:
	"""Factory method to create an AI combat option."""
	var option = CombatOption.new()
	option.type = "ai"
	option.name = p_name
	option.description = p_description
	option.image_path = p_image_path
	option.difficulty = p_difficulty
	option.reward_gold = p_reward_gold
	option.reward_xp = p_reward_xp
	return option


static func create_ghost(
	p_name: String,
	p_description: String,
	p_image_path: String,
	p_rank: int,
	p_reward_gold: int,
	p_reward_xp: int
) -> CombatOption:
	"""Factory method to create a player ghost combat option."""
	var option = CombatOption.new()
	option.type = "ghost"
	option.name = p_name
	option.description = p_description
	option.image_path = p_image_path
	option.rank = p_rank
	option.reward_gold = p_reward_gold
	option.reward_xp = p_reward_xp
	return option


func to_dict() -> Dictionary:
	"""Convert to dictionary for compatibility with existing code."""
	var dict = {
		"type": type,
		"name": name,
		"description": description,
		"image_path": image_path,
		"reward_gold": reward_gold,
		"reward_xp": reward_xp
	}

	if type == "ai":
		dict["difficulty"] = difficulty
	elif type == "ghost":
		dict["rank"] = rank

	return dict


static func from_dict(dict: Dictionary) -> CombatOption:
	"""Create from dictionary for loading saved data."""
	var option = CombatOption.new()
	option.type = dict.get("type", "")
	option.name = dict.get("name", "")
	option.description = dict.get("description", "")
	option.image_path = dict.get("image_path", "")
	option.reward_gold = dict.get("reward_gold", 0)
	option.reward_xp = dict.get("reward_xp", 0)
	option.difficulty = dict.get("difficulty", "")
	option.rank = dict.get("rank", 0)
	return option


# =============================================================================
# TYPE CHECKS
# =============================================================================

func is_ai() -> bool:
	return type == "ai"


func is_ghost() -> bool:
	return type == "ghost"


func get_difficulty_index() -> int:
	"""Get numeric difficulty index (0=Easy, 1=Medium, 2=Hard)."""
	return GameConstants.COMBAT_DIFFICULTIES.find(difficulty)
