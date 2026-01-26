class_name PlayerInventory
extends RefCounted
## Player-level item inventory for run progression.
## Items are owned by the player, not individual characters.
## No slot limit - items accumulate like relics in Slay the Spire.
## Item effects provide bonuses to all characters or player-level effects.

signal item_added(item: ItemInstance)
signal item_removed(item_id: String)
signal item_upgraded(old_item_id: String, new_item: ItemInstance)

var _items: Array[ItemInstance] = []


# =============================================================================
# ITEM MANAGEMENT
# =============================================================================

func add_item(item: ItemInstance) -> void:
	"""Add an item to the player's inventory."""
	if item == null:
		push_warning("PlayerInventory: Cannot add null item")
		return
	_items.append(item)
	item_added.emit(item)


func add_item_by_id(item_id: String, is_upgrade: bool = true) -> ItemInstance:
	"""
	Create and add an item by ID.

	Args:
		item_id: ID of the item in GameData
		is_upgrade: True for item upgrades (default), false for regular items

	Returns:
		The created ItemInstance, or null if item_id is invalid
	"""
	var item = ItemInstance.new(item_id, is_upgrade)
	if item.item_id.is_empty():
		push_warning("PlayerInventory: Invalid item ID: %s" % item_id)
		return null
	add_item(item)
	return item


func remove_item(item_id: String) -> bool:
	"""
	Remove the first item with the given ID from inventory.

	Returns:
		True if item was found and removed, false otherwise
	"""
	for i in range(_items.size()):
		if _items[i].item_id == item_id:
			_items.remove_at(i)
			item_removed.emit(item_id)
			return true
	return false


func remove_item_at(index: int) -> ItemInstance:
	"""
	Remove item at specific index.

	Returns:
		The removed item, or null if index is invalid
	"""
	if index < 0 or index >= _items.size():
		return null
	var item = _items[index]
	_items.remove_at(index)
	item_removed.emit(item.item_id)
	return item


func has_item(item_id: String) -> bool:
	"""Check if the player has an item with the given ID."""
	for item in _items:
		if item.item_id == item_id:
			return true
	return false


func get_item_count(item_id: String) -> int:
	"""Get the count of items with the given ID (for stackable items)."""
	var count = 0
	for item in _items:
		if item.item_id == item_id:
			count += 1
	return count


func get_all_items() -> Array[ItemInstance]:
	"""Get all items in the inventory."""
	return _items.duplicate()


func get_item_count_total() -> int:
	"""Get the total number of items in inventory."""
	return _items.size()


func clear() -> void:
	"""Remove all items from inventory."""
	_items.clear()


# =============================================================================
# ITEM UPGRADES
# =============================================================================

func replace_item_with_upgrade(base_item_id: String, upgrade_id: String) -> ItemInstance:
	"""
	Replace a base item with its upgrade.

	The base item is removed and the upgrade is added in its place.

	Args:
		base_item_id: ID of the base item to replace (must be in inventory)
		upgrade_id: ID of the item upgrade to add

	Returns:
		The new ItemInstance if successful, null if base item not found
	"""
	# Verify the player has the base item
	if not has_item(base_item_id):
		push_warning("PlayerInventory: Cannot upgrade - base item not in inventory: %s" % base_item_id)
		return null

	# Remove the base item
	remove_item(base_item_id)

	# Add the upgrade (is_upgrade = true)
	var upgrade_item = ItemInstance.new(upgrade_id, true)
	if upgrade_item.item_id.is_empty():
		push_warning("PlayerInventory: Invalid upgrade ID: %s" % upgrade_id)
		# Try to restore the base item
		add_item_by_id(base_item_id, false)
		return null

	add_item(upgrade_item)
	item_upgraded.emit(base_item_id, upgrade_item)
	return upgrade_item


# =============================================================================
# STAT AGGREGATION
# =============================================================================

func get_total_stat_modifier(stat_name: String) -> int:
	"""
	Get the total modifier for a stat from all items.
	Items provide bonuses to all characters via this aggregation.

	Args:
		stat_name: The stat name to aggregate (e.g., "health", "mana")

	Returns:
		Total modifier value from all items
	"""
	var total = 0
	for item in _items:
		total += item.stat_modifiers.get(stat_name, 0)
	return total


func get_all_stat_modifiers() -> Dictionary:
	"""
	Get all stat modifiers aggregated from all items.

	Returns:
		Dictionary of stat_name -> total_modifier
	"""
	var modifiers: Dictionary = {}
	for item in _items:
		for stat_name in item.stat_modifiers:
			if not modifiers.has(stat_name):
				modifiers[stat_name] = 0
			modifiers[stat_name] += item.stat_modifiers[stat_name]
	return modifiers


# =============================================================================
# FILTERING
# =============================================================================

func get_items_by_slot(slot: String) -> Array[ItemInstance]:
	"""Get all items that match a specific slot."""
	var result: Array[ItemInstance] = []
	for item in _items:
		if item.slot == slot:
			result.append(item)
	return result


func get_items_with_stat(stat_name: String) -> Array[ItemInstance]:
	"""Get all items that have a specific stat modifier."""
	var result: Array[ItemInstance] = []
	for item in _items:
		if item.stat_modifiers.has(stat_name) and item.stat_modifiers[stat_name] != 0:
			result.append(item)
	return result


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize inventory to dictionary for saving."""
	var items_data: Array = []
	for item in _items:
		items_data.append(item.to_dict())
	return {
		"items": items_data
	}


static func from_dict(data: Dictionary):
	"""Deserialize inventory from save data."""
	var script = load("res://scripts/managers/player_inventory.gd")
	var inventory = script.new()
	var items_data = data.get("items", [])
	for item_data in items_data:
		var item = ItemInstance.from_dict(item_data)
		if item != null:
			inventory._items.append(item)
	return inventory


func to_array() -> Array:
	"""Serialize to array of item dictionaries (alternative format)."""
	var result: Array = []
	for item in _items:
		result.append(item.to_dict())
	return result


func load_from_array(items_data: Array) -> void:
	"""Load items from array of dictionaries."""
	_items.clear()
	for item_data in items_data:
		var item = ItemInstance.from_dict(item_data)
		if item != null:
			_items.append(item)
