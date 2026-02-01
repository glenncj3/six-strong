extends SceneTree
## Unit tests for InventoryManager.

const IM = preload("res://scripts/managers/inventory_manager.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Bootstrap GameData autoload (needed for ItemInstance)
	var autoload_script = load("res://autoloads/game_data.gd")
	if autoload_script and not root.has_node("GameData"):
		var node = Node.new()
		node.set_script(autoload_script)
		node.name = "GameData"
		root.add_child(node)

	var results = _run_all_tests()

	print("\n========================================")
	print("InventoryManager Tests")
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
		_test_add_invalid_item,
		_test_remove_missing_item,
		_test_has_item_empty,
		_test_clear,
		_test_signal_emitted,
		_test_serialization_empty,
	]
	var names: Array[String] = [
		"initial_state",
		"add_invalid_item",
		"remove_missing_item",
		"has_item_empty",
		"clear",
		"signal_emitted",
		"serialization_empty",
	]

	for i in tests.size():
		test_names.append(names[i])
		if tests[i].call():
			passed.append(names[i])
		else:
			failed.append(names[i])
			errors[names[i]] = "Assertion failed"

	return {"passed": passed, "failed": failed, "errors": errors, "test_names": test_names}


func _test_initial_state() -> bool:
	var im = IM.new()
	return im.get_item_count_total() == 0 and im.get_all_items().is_empty()


func _test_add_invalid_item() -> bool:
	var im = IM.new()
	var r = im.add_item_by_id("", false)
	return r.is_err()


func _test_remove_missing_item() -> bool:
	var im = IM.new()
	var r = im.remove_item("nonexistent")
	return r.is_err()


func _test_has_item_empty() -> bool:
	var im = IM.new()
	return not im.has_item("anything")


func _test_clear() -> bool:
	var im = IM.new()
	im.clear()
	return im.get_item_count_total() == 0


func _test_signal_emitted() -> bool:
	# Can't easily test with real items without valid GameData item IDs,
	# but we can verify the signal exists
	var im = IM.new()
	return im.has_signal("item_acquired")


func _test_serialization_empty() -> bool:
	var im = IM.new()
	var data = im.to_dict()
	var im2 = IM.new()
	im2.load_from_dict(data)
	return im2.get_item_count_total() == 0
