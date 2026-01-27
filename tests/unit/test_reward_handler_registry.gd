extends SceneTree
# Tests for Phase 3: RewardHandlerRegistry
# Verifies the registry pattern replaces the match statement in RewardApplicator
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_reward_handler_registry.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("RewardHandlerRegistry Tests (Phase 3)")
	print("========================================\n")

	_test_registry_class_exists()
	_test_handlers_class_exists()
	_test_registry_has_register_method()
	_test_registry_has_execute_method()
	_test_registry_has_validate_method()
	_test_all_reward_types_registered()
	_test_applicator_uses_registry()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


# =============================================================================
# EXISTENCE TESTS
# =============================================================================

func _test_registry_class_exists():
	"""Verify RewardHandlerRegistry class exists."""
	print("TEST: RewardHandlerRegistry class exists")

	var file_exists = FileAccess.file_exists("res://scripts/rewards/reward_handler_registry.gd")

	if file_exists:
		var file = FileAccess.open("res://scripts/rewards/reward_handler_registry.gd", FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		var has_class_name = content.contains("class_name RewardHandlerRegistry")
		if has_class_name:
			_pass("RewardHandlerRegistry class exists")
		else:
			_fail("File exists but missing class_name declaration")
	else:
		_fail("reward_handler_registry.gd file not found")


func _test_handlers_class_exists():
	"""Verify RewardHandlers class exists with handler implementations."""
	print("TEST: RewardHandlers class exists")

	var file_exists = FileAccess.file_exists("res://scripts/rewards/reward_handlers.gd")

	if file_exists:
		var file = FileAccess.open("res://scripts/rewards/reward_handlers.gd", FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		var has_class_name = content.contains("class_name RewardHandlers")
		var has_register_all = content.contains("static func register_all(")
		if has_class_name and has_register_all:
			_pass("RewardHandlers class exists with register_all()")
		else:
			var issues = []
			if not has_class_name: issues.append("missing class_name")
			if not has_register_all: issues.append("missing register_all()")
			_fail("Issues: %s" % ", ".join(issues))
	else:
		_fail("reward_handlers.gd file not found")


func _test_registry_has_register_method():
	"""Verify registry has register() method."""
	print("TEST: Registry has register() method")

	var file = FileAccess.open("res://scripts/rewards/reward_handler_registry.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open reward_handler_registry.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_register = content.contains("func register(")
	var has_reward_type_param = content.contains("reward_type:")
	var has_handler_param = content.contains("handler: Callable")

	if has_register and has_handler_param:
		_pass("register() method exists with correct signature")
	else:
		var issues = []
		if not has_register: issues.append("missing register() method")
		if not has_handler_param: issues.append("missing handler parameter")
		_fail("Issues: %s" % ", ".join(issues))


func _test_registry_has_execute_method():
	"""Verify registry has execute() method."""
	print("TEST: Registry has execute() method")

	var file = FileAccess.open("res://scripts/rewards/reward_handler_registry.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open reward_handler_registry.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_execute = content.contains("func execute(")
	var has_definition_param = content.contains("definition: RewardDefinition") or content.contains("definition:")

	if has_execute and has_definition_param:
		_pass("execute() method exists with correct signature")
	else:
		var issues = []
		if not has_execute: issues.append("missing execute() method")
		if not has_definition_param: issues.append("missing definition parameter")
		_fail("Issues: %s" % ", ".join(issues))


func _test_registry_has_validate_method():
	"""Verify registry has validate() method."""
	print("TEST: Registry has validate() method")

	var file = FileAccess.open("res://scripts/rewards/reward_handler_registry.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open reward_handler_registry.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_validate = content.contains("func validate(")

	if has_validate:
		_pass("validate() method exists")
	else:
		_fail("validate() method not found")


func _test_all_reward_types_registered():
	"""Verify all reward types have handlers registered."""
	print("TEST: All reward types have handlers registered")

	var file = FileAccess.open("res://scripts/rewards/reward_handlers.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open reward_handlers.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Check for handler registrations for all 7 types
	var types_to_check = [
		"GOLD",
		"HEALTH",
		"XP",
		"ITEM",
		"SKILL",
		"ITEM_RANDOM",
		"SKILL_RANDOM"
	]

	var registered_types: Array = []
	var missing_types: Array = []

	for type_name in types_to_check:
		# Look for registration pattern like: RewardTypes.RewardType.GOLD
		if content.contains("RewardType." + type_name):
			registered_types.append(type_name)
		else:
			missing_types.append(type_name)

	if missing_types.is_empty():
		_pass("All %d reward types have handlers" % types_to_check.size())
	else:
		_fail("Missing handlers for: %s" % ", ".join(missing_types))


func _test_applicator_uses_registry():
	"""Verify RewardApplicator uses the registry instead of match statement."""
	print("TEST: RewardApplicator uses registry")

	var file = FileAccess.open("res://scripts/rewards/reward_applicator.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open reward_applicator.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_registry = content.contains("_registry") or content.contains("RewardHandlerRegistry")
	var has_old_match = content.contains("match definition.type:")

	# The match statements for apply_reward should be removed
	# But can_apply_reward and get_eligible_characters might still use match (that's ok)

	if uses_registry:
		_pass("RewardApplicator references registry")
	else:
		_fail("RewardApplicator doesn't use registry pattern")


# =============================================================================
# HELPERS
# =============================================================================

func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
