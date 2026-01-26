extends SceneTree
## Functional tests for Gold Reward Encounter
## Tests the simplest encounter type - automatic gold reward
##
## Run: godot --headless --script res://tests/functional/test_gold_reward_encounter.gd

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const GoldRewardUIScript = preload("res://scripts/encounters/types/gold_reward_encounter_ui.gd")

var test_base: EncounterTestBase


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("GOLD REWARD ENCOUNTER - FUNCTIONAL TESTS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_basic_gold_reward()
	_test_zero_gold_reward()
	_test_large_gold_reward()
	_test_auto_completion()

	_print_results()
	quit(test_base.tests_failed)


func _test_basic_gold_reward():
	test_base.section("Basic Gold Reward")

	var context = test_base.create_mock_context()
	var encounter_data = test_base.create_mock_encounter_data("gold_reward", {
		"gold_amount": 50
	})

	# Create the UI (this should auto-reward and complete)
	var ui = GoldRewardUIScript.create_ui(encounter_data, context)

	test_base.assert_gold_rewarded(50, "Should reward 50 gold")
	test_base.assert_encounter_completed("Should auto-complete")
	test_base.assert_eq(test_base.mock_context["player_gold"], 150, "Player gold should be 100 + 50")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_zero_gold_reward():
	test_base.section("Zero Gold Reward")

	var context = test_base.create_mock_context()
	var encounter_data = test_base.create_mock_encounter_data("gold_reward", {
		"gold_amount": 0
	})

	var ui = GoldRewardUIScript.create_ui(encounter_data, context)

	test_base.assert_gold_rewarded(0, "Should reward 0 gold")
	test_base.assert_encounter_completed("Should still auto-complete with 0 gold")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_large_gold_reward():
	test_base.section("Large Gold Reward")

	var context = test_base.create_mock_context()
	var encounter_data = test_base.create_mock_encounter_data("gold_reward", {
		"gold_amount": 999
	})

	var ui = GoldRewardUIScript.create_ui(encounter_data, context)

	test_base.assert_gold_rewarded(999, "Should reward 999 gold")
	test_base.assert_eq(test_base.mock_context["player_gold"], 1099, "Player gold should be 100 + 999")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_auto_completion():
	test_base.section("Auto Completion Behavior")

	var context = test_base.create_mock_context()
	var encounter_data = test_base.create_mock_encounter_data("gold_reward", {
		"gold_amount": 25
	})

	# Verify completion happens exactly once
	var ui = GoldRewardUIScript.create_ui(encounter_data, context)

	test_base.assert_eq(test_base.mock_context["completion_count"], 1, "Should complete exactly once")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _print_results():
	var results = test_base.get_results()
	print("\n========================================")
	print("Results: %d passed, %d failed" % [results.passed, results.failed])
	if results.errors.size() > 0:
		print("\nErrors:")
		for err in results.errors:
			print("  - %s" % err)
	print("========================================\n")
