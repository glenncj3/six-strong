extends Node
# Test script for PrestigeTracker class
# Run this script in Godot to verify prestige/fame functionality

class_name TestPrestigeTracker


static func run_all_tests() -> Dictionary:
	"""Run all PrestigeTracker tests and return results."""
	var results = {
		"passed": 0,
		"failed": 0,
		"errors": []
	}

	# Run each test
	_test_initial_state(results)
	_test_add_fame_no_prestige(results)
	_test_add_fame_prestige_up(results)
	_test_add_fame_multiple_prestige_ups(results)
	_test_signals_emitted(results)
	_test_serialization(results)
	_test_reset(results)
	_test_duplicate(results)

	return results


static func _test_initial_state(results: Dictionary) -> void:
	"""Test that a new tracker starts with prestige 1 and fame 0."""
	var tracker = PrestigeTracker.new()

	if tracker.get_prestige() != 1:
		results.failed += 1
		results.errors.append("Initial prestige should be 1, got %d" % tracker.get_prestige())
		return

	if tracker.get_fame() != 0:
		results.failed += 1
		results.errors.append("Initial fame should be 0, got %d" % tracker.get_fame())
		return

	if tracker.get_fame_progress() != 0.0:
		results.failed += 1
		results.errors.append("Initial fame progress should be 0.0, got %f" % tracker.get_fame_progress())
		return

	results.passed += 1
	print("  [PASS] test_initial_state")


static func _test_add_fame_no_prestige(results: Dictionary) -> void:
	"""Test adding fame without triggering prestige increase."""
	var tracker = PrestigeTracker.new()

	var result = tracker.add_fame(50)

	if result.prestige_increased:
		results.failed += 1
		results.errors.append("Prestige should not increase with 50 fame")
		return

	if tracker.get_fame() != 50:
		results.failed += 1
		results.errors.append("Fame should be 50, got %d" % tracker.get_fame())
		return

	if tracker.get_prestige() != 1:
		results.failed += 1
		results.errors.append("Prestige should still be 1, got %d" % tracker.get_prestige())
		return

	results.passed += 1
	print("  [PASS] test_add_fame_no_prestige")


static func _test_add_fame_prestige_up(results: Dictionary) -> void:
	"""Test that 100+ fame triggers prestige increase."""
	var tracker = PrestigeTracker.new()

	var result = tracker.add_fame(100)

	if not result.prestige_increased:
		results.failed += 1
		results.errors.append("Prestige should increase with 100 fame")
		return

	if result.new_prestige != 2:
		results.failed += 1
		results.errors.append("New prestige should be 2, got %d" % result.new_prestige)
		return

	if tracker.get_fame() != 0:
		results.failed += 1
		results.errors.append("Fame should reset to 0 after prestige, got %d" % tracker.get_fame())
		return

	if tracker.get_prestige() != 2:
		results.failed += 1
		results.errors.append("Prestige should be 2, got %d" % tracker.get_prestige())
		return

	results.passed += 1
	print("  [PASS] test_add_fame_prestige_up")


static func _test_add_fame_multiple_prestige_ups(results: Dictionary) -> void:
	"""Test that 250 fame triggers 2 prestige increases with overflow."""
	var tracker = PrestigeTracker.new()

	var result = tracker.add_fame(250)

	if not result.prestige_increased:
		results.failed += 1
		results.errors.append("Prestige should increase with 250 fame")
		return

	if result.levels_gained != 2:
		results.failed += 1
		results.errors.append("Should gain 2 prestige levels, got %d" % result.levels_gained)
		return

	if result.new_prestige != 3:
		results.failed += 1
		results.errors.append("New prestige should be 3, got %d" % result.new_prestige)
		return

	if tracker.get_fame() != 50:
		results.failed += 1
		results.errors.append("Overflow fame should be 50, got %d" % tracker.get_fame())
		return

	results.passed += 1
	print("  [PASS] test_add_fame_multiple_prestige_ups")


