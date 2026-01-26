extends SceneTree
# Tests for SceneTransitionData autoload
# Verifies typed scene transition data storage and retrieval
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\auto-battle-journey" --script res://tests/unit/test_scene_transition_data.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("SceneTransitionData Structure Tests")
	print("========================================\n")

	_test_autoload_exists()
	_test_has_encounter_methods()
	_test_has_combat_methods()
	_test_has_run_results_methods()
	_test_scenes_use_typed_data()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_autoload_exists():
	"""Verify SceneTransitionData class exists."""
	print("TEST: SceneTransitionData script exists")

	var file = FileAccess.open("res://autoloads/scene_transition_data.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open scene_transition_data.gd")
		return

	var content = file.get_as_text()
	file.close()

	if content.contains("extends Node"):
		_pass("SceneTransitionData script exists and extends Node")
	else:
		_fail("SceneTransitionData does not extend Node")


func _test_has_encounter_methods():
	"""Verify encounter data methods exist."""
	print("TEST: Has encounter data methods")

	var file = FileAccess.open("res://autoloads/scene_transition_data.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open scene_transition_data.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_set = content.contains("func set_encounter(encounter_data: Dictionary)")
	var has_get = content.contains("func get_encounter(")
	var has_check = content.contains("func has_encounter()")

	if has_set and has_get and has_check:
		_pass("Has set_encounter, get_encounter, has_encounter methods")
	else:
		_fail("Missing encounter methods")


func _test_has_combat_methods():
	"""Verify combat data methods exist."""
	print("TEST: Has combat data methods")

	var file = FileAccess.open("res://autoloads/scene_transition_data.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open scene_transition_data.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_set = content.contains("func set_combat(combat_data: Dictionary)")
	var has_get = content.contains("func get_combat(")
	var has_check = content.contains("func has_combat()")

	if has_set and has_get and has_check:
		_pass("Has set_combat, get_combat, has_combat methods")
	else:
		_fail("Missing combat methods")


func _test_has_run_results_methods():
	"""Verify run results data methods exist."""
	print("TEST: Has run results data methods")

	var file = FileAccess.open("res://autoloads/scene_transition_data.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open scene_transition_data.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_set = content.contains("func set_run_results(results_data: Dictionary)")
	var has_get = content.contains("func get_run_results(")
	var has_check = content.contains("func has_run_results()")

	if has_set and has_get and has_check:
		_pass("Has set_run_results, get_run_results, has_run_results methods")
	else:
		_fail("Missing run results methods")


func _test_scenes_use_typed_data():
	"""Verify scenes use SceneTransitionData instead of SceneManager.scene_data."""
	print("TEST: Scenes use SceneTransitionData")

	var files_to_check = [
		"res://scenes/ui/run_view.gd",
		"res://scenes/ui/encounter_active.gd",
		"res://scenes/ui/combat_stub.gd",
		"res://scenes/ui/run_results.gd"
	]

	var all_use_typed = true
	var issues = []

	for file_path in files_to_check:
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			issues.append("Cannot open: %s" % file_path)
			all_use_typed = false
			continue

		var content = file.get_as_text()
		file.close()

		# Check for old-style usage (should not be present)
		if content.contains("SceneManager.set_scene_data(\"selected_"):
			issues.append("%s still uses SceneManager.set_scene_data" % file_path.get_file())
			all_use_typed = false
		if content.contains("SceneManager.get_scene_data(\"selected_"):
			issues.append("%s still uses SceneManager.get_scene_data" % file_path.get_file())
			all_use_typed = false

	if all_use_typed:
		_pass("All checked scenes use SceneTransitionData")
	else:
		_fail("Issues found: %s" % ", ".join(issues))


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
