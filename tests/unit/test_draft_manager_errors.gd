extends SceneTree
# Tests for LegacyDraftManager error propagation (Phase 4)
# Verifies that LegacyDraftManager properly signals errors instead of silent failures
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_draft_manager_errors.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("LegacyDraftManager Error Propagation Tests")
	print("========================================\n")

	_test_has_generation_failed_signal()
	_test_generate_options_returns_bool()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_has_generation_failed_signal():
	"""Verify LegacyDraftManager has a generation_failed signal."""
	print("TEST: LegacyDraftManager has generation_failed signal")

	var file = FileAccess.open("res://scripts/managers/legacy_draft_manager.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open legacy_draft_manager.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Check for generation_failed signal
	if content.contains("signal generation_failed"):
		_pass("LegacyDraftManager has generation_failed signal")
	else:
		_fail("LegacyDraftManager missing generation_failed signal")


func _test_generate_options_returns_bool():
	"""Verify generate_options() returns bool to indicate success/failure."""
	print("TEST: generate_options() returns bool")

	var file = FileAccess.open("res://scripts/managers/legacy_draft_manager.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open legacy_draft_manager.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Check for bool return type
	if content.contains("func generate_options() -> bool:"):
		_pass("generate_options() returns bool")
	else:
		_fail("generate_options() should return bool, not void")


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
