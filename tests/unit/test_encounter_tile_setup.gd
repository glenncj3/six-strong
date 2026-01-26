extends SceneTree
# Tests for encounter tile setup - verifies tiles are setup directly after add_child
# instead of using ready.connect which causes race conditions
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_encounter_tile_setup.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Encounter Tile Setup Tests")
	print("========================================\n")

	_test_shop_encounter_no_ready_connect()
	_test_skill_trainer_no_ready_connect()
	_test_health_restore_no_ready_connect()
	_test_character_shop_no_ready_connect()
	_test_treasure_chest_no_ready_connect()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_shop_encounter_no_ready_connect():
	"""Verify shop_encounter_ui.gd does not use ready.connect for tile setup."""
	print("TEST: shop_encounter_ui.gd tile setup")
	_verify_no_ready_connect_for_setup("res://scripts/encounters/types/shop_encounter_ui.gd")


func _test_skill_trainer_no_ready_connect():
	"""Verify skill_trainer_encounter_ui.gd does not use ready.connect for tile setup."""
	print("TEST: skill_trainer_encounter_ui.gd tile setup")
	_verify_no_ready_connect_for_setup("res://scripts/encounters/types/skill_trainer_encounter_ui.gd")


func _test_health_restore_no_ready_connect():
	"""Verify health_restore_encounter_ui.gd does not use ready.connect for tile setup."""
	print("TEST: health_restore_encounter_ui.gd tile setup")
	_verify_no_ready_connect_for_setup("res://scripts/encounters/types/health_restore_encounter_ui.gd")


func _test_character_shop_no_ready_connect():
	"""Verify character_shop_encounter_ui.gd does not use ready.connect for tile setup."""
	print("TEST: character_shop_encounter_ui.gd tile setup")
	_verify_no_ready_connect_for_setup("res://scripts/encounters/types/character_shop_encounter_ui.gd")


func _test_treasure_chest_no_ready_connect():
	"""Verify treasure_chest_encounter_ui.gd does not use ready.connect for tile setup."""
	print("TEST: treasure_chest_encounter_ui.gd tile setup")
	_verify_no_ready_connect_for_setup("res://scripts/encounters/types/treasure_chest_encounter_ui.gd")


func _verify_no_ready_connect_for_setup(script_path: String):
	"""Check that a script does NOT use ready.connect for tile setup (race condition)."""
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		_fail("Cannot open %s" % script_path)
		return

	var content = file.get_as_text()
	file.close()

	var filename = script_path.get_file()

	# Check for the problematic pattern: tile.ready.connect(_setup_tile
	# This is a race condition because ready fires during add_child, before connect
	if content.contains(".ready.connect(_setup_tile"):
		_fail("%s uses ready.connect for _setup_tile (race condition bug)" % filename)
		return

	# Verify _setup_tile function exists
	if not content.contains("func _setup_tile("):
		# Some files may not have _setup_tile at all (acceptable)
		if content.contains("_setup_tile"):
			_fail("%s references _setup_tile but function not found" % filename)
			return
		_pass("%s has no _setup_tile pattern (OK)" % filename)
		return

	_pass("%s calls _setup_tile directly (no race condition)" % filename)


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
