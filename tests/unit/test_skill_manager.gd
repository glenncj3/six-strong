extends SceneTree
## Unit tests for SkillManager.

const SM = preload("res://scripts/managers/skill_manager.gd")


func _init() -> void:
	var results = run_all_tests()

	print("\n========================================")
	print("SkillManager Tests")
	print("========================================\n")

	for test_name in results.test_names:
		var status = "PASS" if test_name in results.passed else "FAIL"
		print("TEST: %s" % test_name)
		print("  %s" % status)
		if test_name in results.errors:
			print("  Error: %s" % results.errors[test_name])

	print("\n========================================")
	print("Results: %d passed, %d failed" % [results.passed.size(), results.failed.size()])
	print("========================================\n")

	quit(results.failed.size())


static func run_all_tests() -> Dictionary:
	var passed: Array = []
	var failed: Array = []
	var errors: Dictionary = {}
	var test_names: Array = []

	var tests: Array[Callable] = [
		_test_initial_state,
		_test_registry_has_effects,
		_test_add_lingering_effect,
		_test_add_invalid_effect,
		_test_has_pending_effects,
		_test_get_pending_effects,
		_test_clear,
		_test_serialization,
		_test_signal_emitted,
	]
	var names: Array[String] = [
		"initial_state",
		"registry_has_effects",
		"add_lingering_effect",
		"add_invalid_effect",
		"has_pending_effects",
		"get_pending_effects",
		"clear",
		"serialization",
		"signal_emitted",
	]

	for i in tests.size():
		test_names.append(names[i])
		if tests[i].call():
			passed.append(names[i])
		else:
			failed.append(names[i])
			errors[names[i]] = "Assertion failed"

	return {"passed": passed, "failed": failed, "errors": errors, "test_names": test_names}


static func _test_initial_state() -> bool:
	var sm = SM.new()
	return sm.get_lingering_effects() != null and sm.get_skill_registry() != null


static func _test_registry_has_effects() -> bool:
	var sm = SM.new()
	var registry = sm.get_skill_registry()
	return registry.get_handler_count() > 0


static func _test_add_lingering_effect() -> bool:
	var sm = SM.new()
	var skill_data = {
		"id": "test_skill",
		"name": "Test Skill",
		"effect": {"type": "grant_gold", "value": 50},
		"trigger": "next_combat"
	}
	var ok = sm.add_lingering_effect(skill_data, 1)
	return ok and sm.get_lingering_effects().get_effect_count() == 1


static func _test_add_invalid_effect() -> bool:
	var sm = SM.new()
	var ok = sm.add_lingering_effect({}, 1)  # Missing effect field
	return not ok


static func _test_has_pending_effects() -> bool:
	var sm = SM.new()
	if sm.has_pending_effects("next_combat"):
		return false
	sm.add_lingering_effect({
		"effect": {"type": "grant_gold", "value": 10},
		"trigger": "next_combat"
	}, 1)
	return sm.has_pending_effects("next_combat")


static func _test_get_pending_effects() -> bool:
	var sm = SM.new()
	sm.add_lingering_effect({
		"effect": {"type": "grant_gold", "value": 10},
		"trigger": "next_round"
	}, 1)
	var effects = sm.get_pending_effects("next_round")
	return effects.size() == 1


static func _test_clear() -> bool:
	var sm = SM.new()
	sm.add_lingering_effect({
		"effect": {"type": "grant_gold", "value": 10},
		"trigger": "next_combat"
	}, 1)
	sm.clear()
	return sm.get_lingering_effects().get_effect_count() == 0


static func _test_serialization() -> bool:
	var sm = SM.new()
	sm.add_lingering_effect({
		"id": "ser_test",
		"effect": {"type": "grant_gold", "value": 25},
		"trigger": "next_combat"
	}, 2)
	var data = sm.to_dict()
	var sm2 = SM.new()
	sm2.load_from_dict(data)
	return sm2.get_lingering_effects().get_effect_count() == 1


static func _test_signal_emitted() -> bool:
	var sm = SM.new()
	var received = [false]
	sm.lingering_effect_added.connect(func(_e): received[0] = true)
	sm.add_lingering_effect({
		"effect": {"type": "grant_gold", "value": 10},
		"trigger": "next_combat"
	}, 1)
	return received[0]
