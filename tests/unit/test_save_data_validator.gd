extends SceneTree
# Tests for SaveDataValidator
# Verifies save data validation framework structure and usage
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\auto-battle-journey" --script res://tests/unit/test_save_data_validator.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("SaveDataValidator Structure Tests")
	print("========================================\n")

	_test_validator_class_exists()
	_test_has_validate_method()
	_test_has_validation_result_class()
	_test_has_run_state_schema()
	_test_has_player_account_schema()
	_test_run_manager_uses_validation()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_validator_class_exists():
	"""Verify SaveDataValidator class exists."""
	print("TEST: SaveDataValidator class exists")

	var file = FileAccess.open("res://scripts/utils/save_data_validator.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open save_data_validator.gd")
		return

	var content = file.get_as_text()
	file.close()

	if content.contains("class_name SaveDataValidator"):
		_pass("SaveDataValidator class is defined")
	else:
		_fail("SaveDataValidator class not found")


func _test_has_validate_method():
	"""Verify SaveDataValidator has validate method."""
	print("TEST: Has validate method")

	var file = FileAccess.open("res://scripts/utils/save_data_validator.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open save_data_validator.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_validate = content.contains("static func validate(data: Dictionary, schema: Dictionary)")
	var has_validate_and_fix = content.contains("static func validate_and_fix(data: Dictionary, schema: Dictionary)")

	if has_validate and has_validate_and_fix:
		_pass("Has validate() and validate_and_fix() methods")
	else:
		var missing = []
		if not has_validate:
			missing.append("validate()")
		if not has_validate_and_fix:
			missing.append("validate_and_fix()")
		_fail("Missing methods: %s" % ", ".join(missing))


func _test_has_validation_result_class():
	"""Verify ValidationResult inner class exists."""
	print("TEST: Has ValidationResult class")

	var file = FileAccess.open("res://scripts/utils/save_data_validator.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open save_data_validator.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_class = content.contains("class ValidationResult:")
	var has_is_valid = content.contains("var is_valid: bool")
	var has_errors = content.contains("var errors:")

	if has_class and has_is_valid and has_errors:
		_pass("ValidationResult class with is_valid and errors")
	else:
		_fail("ValidationResult class incomplete")


func _test_has_run_state_schema():
	"""Verify predefined run state schema method exists."""
	print("TEST: Has get_run_state_schema()")

	var file = FileAccess.open("res://scripts/utils/save_data_validator.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open save_data_validator.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_method = content.contains("static func get_run_state_schema()")
	var has_run_id = content.contains("\"run_id\":")
	var has_round = content.contains("\"round\":")
	var has_phase = content.contains("\"phase\":")
	var has_team = content.contains("\"team\":")

	if has_method and has_run_id and has_round and has_phase and has_team:
		_pass("Run state schema has key fields defined")
	else:
		_fail("Run state schema incomplete")


func _test_has_player_account_schema():
	"""Verify predefined player account schema method exists."""
	print("TEST: Has get_player_account_schema()")

	var file = FileAccess.open("res://scripts/utils/save_data_validator.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open save_data_validator.gd")
		return

	var content = file.get_as_text()
	file.close()

	if content.contains("static func get_player_account_schema()"):
		_pass("Player account schema method exists")
	else:
		_fail("Missing get_player_account_schema() method")


func _test_run_manager_uses_validation():
	"""Verify RunManager uses SaveDataValidator when loading."""
	print("TEST: RunManager uses validation")

	var file = FileAccess.open("res://autoloads/run_manager.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open run_manager.gd")
		return

	var content = file.get_as_text()
	file.close()

	var preloads_validator = content.contains("preload(\"res://scripts/utils/save_data_validator.gd\")")
	var uses_validator = content.contains("validate_and_fix")
	var uses_schema = content.contains("get_run_state_schema")
	var validates_team = content.contains("_validate_team_data")

	if preloads_validator and uses_validator and uses_schema and validates_team:
		_pass("RunManager preloads and uses SaveDataValidator with schema and team validation")
	else:
		var missing = []
		if not preloads_validator:
			missing.append("preload SaveDataValidator")
		if not uses_validator:
			missing.append("validate_and_fix")
		if not uses_schema:
			missing.append("get_run_state_schema")
		if not validates_team:
			missing.append("_validate_team_data")
		_fail("RunManager not using: %s" % ", ".join(missing))


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
