extends SceneTree
## Unit tests for ClassRegistry
## Tests data-driven class definitions loading and lookup.

const Registry = preload("res://scripts/classes/class_registry.gd")


func _init() -> void:
	var results = run_all_tests()

	print("\n========================================")
	print("ClassRegistry Tests")
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
	test_names.append("initialize_loads_classes")
	if _test_initialize_loads_classes():
		passed.append("initialize_loads_classes")
	else:
		failed.append("initialize_loads_classes")
		errors["initialize_loads_classes"] = "Failed to initialize class registry"

	# Test get_all_class_ids
	test_names.append("get_all_class_ids_returns_expected")
	if _test_get_all_class_ids():
		passed.append("get_all_class_ids_returns_expected")
	else:
		failed.append("get_all_class_ids_returns_expected")
		errors["get_all_class_ids_returns_expected"] = "Class IDs mismatch"

	# Test get_display_name
	test_names.append("get_display_name_returns_expected")
	if _test_get_display_name():
		passed.append("get_display_name_returns_expected")
	else:
		failed.append("get_display_name_returns_expected")
		errors["get_display_name_returns_expected"] = "Display name mismatch"

	# Test is_valid_class
	test_names.append("is_valid_class_works")
	if _test_is_valid_class():
		passed.append("is_valid_class_works")
	else:
		failed.append("is_valid_class_works")
		errors["is_valid_class_works"] = "is_valid_class check failed"

	# Test get_display_names_map
	test_names.append("get_display_names_map_works")
	if _test_get_display_names_map():
		passed.append("get_display_names_map_works")
	else:
		failed.append("get_display_names_map_works")
		errors["get_display_names_map_works"] = "get_display_names_map failed"

	# Test missing class handling
	test_names.append("handles_missing_class_gracefully")
	if _test_missing_class_handling():
		passed.append("handles_missing_class_gracefully")
	else:
		failed.append("handles_missing_class_gracefully")
		errors["handles_missing_class_gracefully"] = "Missing class not handled gracefully"

	return {
		"passed": passed,
		"failed": failed,
		"errors": errors,
		"test_names": test_names
	}


static func _test_initialize_loads_classes() -> bool:
	Registry.initialize()
	var class_ids = Registry.get_all_class_ids()
	return class_ids.size() > 0


static func _test_get_all_class_ids() -> bool:
	var class_ids = Registry.get_all_class_ids()
	# Should have at least the core classes
	var expected = ["warrior", "mage", "rogue", "cleric", "ranger", "paladin", "necromancer"]
	for id in expected:
		if id not in class_ids:
			return false
	return true


static func _test_get_display_name() -> bool:
	# Test known classes
	if Registry.get_display_name("warrior") != "Warrior":
		return false
	if Registry.get_display_name("mage") != "Mage":
		return false
	if Registry.get_display_name("necromancer") != "Necromancer":
		return false
	return true


static func _test_is_valid_class() -> bool:
	# Valid classes should return true
	if not Registry.is_valid_class("warrior"):
		return false
	if not Registry.is_valid_class("mage"):
		return false
	# Invalid class should return false
	if Registry.is_valid_class("nonexistent_class"):
		return false
	return true


static func _test_get_display_names_map() -> bool:
	var names_map = Registry.get_display_names_map()
	# Should have warrior mapped to Warrior
	if not names_map.has("warrior") or names_map["warrior"] != "Warrior":
		return false
	if not names_map.has("mage") or names_map["mage"] != "Mage":
		return false
	return true


static func _test_missing_class_handling() -> bool:
	# Missing class should return capitalized id as display name
	var display_name = Registry.get_display_name("nonexistent")
	if display_name != "Nonexistent":
		return false
	# Missing class should return empty description
	var desc = Registry.get_description("nonexistent")
	if desc != "":
		return false
	return true
