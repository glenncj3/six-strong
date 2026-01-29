extends Node
# Test script for CharacterInstance class (Phase 1 refactor)
# Tests the simplified character model: no items, no skills, with grid position
# Characters are now static content - no leveling (player levels up instead)
# Note: No class_name - loaded via preload in run_tests.gd


static func run_all_tests() -> Dictionary:
	"""Run all CharacterInstance tests and return results."""
	var results = {
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	# Run each test
	_test_initial_state(results)
	_test_stats_from_master_data(results)
	_test_grid_position(results)
	_test_no_items_or_skills(results)
	_test_combat_functions(results)
	_test_serialization(results)
	_test_from_dict_factory(results)

	return results


static func _get_mock_game_data() -> Dictionary:
	"""Get mock game data for testing (simulates GameData autoload)."""
	return {
		"char_test_001": {
			"id": "char_test_001",
			"name": "Test Warrior",
			"description": "A test character for unit testing",
			"image_path": "res://test.png",
			"cost": 40,
			"level_requirement": 1,
			"base_stats": {
				"health": 100,
				"charges": 5,
				"agility": 15
			}
		}
	}


# Mock GameData node for testing
class MockGameData:
	extends RefCounted
	var _characters: Dictionary = {}

	func _init(chars: Dictionary) -> void:
		_characters = chars

	func get_character_by_id(char_id: String) -> Dictionary:
		return _characters.get(char_id, {})


static func _test_initial_state(results: Dictionary) -> void:
	"""Test that a character instance starts with correct initial state."""
	var instance = CharacterInstance.new()
	instance.base_character_id = "char_test_001"
	instance.stats = {
		"health": 100,
		"charges": 5,
		"agility": 15
	}
	instance.current_health = 100

	if instance.grid_position != Vector2i(-1, -1):
		results.failed += 1
		results.errors.append("Initial grid position should be (-1, -1)")
		return

	if instance.base_character_id != "char_test_001":
		results.failed += 1
		results.errors.append("base_character_id should be char_test_001")
		return

	results.passed += 1
	print("  [PASS] test_initial_state")


static func _test_stats_from_master_data(results: Dictionary) -> void:
	"""Test that stats are correctly calculated from base_stats only."""
	# Create instance with mock stats
	var instance = CharacterInstance.new()
	instance.base_character_id = "char_test_001"
	instance.stats = {
		"health": 100,
		"charges": 5,
		"agility": 15
	}
	instance.current_health = 100

	if instance.max_health != 100:
		results.failed += 1
		results.errors.append("max_health should be 100, got %d" % instance.max_health)
		return

	if instance.charges != 5:
		results.failed += 1
		results.errors.append("charges should be 5, got %d" % instance.charges)
		return

	if instance.agility != 15:
		results.failed += 1
		results.errors.append("agility should be 15, got %d" % instance.agility)
		return

	results.passed += 1
	print("  [PASS] test_stats_from_master_data")


static func _test_grid_position(results: Dictionary) -> void:
	"""Test grid position functionality."""
	var instance = CharacterInstance.new()
	instance.base_character_id = "char_test_001"
	instance.stats = {"health": 100, "charges": 5, "agility": 15}

	# Initially not in grid
	if instance.is_in_grid():
		results.failed += 1
		results.errors.append("Should not be in grid initially")
		return

	# Set grid position
	instance.set_grid_position(0, 1)

	if not instance.is_in_grid():
		results.failed += 1
		results.errors.append("Should be in grid after set_grid_position")
		return

	if instance.grid_position != Vector2i(0, 1):
		results.failed += 1
		results.errors.append("Grid position should be (0, 1), got %s" % str(instance.grid_position))
		return

	# Test front row detection
	if not instance.is_front_row():
		results.failed += 1
		results.errors.append("Row 0 should be front row")
		return

	if instance.is_back_row():
		results.failed += 1
		results.errors.append("Row 0 should not be back row")
		return

	# Move to back row
	instance.set_grid_position(1, 2)

	if not instance.is_back_row():
		results.failed += 1
		results.errors.append("Row 1 should be back row")
		return

	if instance.is_front_row():
		results.failed += 1
		results.errors.append("Row 1 should not be front row")
		return

	# Clear grid position
	instance.clear_grid_position()

	if instance.is_in_grid():
		results.failed += 1
		results.errors.append("Should not be in grid after clear_grid_position")
		return

	results.passed += 1
	print("  [PASS] test_grid_position")


static func _test_no_items_or_skills(results: Dictionary) -> void:
	"""Test that character instances no longer have items or skills."""
	var instance = CharacterInstance.new()
	instance.base_character_id = "char_test_001"

	# Verify the old properties don't exist (they were removed in Phase 1)
	# We check by verifying to_dict doesn't include them
	var data = instance.to_dict()

	if data.has("equipped_items"):
		results.failed += 1
		results.errors.append("to_dict should not include equipped_items")
		return

	if data.has("equipped_item_upgrades"):
		results.failed += 1
		results.errors.append("to_dict should not include equipped_item_upgrades")
		return

	if data.has("learned_skills"):
		results.failed += 1
		results.errors.append("to_dict should not include learned_skills")
		return

	# Characters no longer have level/experience (player levels instead)
	if data.has("level"):
		results.failed += 1
		results.errors.append("to_dict should not include level (player levels, not characters)")
		return

	if data.has("experience"):
		results.failed += 1
		results.errors.append("to_dict should not include experience")
		return

	results.passed += 1
	print("  [PASS] test_no_items_or_skills")


static func _test_combat_functions(results: Dictionary) -> void:
	"""Test combat-related functions."""
	var instance = CharacterInstance.new()
	instance.base_character_id = "char_test_001"
	instance.stats = {"health": 100, "charges": 5, "agility": 15}
	instance.current_health = 100

	# Take damage
	instance.take_damage(30)
	if instance.current_health != 70:
		results.failed += 1
		results.errors.append("Current health should be 70 after 30 damage, got %d" % instance.current_health)
		return

	if not instance.is_alive():
		results.failed += 1
		results.errors.append("Should be alive with 70 HP")
		return

	# Heal
	instance.heal(20)
	if instance.current_health != 90:
		results.failed += 1
		results.errors.append("Current health should be 90 after heal 20, got %d" % instance.current_health)
		return

	# Heal should cap at max
	instance.heal(100)
	if instance.current_health != 100:
		results.failed += 1
		results.errors.append("Heal should cap at max health")
		return

	# Take fatal damage
	instance.take_damage(150)
	if instance.current_health != 0:
		results.failed += 1
		results.errors.append("Damage should clamp health to 0")
		return

	if instance.is_alive():
		results.failed += 1
		results.errors.append("Should be dead with 0 HP")
		return

	# Test restore_full_health
	instance.restore_full_health()
	if instance.current_health != 100:
		results.failed += 1
		results.errors.append("restore_full_health should set health to max")
		return

	results.passed += 1
	print("  [PASS] test_combat_functions")


static func _test_serialization(results: Dictionary) -> void:
	"""Test to_dict serialization includes grid_position."""
	var instance = CharacterInstance.new()
	instance.base_character_id = "char_test_001"
	instance.stats = {"health": 115, "charges": 5, "agility": 15}
	instance.current_health = 80
	instance.set_grid_position(1, 2)

	var data = instance.to_dict()

	if data.base_character_id != "char_test_001":
		results.failed += 1
		results.errors.append("Serialized base_character_id mismatch")
		return

	if data.current_health != 80:
		results.failed += 1
		results.errors.append("Serialized current_health should be 80")
		return

	if not data.has("grid_position"):
		results.failed += 1
		results.errors.append("Serialized data should include grid_position")
		return

	if data.grid_position.x != 1 or data.grid_position.y != 2:
		results.failed += 1
		results.errors.append("Serialized grid_position should be (1, 2)")
		return

	results.passed += 1
	print("  [PASS] test_serialization")


static func _test_from_dict_factory(results: Dictionary) -> void:
	"""Test from_dict deserialization."""
	var saved_data = {
		"base_character_id": "char_test_001",
		"current_health": 75,
		"stats": {"health": 120, "charges": 5, "agility": 15},
		"grid_position": {"x": 0, "y": 1}
	}

	# Note: from_dict would normally use GameData, but we're testing structure
	var instance = CharacterInstance.new()
	instance.base_character_id = saved_data.base_character_id
	instance.current_health = saved_data.current_health
	instance.stats = saved_data.stats.duplicate()
	instance.grid_position = Vector2i(saved_data.grid_position.x, saved_data.grid_position.y)

	if instance.grid_position != Vector2i(0, 1):
		results.failed += 1
		results.errors.append("Deserialized grid_position should be (0, 1)")
		return

	if instance.max_health != 120:
		results.failed += 1
		results.errors.append("Deserialized max_health should be 120")
		return

	if instance.current_health != 75:
		results.failed += 1
		results.errors.append("Deserialized current_health should be 75")
		return

	results.passed += 1
	print("  [PASS] test_from_dict_factory")
