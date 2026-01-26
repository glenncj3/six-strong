extends SceneTree
## Functional tests for Gamble Encounter
## Tests the 50/50 wagering mechanic
##
## Run: godot --headless --script res://tests/functional/test_gamble_encounter.gd

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const GambleUIScript = preload("res://scripts/encounters/types/gamble_encounter_ui.gd")

var test_base: EncounterTestBase


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("GAMBLE ENCOUNTER - FUNCTIONAL TESTS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_ui_creation()
	_test_insufficient_gold_disables_button()
	_test_gamble_deducts_bet()
	_test_multiple_gamble_outcomes()

	_print_results()
	quit(test_base.tests_failed)


func _test_ui_creation():
	test_base.section("UI Creation")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var encounter_data = test_base.create_mock_encounter_data("gamble", {
		"bet": 20,
		"multiplier": 2.0
	})

	var ui = GambleUIScript.create_ui(encounter_data, context)

	test_base.assert_true(ui != null, "UI should be created")
	test_base.assert_true(ui is Control, "UI should be a Control node")

	# Find the gamble button
	var gamble_button = _find_button_by_text(ui, "GAMBLE")
	test_base.assert_true(gamble_button != null, "Should have GAMBLE button")

	if gamble_button:
		test_base.assert_false(gamble_button.disabled, "Button should be enabled when can afford bet")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_insufficient_gold_disables_button():
	test_base.section("Insufficient Gold")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 10  # Less than bet

	var encounter_data = test_base.create_mock_encounter_data("gamble", {
		"bet": 20,
		"multiplier": 2.0
	})

	var ui = GambleUIScript.create_ui(encounter_data, context)

	var gamble_button = _find_button_by_text(ui, "GAMBLE")
	if gamble_button:
		test_base.assert_true(gamble_button.disabled, "Button should be disabled when can't afford bet")
	else:
		test_base.assert_true(false, "Could not find GAMBLE button to test")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_gamble_deducts_bet():
	test_base.section("Bet Deduction")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var encounter_data = test_base.create_mock_encounter_data("gamble", {
		"bet": 25,
		"multiplier": 2.0
	})

	var ui = GambleUIScript.create_ui(encounter_data, context)

	# Simulate clicking the gamble button
	var gamble_button = _find_button_by_text(ui, "GAMBLE")
	if gamble_button and not gamble_button.disabled:
		gamble_button.pressed.emit()

		# Bet should be deducted regardless of win/loss
		test_base.assert_eq(test_base.mock_context["gold_spent"], 25, "Bet should be deducted")
		test_base.assert_encounter_completed("Should complete after gamble")
	else:
		test_base.assert_true(false, "Could not simulate gamble button press")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_multiple_gamble_outcomes():
	test_base.section("Gamble Outcomes (Statistical)")

	# Run multiple gambles to verify both win and loss are possible
	var wins := 0
	var losses := 0
	var iterations := 20

	for i in range(iterations):
		var context = test_base.create_mock_context()
		test_base.mock_context["player_gold"] = 100

		var encounter_data = test_base.create_mock_encounter_data("gamble", {
			"bet": 10,
			"multiplier": 2.0
		})

		var ui = GambleUIScript.create_ui(encounter_data, context)

		var gamble_button = _find_button_by_text(ui, "GAMBLE")
		if gamble_button and not gamble_button.disabled:
			gamble_button.pressed.emit()

			# Check outcome: if gold_rewarded > 0, it was a win
			if test_base.mock_context["gold_rewarded"] > 0:
				wins += 1
			else:
				losses += 1

		if ui and is_instance_valid(ui):
			ui.queue_free()

	# With 50/50 odds over 20 iterations, we should see both outcomes
	# (extremely unlikely to get all wins or all losses)
	test_base.assert_gt(wins, 0, "Should have at least one win in %d iterations" % iterations)
	test_base.assert_gt(losses, 0, "Should have at least one loss in %d iterations" % iterations)
	print("    INFO: Won %d, Lost %d out of %d gambles" % [wins, losses, iterations])


func _find_button_by_text(node: Node, text_contains: String) -> Button:
	"""Recursively find a button containing specific text."""
	if node is Button and text_contains.to_upper() in node.text.to_upper():
		return node

	for child in node.get_children():
		var found = _find_button_by_text(child, text_contains)
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
