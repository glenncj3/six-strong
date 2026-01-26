extends Node
# Test runner for Phase 0 + Phase 1 + Phase 2 Legacy System tests
# Attach this script to a Node and run the scene to execute all tests
#
# Usage in Godot:
#   1. Create a new scene with a Node as root
#   2. Attach this script to the root node
#   3. Run the scene
#   4. Check the Output panel for test results

# Preload Phase 1 test classes (not autoloaded)
const Phase1CharInstance = preload("res://tests/test_character_instance_phase1.gd")
const Phase1StatCalc = preload("res://tests/test_stat_calculator_phase1.gd")
const Phase1CharJson = preload("res://tests/test_character_json_phase1.gd")

# Preload Phase 2 test classes
const Phase2PlayerInventory = preload("res://tests/test_player_inventory_phase2.gd")


func _ready() -> void:
	print("============================================================")
	print("LEGACY REFACTOR TEST SUITE (Phase 0 + Phase 1 + Phase 2)")
	print("============================================================")
	print("")

	var total_passed = 0
	var total_failed = 0
	var all_errors = []

	# ==========================================================================
	# PHASE 0 TESTS (Legacy System)
	# ==========================================================================
	print("--- PHASE 0: Legacy System ---")
	print("")

	# Run PrestigeTracker tests
	print("Running PrestigeTracker tests...")
	var prestige_results = TestPrestigeTracker.run_all_tests()
	total_passed += prestige_results.passed
	total_failed += prestige_results.failed
	all_errors.append_array(prestige_results.errors)
	_print_suite_summary("PrestigeTracker", prestige_results)
	print("")

	# Run LegacyData tests
	print("Running LegacyData tests...")
	var legacy_data_results = TestLegacyData.run_all_tests()
	total_passed += legacy_data_results.passed
	total_failed += legacy_data_results.failed
	all_errors.append_array(legacy_data_results.errors)
	_print_suite_summary("LegacyData", legacy_data_results)
	print("")

	# Run LegacyCollection tests
	print("Running LegacyCollection tests...")
	var collection_results = TestLegacyCollection.run_all_tests()
	total_passed += collection_results.passed
	total_failed += collection_results.failed
	all_errors.append_array(collection_results.errors)
	_print_suite_summary("LegacyCollection", collection_results)
	print("")

	# Run SaveFormatDetection tests
	print("Running SaveFormatDetection tests...")
	var format_results = TestSaveFormatDetection.run_all_tests()
	total_passed += format_results.passed
	total_failed += format_results.failed
	all_errors.append_array(format_results.errors)
	_print_suite_summary("SaveFormatDetection", format_results)
	print("")

	# ==========================================================================
	# PHASE 1 TESTS (Character Simplification)
	# ==========================================================================
	print("--- PHASE 1: Character Simplification ---")
	print("")

	# Run CharacterInstance tests
	print("Running CharacterInstance (Phase 1) tests...")
	var char_instance_results = Phase1CharInstance.run_all_tests()
	total_passed += char_instance_results.passed
	total_failed += char_instance_results.failed
	all_errors.append_array(char_instance_results.errors)
	_print_suite_summary("CharacterInstance", char_instance_results)
	print("")

	# Run StatCalculator tests
	print("Running StatCalculator (Phase 1) tests...")
	var stat_calc_results = Phase1StatCalc.run_all_tests()
	total_passed += stat_calc_results.passed
	total_failed += stat_calc_results.failed
	all_errors.append_array(stat_calc_results.errors)
	_print_suite_summary("StatCalculator", stat_calc_results)
	print("")

	# Run Character JSON tests
	print("Running Character JSON (Phase 1) tests...")
	var char_json_results = Phase1CharJson.run_all_tests()
	total_passed += char_json_results.passed
	total_failed += char_json_results.failed
	all_errors.append_array(char_json_results.errors)
	_print_suite_summary("CharacterJSON", char_json_results)
	print("")

	# ==========================================================================
	# PHASE 2 TESTS (Player-Level Item System)
	# ==========================================================================
	print("--- PHASE 2: Player-Level Item System ---")
	print("")

	# Run PlayerInventory tests
	print("Running PlayerInventory (Phase 2) tests...")
	var inventory_results = Phase2PlayerInventory.run_all_tests()
	total_passed += inventory_results.passed
	total_failed += inventory_results.failed
	all_errors.append_array(inventory_results.errors)
	_print_suite_summary("PlayerInventory", inventory_results)
	print("")

	# ==========================================================================
	# FINAL SUMMARY
	# ==========================================================================
	print("============================================================")
	print("FINAL RESULTS")
	print("============================================================")
	print("Total Passed: %d" % total_passed)
	print("Total Failed: %d" % total_failed)
	print("")

	if all_errors.size() > 0:
		print("ERRORS:")
		for error in all_errors:
			print("  - %s" % error)
		print("")

	if total_failed == 0:
		print("[SUCCESS] All tests passed!")
	else:
		print("[FAILURE] Some tests failed. See errors above.")

	print("")
	print("============================================================")


func _print_suite_summary(suite_name: String, results: Dictionary) -> void:
	"""Print summary for a test suite."""
	var status = "PASS" if results.failed == 0 else "FAIL"
	print("  %s: %d passed, %d failed [%s]" % [suite_name, results.passed, results.failed, status])
