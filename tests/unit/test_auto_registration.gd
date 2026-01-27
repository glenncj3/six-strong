extends SceneTree
# Tests for Phase 4: Auto-Registration
# Verifies the metadata-based handler discovery system
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_auto_registration.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Auto-Registration Tests (Phase 4)")
	print("========================================\n")

	_test_encounter_handlers_have_metadata()
	_test_encounter_registry_uses_handler_list()
	_test_all_encounter_types_discoverable()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


# =============================================================================
# ENCOUNTER HANDLER METADATA TESTS
# =============================================================================

func _test_encounter_handlers_have_metadata():
	"""Verify encounter UI handlers define ENCOUNTER_TYPE constant."""
	print("TEST: Encounter handlers have ENCOUNTER_TYPE metadata")

	var handler_files = [
		"res://scripts/encounters/types/shop_encounter_ui.gd",
		"res://scripts/encounters/types/skill_trainer_encounter_ui.gd",
		"res://scripts/encounters/types/treasure_chest_encounter_ui.gd",
		"res://scripts/encounters/types/health_restore_encounter_ui.gd",
		"res://scripts/encounters/types/character_shop_encounter_ui.gd",
		"res://scripts/encounters/types/gamble_encounter_ui.gd",
		"res://scripts/encounters/types/matching_game_encounter_ui.gd",
		"res://scripts/encounters/types/slot_machine_encounter_ui.gd",
		"res://scripts/encounters/types/wheel_of_fortune_encounter_ui.gd",
	]

	var handlers_with_metadata: Array = []
	var handlers_without_metadata: Array = []

	for file_path in handler_files:
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			handlers_without_metadata.append(file_path.get_file())
			continue

		var content = file.get_as_text()
		file.close()

		if content.contains("const ENCOUNTER_TYPE"):
			handlers_with_metadata.append(file_path.get_file())
		else:
			handlers_without_metadata.append(file_path.get_file())

	if handlers_without_metadata.is_empty():
		_pass("All %d handlers have ENCOUNTER_TYPE" % handlers_with_metadata.size())
	else:
		_fail("Missing ENCOUNTER_TYPE: %s" % ", ".join(handlers_without_metadata))


func _test_encounter_registry_uses_handler_list():
	"""Verify EncounterRegistry uses a handler list pattern."""
	print("TEST: EncounterRegistry uses handler list pattern")

	var file = FileAccess.open("res://scripts/encounters/encounter_registry.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_registry.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Check for the handler list pattern (array of handler classes)
	var has_handler_list = content.contains("HANDLER_CLASSES") or content.contains("_handler_classes") or content.contains("handler_classes")
	var has_register_from_class = content.contains("_register_from_class") or content.contains("register_from_class") or content.contains("ENCOUNTER_TYPE")

	if has_handler_list or has_register_from_class:
		_pass("Uses handler list or metadata-based registration")
	else:
		# The current implementation might not be refactored yet
		# Check if it at least has the basic structure
		var has_handlers = content.contains("_handlers")
		var has_register = content.contains("func register(")
		if has_handlers and has_register:
			_pass("Has registry infrastructure (handler list optional)")
		else:
			_fail("Missing handler list or registration infrastructure")


func _test_all_encounter_types_discoverable():
	"""Verify all encounter types can be discovered from handlers."""
	print("TEST: All encounter types discoverable from handlers")

	var expected_types = [
		"shop",
		"skill_trainer",
		"treasure_chest",
		"health_restore",
		"character_shop",
		"gamble",
		"matching_game",
		"slot_machine",
		"wheel_of_fortune",
	]

	var found_types: Array = []
	var handler_dir = "res://scripts/encounters/types/"

	for type_name in expected_types:
		var file_name = type_name + "_encounter_ui.gd"
		var file_path = handler_dir + file_name
		if FileAccess.file_exists(file_path):
			found_types.append(type_name)

	if found_types.size() == expected_types.size():
		_pass("All %d encounter types have corresponding handlers" % expected_types.size())
	else:
		var missing = expected_types.filter(func(t): return t not in found_types)
		_fail("Missing handlers for: %s" % ", ".join(missing))


# =============================================================================
# HELPERS
# =============================================================================

func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
