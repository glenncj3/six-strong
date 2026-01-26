extends SceneTree
# Tests that group lookups have been replaced with signal-based communication
# Verifies that draft.gd no longer uses get_first_node_in_group for HUD communication
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\auto-battle-journey" --script res://tests/unit/test_no_group_lookups.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Group Lookup Replacement Tests")
	print("========================================\n")

	_test_draft_no_group_lookups()
	_test_run_manager_has_draft_signals()
	_test_huds_connect_to_signals()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_draft_no_group_lookups():
	"""Verify draft.gd doesn't use get_first_node_in_group for HUD communication."""
	print("TEST: draft.gd uses signals instead of group lookups")

	var file = FileAccess.open("res://scenes/ui/draft.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open draft.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Check that get_first_node_in_group is NOT used for HUD communication
	var uses_team_hud_lookup = content.contains("get_first_node_in_group(\"team_hud\")")
	var uses_run_hud_lookup = content.contains("get_first_node_in_group(\"run_hud\")")

	if uses_team_hud_lookup:
		_fail("draft.gd still uses get_first_node_in_group for team_hud")
	elif uses_run_hud_lookup:
		_fail("draft.gd still uses get_first_node_in_group for run_hud")
	else:
		_pass("draft.gd no longer uses group lookups for HUD communication")


func _test_run_manager_has_draft_signals():
	"""Verify RunManager has draft-related signals for HUD communication."""
	print("TEST: RunManager has draft signals")

	var file = FileAccess.open("res://autoloads/run_manager.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open run_manager.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_draft_char_signal = content.contains("signal draft_character_added")
	var has_draft_gold_signal = content.contains("signal draft_gold_updated")
	var has_notify_char = content.contains("func notify_draft_character_added")
	var has_notify_gold = content.contains("func notify_draft_gold_updated")

	if has_draft_char_signal and has_draft_gold_signal and has_notify_char and has_notify_gold:
		_pass("RunManager has all draft signals and notify methods")
	else:
		var missing = []
		if not has_draft_char_signal:
			missing.append("draft_character_added signal")
		if not has_draft_gold_signal:
			missing.append("draft_gold_updated signal")
		if not has_notify_char:
			missing.append("notify_draft_character_added method")
		if not has_notify_gold:
			missing.append("notify_draft_gold_updated method")
		_fail("RunManager missing: %s" % ", ".join(missing))


func _test_huds_connect_to_signals():
	"""Verify HUDs connect to RunManager draft signals."""
	print("TEST: HUDs connect to RunManager draft signals")

	# Check team_hud.gd
	var team_file = FileAccess.open("res://scenes/components/team_hud.gd", FileAccess.READ)
	if team_file == null:
		_fail("Cannot open team_hud.gd")
		return
	var team_content = team_file.get_as_text()
	team_file.close()

	# Check run_hud.gd
	var run_file = FileAccess.open("res://scenes/components/run_hud.gd", FileAccess.READ)
	if run_file == null:
		_fail("Cannot open run_hud.gd")
		return
	var run_content = run_file.get_as_text()
	run_file.close()

	var team_connects = team_content.contains("RunManager.draft_character_added.connect")
	var run_connects = run_content.contains("RunManager.draft_gold_updated.connect")

	if team_connects and run_connects:
		_pass("Both HUDs connect to RunManager draft signals")
	else:
		var missing = []
		if not team_connects:
			missing.append("TeamHUD not connected to draft_character_added")
		if not run_connects:
			missing.append("RunHUD not connected to draft_gold_updated")
		_fail("Missing connections: %s" % ", ".join(missing))


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