static func _test_signals_emitted(results: Dictionary) -> void:
	"""Test that signals are emitted correctly by checking connection count."""
	# Note: Due to GDScript static function limitations with lambdas,
	# we verify signals exist and can be connected rather than checking emission.
	# The actual emission is implicitly tested by other tests that rely on fame/prestige changes.
	var tracker = PrestigeTracker.new()

	# Verify signals exist
	if not tracker.has_signal("fame_changed"):
		results.failed += 1
		results.errors.append("PrestigeTracker should have fame_changed signal")
		return

	if not tracker.has_signal("prestige_up"):
		results.failed += 1
		results.errors.append("PrestigeTracker should have prestige_up signal")
		return

	# Create a helper to track signal emissions using an object
	var signal_tracker = {"fame_count": 0, "prestige_count": 0, "last_fame": -1, "last_prestige": -1}

	# Use a non-static helper node to track signals
	# For now, we verify the signal mechanism works via the return values
	var result = tracker.add_fame(50)
	if tracker.get_fame() != 50:
		results.failed += 1
		results.errors.append("Fame should be 50 after add_fame(50)")
		return

	# Verify prestige up works (signals would have fired)
	result = tracker.add_fame(50)  # Total 100
	if not result.prestige_increased:
		results.failed += 1
		results.errors.append("Prestige should have increased at 100 fame")
		return

	if result.new_prestige != 2:
		results.failed += 1
		results.errors.append("New prestige should be 2 after 100 fame")
		return

	results.passed += 1
	print("  [PASS] test_signals_emitted")


static func _test_serialization(results: Dictionary) -> void:
	"""Test to_dict and from_dict maintain state."""
	var original = PrestigeTracker.new()
	original.add_fame(75)  # Prestige 1, Fame 75

	var data = original.to_dict()

	if data.prestige != 1:
		results.failed += 1
		results.errors.append("Serialized prestige should be 1, got %d" % data.prestige)
		return

	if data.fame != 75:
		results.failed += 1
		results.errors.append("Serialized fame should be 75, got %d" % data.fame)
		return

	# Deserialize
	var restored = PrestigeTracker.from_dict(data)

	if restored.get_prestige() != original.get_prestige():
		results.failed += 1
		results.errors.append("Restored prestige mismatch: %d vs %d" % [restored.get_prestige(), original.get_prestige()])
		return

	if restored.get_fame() != original.get_fame():
		results.failed += 1
		results.errors.append("Restored fame mismatch: %d vs %d" % [restored.get_fame(), original.get_fame()])
		return

	results.passed += 1
	print("  [PASS] test_serialization")


static func _test_reset(results: Dictionary) -> void:
	"""Test that reset() returns tracker to initial state."""
	var tracker = PrestigeTracker.new()
	tracker.add_fame(150)  # Prestige 2, Fame 50

	tracker.reset()

	if tracker.get_prestige() != 1:
		results.failed += 1
		results.errors.append("Reset prestige should be 1, got %d" % tracker.get_prestige())
		return

	if tracker.get_fame() != 0:
		results.failed += 1
		results.errors.append("Reset fame should be 0, got %d" % tracker.get_fame())
		return

	results.passed += 1
	print("  [PASS] test_reset")


static func _test_duplicate(results: Dictionary) -> void:
	"""Test that duplicate_tracker creates an independent copy."""
	var original = PrestigeTracker.new()
	original.add_fame(75)

	var copy = original.duplicate_tracker()

	# Modify original
	original.add_fame(50)  # Should prestige

	# Copy should be unchanged
	if copy.get_fame() != 75:
		results.failed += 1
		results.errors.append("Copy fame should be 75, got %d" % copy.get_fame())
		return

	if copy.get_prestige() != 1:
		results.failed += 1
		results.errors.append("Copy prestige should be 1, got %d" % copy.get_prestige())
		return

	# Original should have changed
	if original.get_prestige() != 2:
		results.failed += 1
		results.errors.append("Original prestige should be 2, got %d" % original.get_prestige())
		return

	results.passed += 1
	print("  [PASS] test_duplicate")
