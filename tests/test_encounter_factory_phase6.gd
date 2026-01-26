extends SceneTree
## Tests for Phase 6: Encounter Pool Composition
##
## Run with:
## "C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/test_encounter_factory_phase6.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Phase 6: Encounter Pool Composition Tests")
	print("========================================\n")

	_test_encounter_types_have_source_field()
	_test_encounter_types_have_weight_100()
	_test_character_shop_encounter_exists()
	_test_encounter_factory_has_run_pool_methods()
	_test_encounter_factory_has_pick_characters_generator()
	_test_character_shop_encounter_ui_exists()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_encounter_types_have_source_field():
	"""Verify all encounter types have 'source' field."""
	print("TEST: Encounter types have source field")

	var file = FileAccess.open("res://data/encounters/encounter_types.json", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_types.json")
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		_fail("Cannot parse encounter_types.json")
		return

	var data = json.data
	var encounter_types = data.get("encounter_types", [])

	if encounter_types.is_empty():
		_fail("No encounter types found")
		return

	var missing_source: Array = []
	for enc in encounter_types:
		if not enc.has("source"):
			missing_source.append(enc.get("type", "unknown"))

	if missing_source.is_empty():
		_pass("All %d encounter types have 'source' field" % encounter_types.size())
	else:
		_fail("Missing 'source' field in: %s" % ", ".join(missing_source))


func _test_encounter_types_have_weight_100():
	"""Verify base encounter types have weight of 100."""
	print("TEST: Base encounter types have weight 100")

	var file = FileAccess.open("res://data/encounters/encounter_types.json", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_types.json")
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		_fail("Cannot parse encounter_types.json")
		return

	var data = json.data
	var encounter_types = data.get("encounter_types", [])

	var wrong_weight: Array = []
	for enc in encounter_types:
		if enc.get("source") == "base":
			var weight = enc.get("weight", 0)
			if weight != 100:
				wrong_weight.append("%s (weight=%s)" % [enc.get("type"), str(weight)])

	if wrong_weight.is_empty():
		_pass("All base encounters have weight 100")
	else:
		_fail("Wrong weight in: %s" % ", ".join(wrong_weight))


func _test_character_shop_encounter_exists():
	"""Verify character_shop encounter type exists."""
	print("TEST: character_shop encounter type exists")

	var file = FileAccess.open("res://data/encounters/encounter_types.json", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_types.json")
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		_fail("Cannot parse encounter_types.json")
		return

	var data = json.data
	var encounter_types = data.get("encounter_types", [])

	var found = false
	var char_shop_data = {}
	for enc in encounter_types:
		if enc.get("type") == "character_shop":
			found = true
			char_shop_data = enc
			break

	if not found:
		_fail("character_shop encounter type not found")
		return

	# Verify it has the right generator
	var generation = char_shop_data.get("generation", {})
	var data_fields = generation.get("data_fields", {})
	var offerings = data_fields.get("offerings", {})
	var generator = offerings.get("generator", "")

	if generator == "pick_characters":
		_pass("character_shop uses pick_characters generator")
	else:
		_fail("character_shop has wrong generator: %s (expected: pick_characters)" % generator)


func _test_encounter_factory_has_run_pool_methods():
	"""Verify EncounterFactory has RunPool integration methods."""
	print("TEST: EncounterFactory has RunPool methods")

	var file = FileAccess.open("res://autoloads/encounter_factory.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_factory.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_set_run_pool = content.contains("func set_run_pool(")
	var has_clear_run_pool = content.contains("func clear_run_pool(")
	var has_run_pool_var = content.contains("var _run_pool")

	var missing: Array = []
	if not has_set_run_pool:
		missing.append("set_run_pool()")
	if not has_clear_run_pool:
		missing.append("clear_run_pool()")
	if not has_run_pool_var:
		missing.append("_run_pool variable")

	if missing.is_empty():
		_pass("EncounterFactory has RunPool integration methods")
	else:
		_fail("Missing: %s" % ", ".join(missing))


func _test_encounter_factory_has_pick_characters_generator():
	"""Verify EncounterFactory has pick_characters generator."""
	print("TEST: EncounterFactory has pick_characters generator")

	var file = FileAccess.open("res://autoloads/encounter_factory.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open encounter_factory.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_gen_func = content.contains("func _gen_pick_characters(")
	var has_generator_registration = content.contains("\"pick_characters\": _gen_pick_characters")
	var has_cached_characters = content.contains("var _cached_characters")
	var has_get_cached_characters = content.contains("func _get_cached_characters(")

	var missing: Array = []
	if not has_gen_func:
		missing.append("_gen_pick_characters()")
	if not has_generator_registration:
		missing.append("pick_characters registration")
	if not has_cached_characters:
		missing.append("_cached_characters variable")
	if not has_get_cached_characters:
		missing.append("_get_cached_characters()")

	if missing.is_empty():
		_pass("EncounterFactory has complete pick_characters generator")
	else:
		_fail("Missing: %s" % ", ".join(missing))


func _test_character_shop_encounter_ui_exists():
	"""Verify CharacterShopEncounterUI class exists."""
	print("TEST: CharacterShopEncounterUI exists")

	var file = FileAccess.open("res://scripts/encounters/types/character_shop_encounter_ui.gd", FileAccess.READ)
	if file == null:
		_fail("character_shop_encounter_ui.gd not found")
		return

	var content = file.get_as_text()
	file.close()

	var has_class_name = content.contains("class_name CharacterShopEncounterUI")
	var has_create_ui = content.contains("static func create_ui(")
	var has_reward_preview = content.contains("static func get_reward_preview(")

	var missing: Array = []
	if not has_class_name:
		missing.append("class_name")
	if not has_create_ui:
		missing.append("create_ui()")
	if not has_reward_preview:
		missing.append("get_reward_preview()")

	if missing.is_empty():
		_pass("CharacterShopEncounterUI class is complete")
	else:
		_fail("Missing: %s" % ", ".join(missing))


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
