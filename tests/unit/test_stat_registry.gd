extends SceneTree
## Unit tests for StatRegistry
## Tests data-driven stat definitions loading and lookup.

const Registry = preload("res://scripts/stats/stat_registry.gd")


func _init() -> void:
	var results = run_all_tests()

	print("\n========================================")
	print("StatRegistry Tests")
	print("========================================\n")

	for test_name in results.test_names:
		var status = "PASS" if test_name in results.passed else "FAIL"
		print("TEST: %s" % test_name)
		print("  %s" % status)
		if test_name in results.errors:
			print("  Error: %s" % results.errors[test_name])

	print("\n========================================")
	print("Results: %d passed, %d failed" % [results.passed.size(), results.failed.size()])
	print("========================================\n")

	quit(results.failed.size())


static func run_all_tests() -> Dictionary:
	"""Run all tests and return results."""
	var passed: Array = []
	var failed: Array = []
	var errors: Dictionary = {}
	var test_names: Array = []

	# Reset registry before tests
	Registry.reset()

	# Test initialization
	test_names.append("initialize_loads_stats")
	if _test_initialize_loads_stats():
		passed.append("initialize_loads_stats")
	else:
		failed.append("initialize_loads_stats")
		errors["initialize_loads_stats"] = "Failed to initialize stat registry"

	# Test get_all_stat_ids
	test_names.append("get_all_stat_ids_returns_expected")
	if _test_get_all_stat_ids():
		passed.append("get_all_stat_ids_returns_expected")
	else:
		failed.append("get_all_stat_ids_returns_expected")
		errors["get_all_stat_ids_returns_expected"] = "Stat IDs mismatch"

	# Test get_display_name
	test_names.append("get_display_name_returns_expected")
	if _test_get_display_name():
		passed.append("get_display_name_returns_expected")
	else:
		failed.append("get_display_name_returns_expected")
		errors["get_display_name_returns_expected"] = "Display name mismatch"

	# Test get_default_value
	test_names.append("get_default_value_returns_expected")
	if _test_get_default_value():
		passed.append("get_default_value_returns_expected")
	else:
		failed.append("get_default_value_returns_expected")
		errors["get_default_value_returns_expected"] = "Default value mismatch"

	# Test is_valid_stat
	test_names.append("is_valid_stat_works")
	if _test_is_valid_stat():
		passed.append("is_valid_stat_works")
	else:
		failed.append("is_valid_stat_works")
		errors["is_valid_stat_works"] = "is_valid_stat check failed"

	# Test get_default_stats
	test_names.append("get_default_stats_returns_all")
	if _test_get_default_stats():
		passed.append("get_default_stats_returns_all")
	else:
		failed.append("get_default_stats_returns_all")
		errors["get_default_stats_returns_all"] = "get_default_stats failed"

	# Test missing stat handling
	test_names.append("handles_missing_stat_gracefully")
	if _test_missing_stat_handling():
		passed.append("handles_missing_stat_gracefully")
	else:
		failed.append("handles_missing_stat_gracefully")
		errors["handles_missing_stat_gracefully"] = "Missing stat not handled gracefully"

	return {
		"passed": passed,
		"failed": failed,
		"errors": errors,
		"test_names": test_names
	}


static func _test_initialize_loads_stats() -> bool:
	Registry.initialize()
	var stat_ids = Registry.get_all_stat_ids()
	return stat_ids.size() > 0


static func _test_get_all_stat_ids() -> bool:
	var stat_ids = Registry.get_all_stat_ids()
	# Should have at least the core stats
	var expected = ["health", "charges", "agility", "speed", "damage", "crit_chance"]
	for id in expected:
		if id not in stat_ids:
			return false
	return true


static func _test_get_display_name() -> bool:
	# Test known stat
	if Registry.get_display_name("health") != "HP":
		return false
	if Registry.get_display_name("charges") != "MP":
		return false
	if Registry.get_display_name("agility") != "DEF":
		return false
	return true


static func _test_get_default_value() -> bool:
	# Test known defaults
	if Registry.get_default_value("health") != 100:
		return false
	if Registry.get_default_value("charges") != 5:
		return false
	if Registry.get_default_value("agility") != 0:
		return false
	if Registry.get_default_value("speed") != 0:
		return false
	return true


static func _test_is_valid_stat() -> bool:
	# Valid stats should return true
	if not Registry.is_valid_stat("health"):
		return false
	if not Registry.is_valid_stat("charges"):
		return false
	# Invalid stat should return false
	if Registry.is_valid_stat("nonexistent_stat"):
		return false
	return true


static func _test_get_default_stats() -> bool:
	var defaults = Registry.get_default_stats()
	# Should have all stats
	if not defaults.has("health") or defaults["health"] != 100:
		return false
	if not defaults.has("charges") or defaults["charges"] != 5:
		return false
	return true


static func _test_missing_stat_handling() -> bool:
	# Missing stat should return id as display name
	var display_name = Registry.get_display_name("nonexistent")
	if display_name != "nonexistent":
		return false
	# Missing stat should return 0 as default value
	var default_val = Registry.get_default_value("nonexistent")
	if default_val != 0:
		return false
	return true
