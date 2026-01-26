extends Node
# Test script for save format detection (clean slate)
# Run this script in Godot to verify old saves trigger fresh account creation

class_name TestSaveFormatDetection


static func run_all_tests() -> Dictionary:
	"""Run all save format detection tests and return results."""
	var results = {
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	# Run each test
	_test_no_format_version(results)
	_test_old_format_version(results)
	_test_missing_legacies(results)
	_test_valid_new_format(results)
	_test_partial_data(results)

	return results


static func _test_no_format_version(results: Dictionary) -> void:
	"""Test that data without format_version is rejected."""
	var old_save = {
		"player_id": "player_123",
		"currencies": {"gems": 1000, "reroll_tokens": 0},
		"characters": [],
		"unlocked_character_ids": []
	}

	var is_valid = _is_valid_save_format(old_save)

	if is_valid:
		results.failed += 1
		results.errors.append("Save without format_version should be invalid")
		return

	results.passed += 1
	print("  [PASS] test_no_format_version")


static func _test_old_format_version(results: Dictionary) -> void:
	"""Test that format_version 1 is rejected."""
	var old_save = {
		"format_version": 1,
		"player_id": "player_123",
		"currencies": {"gems": 1000, "reroll_tokens": 0},
		"characters": []
	}

	var is_valid = _is_valid_save_format(old_save)

	if is_valid:
		results.failed += 1
		results.errors.append("Save with format_version 1 should be invalid")
		return

	results.passed += 1
	print("  [PASS] test_old_format_version")


static func _test_missing_legacies(results: Dictionary) -> void:
	"""Test that version 2 without legacies array is rejected."""
	var save_no_legacies = {
		"format_version": 2,
		"player_id": "player_123",
		"currencies": {"gems": 1000, "reroll_tokens": 0},
		"characters": []
	}

	var is_valid = _is_valid_save_format(save_no_legacies)

	if is_valid:
		results.failed += 1
		results.errors.append("Save without legacies array should be invalid")
		return

	results.passed += 1
	print("  [PASS] test_missing_legacies")


static func _test_valid_new_format(results: Dictionary) -> void:
	"""Test that valid new format is accepted."""
	var valid_save = {
		"format_version": 2,
		"player_id": "player_123",
		"currencies": {"gems": 1000, "reroll_tokens": 0},
		"characters": [],
		"unlocked_character_ids": [],
		"legacies": [
			{
				"id": "legacy_knight_order",
				"unlocked": true,
				"prestige": 1,
				"fame": 50
			}
		]
	}

	var is_valid = _is_valid_save_format(valid_save)

	if not is_valid:
		results.failed += 1
		results.errors.append("Valid new format save should be accepted")
		return

	results.passed += 1
	print("  [PASS] test_valid_new_format")


static func _test_partial_data(results: Dictionary) -> void:
	"""Test that empty/null data is rejected."""
	# Null data
	var is_valid = _is_valid_save_format({})

	if is_valid:
		results.failed += 1
		results.errors.append("Empty dictionary should be invalid")
		return

	results.passed += 1
	print("  [PASS] test_partial_data")


# Replicate the validation logic from PlayerAccount for testing
static func _is_valid_save_format(data: Dictionary) -> bool:
	"""
	Check if save data is in the new legacy-centric format.
	Returns false for old character-centric saves (triggers clean slate).

	This mirrors the logic in PlayerAccount._is_valid_save_format()
	"""
	# Must have format_version field
	if not data.has("format_version"):
		return false

	var version = data.get("format_version", 0)

	# Must be at least version 2 (legacy system)
	if version < 2:
		return false

	# Must have legacies array
	if not data.has("legacies"):
		return false

	return true
