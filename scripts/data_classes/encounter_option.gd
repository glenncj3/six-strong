class_name EncounterOption
extends RefCounted
# EncounterOption - Typed data class for encounter options
# Replaces untyped Dictionary returns for better type safety and IDE support

var id: String = ""
var type: String = ""
var name: String = ""
var description: String = ""
var image_path: String = ""
var data: Dictionary = {}  # Type-specific data (items, skills, xp_amount, etc.)

# Panel colors for clickable UI
var bg_color: Color = Color("#3D2E24")
var hover_color: Color = Color("#5D4E44")
var pressed_color: Color = Color("#2D1E14")
var border_color: Color = Color("#B88726")


static func create(
	p_id: String,
	p_type: String,
	p_name: String,
	p_description: String,
	p_image_path: String,
	p_data: Dictionary = {},
	p_bg_color: Color = Color("#3D2E24"),
	p_hover_color: Color = Color("#5D4E44"),
	p_pressed_color: Color = Color("#2D1E14"),
	p_border_color: Color = Color("#B88726")
) -> EncounterOption:
	"""Factory method to create an EncounterOption."""
	var option = EncounterOption.new()
	option.id = p_id
	option.type = p_type
	option.name = p_name
	option.description = p_description
	option.image_path = p_image_path
	option.data = p_data
	option.bg_color = p_bg_color
	option.hover_color = p_hover_color
	option.pressed_color = p_pressed_color
	option.border_color = p_border_color
	return option


func to_dict() -> Dictionary:
	"""Convert to dictionary for compatibility with existing code."""
	return {
		"id": id,
		"type": type,
		"name": name,
		"description": description,
		"image_path": image_path,
		"data": data,
		"bg_color": bg_color.to_html(),
		"hover_color": hover_color.to_html(),
		"pressed_color": pressed_color.to_html(),
		"border_color": border_color.to_html()
	}


static func from_dict(dict: Dictionary) -> EncounterOption:
	"""Create from dictionary for loading saved data."""
	var option = EncounterOption.new()
	option.id = dict.get("id", "")
	option.type = dict.get("type", "")
	option.name = dict.get("name", "")
	option.description = dict.get("description", "")
	option.image_path = dict.get("image_path", "")
	option.data = dict.get("data", {})
	option.bg_color = Color(dict.get("bg_color", "#3D2E24"))
	option.hover_color = Color(dict.get("hover_color", "#5D4E44"))
	option.pressed_color = Color(dict.get("pressed_color", "#2D1E14"))
	option.border_color = Color(dict.get("border_color", "#B88726"))
	return option


# =============================================================================
# TYPE-SPECIFIC ACCESSORS
# =============================================================================

func get_xp_amount() -> int:
	"""Get XP amount for xp_reward encounters."""
	return data.get("xp_amount", 0)


func get_gold_amount() -> int:
	"""Get gold amount for gold_reward encounters."""
	return data.get("gold_amount", 0)


func get_heal_percentage() -> float:
	"""Get heal percentage for health_restore encounters."""
	return data.get("heal_percentage", 0.0)


func get_shop_items() -> Array:
	"""Get items for sale in shop encounters."""
	return data.get("items", [])


func get_shop_skills() -> Array:
	"""Get skills for sale in shop encounters."""
	return data.get("skills", [])


func is_shop() -> bool:
	return type == "shop"


func is_character_shop() -> bool:
	return type == "character_shop"


func is_minigame() -> bool:
	return type == "minigame"


func is_health_restore() -> bool:
	return id == "health_restore"
