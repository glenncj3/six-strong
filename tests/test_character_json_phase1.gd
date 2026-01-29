extends Node
# Test script for Character JSON schema (Phase 1 refactor)
# Verifies the new character JSON format: no prestige_rewards, no income, has cost/level_requirement/description
# Note: No class_name - loaded via preload in run_tests.gd


static func run_all_tests() -> Dictionary:
	"""Run all Character JSON tests and return results."""
	var results = {
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	# Run each test
	_test_json_loads_without_error(results)
	_test_no_prestige_rewards(results)
	_test_no_income_in_base_stats(results)
	_test_no_starting_item_slots(results)
	_test_has_cost_field(results)
	_test_has_level_requirement(results)
	_test_has_description(results)
	_test_base_stats_structure(results)
	_test_all_characters_valid(results)

	return results


static func _load_characters_json() -> Dictionary:
	"""Load characters.json file."""
	var path = "res://data/characters/characters.json"
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		return {}
	return json.data


static func _test_json_loads_without_error(results: Dictionary) -> void:
	"""Test that characters.json loads successfully."""
	var data = _load_characters_json()

	if data.is_empty():
		results.failed += 1
		results.errors.append("Failed to load characters.json")
		return

	if not data.has("characters"):
		results.failed += 1
		results.errors.append("characters.json should have 'characters' array")
		return

	if data.characters.size() == 0:
		results.failed += 1
		results.errors.append("characters array should not be empty")
		return

	results.passed += 1
	print("  [PASS] test_json_loads_without_error")


static func _test_no_prestige_rewards(results: Dictionary) -> void:
	"""Test that no characters have prestige_rewards field."""
	var data = _load_characters_json()
	if data.is_empty():
		results.failed += 1
		results.errors.append("Failed to load JSON for test")
		return

	for char_data in data.characters:
		if char_data.has("prestige_rewards"):
			results.failed += 1
			results.errors.append("Character '%s' should not have prestige_rewards (Phase 1)" % char_data.get("id", "unknown"))
			return

	results.passed += 1
	print("  [PASS] test_no_prestige_rewards")


static func _test_no_income_in_base_stats(results: Dictionary) -> void:
	"""Test that no characters have income in base_stats."""
	var data = _load_characters_json()
	if data.is_empty():
		results.failed += 1
		results.errors.append("Failed to load JSON for test")
		return

	for char_data in data.characters:
		var base_stats = char_data.get("base_stats", {})
		if base_stats.has("income"):
			results.failed += 1
			results.errors.append("Character '%s' base_stats should not have income (Phase 1)" % char_data.get("id", "unknown"))
			return

	results.passed += 1
	print("  [PASS] test_no_income_in_base_stats")


static func _test_no_starting_item_slots(results: Dictionary) -> void:
	"""Test that no characters have startingItemSlots in base_stats."""
	var data = _load_characters_json()
	if data.is_empty():
		results.failed += 1
		results.errors.append("Failed to load JSON for test")
		return

	for char_data in data.characters:
		var base_stats = char_data.get("base_stats", {})
		if base_stats.has("startingItemSlots"):
			results.failed += 1
			results.errors.append("Character '%s' base_stats should not have startingItemSlots (Phase 1)" % char_data.get("id", "unknown"))
			return

	results.passed += 1
	print("  [PASS] test_no_starting_item_slots")


static func _test_has_cost_field(results: Dictionary) -> void:
	"""Test that all characters have a cost field."""
	var data = _load_characters_json()
	if data.is_empty():
		results.failed += 1
		results.errors.append("Failed to load JSON for test")
		return

	for char_data in data.characters:
		if not char_data.has("cost"):
			results.failed += 1
			results.errors.append("Character '%s' should have cost field (Phase 1)" % char_data.get("id", "unknown"))
			return

		var cost = char_data.get("cost", -1)
		if cost < 0:
			results.failed += 1
			results.errors.append("Character '%s' cost should be >= 0, got %d" % [char_data.get("id", "unknown"), cost])
			return

	results.passed += 1
	print("  [PASS] test_has_cost_field")


static func _test_has_level_requirement(results: Dictionary) -> void:
	"""Test that all characters have a level_requirement field."""
	var data = _load_characters_json()
	if data.is_empty():
		results.failed += 1
		results.errors.append("Failed to load JSON for test")
		return

	for char_data in data.characters:
		if not char_data.has("level_requirement"):
			results.failed += 1
			results.errors.append("Character '%s' should have level_requirement field (Phase 1)" % char_data.get("id", "unknown"))
			return

		var level_req = char_data.get("level_requirement", 0)
		if level_req < 1:
			results.failed += 1
			results.errors.append("Character '%s' level_requirement should be >= 1, got %d" % [char_data.get("id", "unknown"), level_req])
			return

	results.passed += 1
	print("  [PASS] test_has_level_requirement")


static func _test_has_description(results: Dictionary) -> void:
	"""Test that all characters have a description field."""
	var data = _load_characters_json()
	if data.is_empty():
		results.failed += 1
		results.errors.append("Failed to load JSON for test")
		return

	for char_data in data.characters:
		if not char_data.has("description"):
			results.failed += 1
			results.errors.append("Character '%s' should have description field (Phase 1)" % char_data.get("id", "unknown"))
			return

		# Description field exists (may be empty for placeholders)
		var _desc = char_data.get("description", "")

	results.passed += 1
	print("  [PASS] test_has_description")


static func _test_base_stats_structure(results: Dictionary) -> void:
	"""Test that base_stats has required fields: health, charges, agility."""
	var data = _load_characters_json()
	if data.is_empty():
		results.failed += 1
		results.errors.append("Failed to load JSON for test")
		return

	for char_data in data.characters:
		var base_stats = char_data.get("base_stats", {})

		if not base_stats.has("health"):
			results.failed += 1
			results.errors.append("Character '%s' base_stats should have health" % char_data.get("id", "unknown"))
			return

		if not base_stats.has("charges"):
			results.failed += 1
			results.errors.append("Character '%s' base_stats should have charges" % char_data.get("id", "unknown"))
			return

		if not base_stats.has("agility"):
			results.failed += 1
			results.errors.append("Character '%s' base_stats should have agility" % char_data.get("id", "unknown"))
			return

	results.passed += 1
	print("  [PASS] test_base_stats_structure")


static func _test_all_characters_valid(results: Dictionary) -> void:
	"""Test that all characters have required fields: id, name, image_path."""
	var data = _load_characters_json()
	if data.is_empty():
		results.failed += 1
		results.errors.append("Failed to load JSON for test")
		return

	var required_fields = ["id", "name", "image_path", "cost", "level_requirement", "description", "base_stats"]

	for char_data in data.characters:
		for field in required_fields:
			if not char_data.has(field):
				results.failed += 1
				results.errors.append("Character missing required field '%s'" % field)
				return

		# Verify id is not empty
		var char_id = char_data.get("id", "")
		if char_id.is_empty():
			results.failed += 1
			results.errors.append("Character has empty id")
			return

	results.passed += 1
	print("  [PASS] test_all_characters_valid")
