extends Node
# Test runner for Phase 0 Legacy System tests
# Attach this script to a Node and run the scene to execute all tests
#
# Usage in Godot:
#   1. Create a new scene with a Node as root
#   2. Attach this script to the root node
#   3. Run the scene
#   4. Check the Output panel for test results

func _ready() -> void:
	print("============================================================")
	print("PHASE 0: LEGACY SYSTEM TEST SUITE")
	print("============================================================")
	print("")

	var total_passed = 0
	var total_failed = 0
	var all_errors = []

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

	# Print final summary
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
