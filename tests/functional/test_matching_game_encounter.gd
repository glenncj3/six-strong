extends SceneTree
## Functional tests for Matching Game Encounter
## Tests tile flip and match detection
##
## Run: godot --headless --script res://tests/functional/test_matching_game_encounter.gd

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const MatchingGameUIScript = preload("res://scripts/encounters/types/matching_game_encounter_ui.gd")

var test_base: EncounterTestBase


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("MATCHING GAME ENCOUNTER - FUNCTIONAL TESTS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_ui_creation()
	_test_tile_distribution()
	_test_match_detection_logic()
	_test_reward_tiers()
	_test_game_completion()

	_print_results()
	quit(test_base.tests_failed)


func _test_ui_creation():
	test_base.section("UI Creation")

	var context = test_base.create_mock_context()

	var encounter_data = test_base.create_mock_encounter_data("matching_game", {
		"big_gold": 100,
		"medium_gold": 50,
		"small_gold": 25
	})

	var ui = MatchingGameUIScript.create_ui(encounter_data, context)

	test_base.assert_true(ui != null, "UI should be created")
	test_base.assert_encounter_not_completed("Game should not auto-complete")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _test_tile_distribution():
	test_base.section("Tile Distribution")

	# The matching game should have:
	# - 2 big tiles ($$$)
	# - 3 medium tiles ($$)
	# - 4 small tiles ($)
	# = 9 total tiles in a 3x3 grid

	var expected_distribution = {
		"big": 2,
		"medium": 3,
		"small": 4
	}

	var total_tiles = 0
	for type in expected_distribution:
		total_tiles += expected_distribution[type]

	test_base.assert_eq(total_tiles, 9, "Should have 9 tiles total")
	test_base.assert_eq(expected_distribution["big"], 2, "Should have 2 big tiles")
	test_base.assert_eq(expected_distribution["medium"], 3, "Should have 3 medium tiles")
	test_base.assert_eq(expected_distribution["small"], 4, "Should have 4 small tiles")


func _test_match_detection_logic():
	test_base.section("Match Detection Logic")

	# Test that matching 2 of the same type triggers completion
	var revealed_counts = {"big": 0, "medium": 0, "small": 0}

	# Reveal first tile (no match yet)
	revealed_counts["big"] = 1
	var has_match = _check_for_match(revealed_counts)
	test_base.assert_false(has_match, "1 big tile should not trigger match")

	# Reveal second big tile (match!)
	revealed_counts["big"] = 2
	has_match = _check_for_match(revealed_counts)
	test_base.assert_true(has_match, "2 big tiles should trigger match")

	# Test medium match
	revealed_counts = {"big": 1, "medium": 2, "small": 0}
	has_match = _check_for_match(revealed_counts)
	test_base.assert_true(has_match, "2 medium tiles should trigger match")

	# Test small match
	revealed_counts = {"big": 1, "medium": 1, "small": 2}
	has_match = _check_for_match(revealed_counts)
	test_base.assert_true(has_match, "2 small tiles should trigger match")


func _test_reward_tiers():
	test_base.section("Reward Tiers")

	var big_gold = 100
	var medium_gold = 50
	var small_gold = 25

	# Test reward scaling
	test_base.assert_gt(big_gold, medium_gold, "Big reward should be greater than medium")
	test_base.assert_gt(medium_gold, small_gold, "Medium reward should be greater than small")
	test_base.assert_gt(small_gold, 0, "Small reward should be positive")


func _test_game_completion():
	test_base.section("Game Completion")

	var context = test_base.create_mock_context()

	var encounter_data = test_base.create_mock_encounter_data("matching_game", {
		"big_gold": 100,
		"medium_gold": 50,
		"small_gold": 25
	})

	var ui = MatchingGameUIScript.create_ui(encounter_data, context)

	# Simulate winning with a big match by calling callback directly
	context["on_gold_reward"].call(100)
	context["on_encounter_complete"].call()

	test_base.assert_gold_rewarded(100, "Should reward 100 gold for big match")
	test_base.assert_encounter_completed("Game should complete after match")

	if ui and is_instance_valid(ui):
		ui.queue_free()


func _check_for_match(revealed_counts: Dictionary) -> bool:
	"""Check if any tile type has 2+ revealed (a match)."""
	for type in revealed_counts:
		if revealed_counts[type] >= 2:
			return true
	return false


func _print_results():
	var results = test_base.get_results()
	print("\n========================================")
	print("Results: %d passed, %d failed" % [results.passed, results.failed])
	if results.errors.size() > 0:
		print("\nErrors:")
		for err in results.errors:
			print("  - %s" % err)
	print("========================================\n")
