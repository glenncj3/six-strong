extends Node
# Test script for LegacyData class
# Run this script in Godot to verify legacy data functionality

class_name TestLegacyData


static func run_all_tests() -> Dictionary:
	"""Run all LegacyData tests and return results."""
	var results = {
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	# Run each test
	_test_from_dict_master_data(results)
	_test_from_dict_with_account_data(results)
	_test_unlock_applies_prestige_1_rewards(results)
	_test_add_fame_and_prestige_up(results)
	_test_starting_character_selection(results)
	_test_starting_item_selection(results)
	_test_account_serialization(results)
	_test_encounter_weight(results)

	return results


static func _get_test_master_data() -> Dictionary:
	"""Get test master data for a legacy."""
	return {
		"id": "test_legacy",
		"name": "Test Legacy",
		"description": "A legacy for testing",
		"image_path": "res://test.png",
		"income": 15,
		"starting_character_options": ["char_a", "char_b"],
		"starting_item_options": ["item_a", "item_b"],
		"character_pool": ["char_a", "char_b", "char_c"],
		"item_pool": ["item_a", "item_b", "item_c"],
		"skill_pool": ["skill_a", "skill_b"],
		"unique_encounters": ["enc_a", "enc_b"],
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
					"starting_characters": ["char_b"],
					"starting_items": ["item_b"],
					"characters": ["char_b"],
					"items": ["item_b"],
					"skills": ["skill_a"],
					"encounters": ["enc_a"],
					"encounter_weight_bonus": 10
				}
			},
			{
				"prestige": 3,
				"unlocks": {
					"starting_characters": [],
					"starting_items": [],
					"characters": ["char_c"],
					"items": ["item_c"],
					"skills": ["skill_b"],
					"encounters": ["enc_b"],
					"encounter_weight_bonus": 15
				}
			}
		]
	}


static func _test_from_dict_master_data(results: Dictionary) -> void:
	"""Test that from_dict correctly loads master data."""
	var master = _get_test_master_data()
	var legacy = LegacyData.from_dict(master)

	if legacy.id != "test_legacy":
		results.failed += 1
		results.errors.append("ID should be 'test_legacy', got '%s'" % legacy.id)
		return

	if legacy.legacy_name != "Test Legacy":
		results.failed += 1
		results.errors.append("Name should be 'Test Legacy', got '%s'" % legacy.legacy_name)
		return

	if legacy.income != 15:
		results.failed += 1
		results.errors.append("Income should be 15, got %d" % legacy.income)
		return

	if legacy.starting_character_options.size() != 2:
		results.failed += 1
		results.errors.append("Should have 2 starting character options, got %d" % legacy.starting_character_options.size())
		return

	if legacy.character_pool.size() != 3:
		results.failed += 1
		results.errors.append("Should have 3 characters in pool, got %d" % legacy.character_pool.size())
		return

	results.passed += 1
	print("  [PASS] test_from_dict_master_data")


static func _test_from_dict_with_account_data(results: Dictionary) -> void:
	"""Test that from_dict correctly loads account state."""
	var master = _get_test_master_data()
	var account = {
		"unlocked": true,
		"prestige": 2,
		"fame": 50,
		"selected_starting_character_id": "char_b",
		"selected_starting_item_id": "item_a",
		"unlocked_starting_characters": ["char_a", "char_b"],
		"unlocked_starting_items": ["item_a", "item_b"],
		"unlocked_characters": ["char_a", "char_b"],
		"unlocked_items": ["item_a", "item_b"],
		"unlocked_skills": ["skill_a"],
		"unlocked_encounters": ["enc_a"],
		"total_encounter_weight_bonus": 10
	}

	var legacy = LegacyData.from_dict(master, account)

	if not legacy.unlocked:
		results.failed += 1
		results.errors.append("Legacy should be unlocked")
		return

	if legacy.get_prestige() != 2:
		results.failed += 1
		results.errors.append("Prestige should be 2, got %d" % legacy.get_prestige())
		return

	if legacy.get_fame() != 50:
		results.failed += 1
		results.errors.append("Fame should be 50, got %d" % legacy.get_fame())
		return

	if legacy.selected_starting_character_id != "char_b":
		results.failed += 1
		results.errors.append("Selected starting character should be 'char_b', got '%s'" % legacy.selected_starting_character_id)
		return

	if legacy.unlocked_skills.size() != 1:
		results.failed += 1
		results.errors.append("Should have 1 unlocked skill, got %d" % legacy.unlocked_skills.size())
		return

	results.passed += 1
	print("  [PASS] test_from_dict_with_account_data")


static func _test_unlock_applies_prestige_1_rewards(results: Dictionary) -> void:
	"""Test that unlocking a legacy applies prestige 1 rewards."""
	var master = _get_test_master_data()
	var legacy = LegacyData.from_dict(master)

	# Initially not unlocked
	if legacy.unlocked:
		results.failed += 1
		results.errors.append("Legacy should not be unlocked initially")
		return

	if legacy.unlocked_characters.size() != 0:
		results.failed += 1
		results.errors.append("Should have 0 unlocked characters before unlock")
		return

	# Unlock the legacy
	legacy.unlock()

	if not legacy.unlocked:
		results.failed += 1
		results.errors.append("Legacy should be unlocked after unlock()")
		return

	if not "char_a" in legacy.unlocked_characters:
		results.failed += 1
		results.errors.append("char_a should be unlocked after unlock()")
		return

	if not "char_a" in legacy.unlocked_starting_characters:
		results.failed += 1
		results.errors.append("char_a should be in unlocked starting characters")
		return

	# Should auto-select first starting character
	if legacy.selected_starting_character_id != "char_a":
		results.failed += 1
		results.errors.append("Should auto-select first starting character")
		return

	results.passed += 1
	print("  [PASS] test_unlock_applies_prestige_1_rewards")


