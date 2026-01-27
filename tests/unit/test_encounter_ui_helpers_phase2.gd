extends SceneTree
# Tests for Phase 2: EncounterUIHelpers Factory Methods
# Verifies new helper methods exist and are used by encounter UIs
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_encounter_ui_helpers_phase2.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("EncounterUIHelpers Factory Methods Tests (Phase 2)")
	print("========================================\n")

	_test_calculate_purchasable_tile_size_exists()
	_test_handle_empty_offerings_exists()
	_test_create_tile_container_exists()
	_test_create_result_label_exists()
	_test_shop_uses_helpers()
	_test_skill_trainer_uses_helpers()
	_test_treasure_chest_uses_helpers()
	_test_health_restore_uses_helpers()
	_test_character_shop_uses_helpers()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


# =============================================================================
# EXISTENCE TESTS - Verify methods are defined
# =============================================================================

func _test_calculate_purchasable_tile_size_exists():
	"""Verify calculate_purchasable_tile_size method exists in EncounterUIHelpers."""
	print("TEST: calculate_purchasable_tile_size() exists")

	var file = FileAccess.open("res://scripts/encounters/encounter_ui_helpers.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_ui_helpers.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_method = content.contains("static func calculate_purchasable_tile_size(")
	var uses_constants = content.contains("GameConstants.ENCOUNTER_TILE_MARGIN") or content.contains("ENCOUNTER_TILE_")

	if has_method and uses_constants:
		_pass("calculate_purchasable_tile_size exists and uses constants")
	else:
		var issues = []
		if not has_method: issues.append("method not found")
		if not uses_constants: issues.append("doesn't use GameConstants tile values")
		_fail("Issues: %s" % ", ".join(issues))


func _test_handle_empty_offerings_exists():
	"""Verify handle_empty_offerings method exists in EncounterUIHelpers."""
	print("TEST: handle_empty_offerings() exists")

	var file = FileAccess.open("res://scripts/encounters/encounter_ui_helpers.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_ui_helpers.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_method = content.contains("static func handle_empty_offerings(")
	var has_vbox_param = content.contains("vbox:") or content.contains("container:")
	var has_message_param = content.contains("message: String")
	var has_callback_param = content.contains("on_complete: Callable")

	if has_method and has_message_param:
		_pass("handle_empty_offerings exists with correct parameters")
	else:
		var issues = []
		if not has_method: issues.append("method not found")
		if not has_message_param: issues.append("missing message parameter")
		_fail("Issues: %s" % ", ".join(issues))


func _test_create_tile_container_exists():
	"""Verify create_tile_container method exists in EncounterUIHelpers."""
	print("TEST: create_tile_container() exists")

	var file = FileAccess.open("res://scripts/encounters/encounter_ui_helpers.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_ui_helpers.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_method = content.contains("static func create_tile_container(")

	if has_method:
		_pass("create_tile_container exists")
	else:
		_fail("create_tile_container method not found")


func _test_create_result_label_exists():
	"""Verify create_result_label method exists in EncounterUIHelpers."""
	print("TEST: create_result_label() exists")

	var file = FileAccess.open("res://scripts/encounters/encounter_ui_helpers.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_ui_helpers.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_method = content.contains("static func create_result_label(")

	if has_method:
		_pass("create_result_label exists")
	else:
		_fail("create_result_label method not found")


# =============================================================================
# USAGE TESTS - Verify encounter UIs use the new helpers
# =============================================================================

func _test_shop_uses_helpers():
	"""Verify shop_encounter_ui.gd uses the new helper methods."""
	print("TEST: shop_encounter_ui.gd uses helper methods")

	var file = FileAccess.open("res://scripts/encounters/types/shop_encounter_ui.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open shop_encounter_ui.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_tile_size = content.contains("EncounterUIHelpers.calculate_purchasable_tile_size()")
	var no_hardcoded_tile = not content.contains("UIScaler.calculate_tile_size(")

	if uses_tile_size and no_hardcoded_tile:
		_pass("Uses calculate_purchasable_tile_size()")
	else:
		var issues = []
		if not uses_tile_size: issues.append("doesn't use calculate_purchasable_tile_size")
		if not no_hardcoded_tile: issues.append("still has hardcoded UIScaler call")
		_fail("Issues: %s" % ", ".join(issues))


func _test_skill_trainer_uses_helpers():
	"""Verify skill_trainer_encounter_ui.gd uses the new helper methods."""
	print("TEST: skill_trainer_encounter_ui.gd uses helper methods")

	var file = FileAccess.open("res://scripts/encounters/types/skill_trainer_encounter_ui.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open skill_trainer_encounter_ui.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_tile_size = content.contains("EncounterUIHelpers.calculate_purchasable_tile_size()")
	var no_hardcoded_tile = not content.contains("UIScaler.calculate_tile_size(")

	if uses_tile_size and no_hardcoded_tile:
		_pass("Uses calculate_purchasable_tile_size()")
	else:
		var issues = []
		if not uses_tile_size: issues.append("doesn't use calculate_purchasable_tile_size")
		if not no_hardcoded_tile: issues.append("still has hardcoded UIScaler call")
		_fail("Issues: %s" % ", ".join(issues))


func _test_treasure_chest_uses_helpers():
	"""Verify treasure_chest_encounter_ui.gd uses the new helper methods."""
	print("TEST: treasure_chest_encounter_ui.gd uses helper methods")

	var file = FileAccess.open("res://scripts/encounters/types/treasure_chest_encounter_ui.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open treasure_chest_encounter_ui.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_tile_size = content.contains("EncounterUIHelpers.calculate_purchasable_tile_size()")
	var no_hardcoded_tile = not content.contains("UIScaler.calculate_tile_size(")

	if uses_tile_size and no_hardcoded_tile:
		_pass("Uses calculate_purchasable_tile_size()")
	else:
		var issues = []
		if not uses_tile_size: issues.append("doesn't use calculate_purchasable_tile_size")
		if not no_hardcoded_tile: issues.append("still has hardcoded UIScaler call")
		_fail("Issues: %s" % ", ".join(issues))


func _test_health_restore_uses_helpers():
	"""Verify health_restore_encounter_ui.gd uses the new helper methods."""
	print("TEST: health_restore_encounter_ui.gd uses helper methods")

	var file = FileAccess.open("res://scripts/encounters/types/health_restore_encounter_ui.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open health_restore_encounter_ui.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_tile_size = content.contains("EncounterUIHelpers.calculate_purchasable_tile_size()")
	var no_hardcoded_tile = not content.contains("UIScaler.calculate_tile_size(")

	if uses_tile_size and no_hardcoded_tile:
		_pass("Uses calculate_purchasable_tile_size()")
	else:
		var issues = []
		if not uses_tile_size: issues.append("doesn't use calculate_purchasable_tile_size")
		if not no_hardcoded_tile: issues.append("still has hardcoded UIScaler call")
		_fail("Issues: %s" % ", ".join(issues))


func _test_character_shop_uses_helpers():
	"""Verify character_shop_encounter_ui.gd uses the new helper methods."""
	print("TEST: character_shop_encounter_ui.gd uses helper methods")

	var file = FileAccess.open("res://scripts/encounters/types/character_shop_encounter_ui.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open character_shop_encounter_ui.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_tile_size = content.contains("EncounterUIHelpers.calculate_purchasable_tile_size()")
	var no_hardcoded_tile = not content.contains("UIScaler.calculate_tile_size(")

	if uses_tile_size and no_hardcoded_tile:
		_pass("Uses calculate_purchasable_tile_size()")
	else:
		var issues = []
		if not uses_tile_size: issues.append("doesn't use calculate_purchasable_tile_size")
		if not no_hardcoded_tile: issues.append("still has hardcoded UIScaler call")
		_fail("Issues: %s" % ", ".join(issues))


# =============================================================================
# HELPERS
# =============================================================================

func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
