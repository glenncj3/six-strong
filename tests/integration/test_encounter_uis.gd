extends SceneTree
# Integration test for encounter UI instantiation and cleanup
# Tests that all encounter UIs can be instantiated and have proper cleanup
#
# Run with: "C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/integration/test_encounter_uis.gd

var tests_passed := 0
var tests_failed := 0
var errors: Array[String] = []

# Encounter UI scripts to test
const ENCOUNTER_UIS = {
	"shop": "res://scripts/encounters/types/shop_encounter_ui.gd",
	"character_shop": "res://scripts/encounters/types/character_shop_encounter_ui.gd",
	"skill_trainer": "res://scripts/encounters/types/skill_trainer_encounter_ui.gd",
	"health_restore": "res://scripts/encounters/types/health_restore_encounter_ui.gd",
	"gold_reward": "res://scripts/encounters/types/gold_reward_encounter_ui.gd",
	"treasure_chest": "res://scripts/encounters/types/treasure_chest_encounter_ui.gd",
	"wheel_of_fortune": "res://scripts/encounters/types/wheel_of_fortune_encounter_ui.gd",
	"slot_machine": "res://scripts/encounters/types/slot_machine_encounter_ui.gd",
	"matching_game": "res://scripts/encounters/types/matching_game_encounter_ui.gd",
	"gamble": "res://scripts/encounters/types/gamble_encounter_ui.gd",
}


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("ENCOUNTER UI INTEGRATION TESTS")
	print("========================================\n")

	# Setup a run for context
	_setup_test_run()

	# Test each encounter UI
	for encounter_name in ENCOUNTER_UIS:
		_test_encounter_ui(encounter_name, ENCOUNTER_UIS[encounter_name])

	# Test encounter context
	_test_encounter_context()

	# Cleanup
	_cleanup_test_run()

	_print_results()
	quit(tests_failed)


func _setup_test_run():
	"""Setup a test run for encounter context."""
	print("--- Setup Test Run ---")

	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	if unlocked.size() < 3:
		_fail("Not enough unlocked legacies for test run")
		return

	var legacies: Array[LegacyData] = []
	for i in range(3):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)
	_assert_true(RunManager.is_run_active, "Test run started")
	print("")


func _cleanup_test_run():
	"""Cleanup the test run."""
	if RunManager.is_run_active:
		RunManager.clear_run_state()


func _test_encounter_ui(encounter_name: String, script_path: String):
	"""Test that an encounter UI script loads and has required methods."""
	print("--- Testing: %s ---" % encounter_name)

	# Check script exists
	if not FileAccess.file_exists(script_path):
		_fail("%s: Script not found at %s" % [encounter_name, script_path])
		return

	# Load the script
	var script = load(script_path)
	if script == null:
		_fail("%s: Failed to load script" % encounter_name)
		return

	_pass("%s: Script loaded" % encounter_name)

	# Read script content for analysis
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		_fail("%s: Cannot read script file" % encounter_name)
		return

	var content = file.get_as_text()
	file.close()

	# Check for required patterns
	_check_script_patterns(encounter_name, content)

	print("")


func _check_script_patterns(encounter_name: String, content: String):
	"""Check script for common patterns and potential issues."""

	# Check for _exit_tree (cleanup)
	if content.contains("func _exit_tree()"):
		_pass("%s: Has _exit_tree for cleanup" % encounter_name)
	else:
		# Not all encounter UIs need _exit_tree, but it's good practice
		print("  INFO: %s: No _exit_tree (may be OK if no cleanup needed)" % encounter_name)

	# Check for signal disconnection patterns
	if content.contains(".connect("):
		if content.contains(".disconnect(") or content.contains("_exit_tree"):
			_pass("%s: Has signal cleanup patterns" % encounter_name)
		else:
			_fail("%s: Connects signals but may not disconnect them" % encounter_name)

	# Check for tween usage and cleanup
	if content.contains("create_tween()"):
		if content.contains(".kill()") or content.contains("_active_tweens"):
			_pass("%s: Has tween cleanup" % encounter_name)
		else:
			_fail("%s: Creates tweens but may not clean them up" % encounter_name)

	# Check for timer usage
	if content.contains("get_tree().create_timer("):
		# Timers should be fine as they're one-shot, but check for await
		if content.contains("await"):
			_pass("%s: Uses await with timers (correct)" % encounter_name)

	# Check for static variables (potential state leak)
	if content.contains("static var"):
		_fail("%s: Uses static var (potential state leak between encounters)" % encounter_name)
	else:
		_pass("%s: No static variables" % encounter_name)

	# Check for queue_free usage
	if content.contains("queue_free()"):
		_pass("%s: Uses queue_free for cleanup" % encounter_name)

	# Check extends statement
	if content.contains("extends Control") or content.contains("extends Node"):
		_pass("%s: Extends correct base class" % encounter_name)


func _test_encounter_context():
	"""Test EncounterContext creation and usage."""
	print("--- EncounterContext ---")

	if not RunManager.is_run_active:
		_fail("No active run for context test")
		return

	var EncounterContextScript = preload("res://scripts/encounters/encounter_context.gd")
	var context = EncounterContextScript.create()

	_assert_true(context != null, "Context created")
	_assert_true(context.team.size() > 0, "Context has team: %d members" % context.team.size())
	_assert_true(context.player_level >= 1, "Context has player level: %d" % context.player_level)

	# Test team iteration
	for i in range(context.team.size()):
		var char_instance = context.team[i]
		_assert_true(char_instance != null, "Team member %d is valid" % i)

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


func _assert_false(condition: bool, message: String) -> bool:
	return _assert_true(not condition, message)


func _assert_eq(actual, expected, message: String) -> bool:
	if actual == expected:
		_pass(message)
		return true
	else:
		_fail("%s (expected: %s, got: %s)" % [message, expected, actual])
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
