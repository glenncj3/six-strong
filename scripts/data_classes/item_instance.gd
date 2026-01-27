class_name ItemInstance
extends RefCounted
# ItemInstance - Runtime representation of an item during a run
# Phase 2 Refactor: Items are now player-owned, not character-owned.
# Items are stored in PlayerInventory and provide team-wide bonuses.

var item_id: String = ""
var name: String = ""
var description: String = ""
var image_path: String = ""
var stat_modifiers: Dictionary = {}
var slot: String = ""  # For regular items, not upgrades


func _init(item_data_id: String, is_upgrade: bool = false) -> void:
	"""
	Initialize from item or item upgrade data.

	Args:
		item_data_id: Item or item upgrade ID from GameData
		is_upgrade: True if this is an item upgrade, false for regular item
	"""
	item_id = item_data_id

	var item_data: Dictionary
	if is_upgrade:
		item_data = GameData.get_item_upgrade_by_id(item_id)
	else:
		item_data = GameData.get_item_by_id(item_id)

	if item_data.is_empty():
		push_error("ItemInstance: Item data not found: %s" % item_id)
		item_id = ""  # Clear item_id to indicate invalid item
		return

	name = item_data.get("name", "Unknown Item")
	description = item_data.get("description", "")
	image_path = item_data.get("image_path", "")

	if item_data.has("stat_modifiers"):
		stat_modifiers = item_data["stat_modifiers"].duplicate()

	if item_data.has("slot"):
		slot = item_data["slot"]
	elif item_data.has("replaces_slot"):
		slot = item_data["replaces_slot"]


func to_dict() -> Dictionary:
	"""Serialize for saving."""
	return {
		"item_id": item_id,
		"name": name,
		"description": description,
		"image_path": image_path,
		"stat_modifiers": stat_modifiers,
		"slot": slot
	}


static func from_dict(data: Dictionary) -> ItemInstance:
	"""Deserialize from save data."""
	var instance = ItemInstance.new(data.get("item_id", ""))
	# Data is already populated from GameData, but restore any runtime changes if needed
	return instance
