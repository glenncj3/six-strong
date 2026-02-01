extends SceneTree
## Unit tests for CharacterManager.

const CM = preload("res://scripts/managers/character_manager.gd")
const CI = preload("res://scripts/data_classes/character_instance.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Bootstrap GameData
	var autoload_script = load("res://autoloads/game_data.gd")
	if autoload_script and not root.has_node("GameData"):
		var node = Node.new()
		node.set_script(autoload_script)
		node.name = "GameData"
		root.add_child(node)

	var results = _run_all_tests()

	print("\n========================================")
	print("CharacterManager Tests")
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


func _run_all_tests() -> Dictionary:
	var passed: Array = []
	var failed: Array = []
	var errors: Dictionary = {}
	var test_names: Array = []

	var tests: Array[Callable] = [
		_test_initial_state,
		_test_add_character,
		_test_add_character_at,
		_test_remove_character,
		_test_swap_characters,
		_test_is_full,
		_test_clear,
		_test_pending_character,
		_test_cancel_pending,
		_test_get_grid,
		_test_serialization,
	]
	var names: Array[String] = [
		"initial_state",
		"add_character",
		"add_character_at",
		"remove_character",
		"swap_characters",
		"is_full",
		"clear",
		"pending_character",
		"cancel_pending",
		"get_grid",
		"serialization",
	]

	for i in tests.size():
		test_names.append(names[i])
		if tests[i].call():
			passed.append(names[i])
		else:
			failed.append(names[i])
			errors[names[i]] = "Assertion failed"

	return {"passed": passed, "failed": failed, "errors": errors, "test_names": test_names}


static func _make_char(id: String) -> CharacterInstance:
	var c = CI.new()
	c.base_character_id = id
	c.stats = {"health": 100, "speed": 10, "damage": 15, "agility": 5, "crit_chance": 0, "charges": -1}
	c.current_health = 100
	return c


static func _test_initial_state() -> bool:
	var cm = CM.new()
	return cm.get_character_count() == 0 and not cm.is_full()


static func _test_add_character() -> bool:
	var cm = CM.new()
	var c = _make_char("test1")
	var ok = cm.add_character(c)
	return ok and cm.get_character_count() == 1


static func _test_add_character_at() -> bool:
	var cm = CM.new()
	var c = _make_char("test2")
	var ok = cm.add_character_at(c, 1, 2)
	return ok and cm.get_character_at(1, 2) == c


static func _test_remove_character() -> bool:
	var cm = CM.new()
	var c = _make_char("test3")
	cm.add_character_at(c, 0, 1)
	var removed = cm.remove_character(0, 1)
	return removed == c and cm.get_character_count() == 0


static func _test_swap_characters() -> bool:
	var cm = CM.new()
	var c1 = _make_char("a")
	var c2 = _make_char("b")
	cm.add_character_at(c1, 0, 0)
	cm.add_character_at(c2, 1, 1)
	cm.swap_characters(0, 0, 1, 1)
	return cm.get_character_at(0, 0) == c2 and cm.get_character_at(1, 1) == c1


static func _test_is_full() -> bool:
	var cm = CM.new()
	for i in 6:
		cm.add_character(_make_char("char_%d" % i))
	return cm.is_full()


static func _test_clear() -> bool:
	var cm = CM.new()
	cm.add_character(_make_char("x"))
	cm.clear()
	return cm.get_character_count() == 0 and cm.get_pending_character() == null


static func _test_pending_character() -> bool:
	var cm = CM.new()
	# Fill grid
	for i in 6:
		cm.add_character(_make_char("char_%d" % i))
	# Next add should make it pending (via acquire_character would, but add_character returns false)
	var extra = _make_char("extra")
	var ok = cm.add_character(extra)
	return not ok and cm.get_character_count() == 6


static func _test_cancel_pending() -> bool:
	var cm = CM.new()
	cm._pending_character = _make_char("pending")
	cm.cancel_pending_character()
	return cm.get_pending_character() == null


static func _test_get_grid() -> bool:
	var cm = CM.new()
	return cm.get_grid() != null


static func _test_serialization() -> bool:
	var cm = CM.new()
	cm.add_character_at(_make_char("s1"), 0, 0)
	cm.add_character_at(_make_char("s2"), 1, 2)
	var data = cm.to_dict()
	var cm2 = CM.new()
	cm2.load_from_dict(data)
	return cm2.get_character_count() == 2 and cm2.get_character_at(0, 0) != null
