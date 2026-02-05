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

# Optional: injected data source for testing (Dependency Inversion)
var _game_data: Node = null


func _init(item_data_id: String, is_upgrade: bool = false, game_data = null) -> void:
	"""
	Initialize from item or item upgrade data.

	Args:
		item_data_id: Item or item upgrade ID from GameData
		is_upgrade: True to check upgrades first, false to check regular items first
		game_data: Optional injected GameData for testing (defaults to global autoload)
	"""
	_game_data = game_data
	item_id = item_data_id

	var gd = _get_game_data()
	if gd == null:
		# No game data available - leave fields empty for manual setup
		return

	# Try the specified type first, then fall back to the other
	var item_data: Dictionary
	if is_upgrade:
		item_data = gd.get_item_upgrade_by_id(item_id)
		if item_data.is_empty():
			item_data = gd.get_item_by_id(item_id)
	else:
		item_data = gd.get_item_by_id(item_id)
		if item_data.is_empty():
			item_data = gd.get_item_upgrade_by_id(item_id)

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


func _get_game_data():
	"""Get game data source (supports dependency injection)."""
	if _game_data != null:
		return _game_data
	# Try to get the autoload - may be null in test mode
	if Engine.has_singleton("GameData"):
		return Engine.get_singleton("GameData")
	# Check if it's available as an autoload node
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("/root/GameData"):
		return tree.root.get_node("/root/GameData")
	return null


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


static func from_dict(data: Dictionary, game_data = null) -> ItemInstance:
	"""Deserialize from save data."""
	var instance = ItemInstance.new(data.get("item_id", ""), false, game_data)
	# Data is already populated from GameData, but restore any runtime changes if needed
	return instance
