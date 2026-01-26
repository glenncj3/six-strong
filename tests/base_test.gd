extends SceneTree
# Base test class providing common testing utilities
# Extend this class to create new test files
# Run with: godot --headless --script res://tests/your_test.gd

var tests_passed := 0
var tests_failed := 0
var test_name := "BaseTest"


func _init():
	call_deferred("_run_all_tests")


func _run_all_tests():
	_print_header()
	_run_tests()
	_print_results()
	quit(tests_failed)


func _print_header():
	print("\n========================================")
	print(test_name)
	print("========================================\n")


func _print_results():
	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")


func _run_tests():
	# Override in subclasses to run actual tests
	push_warning("BaseTest: No tests implemented. Override _run_tests()")


# Test assertion helpers

func assert_true(condition: bool, message: String) -> bool:
	if condition:
		_pass(message)
		return true
	else:
		_fail(message)
		return false


func assert_false(condition: bool, message: String) -> bool:
	return assert_true(not condition, message)


func assert_eq(actual, expected, message: String) -> bool:
	if actual == expected:
		_pass(message)
		return true
	else:
		_fail("%s (expected: %s, got: %s)" % [message, expected, actual])
		return false


func assert_ne(actual, not_expected, message: String) -> bool:
	if actual != not_expected:
		_pass(message)
		return true
	else:
		_fail("%s (should not equal: %s)" % [message, not_expected])
		return false


func assert_null(value, message: String) -> bool:
	return assert_true(value == null, message)


func assert_not_null(value, message: String) -> bool:
	return assert_true(value != null, message)


func assert_has(container, value, message: String) -> bool:
	var has_value = false
	if container is Dictionary:
		has_value = container.has(value)
	elif container is Array:
		has_value = container.has(value)
	elif container is String:
		has_value = container.contains(value)
	return assert_true(has_value, message)


func assert_signal_connected(obj: Object, signal_name: String, target: Object, method_name: String, message: String) -> bool:
	var callable = Callable(target, method_name)
	var signal_ref = obj.get(signal_name) if obj.has_signal(signal_name) else null
	if signal_ref == null:
		_fail("%s (signal '%s' not found)" % [message, signal_name])
		return false
	return assert_true(obj.is_connected(signal_name, callable), message)


func assert_signal_not_connected(obj: Object, signal_name: String, target: Object, method_name: String, message: String) -> bool:
	var callable = Callable(target, method_name)
	if not obj.has_signal(signal_name):
		_pass("%s (signal '%s' not found - OK)" % [message, signal_name])
		return true
	return assert_false(obj.is_connected(signal_name, callable), message)


# Helper to wait for a frame
func wait_frame():
	await process_frame


# Helper to wait for physics frame
func wait_physics_frame():
	await physics_frame


# Output helpers

func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)


func section(name: String):
	print("\n--- %s ---" % name)
