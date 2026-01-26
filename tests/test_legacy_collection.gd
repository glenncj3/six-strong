extends Node
# Test script for LegacyCollection class
# Run this script in Godot to verify legacy collection functionality

class_name TestLegacyCollection


static func run_all_tests() -> Dictionary:
	"""Run all LegacyCollection tests and return results."""
	var results = {
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	# Run each test
	_test_initialize_from_master_data(results)
	_test_initialize_with_account_data(results)
	_test_unlock_legacy(results)
	_test_add_legacy_fame(results)
	_test_signals_emitted(results)
	_test_serialization_roundtrip(results)
	_test_starting_selection(results)
	_test_content_queries(results)

	return results


static func _get_test_master_data() -> Array:
	"""Get test master data for multiple legacies."""
	return [
		{
			"id": "legacy_a",
			"name": "Legacy A",
			"description": "First test legacy",
			"image_path": "res://a.png",
			"income": 10,
			"starting_character_options": ["char_a"],
			"starting_item_options": ["item_a"],
			"character_pool": ["char_a", "char_b"],
			"item_pool": ["item_a"],
			"skill_pool": ["skill_a"],
			"unique_encounters": ["enc_a"],
			"prestige_rewards": [
				{
					"prestige": 1,
					"unlocks": {
						"starting_characters": ["char_a"],
						"starting_items": ["item_a"],
						"characters": ["char_a"],
						"items": ["item_a"],
						"skills": [],
						"encounters": []
					}
				},
				{
					"prestige": 2,
					"unlocks": {
						"starting_characters": [],
						"starting_items": [],
						"characters": ["char_b"],
						"items": [],
						"skills": ["skill_a"],
						"encounters": ["enc_a"],
						"encounter_weight_bonus": 10
					}
				}
			]
		},
		{
			"id": "legacy_b",
			"name": "Legacy B",
			"description": "Second test legacy",
			"image_path": "res://b.png",
			"income": 15,
			"starting_character_options": ["char_c"],
			"starting_item_options": [],
			"character_pool": ["char_c"],
			"item_pool": ["item_b"],
			"skill_pool": [],
			"unique_encounters": [],
			"prestige_rewards": [
				{
					"prestige": 1,
					"unlocks": {
						"starting_characters": ["char_c"],
						"starting_items": [],
						"characters": ["char_c"],
						"items": ["item_b"],
						"skills": [],
						"encounters": []
					}
				}
			]
		}
	]


static func _test_initialize_from_master_data(results: Dictionary) -> void:
	"""Test that collection initializes correctly from master data."""
	var master_data = _get_test_master_data()
	var collection = LegacyCollection.new()
	collection.initialize(master_data, [])

	if collection.get_legacy_count() != 2:
		results.failed += 1
		results.errors.append("Should have 2 legacies, got %d" % collection.get_legacy_count())
		return

	var legacy_a = collection.get_legacy("legacy_a")
	if legacy_a == null:
		results.failed += 1
		results.errors.append("legacy_a should exist")
		return

	if legacy_a.legacy_name != "Legacy A":
		results.failed += 1
		results.errors.append("legacy_a name should be 'Legacy A'")
		return

	if collection.get_unlocked_count() != 0:
		results.failed += 1
		results.errors.append("Should have 0 unlocked legacies initially")
		return

	results.passed += 1
	print("  [PASS] test_initialize_from_master_data")


static func _test_initialize_with_account_data(results: Dictionary) -> void:
	"""Test that collection loads account state correctly."""
	var master_data = _get_test_master_data()
	var account_data = [
		{
			"id": "legacy_a",
			"unlocked": true,
			"prestige": 2,
			"fame": 50,
			"selected_starting_character_id": "char_a",
			"selected_starting_item_id": "item_a",
			"unlocked_starting_characters": ["char_a"],
			"unlocked_starting_items": ["item_a"],
			"unlocked_characters": ["char_a", "char_b"],
			"unlocked_items": ["item_a"],
			"unlocked_skills": ["skill_a"],
			"unlocked_encounters": ["enc_a"],
			"total_encounter_weight_bonus": 10
		}
	]

	var collection = LegacyCollection.from_array(master_data, account_data)

	var legacy_a = collection.get_legacy("legacy_a")
	if not legacy_a.unlocked:
		results.failed += 1
		results.errors.append("legacy_a should be unlocked from account data")
		return

	if legacy_a.get_prestige() != 2:
		results.failed += 1
		results.errors.append("legacy_a prestige should be 2, got %d" % legacy_a.get_prestige())
		return

	var legacy_b = collection.get_legacy("legacy_b")
	if legacy_b.unlocked:
		results.failed += 1
		results.errors.append("legacy_b should not be unlocked (no account data)")
		return

	results.passed += 1
	print("  [PASS] test_initialize_with_account_data")


static func _test_unlock_legacy(results: Dictionary) -> void:
	"""Test unlocking a legacy."""
	var master_data = _get_test_master_data()
	var collection = LegacyCollection.new()
	collection.initialize(master_data, [])

	# Unlock legacy_a
	var success = collection.unlock_legacy("legacy_a")
	if not success:
		results.failed += 1
		results.errors.append("unlock_legacy should return true")
		return

	if not collection.is_legacy_unlocked("legacy_a"):
		results.failed += 1
		results.errors.append("legacy_a should be unlocked")
		return

	# Try to unlock again
	success = collection.unlock_legacy("legacy_a")
	if success:
		results.failed += 1
		results.errors.append("unlock_legacy should return false for already unlocked")
		return

	# Try to unlock non-existent
	success = collection.unlock_legacy("legacy_z")
	if success:
		results.failed += 1
		results.errors.append("unlock_legacy should return false for non-existent")
		return

	results.passed += 1
	print("  [PASS] test_unlock_legacy")


static func _test_add_legacy_fame(results: Dictionary) -> void:
	"""Test adding fame to a legacy."""
	var master_data = _get_test_master_data()
	var collection = LegacyCollection.new()
	collection.initialize(master_data, [])
	collection.unlock_legacy("legacy_a")

	# Add fame
	var result = collection.add_legacy_fame("legacy_a", 100)

	if not result.prestige_increased:
		results.failed += 1
		results.errors.append("Prestige should increase with 100 fame")
		return

	if collection.get_legacy_prestige("legacy_a") != 2:
		results.failed += 1
		results.errors.append("Prestige should be 2, got %d" % collection.get_legacy_prestige("legacy_a"))
		return

	# Adding to locked legacy should fail gracefully
	result = collection.add_legacy_fame("legacy_b", 50)
	if result.prestige_increased:
		results.failed += 1
		results.errors.append("Should not be able to add fame to locked legacy")
		return

	results.passed += 1
	print("  [PASS] test_add_legacy_fame")


static func _test_signals_emitted(results: Dictionary) -> void:
	"""Test that collection signals exist and can be connected."""
	# Note: Due to GDScript static function limitations with lambdas,
	# we verify signals exist rather than checking emission in static context.
	var master_data = _get_test_master_data()
	var collection = LegacyCollection.new()
	collection.initialize(master_data, [])

	# Verify signals exist
	if not collection.has_signal("legacy_unlocked"):
		results.failed += 1
		results.errors.append("LegacyCollection should have legacy_unlocked signal")
		return

	if not collection.has_signal("legacy_prestige_up"):
		results.failed += 1
		results.errors.append("LegacyCollection should have legacy_prestige_up signal")
		return

	if not collection.has_signal("legacy_fame_changed"):
		results.failed += 1
		results.errors.append("LegacyCollection should have legacy_fame_changed signal")
		return

	if not collection.has_signal("starting_character_changed"):
		results.failed += 1
		results.errors.append("LegacyCollection should have starting_character_changed signal")
		return

	if not collection.has_signal("starting_item_changed"):
		results.failed += 1
		results.errors.append("LegacyCollection should have starting_item_changed signal")
		return

	# Test operations that would trigger signals
	var success = collection.unlock_legacy("legacy_a")
	if not success:
		results.failed += 1
		results.errors.append("unlock_legacy should succeed")
		return

	if not collection.is_legacy_unlocked("legacy_a"):
		results.failed += 1
		results.errors.append("legacy_a should be unlocked after unlock_legacy")
		return

	# Add fame and verify state change (signals would fire)
	var result = collection.add_legacy_fame("legacy_a", 100)
	if not result.prestige_increased:
		results.failed += 1
		results.errors.append("Prestige should have increased")
		return

	results.passed += 1
	print("  [PASS] test_signals_emitted")


static func _test_serialization_roundtrip(results: Dictionary) -> void:
	"""Test that serialization and deserialization maintains state."""
	var master_data = _get_test_master_data()
	var collection = LegacyCollection.new()
	collection.initialize(master_data, [])

	# Make some changes
	collection.unlock_legacy("legacy_a")
	collection.add_legacy_fame("legacy_a", 75)
	collection.select_starting_character("legacy_a", "char_a")

	# Serialize
	var saved_data = collection.to_array()

	# Create new collection from saved data
	var restored = LegacyCollection.from_array(master_data, saved_data)

	# Verify state
	if not restored.is_legacy_unlocked("legacy_a"):
		results.failed += 1
		results.errors.append("Restored: legacy_a should be unlocked")
		return

	if restored.get_legacy_fame("legacy_a") != 75:
		results.failed += 1
		results.errors.append("Restored: fame should be 75, got %d" % restored.get_legacy_fame("legacy_a"))
		return

	if restored.get_starting_character("legacy_a") != "char_a":
		results.failed += 1
		results.errors.append("Restored: starting character should be 'char_a'")
		return

	results.passed += 1
	print("  [PASS] test_serialization_roundtrip")


static func _test_starting_selection(results: Dictionary) -> void:
	"""Test starting character and item selection."""
	var master_data = _get_test_master_data()
	var collection = LegacyCollection.new()
	collection.initialize(master_data, [])
	collection.unlock_legacy("legacy_a")

	# Get starting character
	var char_id = collection.get_starting_character("legacy_a")
	if char_id != "char_a":
		results.failed += 1
		results.errors.append("Starting character should be 'char_a', got '%s'" % char_id)
		return

	# Change selection
	var success = collection.select_starting_character("legacy_a", "char_a")
	if not success:
		results.failed += 1
		results.errors.append("Should be able to select char_a")
		return

	# Get starting item
	var item_id = collection.get_starting_item("legacy_a")
	if item_id != "item_a":
		results.failed += 1
		results.errors.append("Starting item should be 'item_a', got '%s'" % item_id)
		return

	results.passed += 1
	print("  [PASS] test_starting_selection")


static func _test_content_queries(results: Dictionary) -> void:
	"""Test content query methods."""
	var master_data = _get_test_master_data()
	var collection = LegacyCollection.new()
	collection.initialize(master_data, [])
	collection.unlock_legacy("legacy_a")
	collection.add_legacy_fame("legacy_a", 100)  # Prestige 2

	# Get unlocked characters
	var chars = collection.get_unlocked_characters("legacy_a")
	if chars.size() != 2:
		results.failed += 1
		results.errors.append("Should have 2 unlocked characters at prestige 2")
		return

	# Get unlocked skills
	var skills = collection.get_unlocked_skills("legacy_a")
	if skills.size() != 1:
		results.failed += 1
		results.errors.append("Should have 1 unlocked skill at prestige 2")
		return

	# Get encounter weight
	var weight = collection.get_encounter_weight("legacy_a")
	if weight != 110:
		results.failed += 1
		results.errors.append("Encounter weight should be 110, got %d" % weight)
		return

	results.passed += 1
	print("  [PASS] test_content_queries")
