extends SceneTree
## Unit tests for GoldManager.

const GM = preload("res://scripts/managers/gold_manager.gd")


func _init() -> void:
	var results = run_all_tests()

	print("\n========================================")
	print("GoldManager Tests")
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
		_test_add_gold,
		_test_spend_gold_success,
		_test_spend_gold_insufficient,
		_test_can_afford,
		_test_set_starting_gold,
		_test_reset,
		_test_add_negative_gold,
		_test_spend_negative_gold,
		_test_serialization,
		_test_signal_emitted_on_add,
		_test_signal_emitted_on_spend,
	]
	var names: Array[String] = [
		"initial_state",
		"add_gold",
		"spend_gold_success",
		"spend_gold_insufficient",
		"can_afford",
		"set_starting_gold",
		"reset",
		"add_negative_gold",
		"spend_negative_gold",
		"serialization",
		"signal_emitted_on_add",
		"signal_emitted_on_spend",
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
	var gm = GM.new()
	return gm.current_gold == 0 and gm.starting_gold == 0


static func _test_add_gold() -> bool:
	var gm = GM.new()
	var r = gm.add_gold(50)
	return r.is_ok() and gm.current_gold == 50


static func _test_spend_gold_success() -> bool:
	var gm = GM.new()
	gm.add_gold(100)
	var r = gm.spend_gold(30)
	return r.is_ok() and gm.current_gold == 70


static func _test_spend_gold_insufficient() -> bool:
	var gm = GM.new()
	gm.add_gold(10)
	var r = gm.spend_gold(50)
	return r.is_err() and gm.current_gold == 10


static func _test_can_afford() -> bool:
	var gm = GM.new()
	gm.add_gold(25)
	return gm.can_afford(25) and gm.can_afford(20) and not gm.can_afford(30)


static func _test_set_starting_gold() -> bool:
	var gm = GM.new()
	gm.set_starting_gold(100)
	return gm.starting_gold == 100 and gm.current_gold == 100


static func _test_reset() -> bool:
	var gm = GM.new()
	gm.add_gold(999)
	gm.starting_gold = 50
	gm.reset()
	return gm.current_gold == 0 and gm.starting_gold == 0


static func _test_add_negative_gold() -> bool:
	var gm = GM.new()
	var r = gm.add_gold(-10)
	return r.is_err() and gm.current_gold == 0


static func _test_spend_negative_gold() -> bool:
	var gm = GM.new()
	gm.add_gold(50)
	var r = gm.spend_gold(-10)
	return r.is_err() and gm.current_gold == 50


static func _test_serialization() -> bool:
	var gm = GM.new()
	gm.set_starting_gold(100)
	gm.spend_gold(30)
	var data = gm.to_dict()
	var gm2 = GM.new()
	gm2.load_from_dict(data)
	return gm2.current_gold == 70 and gm2.starting_gold == 100


static func _test_signal_emitted_on_add() -> bool:
	var gm = GM.new()
	var received = [0]
	gm.gold_changed.connect(func(v): received[0] = v)
	gm.add_gold(42)
	return received[0] == 42


static func _test_signal_emitted_on_spend() -> bool:
	var gm = GM.new()
	gm.current_gold = 100
	var received = [0]
	gm.gold_changed.connect(func(v): received[0] = v)
	gm.spend_gold(25)
	return received[0] == 75
