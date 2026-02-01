extends SceneTree
## Unit tests for ErrorLogger.

const EL = preload("res://scripts/core/error_logger.gd")


func _init() -> void:
	var results = run_all_tests()

	print("\n========================================")
	print("ErrorLogger Tests")
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
		_test_log_error,
		_test_log_warning,
		_test_log_info,
		_test_get_recent,
		_test_get_recent_errors,
		_test_get_by_category,
		_test_clear,
		_test_max_history,
	]
	var names: Array[String] = [
		"log_error",
		"log_warning",
		"log_info",
		"get_recent",
		"get_recent_errors",
		"get_by_category",
		"clear",
		"max_history",
	]

	for i in tests.size():
		test_names.append(names[i])
		EL.clear()  # Reset state between tests
		if tests[i].call():
			passed.append(names[i])
		else:
			failed.append(names[i])
			errors[names[i]] = "Assertion failed"

	EL.clear()
	return {"passed": passed, "failed": failed, "errors": errors, "test_names": test_names}


static func _test_log_error() -> bool:
	EL.log_error("GOLD", "INSUFFICIENT_GOLD", "Not enough gold")
	var history = EL.get_recent(1)
	return history.size() == 1 and history[0].level == "error" and history[0].code == "INSUFFICIENT_GOLD"


static func _test_log_warning() -> bool:
	EL.log_warning("INVENTORY", "Item not found")
	var history = EL.get_recent(1)
	return history.size() == 1 and history[0].level == "warning" and history[0].category == "INVENTORY"


static func _test_log_info() -> bool:
	EL.log_info("RUN", "Run started")
	var history = EL.get_recent(1)
	return history.size() == 1 and history[0].level == "info"


static func _test_get_recent() -> bool:
	EL.log_info("A", "one")
	EL.log_warning("B", "two")
	EL.log_error("C", "ERR", "three")
	var recent = EL.get_recent(2)
	return recent.size() == 2 and recent[0].category == "B" and recent[1].category == "C"


static func _test_get_recent_errors() -> bool:
	EL.log_info("A", "info")
	EL.log_warning("B", "warn")
	EL.log_error("C", "ERR1", "error1")
	EL.log_error("D", "ERR2", "error2")
	var errs = EL.get_recent_errors(10)
	return errs.size() == 2 and errs[0].code == "ERR1" and errs[1].code == "ERR2"


static func _test_get_by_category() -> bool:
	EL.log_info("GOLD", "a")
	EL.log_info("INVENTORY", "b")
	EL.log_info("GOLD", "c")
	var gold_entries = EL.get_by_category("GOLD", 10)
	return gold_entries.size() == 2 and gold_entries[0].message == "a" and gold_entries[1].message == "c"


static func _test_clear() -> bool:
	EL.log_info("A", "test")
	EL.clear()
	return EL.get_history_size() == 0


static func _test_max_history() -> bool:
	for i in 110:
		EL.log_info("TEST", "entry_%d" % i)
	return EL.get_history_size() == EL.MAX_HISTORY
