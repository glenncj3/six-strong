extends SceneTree
# Tests for character_shop_encounter_ui.gd state management
# Verifies no static state variables are used (prevents race conditions)
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_character_shop_state.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Character Shop State Tests")
	print("========================================\n")

	_test_no_static_state_variable()
	_test_uses_one_shot_connection()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_no_static_state_variable():
	"""Verify character_shop_encounter_ui.gd does not use static var for state."""
	print("TEST: No static state variable")

	var file = FileAccess.open("res://scripts/encounters/types/character_shop_encounter_ui.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open character_shop_encounter_ui.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Check for static var _pending_state
	if content.contains("static var _pending_state"):
		_fail("character_shop_encounter_ui.gd uses static _pending_state (race condition risk)")
		return

	_pass("No static state variable found")


func _test_uses_one_shot_connection():
	"""Verify signal connections use CONNECT_ONE_SHOT or proper cleanup."""
	print("TEST: Uses one-shot or proper signal cleanup")

	var file = FileAccess.open("res://scripts/encounters/types/character_shop_encounter_ui.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open character_shop_encounter_ui.gd")
		return

	var content = file.get_as_text()
	file.close()

	# If it connects to character_acquired, it should use CONNECT_ONE_SHOT or bind state
	if content.contains("character_acquired.connect("):
		# Should use CONNECT_ONE_SHOT to auto-disconnect
		if content.contains("CONNECT_ONE_SHOT"):
			_pass("Uses CONNECT_ONE_SHOT for auto-disconnect")
			return
		# Or should bind state directly
		if content.contains(".bind(state)") or content.contains(".bind(state,"):
			_pass("Binds state directly to callback (no static needed)")
			return
		_fail("character_acquired connection doesn't use CONNECT_ONE_SHOT or bind state")
		return

	_pass("No character_acquired connection found (may be refactored)")


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
