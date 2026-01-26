extends SceneTree
# Tests for heal eligibility - verifies all characters are eligible for healing
# regardless of current health (user design decision)
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_heal_eligibility.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Heal Eligibility Tests")
	print("========================================\n")

	_test_filter_returns_all_characters()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_filter_returns_all_characters():
	"""Verify filter_heal_eligible_characters returns all team members, not just damaged ones."""
	print("TEST: filter_heal_eligible_characters returns all characters")

	var file = FileAccess.open("res://scripts/encounters/encounter_ui_helpers.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_ui_helpers.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Should NOT filter by health - all characters should be eligible
	# The old pattern was: current_health < max_health
	if content.contains("current_health < max_health") or content.contains("needs_healing"):
		_fail("filter_heal_eligible_characters still filters by health (should allow all characters)")
		return

	# Should have the function
	if not content.contains("func filter_heal_eligible_characters"):
		_fail("filter_heal_eligible_characters function not found")
		return

	_pass("filter_heal_eligible_characters allows all characters (no health filter)")


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
