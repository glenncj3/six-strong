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
var prestige: int = 0

# Panel colors for clickable UI
var bg_color: Color = Color("#3D2E24")
var hover_color: Color = Color("#5D4E44")
var pressed_color: Color = Color("#2D1E14")
var border_color: Color = Color("#B88726")


static func create_ai(
	p_name: String,
	p_description: String,
	p_image_path: String,
	p_difficulty: String,
	p_reward_gold: int,
	p_reward_xp: int,
	p_bg_color: Color = Color("#3D2E24"),
	p_hover_color: Color = Color("#5D4E44"),
	p_pressed_color: Color = Color("#2D1E14"),
	p_border_color: Color = Color("#B88726")
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
	option.bg_color = p_bg_color
	option.hover_color = p_hover_color
	option.pressed_color = p_pressed_color
	option.border_color = p_border_color
	return option


static func create_ghost(
	p_name: String,
	p_description: String,
	p_image_path: String,
	p_prestige: int,
	p_reward_gold: int,
	p_reward_xp: int,
	p_bg_color: Color = Color("#6A3A8A"),
	p_hover_color: Color = Color("#8A5AAA"),
	p_pressed_color: Color = Color("#4A1A6A"),
	p_border_color: Color = Color("#B88726")
) -> CombatOption:
	"""Factory method to create a player ghost combat option."""
	var option = CombatOption.new()
	option.type = "ghost"
	option.name = p_name
	option.description = p_description
	option.image_path = p_image_path
	option.prestige = p_prestige
	option.reward_gold = p_reward_gold
	option.reward_xp = p_reward_xp
	option.bg_color = p_bg_color
	option.hover_color = p_hover_color
	option.pressed_color = p_pressed_color
	option.border_color = p_border_color
	return option


func to_dict() -> Dictionary:
	"""Convert to dictionary for compatibility with existing code."""
	var dict = {
		"type": type,
		"name": name,
		"description": description,
		"image_path": image_path,
		"reward_gold": reward_gold,
		"reward_xp": reward_xp,
		"bg_color": bg_color.to_html(),
		"hover_color": hover_color.to_html(),
		"pressed_color": pressed_color.to_html(),
		"border_color": border_color.to_html()
	}

	if type == "ai":
		dict["difficulty"] = difficulty
	elif type == "ghost":
		dict["prestige"] = prestige

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
	option.prestige = dict.get("prestige", 0)
	option.bg_color = Color(dict.get("bg_color", "#3D2E24"))
	option.hover_color = Color(dict.get("hover_color", "#5D4E44"))
	option.pressed_color = Color(dict.get("pressed_color", "#2D1E14"))
	option.border_color = Color(dict.get("border_color", "#B88726"))
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
