extends SceneTree
## Unit tests for Result type and ErrorCodes.

const ResultClass = preload("res://scripts/core/result.gd")
const Errors = preload("res://scripts/core/error_codes.gd")


func _init() -> void:
	var results = run_all_tests()

	print("\n========================================")
	print("Result Type Tests")
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

	var test_funcs: Array[Callable] = [
		_test_ok_returns_value,
		_test_ok_is_ok,
		_test_ok_is_not_err,
		_test_ok_with_null_value,
		_test_err_is_err,
		_test_err_is_not_ok,
		_test_err_has_error_code,
		_test_err_has_error_message,
		_test_unwrap_returns_value,
		_test_unwrap_on_err_returns_null,
		_test_unwrap_or_returns_value_on_ok,
		_test_unwrap_or_returns_default_on_err,
		_test_error_codes_are_strings,
	]

	var names: Array[String] = [
		"ok_returns_value",
		"ok_is_ok",
		"ok_is_not_err",
		"ok_with_null_value",
		"err_is_err",
		"err_is_not_ok",
		"err_has_error_code",
		"err_has_error_message",
		"unwrap_returns_value",
		"unwrap_on_err_returns_null",
		"unwrap_or_returns_value_on_ok",
		"unwrap_or_returns_default_on_err",
		"error_codes_are_strings",
	]

	for i in test_funcs.size():
		var t = names[i]
		test_names.append(t)
		if test_funcs[i].call():
			passed.append(t)
		else:
			failed.append(t)
			errors[t] = "Assertion failed"

	return {
		"passed": passed,
		"failed": failed,
		"errors": errors,
		"test_names": test_names
	}


static func _test_ok_returns_value() -> bool:
	var r = ResultClass.ok(42)
	return r.unwrap() == 42


static func _test_ok_is_ok() -> bool:
	var r = ResultClass.ok("hello")
	return r.is_ok()


static func _test_ok_is_not_err() -> bool:
	var r = ResultClass.ok("hello")
	return not r.is_err()


static func _test_ok_with_null_value() -> bool:
	var r = ResultClass.ok()
	return r.is_ok() and r.unwrap() == null


static func _test_err_is_err() -> bool:
	var r = ResultClass.err("TEST_ERROR", "something went wrong")
	return r.is_err()


static func _test_err_is_not_ok() -> bool:
	var r = ResultClass.err("TEST_ERROR")
	return not r.is_ok()


static func _test_err_has_error_code() -> bool:
	var r = ResultClass.err("MY_CODE", "msg")
	return r.error_code() == "MY_CODE"


static func _test_err_has_error_message() -> bool:
	var r = ResultClass.err("MY_CODE", "detailed message")
	return r.error_message() == "detailed message"


static func _test_unwrap_returns_value() -> bool:
	var r = ResultClass.ok({"key": "val"})
	var v = r.unwrap()
	return v is Dictionary and v["key"] == "val"


static func _test_unwrap_on_err_returns_null() -> bool:
	var r = ResultClass.err("ERR")
	return r.unwrap() == null


static func _test_unwrap_or_returns_value_on_ok() -> bool:
	var r = ResultClass.ok(10)
	return r.unwrap_or(99) == 10


static func _test_unwrap_or_returns_default_on_err() -> bool:
	var r = ResultClass.err("ERR")
	return r.unwrap_or(99) == 99


static func _test_error_codes_are_strings() -> bool:
	# Verify a few error codes exist and are non-empty strings
	return (
		Errors.INSUFFICIENT_GOLD is String and Errors.INSUFFICIENT_GOLD != ""
		and Errors.INVALID_CHARACTER_ID is String and Errors.INVALID_CHARACTER_ID != ""
		and Errors.NO_ACTIVE_RUN is String and Errors.NO_ACTIVE_RUN != ""
	)
