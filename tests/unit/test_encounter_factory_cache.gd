extends SceneTree
# Tests for EncounterFactory caching optimization
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\auto-battle-journey" --script res://tests/unit/test_encounter_factory_cache.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("EncounterFactory Cache Tests")
	print("========================================\n")

	_test_has_cache_variables()
	_test_has_cache_refresh_method()
	_test_generators_use_cache()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_has_cache_variables():
	"""Verify EncounterFactory has cache variables."""
	print("TEST: Has cache variables")

	var file = FileAccess.open("res://autoloads/encounter_factory.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_factory.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_cache_round = content.contains("var _cache_round")
	var has_cached_items = content.contains("var _cached_items")
	var has_cached_skills = content.contains("var _cached_skills")

	if has_cache_round and has_cached_items and has_cached_skills:
		_pass("Has cache variables for round, items, and skills")
	else:
		_fail("Missing cache variables")


func _test_has_cache_refresh_method():
	"""Verify EncounterFactory has cache refresh method."""
	print("TEST: Has cache refresh method")

	var file = FileAccess.open("res://autoloads/encounter_factory.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_factory.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_refresh = content.contains("func _refresh_cache_if_needed()")
	var has_get_cached_items = content.contains("func _get_cached_items()")
	var has_get_cached_skills = content.contains("func _get_cached_skills()")

	if has_refresh and has_get_cached_items and has_get_cached_skills:
		_pass("Has cache refresh and getter methods")
	else:
		_fail("Missing cache methods")


func _test_generators_use_cache():
	"""Verify generators use cached pools instead of direct filtering."""
	print("TEST: Generators use cached pools")

	var file = FileAccess.open("res://autoloads/encounter_factory.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_factory.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Check that generators use _get_cached_* methods
	var uses_cached_skills = content.contains("= _get_cached_skills()")
	var uses_cached_items = content.contains("= _get_cached_items()")

	# Verify cache methods exist and are used
	if uses_cached_skills and uses_cached_items:
		_pass("Generators use cached pools via _get_cached_* methods")
	else:
		var missing = []
		if not uses_cached_skills:
			missing.append("_get_cached_skills()")
		if not uses_cached_items:
			missing.append("_get_cached_items()")
		_fail("Generators not using: %s" % ", ".join(missing))


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
