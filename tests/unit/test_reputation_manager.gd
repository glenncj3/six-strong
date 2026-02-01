extends SceneTree
## Unit tests for ReputationManager.

const RM = preload("res://scripts/managers/reputation_manager.gd")


func _init() -> void:
	var results = run_all_tests()

	print("\n========================================")
	print("ReputationManager Tests")
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
		_test_lose_reputation,
		_test_lose_clamps_to_zero,
		_test_is_defeated,
		_test_lose_negative_amount,
		_test_lose_when_already_defeated,
		_test_reset,
		_test_serialization,
		_test_signal_emitted,
	]
	var names: Array[String] = [
		"initial_state",
		"lose_reputation",
		"lose_clamps_to_zero",
		"is_defeated",
		"lose_negative_amount",
		"lose_when_already_defeated",
		"reset",
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
	var rm = RM.new()
	return rm.reputation == 20


static func _test_lose_reputation() -> bool:
	var rm = RM.new()
	var r = rm.lose_reputation(5)
	return r.is_ok() and rm.reputation == 15


static func _test_lose_clamps_to_zero() -> bool:
	var rm = RM.new()
	rm.lose_reputation(100)
	return rm.reputation == 0


static func _test_is_defeated() -> bool:
	var rm = RM.new()
	if rm.is_defeated():
		return false
	rm.lose_reputation(20)
	return rm.is_defeated()


static func _test_lose_negative_amount() -> bool:
	var rm = RM.new()
	var r = rm.lose_reputation(-5)
	return r.is_err() and rm.reputation == 20


static func _test_lose_when_already_defeated() -> bool:
	var rm = RM.new()
	rm.lose_reputation(20)
	var r = rm.lose_reputation(5)
	return r.is_err() and rm.reputation == 0


static func _test_reset() -> bool:
	var rm = RM.new()
	rm.lose_reputation(10)
	rm.reset()
	return rm.reputation == 20


static func _test_serialization() -> bool:
	var rm = RM.new()
	rm.lose_reputation(7)
	var data = rm.to_dict()
	var rm2 = RM.new()
	rm2.load_from_dict(data)
	return rm2.reputation == 13


static func _test_signal_emitted() -> bool:
	var rm = RM.new()
	var received = [-1]
	rm.reputation_changed.connect(func(v): received[0] = v)
	rm.lose_reputation(3)
	return received[0] == 17
