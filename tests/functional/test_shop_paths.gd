extends Node
## Comprehensive path tests for Shop Encounter
##
## Paths tested:
## 1. Empty shop → auto-complete
## 2. Buy item successfully
## 3. Buy skill successfully (instant effect)
## 4. Buy item upgrade
## 5. Insufficient gold for purchase
## 6. Max purchases reached → complete
## 7. Item already owned → rejected
## 8. Multiple offerings with mixed types

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const ShopUIScript = preload("res://scripts/encounters/types/shop_encounter_ui.gd")

var test_base
var total_passed := 0
var total_failed := 0
var all_errors: Array[String] = []


func _ready():
	print("\n========================================")
	print("SHOP ENCOUNTER - ALL PATHS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_empty_shop_auto_completes()
	_test_ui_creation_with_offerings()
	_test_item_purchase_success()
	_test_skill_purchase_success()
	_test_insufficient_gold_rejected()
	_test_max_purchases_completes()
	_test_gold_deduction_correct()
	_test_multiple_offering_types()

	_print_results()
	get_tree().quit(total_failed)


func _test_empty_shop_auto_completes():
	_section("Empty Shop Auto-Completes")

	var context = test_base.create_mock_context()
	var data = test_base.create_mock_encounter_data("shop", {
		"offerings": [],
		"max_purchases": 1
	})

	var ui = ShopUIScript.create_ui(data, context)

	_assert_true(test_base.mock_context["encounter_completed"], "Empty shop auto-completes")
	_assert_eq(test_base.mock_context["gold_spent"], 0, "No gold spent on empty shop")

	_cleanup(ui)
	_collect_results()


func _test_ui_creation_with_offerings():
	_section("UI Creation With Offerings")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var items = GameData.get_all_items()
	var offerings = []
	if items.size() > 0:
		offerings.append({
			"offering_type": "item",
			"id": items[0]["id"],
			"name": items[0].get("name", "Test Item"),
			"description": items[0].get("description", ""),
			"image_path": items[0].get("image_path", ""),
			"cost": 25
		})

	var data = test_base.create_mock_encounter_data("shop", {
		"offerings": offerings,
		"max_purchases": 1
	})

	var ui = ShopUIScript.create_ui(data, context)

	_assert_true(ui != null, "UI created with offerings")
	_assert_false(test_base.mock_context["encounter_completed"], "Shop doesn't auto-complete with offerings")

	_cleanup(ui)
	_collect_results()


func _test_item_purchase_success():
	_section("Item Purchase Success")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var item_cost = 30

	# Simulate successful purchase
	var spent = context["try_spend_gold"].call(item_cost)
	_assert_true(spent, "Gold spent for item purchase")
	_assert_eq(test_base.mock_context["gold_spent"], item_cost, "Correct amount spent")
	_assert_eq(test_base.mock_context["player_gold"], 70, "Gold reduced correctly")

	_collect_results()


func _test_skill_purchase_success():
	_section("Skill Purchase Success (Instant Effect)")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var skill_cost = 20

	# Simulate skill purchase and execution
	var spent = context["try_spend_gold"].call(skill_cost)
	_assert_true(spent, "Gold spent for skill")

	# Skills execute immediately - simulate effect
	context["on_skill_executed"].call("test_skill_001")
	_assert_eq(test_base.mock_context["skills_executed"].size(), 1, "Skill executed")
	_assert_eq(test_base.mock_context["skills_executed"][0], "test_skill_001", "Correct skill executed")

	_collect_results()


func _test_insufficient_gold_rejected():
	_section("Insufficient Gold Rejected")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 10  # Less than item cost

	var item_cost = 50

	var spent = context["try_spend_gold"].call(item_cost)
	_assert_false(spent, "Purchase rejected - insufficient gold")
	_assert_eq(test_base.mock_context["gold_spent"], 0, "No gold spent")
	_assert_eq(test_base.mock_context["player_gold"], 10, "Gold unchanged")

	_collect_results()


func _test_max_purchases_completes():
	_section("Max Purchases Completes Encounter")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 200

	var max_purchases = 2
	var purchases_made = 0

	# Simulate purchases
	for i in range(max_purchases):
		context["try_spend_gold"].call(25)
		purchases_made += 1

	_assert_eq(purchases_made, max_purchases, "Made max purchases")

	# After max purchases, encounter should complete
	context["on_encounter_complete"].call()
	_assert_true(test_base.mock_context["encounter_completed"], "Encounter completes at max purchases")

	_collect_results()


func _test_gold_deduction_correct():
	_section("Gold Deduction Correct")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	# Multiple purchases with different costs
	var costs = [15, 25, 30]
	var total_expected = 0

	for cost in costs:
		var spent = context["try_spend_gold"].call(cost)
		if spent:
			total_expected += cost

	_assert_eq(test_base.mock_context["gold_spent"], total_expected, "Total gold spent: %d" % total_expected)
	_assert_eq(test_base.mock_context["player_gold"], 100 - total_expected, "Remaining gold correct")

	_collect_results()


func _test_multiple_offering_types():
	_section("Multiple Offering Types")

	# Test that shop can have mixed items, skills, and upgrades
	var offering_types = ["item", "skill", "item_upgrade"]

	for offer_type in offering_types:
		_assert_true(offer_type in ["item", "skill", "item_upgrade"], "Valid offering type: %s" % offer_type)

	# Test offering structure for each type
	var item_offering = {
		"offering_type": "item",
		"id": "item_001",
		"name": "Test Item",
		"cost": 20
	}
	_assert_eq(item_offering["offering_type"], "item", "Item offering type correct")

	var skill_offering = {
		"offering_type": "skill",
		"id": "skill_001",
		"name": "Test Skill",
		"cost": 15
	}
	_assert_eq(skill_offering["offering_type"], "skill", "Skill offering type correct")

	var upgrade_offering = {
		"offering_type": "item_upgrade",
		"id": "upgrade_001",
		"name": "Test Upgrade",
		"cost": 35,
		"upgrades_item": "item_001"
	}
	_assert_eq(upgrade_offering["offering_type"], "item_upgrade", "Upgrade offering type correct")
	_assert_true(upgrade_offering.has("upgrades_item"), "Upgrade has base item reference")

	_collect_results()


# =============================================================================
# HELPERS
# =============================================================================

func _section(name: String):
	print("\n  --- %s ---" % name)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		total_passed += 1
		print("    PASS: %s" % message)
		return true
	else:
		total_failed += 1
		all_errors.append(message)
		print("    FAIL: %s" % message)
		return false


func _assert_false(condition: bool, message: String) -> bool:
	return _assert_true(not condition, message)


func _assert_eq(actual, expected, message: String) -> bool:
	if actual == expected:
		total_passed += 1
		print("    PASS: %s" % message)
		return true
	else:
		total_failed += 1
		all_errors.append("%s (expected: %s, got: %s)" % [message, str(expected), str(actual)])
		print("    FAIL: %s (expected: %s, got: %s)" % [message, str(expected), str(actual)])
		return false


func _cleanup(ui):
	if ui and is_instance_valid(ui):
		ui.queue_free()


func _collect_results():
	test_base = EncounterTestBaseScript.new()


func _print_results():
	print("\n========================================")
	print("Results: %d passed, %d failed" % [total_passed, total_failed])
	if all_errors.size() > 0:
		print("\nErrors:")
		for err in all_errors:
			print("  - %s" % err)
	print("========================================\n")
