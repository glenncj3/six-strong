extends SceneTree
# Data integrity tests - validates JSON data files and cross-references
#
# Run with: "C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/integration/test_data_integrity.gd

var tests_passed := 0
var tests_failed := 0
var errors: Array[String] = []


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("DATA INTEGRITY TESTS")
	print("========================================\n")

	_test_character_data_integrity()
	_test_legacy_data_integrity()
	_test_item_data_integrity()
	_test_skill_data_integrity()
	_test_encounter_type_integrity()
	_test_cross_references()

	_print_results()
	quit(tests_failed)


func _test_character_data_integrity():
	"""Validate all character data."""
	print("--- Character Data Integrity ---")

	var characters = GameData.get_all_characters()
	_assert_true(characters.size() > 0, "Characters exist: %d" % characters.size())

	var required_fields = ["id", "name", "base_stats"]
	var stat_fields = ["health", "charges", "agility"]

	for char_data in characters:
		var char_id = char_data.get("id", "UNKNOWN")

		# Check required fields
		for field in required_fields:
			if not char_data.has(field):
				_fail("Character %s missing field: %s" % [char_id, field])

		# Check base_stats structure
		if char_data.has("base_stats"):
			var stats = char_data["base_stats"]
			for stat in stat_fields:
				if not stats.has(stat):
					_fail("Character %s missing stat: %s" % [char_id, stat])

		# Verify ID is not empty
		if char_id.is_empty():
			_fail("Character has empty ID")

	_pass("All %d characters validated" % characters.size())
	print("")


func _test_legacy_data_integrity():
	"""Validate all legacy data."""
	print("--- Legacy Data Integrity ---")

	var legacies = GameData.get_all_legacies()
	_assert_true(legacies.size() > 0, "Legacies exist: %d" % legacies.size())

	var required_fields = ["id", "name", "starting_character_options", "income"]

	for legacy_data in legacies:
		var legacy_id = legacy_data.get("id", "UNKNOWN")

		# Check required fields
		for field in required_fields:
			if not legacy_data.has(field):
				_fail("Legacy %s missing field: %s" % [legacy_id, field])

		# Validate starting_character_options references exist
		if legacy_data.has("starting_character_options"):
			var starting_chars = legacy_data["starting_character_options"]
			for char_id in starting_chars:
				if not GameData.has_character(char_id):
					_fail("Legacy %s references non-existent character: %s" % [legacy_id, char_id])

		# Validate character_pool references exist
		if legacy_data.has("character_pool"):
			for char_id in legacy_data["character_pool"]:
				if not GameData.has_character(char_id):
					_fail("Legacy %s character_pool references non-existent character: %s" % [legacy_id, char_id])

		# Validate income is non-negative
		var income = legacy_data.get("income", 0)
		if income < 0:
			_fail("Legacy %s has negative income: %d" % [legacy_id, income])

	_pass("All %d legacies validated" % legacies.size())
	print("")


func _test_item_data_integrity():
	"""Validate all item data."""
	print("--- Item Data Integrity ---")

	var items = GameData.get_all_items()
	_assert_true(items.size() > 0, "Items exist: %d" % items.size())

	var required_fields = ["id", "name"]

	for item_data in items:
		var item_id = item_data.get("id", "UNKNOWN")

		# Check required fields
		for field in required_fields:
			if not item_data.has(field):
				_fail("Item %s missing field: %s" % [item_id, field])

		# Validate stat_modifiers if present
		if item_data.has("stat_modifiers"):
			var mods = item_data["stat_modifiers"]
			if not mods is Dictionary:
				_fail("Item %s stat_modifiers is not a Dictionary" % item_id)

	_pass("All %d items validated" % items.size())

	# Also test item upgrades
	var upgrades = GameData.get_all_item_upgrades()
	if upgrades.size() > 0:
		for upgrade_data in upgrades:
			var upgrade_id = upgrade_data.get("id", "UNKNOWN")
			if upgrade_data.has("base_item_id"):
				var base_id = upgrade_data["base_item_id"]
				if not GameData.has_item(base_id):
					_fail("Item upgrade %s references non-existent base item: %s" % [upgrade_id, base_id])
		_pass("All %d item upgrades validated" % upgrades.size())

	print("")


func _test_skill_data_integrity():
	"""Validate all skill data."""
	print("--- Skill Data Integrity ---")

	var skills = GameData.get_all_skills()
	_assert_true(skills.size() > 0, "Skills exist: %d" % skills.size())

	var required_fields = ["id", "name"]

	for skill_data in skills:
		var skill_id = skill_data.get("id", "UNKNOWN")

		# Check required fields
		for field in required_fields:
			if not skill_data.has(field):
				_fail("Skill %s missing field: %s" % [skill_id, field])

		# Validate effect if present
		if skill_data.has("effect"):
			var effect = skill_data["effect"]
			if not effect is Dictionary:
				_fail("Skill %s effect is not a Dictionary" % skill_id)
			elif not effect.has("type"):
				_fail("Skill %s effect missing type" % skill_id)

	_pass("All %d skills validated" % skills.size())
	print("")


func _test_encounter_type_integrity():
	"""Validate all encounter type definitions."""
	print("--- Encounter Type Integrity ---")

	var encounters = GameData.get_encounter_types()
	_assert_true(encounters.size() > 0, "Encounter types exist: %d" % encounters.size())

	var required_fields = ["type", "name", "weight"]

	for enc_data in encounters:
		var enc_type = enc_data.get("type", "UNKNOWN")

		# Check required fields
		for field in required_fields:
			if not enc_data.has(field):
				_fail("Encounter type %s missing field: %s" % [enc_type, field])

		# Validate weight is positive
		var weight = enc_data.get("weight", 0)
		if weight <= 0:
			_fail("Encounter type %s has non-positive weight: %d" % [enc_type, weight])

	_pass("All %d encounter types validated" % encounters.size())
	print("")


func _test_cross_references():
	"""Test cross-references between data files."""
	print("--- Cross-Reference Validation ---")

	# Test PlayerAccount starting legacy IDs exist
	var starting_ids = PlayerAccount.STARTING_LEGACY_IDS
	for legacy_id in starting_ids:
		if not GameData.has_legacy(legacy_id):
			_fail("Starting legacy ID not found in GameData: %s" % legacy_id)

	_pass("All starting legacy IDs valid")

	# Test unlocked legacies have valid character references
	var unlocked_legacies = PlayerAccount.get_unlocked_legacies()
	for legacy in unlocked_legacies:
		var starting_char = legacy.selected_starting_character_id
		if not starting_char.is_empty():
			if not GameData.has_character(starting_char):
				_fail("Legacy %s selected character not in GameData: %s" % [legacy.id, starting_char])

	_pass("All legacy character references valid")

	print("")


# =============================================================================
# ASSERTION HELPERS
# =============================================================================

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		_pass(message)
		return true
	else:
		_fail(message)
		return false


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	errors.append(msg)
	print("  FAIL: %s" % msg)


func _print_results():
	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])

	if errors.size() > 0:
		print("\nErrors:")
		for error in errors:
			print("  - %s" % error)

	print("========================================\n")
