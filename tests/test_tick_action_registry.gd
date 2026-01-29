extends "res://tests/base_test.gd"
# Tests for TickActionRegistry

func _init():
	test_name = "TickActionRegistry Tests"
	super()


func _run_tests():
	section("Registry")
	test_register_and_get()
	test_defaults_registered()
	test_unknown_returns_invalid_callable()


func test_register_and_get():
	var called = [false]
	var fn = func(_ctx): called[0] = true
	TickActionRegistry.register("test_action", fn)
	var action = TickActionRegistry.get_action("test_action")
	assert_true(action.is_valid(), "registered action is valid")
	action.call({})
	assert_true(called[0], "registered action callable works")


func test_defaults_registered():
	TickActionRegistry.register_defaults()
	assert_true(TickActionRegistry.has_action("poison_tick"), "poison_tick registered")
	var action = TickActionRegistry.get_action("poison_tick")
	assert_true(action.is_valid(), "poison_tick action is valid")


func test_unknown_returns_invalid_callable():
	var action = TickActionRegistry.get_action("nonexistent_action")
	assert_false(action.is_valid(), "unknown action returns invalid callable")
