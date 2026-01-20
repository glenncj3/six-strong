class_name EncounterOption
extends RefCounted
# EncounterOption - Typed data class for encounter options
# Replaces untyped Dictionary returns for better type safety and IDE support

var type: String = ""
var name: String = ""
var description: String = ""
var image_path: String = ""
var data: Dictionary = {}  # Type-specific data (items, skills, xp_amount, etc.)


static func create(
	p_type: String,
	p_name: String,
	p_description: String,
	p_image_path: String,
	p_data: Dictionary = {}
) -> EncounterOption:
	"""Factory method to create an EncounterOption."""
	var option = EncounterOption.new()
	option.type = p_type
	option.name = p_name
	option.description = p_description
	option.image_path = p_image_path
	option.data = p_data
	return option


func to_dict() -> Dictionary:
	"""Convert to dictionary for compatibility with existing code."""
	return {
		"type": type,
		"name": name,
		"description": description,
		"image_path": image_path,
		"data": data
	}


static func from_dict(dict: Dictionary) -> EncounterOption:
	"""Create from dictionary for loading saved data."""
	return create(
		dict.get("type", ""),
		dict.get("name", ""),
		dict.get("description", ""),
		dict.get("image_path", ""),
		dict.get("data", {})
	)


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


func is_xp_reward() -> bool:
	return type == "xp_reward"


func is_gold_reward() -> bool:
	return type == "gold_reward"


func is_health_restore() -> bool:
	return type == "health_restore"
