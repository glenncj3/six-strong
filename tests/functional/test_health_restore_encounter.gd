extends SceneTree
## Functional tests for Health Restore Encounter
## Tests character healing selection flow
##
## Run: godot --headless --script res://tests/functional/test_health_restore_encounter.gd

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const HealthRestoreUIScript = preload("res://scripts/encounters/types/health_restore_encounter_ui.gd")

var test_base: EncounterTestBase


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("HEALTH RESTORE ENCOUNTER - FUNCTIONAL TESTS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_empty_options_auto_completes()
	_test_ui_creation_with_options()
	_test_heal_option_structure()
	_test_healing_callback()
	_test_gold_cost_for_healing()

	_print_results()
	quit(test_base.tests_failed)


func _test_empty_options_auto_completes():
	test_base.section("Empty Options Auto-Completion")

	var context = test_base.create_mock_context()
	var encounter_data = test_base.create_mock_encounter_data("health_restore", {
		"heal_options": []
	})

	var ui = HealthRestoreUIScript.create_ui(encounter_data, context)

	test_base.assert_encounter_completed("Empty heal options should auto-complete")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_ui_creation_with_options():
	test_base.section("UI Creation With Options")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var encounter_data = test_base.create_mock_encounter_data("health_restore", {
		"heal_options": [
			{"heal_amount": 20, "cost": 10},
			{"heal_amount": 50, "cost": 25},
			{"heal_amount": 100, "cost": 50}
		]
	})

	var ui = HealthRestoreUIScript.create_ui(encounter_data, context)

	test_base.assert_true(ui != null, "UI should be created")
	test_base.assert_true(ui is Control, "UI should be a Control node")
	test_base.assert_encounter_not_completed("Should not auto-complete with heal options")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_heal_option_structure():
	test_base.section("Heal Option Structure")

	var context = test_base.create_mock_context()

	var heal_options = [
		{"heal_amount": 20, "cost": 10},
		{"heal_amount": 50, "cost": 25}
	]

	var encounter_data = test_base.create_mock_encounter_data("health_restore", {
		"heal_options": heal_options
	})

	var ui = HealthRestoreUIScript.create_ui(encounter_data, context)

	# Verify heal options are valid
	for option in heal_options:
		test_base.assert_true(option.has("heal_amount"), "Option should have heal_amount")
		test_base.assert_true(option.has("cost"), "Option should have cost")
		test_base.assert_gt(option["heal_amount"], 0, "Heal amount should be positive")
		test_base.assert_gte(option["cost"], 0, "Cost should be non-negative")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_healing_callback():
	test_base.section("Healing Callback")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	# Get a team member to heal
	var team = test_base.mock_context["team"]
	if team.size() == 0:
		test_base.assert_true(false, "No team members for healing test")
		return

	var character = team[0]
	var heal_amount = 30

	# Simulate healing callback directly
	context["on_health_restore"].call(character, heal_amount)

	test_base.assert_eq(test_base.mock_context["health_restored"].size(), 1, "Should have 1 heal record")

	var heal_record = test_base.mock_context["health_restored"][0]
	test_base.assert_eq(heal_record["character"], character, "Should heal correct character")
	test_base.assert_eq(heal_record["amount"], heal_amount, "Should heal correct amount")


func _test_gold_cost_for_healing():
	test_base.section("Gold Cost For Healing")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 50

	# Test spending gold for healing
	var heal_cost = 25
	var result = context["try_spend_gold"].call(heal_cost)

	test_base.assert_true(result, "Should be able to spend gold")
	test_base.assert_eq(test_base.mock_context["player_gold"], 25, "Should have 25 gold remaining")
	test_base.assert_eq(test_base.mock_context["gold_spent"], 25, "Should record 25 gold spent")

	# Test insufficient gold
	var result2 = context["try_spend_gold"].call(50)  # More than remaining
	test_base.assert_false(result2, "Should not spend more than available")
	test_base.assert_eq(test_base.mock_context["player_gold"], 25, "Gold unchanged after failed spend")


func _print_results():
	var results = test_base.get_results()
	print("\n========================================")
	print("Results: %d passed, %d failed" % [results.passed, results.failed])
	if results.errors.size() > 0:
		print("\nErrors:")
		for err in results.errors:
			print("  - %s" % err)
	print("========================================\n")
