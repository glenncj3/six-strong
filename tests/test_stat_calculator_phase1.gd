extends Node
# Test script for StatCalculator class (Phase 1 refactor)
# Tests the simplified stat calculation: base stats only, no items/skills/prestige
# Note: No class_name - loaded via preload in run_tests.gd


static func run_all_tests() -> Dictionary:
	"""Run all StatCalculator tests and return results."""
	var results = {
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	# Run each test
	_test_calculate_base_stats(results)
	_test_no_income_stat(results)
	_test_no_item_slots(results)
	_test_calculate_character_stats_ignores_params(results)
	_test_apply_modifier(results)
	_test_apply_stat_modifiers(results)
	_test_level_bonus_calculation(results)
	_test_stats_to_string(results)
	_test_clone_stats(results)

	return results


static func _get_mock_character_master() -> Dictionary:
	"""Get mock character master data for testing."""
	return {
		"id": "char_test",
		"name": "Test Character",
		"description": "A test character",
		"cost": 40,
		"level_requirement": 1,
		"base_stats": {
			"health": 100,
			"mana": 5,
			"defend_rate": 15
		}
	}


static func _test_calculate_base_stats(results: Dictionary) -> void:
	"""Test that calculate_character_base_stats returns only base stats."""
	var master = _get_mock_character_master()
	var stats = StatCalculator.calculate_character_base_stats(master)

	if stats.get("health", 0) != 100:
		results.failed += 1
		results.errors.append("Health should be 100, got %d" % stats.get("health", 0))
		return

	if stats.get("mana", 0) != 5:
		results.failed += 1
		results.errors.append("Mana should be 5, got %d" % stats.get("mana", 0))
		return

	if stats.get("defend_rate", 0) != 15:
		results.failed += 1
		results.errors.append("defend_rate should be 15, got %d" % stats.get("defend_rate", 0))
		return

	results.passed += 1
	print("  [PASS] test_calculate_base_stats")


static func _test_no_income_stat(results: Dictionary) -> void:
	"""Test that income stat is no longer included."""
	# Create master data that includes income (old format)
	var master_with_income = {
		"id": "char_old",
		"base_stats": {
			"health": 100,
			"mana": 5,
			"income": 10,  # Old field - should be ignored
			"defend_rate": 15
		}
	}

	var stats = StatCalculator.calculate_character_base_stats(master_with_income)

	# Income should NOT be in the result
	if stats.has("income"):
		results.failed += 1
		results.errors.append("Stats should not include income in Phase 1")
		return

	# Other stats should still work
	if stats.get("health", 0) != 100:
		results.failed += 1
		results.errors.append("Health should still be 100")
		return

	results.passed += 1
	print("  [PASS] test_no_income_stat")


static func _test_no_item_slots(results: Dictionary) -> void:
	"""Test that item slots stats are no longer included."""
	# Create master data with old item slot fields
	var master_with_slots = {
		"id": "char_old",
		"base_stats": {
			"health": 100,
			"mana": 5,
			"defend_rate": 15,
			"itemSlots": 9,  # Old field - should be ignored
			"startingItemSlots": 2  # Old field - should be ignored
		}
	}

	var stats = StatCalculator.calculate_character_base_stats(master_with_slots)

	# Item slots should NOT be in the result
	if stats.has("itemSlots"):
		results.failed += 1
		results.errors.append("Stats should not include itemSlots in Phase 1")
		return

	if stats.has("startingItemSlots"):
		results.failed += 1
		results.errors.append("Stats should not include startingItemSlots in Phase 1")
		return

	results.passed += 1
	print("  [PASS] test_no_item_slots")


static func _test_calculate_character_stats_ignores_params(results: Dictionary) -> void:
	"""Test that calculate_character_stats ignores char_data and include_items."""
	var master = _get_mock_character_master()

	# Old format char_data with prestige and equipped items
	var char_data_with_prestige = {
		"id": "char_test",
		"prestige": 5,
		"equipped_items": ["item_a", "item_b"]
	}

	# Call with include_items = true (should be ignored)
	var stats_with_items = StatCalculator.calculate_character_stats(master, char_data_with_prestige, true)

	# Call with include_items = false
	var stats_without_items = StatCalculator.calculate_character_stats(master, char_data_with_prestige, false)

	# Call with empty char_data
	var stats_empty_char = StatCalculator.calculate_character_stats(master, {})

	# All should return the same base stats
	if stats_with_items.get("health", 0) != stats_without_items.get("health", 0):
		results.failed += 1
		results.errors.append("include_items param should be ignored - stats differ")
		return

	if stats_with_items.get("health", 0) != stats_empty_char.get("health", 0):
		results.failed += 1
		results.errors.append("char_data param should be ignored - stats differ")
		return

	# Stats should match base stats exactly (no prestige boost)
	if stats_with_items.get("health", 0) != 100:
		results.failed += 1
		results.errors.append("Stats should be base stats only, not modified by prestige")
		return

	results.passed += 1
	print("  [PASS] test_calculate_character_stats_ignores_params")


static func _test_apply_modifier(results: Dictionary) -> void:
	"""Test apply_modifier for additive and multiplicative modifiers."""
	var stats = {"health": 100, "mana": 5}

	# Additive modifier
	StatCalculator.apply_modifier(stats, "health", 20, false)
	if stats.health != 120:
		results.failed += 1
		results.errors.append("Health should be 120 after +20, got %d" % stats.health)
		return

	# Multiplicative modifier
	StatCalculator.apply_modifier(stats, "mana", 2.0, true)
	if stats.mana != 10:
		results.failed += 1
		results.errors.append("Mana should be 10 after *2, got %d" % stats.mana)
		return

	# New stat (not in dictionary - should initialize to 0 then add)
	StatCalculator.apply_modifier(stats, "newStat", 15, false)
	if stats.get("newStat", -1) != 15:
		results.failed += 1
		results.errors.append("New stat should be initialized and modified")
		return

	results.passed += 1
	print("  [PASS] test_apply_modifier")


static func _test_apply_stat_modifiers(results: Dictionary) -> void:
	"""Test apply_stat_modifiers with dictionary of modifiers."""
	var stats = {"health": 100, "mana": 5, "defend_rate": 10}

	var modifiers = {
		"health": 25,
		"defend_rate": 5
	}

	StatCalculator.apply_stat_modifiers(stats, modifiers)

	if stats.health != 125:
		results.failed += 1
		results.errors.append("Health should be 125, got %d" % stats.health)
		return

	if stats.defend_rate != 15:
		results.failed += 1
		results.errors.append("defend_rate should be 15, got %d" % stats.defend_rate)
		return

	if stats.mana != 5:
		results.failed += 1
		results.errors.append("Mana should be unchanged at 5, got %d" % stats.mana)
		return

	results.passed += 1
	print("  [PASS] test_apply_stat_modifiers")


static func _test_level_bonus_calculation(results: Dictionary) -> void:
	"""Test calculate_level_bonus applies level bonuses correctly."""
	var base_stats = {"health": 100, "mana": 5, "defend_rate": 15}

	# Level 1 - no bonus
	var level_1_stats = StatCalculator.calculate_level_bonus(base_stats, 1)
	if level_1_stats.health != 100:
		results.failed += 1
		results.errors.append("Level 1 health should be 100 (no bonus), got %d" % level_1_stats.health)
		return

	# Level 5 - +20 health (5 per level after 1)
	var level_5_stats = StatCalculator.calculate_level_bonus(base_stats, 5)
	if level_5_stats.health != 120:
		results.failed += 1
		results.errors.append("Level 5 health should be 120 (+20), got %d" % level_5_stats.health)
		return

	# Verify original stats unchanged
	if base_stats.health != 100:
		results.failed += 1
		results.errors.append("Original stats should not be modified")
		return

	results.passed += 1
	print("  [PASS] test_level_bonus_calculation")


static func _test_stats_to_string(results: Dictionary) -> void:
	"""Test stats_to_string formatting."""
	var stats = {"health": 150, "mana": 10, "defend_rate": 25}

	var str_result = StatCalculator.stats_to_string(stats)

	# Should contain HP, MP, DEF%
	if not str_result.contains("HP:150"):
		results.failed += 1
		results.errors.append("stats_to_string should contain 'HP:150', got '%s'" % str_result)
		return

	if not str_result.contains("MP:10"):
		results.failed += 1
		results.errors.append("stats_to_string should contain 'MP:10', got '%s'" % str_result)
		return

	if not str_result.contains("DEF%:25"):
		results.failed += 1
		results.errors.append("stats_to_string should contain 'DEF%%:25', got '%s'" % str_result)
		return

	# Should NOT contain income (Phase 1 change)
	if str_result.contains("INC"):
		results.failed += 1
		results.errors.append("stats_to_string should not contain income")
		return

	results.passed += 1
	print("  [PASS] test_stats_to_string")


static func _test_clone_stats(results: Dictionary) -> void:
	"""Test that clone_stats creates an independent copy."""
	var original = {"health": 100, "mana": 5}
	var clone = StatCalculator.clone_stats(original)

	# Modify clone
	clone.health = 200

	# Original should be unchanged
	if original.health != 100:
		results.failed += 1
		results.errors.append("Original stats should not be affected by clone modification")
		return

	if clone.health != 200:
		results.failed += 1
		results.errors.append("Clone should have modified value")
		return

	results.passed += 1
	print("  [PASS] test_clone_stats")
