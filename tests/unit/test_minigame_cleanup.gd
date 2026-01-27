extends SceneTree
# Tests for wheel_of_fortune and slot_machine cleanup
# Verifies _exit_tree exists with proper signal disconnect and tween cleanup
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_minigame_cleanup.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Minigame Cleanup Tests")
	print("========================================\n")

	_test_wheel_has_exit_tree()
	_test_wheel_disconnects_signals()
	_test_wheel_has_tween_cleanup()
	_test_slot_machine_has_exit_tree()
	_test_slot_machine_has_tween_cleanup()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_wheel_has_exit_tree():
	"""Verify WheelEncounterContainer has _exit_tree function."""
	print("TEST: WheelEncounterContainer has _exit_tree")
	_verify_has_exit_tree("res://scripts/encounters/types/wheel_of_fortune_encounter_ui.gd", "WheelEncounterContainer")


func _test_wheel_disconnects_signals():
	"""Verify WheelEncounterContainer disconnects controller signals."""
	print("TEST: WheelEncounterContainer disconnects signals")

	var file = FileAccess.open("res://scripts/encounters/types/wheel_of_fortune_encounter_ui.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open wheel_of_fortune_encounter_ui.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Should disconnect the controller signals it connects to
	var expected_disconnects = ["state_changed", "spin_started", "spin_ended", "reward_applied"]
	var missing = []

	for signal_name in expected_disconnects:
		if not content.contains("%s.disconnect(" % signal_name):
			missing.append(signal_name)

	if missing.size() > 0:
		_fail("Missing disconnect for: %s" % ", ".join(missing))
		return

	_pass("All controller signals properly disconnected")


func _test_wheel_has_tween_cleanup():
	"""Verify WheelEncounterContainer has tween cleanup."""
	print("TEST: WheelEncounterContainer has tween cleanup")
	_verify_has_tween_cleanup("res://scripts/encounters/types/wheel_of_fortune_encounter_ui.gd")


func _test_slot_machine_has_exit_tree():
	"""Verify SlotMachineController has _exit_tree function."""
	print("TEST: SlotMachineController has _exit_tree")
	_verify_has_exit_tree("res://scripts/encounters/types/slot_machine_encounter_ui.gd", "SlotMachineController")


func _test_slot_machine_has_tween_cleanup():
	"""Verify SlotMachineController has tween cleanup."""
	print("TEST: SlotMachineController has tween cleanup")
	_verify_has_tween_cleanup("res://scripts/encounters/types/slot_machine_encounter_ui.gd")


func _verify_has_exit_tree(script_path: String, class_name_hint: String):
	"""Check that a script has _exit_tree function."""
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		_fail("Cannot open %s" % script_path)
		return

	var content = file.get_as_text()
	file.close()

	if not content.contains("func _exit_tree()"):
		_fail("%s missing _exit_tree() in %s" % [class_name_hint, script_path.get_file()])
		return

	_pass("%s has _exit_tree()" % class_name_hint)


func _verify_has_tween_cleanup(script_path: String):
	"""Check that a script has tween tracking and cleanup."""
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		_fail("Cannot open %s" % script_path)
		return

	var content = file.get_as_text()
	file.close()

	var filename = script_path.get_file()

	# Should have tween tracking (either _active_tweens array or TweenTracker)
	var has_tracking = content.contains("_active_tweens") or content.contains("_tweens: TweenTracker") or content.contains("_tweens:")
	if not has_tracking:
		_fail("%s missing tween tracking (_active_tweens or TweenTracker)" % filename)
		return

	# Should have cleanup (either manual kill() or TweenTracker.kill_all())
	var has_cleanup = content.contains(".kill()") or content.contains(".kill_all()")
	if not has_cleanup:
		_fail("%s missing tween cleanup (kill() or kill_all())" % filename)
		return

	_pass("%s has tween tracking and cleanup" % filename)


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
