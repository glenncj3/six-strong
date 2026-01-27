extends SceneTree
## Unit tests for TweenTracker
## Tests tween management and cleanup functionality.

const Tracker = preload("res://scripts/utils/tween_tracker.gd")


func _init() -> void:
	# We need to wait for the tree to be ready
	call_deferred("_run_tests")


func _run_tests() -> void:
	var results = _run_all_tests()

	print("\n========================================")
	print("TweenTracker Tests")
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
	"""Run all tests and return results."""
	var passed: Array = []
	var failed: Array = []
	var errors: Dictionary = {}
	var test_names: Array = []

	# Create a test node to own tweens
	var test_node = Node.new()
	root.add_child(test_node)

	# Test initialization
	test_names.append("initialization_works")
	var tracker = Tracker.new(test_node)
	if tracker != null:
		passed.append("initialization_works")
	else:
		failed.append("initialization_works")
		errors["initialization_works"] = "Failed to initialize TweenTracker"

	# Test create returns tween
	test_names.append("create_returns_tween")
	var tween = tracker.create()
	if tween != null:
		passed.append("create_returns_tween")
	else:
		failed.append("create_returns_tween")
		errors["create_returns_tween"] = "Create did not return valid tween"
	tracker.kill_all()

	# Test kill_all clears tweens
	test_names.append("kill_all_clears_tweens")
	var tracker2 = Tracker.new(test_node)
	var _t1 = tracker2.create()
	var _t2 = tracker2.create()
	tracker2.kill_all()
	if not tracker2.is_any_running():
		passed.append("kill_all_clears_tweens")
	else:
		failed.append("kill_all_clears_tweens")
		errors["kill_all_clears_tweens"] = "kill_all did not stop running tweens"

	# Test is_any_running
	test_names.append("is_any_running_works")
	var tracker3 = Tracker.new(test_node)
	var no_tweens_running = not tracker3.is_any_running()
	var tween3 = tracker3.create()
	tween3.tween_callback(func(): pass).set_delay(0.5)
	var has_running_tween = tracker3.is_any_running()
	tracker3.kill_all()

	if no_tweens_running and has_running_tween:
		passed.append("is_any_running_works")
	else:
		failed.append("is_any_running_works")
		if not no_tweens_running:
			errors["is_any_running_works"] = "is_any_running returned true with no tweens"
		else:
			errors["is_any_running_works"] = "is_any_running returned false with running tween"

	# Cleanup
	test_node.queue_free()

	return {
		"passed": passed,
		"failed": failed,
		"errors": errors,
		"test_names": test_names
	}
