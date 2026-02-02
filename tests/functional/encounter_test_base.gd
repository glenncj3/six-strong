class_name EncounterTestBase
extends RefCounted
## Base class for functional encounter tests
## Provides mock context, assertion helpers, and common test utilities

# Test results
var tests_passed := 0
var tests_failed := 0
var errors: Array[String] = []
var test_name := "EncounterTest"

# Mock context for tracking callbacks
var mock_context: Dictionary = {}

# Reset between tests
func reset_context() -> void:
	mock_context = {
		"gold_spent": 0,
		"gold_rewarded": 0,
		"health_restored": [],  # Array of {character, amount}
		"items_acquired": [],
		"skills_executed": [],
		"encounter_completed": false,
		"completion_count": 0,
		"team": [],
		"player_gold": 100,  # Starting gold for tests
		"player_level": 1,
	}


func create_mock_context() -> Dictionary:
	"""Create a mock EncounterContext-compatible dictionary for testing."""
	reset_context()

	# Setup mock team
	var team: Array[CharacterInstance] = []
	for i in range(3):
		var char_data = GameData.get_all_characters()[i % GameData.get_all_characters().size()]
		var char_instance = CharacterInstance.from_master_data(char_data["id"])
		if char_instance:
			# Set some damage so healing tests work
			char_instance.current_health = int(char_instance.stats.get("health", 100) * 0.5)
			team.append(char_instance)

	mock_context["team"] = team

	return {
		"team": team,
		"player_level": mock_context["player_level"],
		"player_gold": mock_context["player_gold"],

		# Callback functions
		"on_gold_spend": func(amount: int) -> bool:
			if mock_context["player_gold"] >= amount:
				mock_context["player_gold"] -= amount
				mock_context["gold_spent"] += amount
				return true
			return false,

		"on_gold_reward": func(amount: int):
			mock_context["player_gold"] += amount
			mock_context["gold_rewarded"] += amount,

		"on_health_restore": func(character: CharacterInstance, amount: int):
			mock_context["health_restored"].append({"character": character, "amount": amount}),

		"on_item_acquired": func(item_id: String):
			mock_context["items_acquired"].append(item_id),

		"on_skill_executed": func(skill_id: String):
			mock_context["skills_executed"].append(skill_id),

		"on_encounter_complete": func():
			mock_context["encounter_completed"] = true
			mock_context["completion_count"] += 1,

		"try_spend_gold": func(amount: int) -> bool:
			if mock_context["player_gold"] >= amount:
				mock_context["player_gold"] -= amount
				mock_context["gold_spent"] += amount
				return true
			return false,
	}


func create_mock_encounter_data(encounter_id: String, custom_data: Dictionary = {}) -> Dictionary:
	"""Create mock encounter data for testing."""
	var base_data = {
		"id": encounter_id,
		"type": encounter_id,
		"name": "Test %s" % encounter_id,
		"description": "Test encounter",
		"image_path": "",
		"bg_color": "#3D2E24",
		"hover_color": "#5D4E44",
		"pressed_color": "#2D1E14",
		"border_color": "#B88726",
		"data": custom_data
	}
	return base_data


# =============================================================================
# ASSERTION HELPERS
# =============================================================================

func assert_true(condition: bool, message: String) -> bool:
	if condition:
		_pass(message)
		return true
	else:
		_fail(message)
		return false


func assert_false(condition: bool, message: String) -> bool:
	return assert_true(not condition, message)


func assert_eq(actual, expected, message: String) -> bool:
	if actual == expected:
		_pass(message)
		return true
	else:
		_fail("%s (expected: %s, got: %s)" % [message, str(expected), str(actual)])
		return false


func assert_gt(actual: int, threshold: int, message: String) -> bool:
	if actual > threshold:
		_pass(message)
		return true
	else:
		_fail("%s (expected > %d, got: %d)" % [message, threshold, actual])
		return false


func assert_gte(actual: int, threshold: int, message: String) -> bool:
	if actual >= threshold:
		_pass(message)
		return true
	else:
		_fail("%s (expected >= %d, got: %d)" % [message, threshold, actual])
		return false


func assert_contains(container, value, message: String) -> bool:
	var found = false
	if container is Array:
		found = container.has(value)
	elif container is Dictionary:
		found = container.has(value)
	elif container is String:
		found = container.contains(str(value))

	if found:
		_pass(message)
		return true
	else:
		_fail("%s (value not found)" % message)
		return false


func assert_gold_spent(expected: int, message: String = "") -> bool:
	var msg = message if message else "Gold spent: %d" % expected
	return assert_eq(mock_context["gold_spent"], expected, msg)


func assert_gold_rewarded(expected: int, message: String = "") -> bool:
	var msg = message if message else "Gold rewarded: %d" % expected
	return assert_eq(mock_context["gold_rewarded"], expected, msg)


func assert_encounter_completed(message: String = "") -> bool:
	var msg = message if message else "Encounter completed"
	return assert_true(mock_context["encounter_completed"], msg)


func assert_encounter_not_completed(message: String = "") -> bool:
	var msg = message if message else "Encounter not yet completed"
	return assert_false(mock_context["encounter_completed"], msg)


func _pass(msg: String):
	tests_passed += 1
	print("    PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	errors.append(msg)
	print("    FAIL: %s" % msg)


func section(name: String):
	print("\n  --- %s ---" % name)


func get_results() -> Dictionary:
	return {
		"passed": tests_passed,
		"failed": tests_failed,
		"errors": errors
	}
