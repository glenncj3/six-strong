extends SceneTree
# Tests for signal cleanup - verifies _exit_tree methods exist and properly disconnect signals
# This test validates the code structure without requiring autoloads
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\auto-battle-journey" --script res://tests/unit/test_signal_cleanup.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Signal Cleanup Structure Tests")
	print("========================================\n")

	_test_run_results_has_exit_tree()
	_test_collection_has_exit_tree()
	_test_main_menu_has_exit_tree()
	_test_combat_stub_has_exit_tree()
	_test_run_view_has_exit_tree()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_run_results_has_exit_tree():
	"""Verify run_results.gd has _exit_tree with disconnect calls."""
	print("TEST: run_results.gd signal cleanup")
	_verify_script_has_exit_tree_cleanup(
		"res://scenes/ui/run_results.gd",
		["gems_changed", "reroll_tokens_changed"]
	)


func _test_collection_has_exit_tree():
	"""Verify collection.gd has _exit_tree with disconnect calls."""
	print("TEST: collection.gd signal cleanup")
	_verify_script_has_exit_tree_cleanup(
		"res://scenes/ui/collection.gd",
		["gems_changed", "reroll_tokens_changed"]
	)


func _test_main_menu_has_exit_tree():
	"""Verify main_menu.gd has _exit_tree with disconnect calls."""
	print("TEST: main_menu.gd signal cleanup")
	_verify_script_has_exit_tree_cleanup(
		"res://scenes/ui/main_menu.gd",
		["gems_changed", "reroll_tokens_changed"]
	)


func _test_combat_stub_has_exit_tree():
	"""Verify combat_stub.gd has _exit_tree with disconnect calls."""
	print("TEST: combat_stub.gd signal cleanup")
	_verify_script_has_exit_tree_cleanup(
		"res://scenes/ui/combat_stub.gd",
		["combat_completed"]
	)


func _test_run_view_has_exit_tree():
	"""Verify run_view.gd has _exit_tree (reference implementation)."""
	print("TEST: run_view.gd signal cleanup (reference)")
	_verify_script_has_exit_tree_cleanup(
		"res://scenes/ui/run_view.gd",
		["phase_changed"]
	)


func _verify_script_has_exit_tree_cleanup(script_path: String, expected_signals: Array):
	"""Check that a script has _exit_tree with disconnect calls for expected signals."""
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		_fail("Cannot open %s" % script_path)
		return

	var content = file.get_as_text()
	file.close()

	# Check for _exit_tree function
	if not content.contains("func _exit_tree()"):
		_fail("%s missing _exit_tree() function" % script_path.get_file())
		return

	# Check for disconnect calls for each expected signal
	var all_found = true
	for signal_name in expected_signals:
		# Look for disconnect pattern: .signal_name.disconnect( or signal_name.is_connected
		var has_disconnect = content.contains("%s.disconnect(" % signal_name) or content.contains("%s.is_connected(" % signal_name)
		if not has_disconnect:
			_fail("%s: missing disconnect for '%s'" % [script_path.get_file(), signal_name])
			all_found = false

	if all_found:
		_pass("%s has proper _exit_tree with disconnects for %s" % [script_path.get_file(), expected_signals])


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
