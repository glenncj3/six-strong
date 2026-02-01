class_name InventoryManager
extends RefCounted
## Wrapper around PlayerInventory adding Result-based error handling.
## Extracted from RunManager for SRP.

const ResultScript = preload("res://scripts/core/result.gd")
const ErrorCodesScript = preload("res://scripts/core/error_codes.gd")
const PlayerInventoryScript = preload("res://scripts/managers/player_inventory.gd")

signal item_acquired(item: ItemInstance)

var _inventory = null  # PlayerInventory instance


func _init() -> void:
	_inventory = PlayerInventoryScript.new()


func get_inventory():
	"""Get the underlying PlayerInventory."""
	return _inventory


func add_item_by_id(item_id: String, is_upgrade: bool = true):
	"""Add an item by ID. Returns Result with the ItemInstance."""
	if item_id.is_empty():
		return ResultScript.err(ErrorCodesScript.INVALID_ITEM, "Empty item ID")
	var item = _inventory.add_item_by_id(item_id, is_upgrade)
	if item == null:
		return ResultScript.err(ErrorCodesScript.INVALID_ITEM, "Invalid item ID: %s" % item_id)
	item_acquired.emit(item)
	return ResultScript.ok(item)


func remove_item(item_id: String):
	"""Remove item by ID. Returns Result."""
	if not _inventory.has_item(item_id):
		return ResultScript.err(ErrorCodesScript.ITEM_NOT_FOUND, "Item not in inventory: %s" % item_id)
	_inventory.remove_item(item_id)
	return ResultScript.ok()


func has_item(item_id: String) -> bool:
	return _inventory.has_item(item_id)


func get_all_items() -> Array:
	return _inventory.get_all_items()


func get_item_count_total() -> int:
	return _inventory.get_item_count_total()


func get_total_stat_modifier(stat_name: String) -> int:
	return _inventory.get_total_stat_modifier(stat_name)


func replace_item_with_upgrade(base_item_id: String, upgrade_id: String):
	"""Replace base item with upgrade. Returns Result with new ItemInstance."""
	var upgrade_item = _inventory.replace_item_with_upgrade(base_item_id, upgrade_id)
	if upgrade_item == null:
		return ResultScript.err(ErrorCodesScript.ITEM_NOT_FOUND, "Upgrade failed")
	item_acquired.emit(upgrade_item)
	return ResultScript.ok(upgrade_item)


func clear() -> void:
	_inventory.clear()


func to_dict() -> Dictionary:
	return _inventory.to_dict()


func load_from_dict(data: Dictionary) -> void:
	if data.has("items"):
		_inventory = PlayerInventoryScript.from_dict(data)
