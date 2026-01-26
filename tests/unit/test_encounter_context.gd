extends SceneTree
# Tests for the typed EncounterContext class
# Verifies type safety and proper interface definition
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\auto-battle-journey" --script res://tests/unit/test_encounter_context.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("EncounterContext Type Safety Tests")
	print("========================================\n")

	_test_encounter_context_exists()
	_test_has_all_callbacks()
	_test_to_dict_conversion()
	_test_from_dict_creation()
	_test_encounter_active_uses_context()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_encounter_context_exists():
	"""Verify EncounterContext class exists."""
	print("TEST: EncounterContext class exists")

	var file = FileAccess.open("res://scripts/encounters/encounter_context.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_context.gd")
		return

	var content = file.get_as_text()
	file.close()

	if content.contains("class_name EncounterContext"):
		_pass("EncounterContext class is defined")
	else:
		_fail("EncounterContext class not found")


func _test_has_all_callbacks():
	"""Verify EncounterContext has all required callback properties."""
	print("TEST: EncounterContext has all callback properties")

	var file = FileAccess.open("res://scripts/encounters/encounter_context.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_context.gd")
		return

	var content = file.get_as_text()
	file.close()

	var required_callbacks = [
		"var set_gold_label: Callable",
		"var on_buy_item: Callable",
		"var on_buy_skill: Callable",
		"var on_xp_select: Callable",
		"var on_encounter_complete: Callable",
		"var on_gold_reward: Callable",
		"var on_health_restore: Callable",
		"var on_skill_learn: Callable",
		"var on_gold_spend: Callable",
		"var on_xp_reward_all: Callable",
	]

	var missing = []
	for callback in required_callbacks:
		if not content.contains(callback):
			missing.append(callback.split(":")[0].replace("var ", ""))

	if missing.is_empty():
		_pass("All %d callback properties defined" % required_callbacks.size())
	else:
		_fail("Missing callbacks: %s" % ", ".join(missing))


func _test_to_dict_conversion():
	"""Verify EncounterContext has to_dict() for backwards compatibility."""
	print("TEST: EncounterContext has to_dict() method")

	var file = FileAccess.open("res://scripts/encounters/encounter_context.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_context.gd")
		return

	var content = file.get_as_text()
	file.close()

	if content.contains("func to_dict() -> Dictionary:"):
		_pass("to_dict() method exists for backwards compatibility")
	else:
		_fail("Missing to_dict() method")


func _test_from_dict_creation():
	"""Verify EncounterContext has from_dict() factory method."""
	print("TEST: EncounterContext has from_dict() factory")

	var file = FileAccess.open("res://scripts/encounters/encounter_context.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_context.gd")
		return

	var content = file.get_as_text()
	file.close()

	if content.contains("static func from_dict(dict: Dictionary) -> EncounterContext:"):
		_pass("from_dict() factory method exists")
	else:
		_fail("Missing from_dict() factory method")


func _test_encounter_active_uses_context():
	"""Verify encounter_active.gd uses typed EncounterContext."""
	print("TEST: encounter_active.gd uses typed EncounterContext")

	var file = FileAccess.open("res://scenes/ui/encounter_active.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_active.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_context_class = content.contains("EncounterContext.new()")
	var uses_typed_assignment = content.contains("context.on_encounter_complete")

	if uses_context_class and uses_typed_assignment:
		_pass("encounter_active.gd uses typed EncounterContext")
	else:
		var missing = []
		if not uses_context_class:
			missing.append("EncounterContext.new()")
		if not uses_typed_assignment:
			missing.append("typed property assignments")
		_fail("encounter_active.gd not using: %s" % ", ".join(missing))


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