static func _test_add_fame_and_prestige_up(results: Dictionary) -> void:
	"""Test that adding fame can trigger prestige up and unlock content."""
	var master = _get_test_master_data()
	var legacy = LegacyData.from_dict(master)
	legacy.unlock()

	# Add enough fame to reach prestige 2
	var result = legacy.add_fame(100)

	if not result.prestige_increased:
		results.failed += 1
		results.errors.append("Prestige should increase with 100 fame")
		return

	if result.new_prestige != 2:
		results.failed += 1
		results.errors.append("New prestige should be 2, got %d" % result.new_prestige)
		return

	# Check that prestige 2 content was unlocked
	if not "char_b" in legacy.unlocked_characters:
		results.failed += 1
		results.errors.append("char_b should be unlocked at prestige 2")
		return

	if not "skill_a" in legacy.unlocked_skills:
		results.failed += 1
		results.errors.append("skill_a should be unlocked at prestige 2")
		return

	if legacy.total_encounter_weight_bonus != 10:
		results.failed += 1
		results.errors.append("Encounter weight bonus should be 10, got %d" % legacy.total_encounter_weight_bonus)
		return

	results.passed += 1
	print("  [PASS] test_add_fame_and_prestige_up")


static func _test_starting_character_selection(results: Dictionary) -> void:
	"""Test starting character selection logic."""
	var master = _get_test_master_data()
	var legacy = LegacyData.from_dict(master)
	legacy.unlock()

	# Can't select char_b yet (not unlocked at prestige 1)
	var success = legacy.select_starting_character("char_b")
	if success:
		results.failed += 1
		results.errors.append("Should not be able to select char_b before prestige 2")
		return

	# Prestige up to unlock char_b
	legacy.add_fame(100)

	# Now can select char_b
	success = legacy.select_starting_character("char_b")
	if not success:
		results.failed += 1
		results.errors.append("Should be able to select char_b at prestige 2")
		return

	if legacy.selected_starting_character_id != "char_b":
		results.failed += 1
		results.errors.append("Selected starting character should be 'char_b'")
		return

	results.passed += 1
	print("  [PASS] test_starting_character_selection")


static func _test_starting_item_selection(results: Dictionary) -> void:
	"""Test starting item selection logic."""
	var master = _get_test_master_data()
	var legacy = LegacyData.from_dict(master)
	legacy.unlock()

	# item_a should be auto-selected
	if legacy.selected_starting_item_id != "item_a":
		results.failed += 1
		results.errors.append("item_a should be auto-selected after unlock")
		return

	# Can clear selection
	var success = legacy.select_starting_item("")
	if not success:
		results.failed += 1
		results.errors.append("Should be able to clear starting item selection")
		return

	if legacy.selected_starting_item_id != "":
		results.failed += 1
		results.errors.append("Starting item should be cleared")
		return

	results.passed += 1
	print("  [PASS] test_starting_item_selection")


static func _test_account_serialization(results: Dictionary) -> void:
	"""Test that to_account_dict correctly serializes state."""
	var master = _get_test_master_data()
	var legacy = LegacyData.from_dict(master)
	legacy.unlock()
	legacy.add_fame(100)  # Prestige 2
	legacy.select_starting_character("char_b")

	var data = legacy.to_account_dict()

	if data.id != "test_legacy":
		results.failed += 1
		results.errors.append("Serialized ID should be 'test_legacy'")
		return

	if not data.unlocked:
		results.failed += 1
		results.errors.append("Serialized unlocked should be true")
		return

	if data.prestige != 2:
		results.failed += 1
		results.errors.append("Serialized prestige should be 2")
		return

	if data.selected_starting_character_id != "char_b":
		results.failed += 1
		results.errors.append("Serialized starting character should be 'char_b'")
		return

	results.passed += 1
	print("  [PASS] test_account_serialization")


static func _test_encounter_weight(results: Dictionary) -> void:
	"""Test that encounter weight accumulates correctly."""
	var master = _get_test_master_data()
	var legacy = LegacyData.from_dict(master)
	legacy.unlock()

	# Base weight at prestige 1
	if legacy.get_encounter_weight() != 100:
		results.failed += 1
		results.errors.append("Base encounter weight should be 100, got %d" % legacy.get_encounter_weight())
		return

	# Prestige 2: +10 bonus
	legacy.add_fame(100)
	if legacy.get_encounter_weight() != 110:
		results.failed += 1
		results.errors.append("Encounter weight at prestige 2 should be 110, got %d" % legacy.get_encounter_weight())
		return

	# Prestige 3: +15 bonus (total +25)
	legacy.add_fame(100)
	if legacy.get_encounter_weight() != 125:
		results.failed += 1
		results.errors.append("Encounter weight at prestige 3 should be 125, got %d" % legacy.get_encounter_weight())
		return

	results.passed += 1
	print("  [PASS] test_encounter_weight")
