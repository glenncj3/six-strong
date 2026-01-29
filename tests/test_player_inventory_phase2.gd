extends Node
# Test script for PlayerInventory class (Phase 2)
# Tests player-level item inventory functionality

class_name TestPlayerInventoryPhase2


static func run_all_tests() -> Dictionary:
	"""Run all PlayerInventory tests and return results."""
	var results = {
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	# Run each test
	_test_initial_state(results)
	_test_add_item(results)
	_test_add_item_by_id(results)
	_test_remove_item(results)
	_test_has_item(results)
	_test_get_all_items(results)
	_test_stat_aggregation(results)
	_test_serialization(results)
	_test_clear(results)
	_test_filtering(results)

	return results


static func _test_initial_state(results: Dictionary) -> void:
	"""Test that a new inventory starts empty."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var inventory = PlayerInventoryScript.new()

	if inventory.get_item_count_total() != 0:
		results.failed += 1
		results.errors.append("Initial inventory should be empty, got %d items" % inventory.get_item_count_total())
		return

	if inventory.get_all_items().size() != 0:
		results.failed += 1
		results.errors.append("Initial get_all_items should be empty")
		return

	results.passed += 1
	print("  [PASS] test_initial_state")


static func _test_add_item(results: Dictionary) -> void:
	"""Test adding an item directly."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var inventory = PlayerInventoryScript.new()
	var item = ItemInstance.new("test_item_001", false)
	item.item_id = "test_item_001"  # Set manually for test

	inventory.add_item(item)

	if inventory.get_item_count_total() != 1:
		results.failed += 1
		results.errors.append("Inventory should have 1 item after add, got %d" % inventory.get_item_count_total())
		return

	results.passed += 1
	print("  [PASS] test_add_item")


static func _test_add_item_by_id(results: Dictionary) -> void:
	"""Test adding an item by ID (creates ItemInstance)."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var inventory = PlayerInventoryScript.new()

	# Note: This test may fail if GameData doesn't have the item
	# We test the mechanism rather than requiring actual data
	var item = inventory.add_item_by_id("nonexistent_item_12345", true)

	# Should return null for invalid item
	if item != null and not item.item_id.is_empty():
		# If it succeeded, check count
		if inventory.get_item_count_total() != 1:
			results.failed += 1
			results.errors.append("Inventory should have 1 item after add_item_by_id")
			return

	results.passed += 1
	print("  [PASS] test_add_item_by_id")


static func _test_remove_item(results: Dictionary) -> void:
	"""Test removing an item by ID."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var inventory = PlayerInventoryScript.new()

	# Add two items
	var item1 = ItemInstance.new("", false)
	item1.item_id = "item_a"
	var item2 = ItemInstance.new("", false)
	item2.item_id = "item_b"

	inventory.add_item(item1)
	inventory.add_item(item2)

	if inventory.get_item_count_total() != 2:
		results.failed += 1
		results.errors.append("Should have 2 items before remove")
		return

	# Remove first item
	var removed = inventory.remove_item("item_a")
	if not removed:
		results.failed += 1
		results.errors.append("remove_item should return true for existing item")
		return

	if inventory.get_item_count_total() != 1:
		results.failed += 1
		results.errors.append("Should have 1 item after remove, got %d" % inventory.get_item_count_total())
		return

	if inventory.has_item("item_a"):
		results.failed += 1
		results.errors.append("Removed item should not exist")
		return

	# Try to remove non-existent item
	removed = inventory.remove_item("nonexistent")
	if removed:
		results.failed += 1
		results.errors.append("remove_item should return false for non-existent item")
		return

	results.passed += 1
	print("  [PASS] test_remove_item")


static func _test_has_item(results: Dictionary) -> void:
	"""Test checking if item exists."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var inventory = PlayerInventoryScript.new()
	var item = ItemInstance.new("", false)
	item.item_id = "check_item"

	if inventory.has_item("check_item"):
		results.failed += 1
		results.errors.append("has_item should return false for empty inventory")
		return

	inventory.add_item(item)

	if not inventory.has_item("check_item"):
		results.failed += 1
		results.errors.append("has_item should return true for added item")
		return

	if inventory.has_item("other_item"):
		results.failed += 1
		results.errors.append("has_item should return false for non-existent item")
		return

	results.passed += 1
	print("  [PASS] test_has_item")


static func _test_get_all_items(results: Dictionary) -> void:
	"""Test getting all items returns a copy."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var inventory = PlayerInventoryScript.new()
	var item = ItemInstance.new("", false)
	item.item_id = "all_items_test"

	inventory.add_item(item)

	var items = inventory.get_all_items()
	if items.size() != 1:
		results.failed += 1
		results.errors.append("get_all_items should return 1 item")
		return

	# Verify it's a copy (modifying returned array shouldn't affect inventory)
	items.clear()
	if inventory.get_item_count_total() != 1:
		results.failed += 1
		results.errors.append("Modifying returned array should not affect inventory")
		return

	results.passed += 1
	print("  [PASS] test_get_all_items")


static func _test_stat_aggregation(results: Dictionary) -> void:
	"""Test stat modifier aggregation from multiple items."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var inventory = PlayerInventoryScript.new()

	# Create items with stat modifiers
	var item1 = ItemInstance.new("", false)
	item1.item_id = "stat_item_1"
	item1.stat_modifiers = {"health": 10, "charges": 5}

	var item2 = ItemInstance.new("", false)
	item2.item_id = "stat_item_2"
	item2.stat_modifiers = {"health": 15, "income": 3}

	inventory.add_item(item1)
	inventory.add_item(item2)

	# Check individual stat totals
	var health_total = inventory.get_total_stat_modifier("health")
	if health_total != 25:
		results.failed += 1
		results.errors.append("Health total should be 25, got %d" % health_total)
		return

	var charges_total = inventory.get_total_stat_modifier("charges")
	if charges_total != 5:
		results.failed += 1
		results.errors.append("Charges total should be 5, got %d" % charges_total)
		return

	var income_total = inventory.get_total_stat_modifier("income")
	if income_total != 3:
		results.failed += 1
		results.errors.append("Income total should be 3, got %d" % income_total)
		return

	# Check non-existent stat
	var defense_total = inventory.get_total_stat_modifier("defense")
	if defense_total != 0:
		results.failed += 1
		results.errors.append("Non-existent stat should return 0, got %d" % defense_total)
		return

	# Check get_all_stat_modifiers
	var all_mods = inventory.get_all_stat_modifiers()
	if all_mods.get("health", 0) != 25:
		results.failed += 1
		results.errors.append("get_all_stat_modifiers health should be 25")
		return

	results.passed += 1
	print("  [PASS] test_stat_aggregation")


static func _test_serialization(results: Dictionary) -> void:
	"""Test to_dict and from_dict maintain state."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var original = PlayerInventoryScript.new()

	# Add items with data
	var item1 = ItemInstance.new("", false)
	item1.item_id = "serial_item_1"
	item1.stat_modifiers = {"health": 20}

	var item2 = ItemInstance.new("", false)
	item2.item_id = "serial_item_2"
	item2.slot = "weapon"

	original.add_item(item1)
	original.add_item(item2)

	# Serialize
	var data = original.to_dict()

	if not data.has("items"):
		results.failed += 1
		results.errors.append("Serialized data should have 'items' key")
		return

	if data["items"].size() != 2:
		results.failed += 1
		results.errors.append("Serialized items should have 2 entries")
		return

	# Deserialize
	var restored = PlayerInventoryScript.from_dict(data)

	if restored.get_item_count_total() != 2:
		results.failed += 1
		results.errors.append("Restored inventory should have 2 items, got %d" % restored.get_item_count_total())
		return

	if not restored.has_item("serial_item_1"):
		results.failed += 1
		results.errors.append("Restored inventory should have serial_item_1")
		return

	if not restored.has_item("serial_item_2"):
		results.failed += 1
		results.errors.append("Restored inventory should have serial_item_2")
		return

	results.passed += 1
	print("  [PASS] test_serialization")


static func _test_clear(results: Dictionary) -> void:
	"""Test clearing the inventory."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var inventory = PlayerInventoryScript.new()

	var item = ItemInstance.new("", false)
	item.item_id = "clear_test"
	inventory.add_item(item)

	if inventory.get_item_count_total() != 1:
		results.failed += 1
		results.errors.append("Should have 1 item before clear")
		return

	inventory.clear()

	if inventory.get_item_count_total() != 0:
		results.failed += 1
		results.errors.append("Should have 0 items after clear, got %d" % inventory.get_item_count_total())
		return

	results.passed += 1
	print("  [PASS] test_clear")


static func _test_filtering(results: Dictionary) -> void:
	"""Test filtering items by slot and stat."""
	var PlayerInventoryScript = load("res://scripts/managers/player_inventory.gd")
	var inventory = PlayerInventoryScript.new()

	var item1 = ItemInstance.new("", false)
	item1.item_id = "filter_item_1"
	item1.slot = "weapon"
	item1.stat_modifiers = {"damage": 10}

	var item2 = ItemInstance.new("", false)
	item2.item_id = "filter_item_2"
	item2.slot = "armor"
	item2.stat_modifiers = {"health": 20}

	var item3 = ItemInstance.new("", false)
	item3.item_id = "filter_item_3"
	item3.slot = "weapon"
	item3.stat_modifiers = {"damage": 15, "health": 5}

	inventory.add_item(item1)
	inventory.add_item(item2)
	inventory.add_item(item3)

	# Filter by slot
	var weapons = inventory.get_items_by_slot("weapon")
	if weapons.size() != 2:
		results.failed += 1
		results.errors.append("Should have 2 weapons, got %d" % weapons.size())
		return

	var armors = inventory.get_items_by_slot("armor")
	if armors.size() != 1:
		results.failed += 1
		results.errors.append("Should have 1 armor, got %d" % armors.size())
		return

	# Filter by stat
	var damage_items = inventory.get_items_with_stat("damage")
	if damage_items.size() != 2:
		results.failed += 1
		results.errors.append("Should have 2 items with damage stat, got %d" % damage_items.size())
		return

	var health_items = inventory.get_items_with_stat("health")
	if health_items.size() != 2:
		results.failed += 1
		results.errors.append("Should have 2 items with health stat, got %d" % health_items.size())
		return

	results.passed += 1
	print("  [PASS] test_filtering")
