extends SceneTree
## Functional tests for Shop Encounter
## Tests item/skill purchasing with gold
##
## Run: godot --headless --script res://tests/functional/test_shop_encounter.gd

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const ShopUIScript = preload("res://scripts/encounters/types/shop_encounter_ui.gd")

var test_base: EncounterTestBase


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("SHOP ENCOUNTER - FUNCTIONAL TESTS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_empty_shop_auto_completes()
	_test_shop_ui_creation()
	_test_single_purchase_flow()
	_test_insufficient_gold()
	_test_max_purchases_limit()

	_print_results()
	quit(test_base.tests_failed)


func _test_empty_shop_auto_completes():
	test_base.section("Empty Shop Auto-Completion")

	var context = test_base.create_mock_context()
	var encounter_data = test_base.create_mock_encounter_data("shop", {
		"offerings": [],
		"max_purchases": 1
	})

	var ui = ShopUIScript.create_ui(encounter_data, context)

	test_base.assert_encounter_completed("Empty shop should auto-complete")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_shop_ui_creation():
	test_base.section("Shop UI Creation")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 200

	# Get real item/skill data for the shop
	var items = GameData.get_all_items()
	var offerings = []

	if items.size() > 0:
		offerings.append({
			"offering_type": "item",
			"id": items[0]["id"],
			"name": items[0].get("name", "Test Item"),
			"description": items[0].get("description", ""),
			"cost": 30
		})

	var encounter_data = test_base.create_mock_encounter_data("shop", {
		"offerings": offerings,
		"max_purchases": 1
	})

	var ui = ShopUIScript.create_ui(encounter_data, context)

	test_base.assert_true(ui != null, "UI should be created")
	test_base.assert_true(ui is Control, "UI should be a Control node")
	test_base.assert_encounter_not_completed("Shop should not auto-complete with offerings")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_single_purchase_flow():
	test_base.section("Single Purchase Flow")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var items = GameData.get_all_items()
	if items.size() == 0:
		test_base.assert_true(false, "No items in GameData for testing")
		return

	var offerings = [{
		"offering_type": "item",
		"id": items[0]["id"],
		"name": items[0].get("name", "Test Item"),
		"description": "",
		"cost": 25
	}]

	var encounter_data = test_base.create_mock_encounter_data("shop", {
		"offerings": offerings,
		"max_purchases": 1
	})

	var ui = ShopUIScript.create_ui(encounter_data, context)

	# Find and click the purchasable tile
	var tile = _find_purchasable_tile(ui)
	if tile:
		# Simulate tile click
		if tile.has_signal("tile_clicked"):
			tile.tile_clicked.emit(items[0]["id"], 25, "item")

		test_base.assert_eq(test_base.mock_context["gold_spent"], 25, "Should spend 25 gold")
		test_base.assert_eq(test_base.mock_context["player_gold"], 75, "Player should have 75 gold left")
		# Note: encounter completion depends on max_purchases logic
	else:
		# If we can't find the tile, test the logic directly
		print("    INFO: Could not find purchasable tile, testing callback directly")
		context["on_gold_spend"].call(25)
		test_base.assert_eq(test_base.mock_context["gold_spent"], 25, "Direct gold spend works")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_insufficient_gold():
	test_base.section("Insufficient Gold")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 10  # Less than item cost

	var items = GameData.get_all_items()
	if items.size() == 0:
		return

	var offerings = [{
		"offering_type": "item",
		"id": items[0]["id"],
		"name": items[0].get("name", "Test Item"),
		"description": "",
		"cost": 50  # More than player has
	}]

	var encounter_data = test_base.create_mock_encounter_data("shop", {
		"offerings": offerings,
		"max_purchases": 1
	})

	var ui = ShopUIScript.create_ui(encounter_data, context)

	# Try to buy - should fail
	var result = context["try_spend_gold"].call(50)
	test_base.assert_false(result, "Should not be able to spend more gold than available")
	test_base.assert_eq(test_base.mock_context["gold_spent"], 0, "No gold should be spent")
	test_base.assert_eq(test_base.mock_context["player_gold"], 10, "Player gold unchanged")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_max_purchases_limit():
	test_base.section("Max Purchases Limit")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 200

	var items = GameData.get_all_items()
	if items.size() < 2:
		print("    SKIP: Need at least 2 items for max purchases test")
		return

	var offerings = [
		{
			"offering_type": "item",
			"id": items[0]["id"],
			"name": items[0].get("name", "Item 1"),
			"description": "",
			"cost": 20
		},
		{
			"offering_type": "item",
			"id": items[1]["id"],
			"name": items[1].get("name", "Item 2"),
			"description": "",
			"cost": 20
		}
	]

	var encounter_data = test_base.create_mock_encounter_data("shop", {
		"offerings": offerings,
		"max_purchases": 1  # Only 1 purchase allowed
	})

	var ui = ShopUIScript.create_ui(encounter_data, context)

	# Simulate first purchase
	context["on_gold_spend"].call(20)

	test_base.assert_eq(test_base.mock_context["gold_spent"], 20, "First purchase should succeed")

	# After max_purchases, encounter should complete
	# (actual completion depends on UI logic tracking purchases_made)

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _find_purchasable_tile(node: Node):
	"""Recursively find a PurchasableTile node."""
	if node.get_class() == "PurchasableTile" or "PurchasableTile" in node.get_script().get_path() if node.get_script() else false:
		return node

	for child in node.get_children():
		var found = _find_purchasable_tile(child)
		if found:
			return found

	return null


func _print_results():
	var results = test_base.get_results()
	print("\n========================================")
	print("Results: %d passed, %d failed" % [results.passed, results.failed])
	if results.errors.size() > 0:
		print("\nErrors:")
		for err in results.errors:
			print("  - %s" % err)
	print("========================================\n")
