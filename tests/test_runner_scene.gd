extends Node
# Test runner that runs all tests when the scene loads
# Run this scene to execute all tests with full autoload access
#
# Usage: Open tests/test_runner_scene.tscn and press Play (F5)

signal all_tests_complete(passed: int, failed: int)

var total_passed := 0
var total_failed := 0
var all_errors: Array[String] = []


func _ready() -> void:
	print("")
	print("============================================================")
	print("SIX STRONG - COMPREHENSIVE TEST SUITE")
	print("============================================================")
	print("")

	# Run all test suites
	_run_data_validation()
	_run_player_account_tests()
	_run_draft_tests()
	_run_run_lifecycle_tests()
	_run_save_load_tests()
	_run_encounter_tests()

	_print_final_results()

	# Auto-quit with result code
	get_tree().quit(total_failed)


func _run_data_validation():
	print("--- DATA VALIDATION ---")

	# Characters
	var characters = GameData.get_all_characters()
	_assert_true(characters.size() > 0, "Characters loaded: %d" % characters.size())

	# Validate character structure
	for char_data in characters:
		var char_id = char_data.get("id", "")
		if char_id.is_empty():
			_fail("Character has empty ID")
			break
		if not char_data.has("base_stats"):
			_fail("Character %s missing base_stats" % char_id)
			break
	_pass("All characters have valid structure")

	# Legacies
	var legacies = GameData.get_all_legacies()
	_assert_true(legacies.size() > 0, "Legacies loaded: %d" % legacies.size())

	# Items
	var items = GameData.get_all_items()
	_assert_true(items.size() > 0, "Items loaded: %d" % items.size())

	# Skills
	var skills = GameData.get_all_skills()
	_assert_true(skills.size() > 0, "Skills loaded: %d" % skills.size())

	# Encounters
	var encounters = GameData.get_encounter_types()
	_assert_true(encounters.size() > 0, "Encounter types loaded: %d" % encounters.size())

	print("")


func _run_player_account_tests():
	print("--- PLAYER ACCOUNT TESTS ---")

	# Check unlocked legacies
	var unlocked = PlayerAccount.get_unlocked_legacies()
	_assert_true(unlocked.size() >= 3, "At least 3 legacies unlocked: %d" % unlocked.size())

	# Validate legacy data
	for legacy in unlocked:
		if legacy == null:
			_fail("Null legacy in unlocked list")
			break
		if legacy.id.is_empty():
			_fail("Legacy has empty ID")
			break
		if legacy.legacy_name.is_empty():
			_fail("Legacy %s has empty name" % legacy.id)
			break
	_pass("All unlocked legacies valid")

	# Check starting legacy IDs exist in GameData
	for legacy_id in PlayerAccount.STARTING_LEGACY_IDS:
		if not GameData.has_legacy(legacy_id):
			_fail("Starting legacy not in GameData: %s" % legacy_id)
	_pass("All starting legacy IDs valid")

	# Test currency operations
	var initial_gems = PlayerAccount.get_gems()
	PlayerAccount.add_gems(100)
	_assert_eq(PlayerAccount.get_gems(), initial_gems + 100, "Gems added correctly")
	PlayerAccount.spend_gems(100)  # Restore original

	print("")


func _run_draft_tests():
	print("--- DRAFT TESTS ---")

	var draft_manager = LegacyDraftManager.new()

	# Generate options
	var success = draft_manager.generate_options()
	_assert_true(success, "Draft options generated")
	_assert_eq(draft_manager.current_options.size(), 3, "3 options generated")

	# Verify options structure
	for i in range(draft_manager.current_options.size()):
		var option = draft_manager.current_options[i]
		_assert_true(option.has("legacy"), "Option %d has legacy" % i)
		_assert_true(option.has("is_owned"), "Option %d has is_owned" % i)
		_assert_true(option["legacy"] != null, "Option %d legacy not null" % i)

	# Test full draft flow
	for round_num in range(3):
		var owned_option = null
		for option in draft_manager.current_options:
			if option["is_owned"]:
				owned_option = option
				break

		if owned_option:
			draft_manager.select_legacy(owned_option["legacy"])
			if not draft_manager.is_draft_complete():
				draft_manager.generate_options()

	_assert_true(draft_manager.is_draft_complete(), "Draft completed")
	_assert_eq(draft_manager.get_drafted_legacies().size(), 3, "3 legacies drafted")

	# Test starting gold calculation
	var gold = draft_manager.calculate_starting_gold()
	_assert_true(gold >= 0, "Starting gold calculated: %d" % gold)

	print("")


func _run_run_lifecycle_tests():
	print("--- RUN LIFECYCLE TESTS ---")

	# Cleanup any existing run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	# Get legacies for test run
	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	_assert_eq(legacies.size(), 3, "Have 3 legacies for run")

	# Start run
	RunManager.start_new_run_with_legacies(legacies)
	_assert_true(RunManager.is_run_active, "Run started")
	_assert_eq(RunManager.get_round(), 1, "Starting round is 1")
	_assert_eq(RunManager.get_reputation(), 20, "Starting rep is 20")

	# Test gold operations
	var initial_gold = RunManager.get_gold()
	RunManager.add_gold(50)
	_assert_eq(RunManager.get_gold(), initial_gold + 50, "Gold added")
	RunManager.spend_gold(50)
	_assert_eq(RunManager.get_gold(), initial_gold, "Gold spent")

	# Test phase - round 1 starts in combat phase (no encounter after draft)
	_assert_eq(RunManager.get_phase(), "combat", "Initial phase is combat after draft")
	RunManager.set_phase("combat")
	_assert_eq(RunManager.get_phase(), "combat", "Phase changed")
	RunManager.set_phase("encounter")

	# Test team
	var team = RunManager.get_team()
	_assert_true(team.size() > 0, "Team has members: %d" % team.size())

	for char_instance in team:
		_assert_true(char_instance != null, "Team member not null")
		_assert_true(not char_instance.base_character_id.is_empty(), "Team member has ID")

	# Cleanup
	RunManager.clear_run_state()
	_assert_false(RunManager.is_run_active, "Run cleared")

	print("")


func _run_save_load_tests():
	"""Test save/load/resume functionality - critical for resume game button."""
	print("--- SAVE/LOAD/RESUME TESTS ---")

	# Cleanup any existing state
	if RunManager.is_run_active:
		RunManager.clear_run_state()
	JsonPersistence.delete_file("user://active_run.json")

	# Test 1: has_active_run returns false when no save
	_assert_false(RunManager.has_active_run(), "has_active_run false when no save")

	# Test 2: Start a run and verify save is created
	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)
	_assert_true(RunManager.has_active_run(), "has_active_run true after starting run")
	_assert_true(RunManager.is_run_active, "is_run_active true after start")

	# Capture state for comparison
	var saved_gold = RunManager.get_gold()
	var saved_round = RunManager.get_round()

	# Test 3: Clear internal state (simulating app restart) but keep save file
	RunManager.is_run_active = false
	RunManager._run_state = null
	_assert_false(RunManager.is_run_active, "is_run_active false after clearing internal state")
	_assert_true(RunManager.has_active_run(), "has_active_run still true (save file exists)")

	# Test 4: load_run_state returns true on success
	var load_result = RunManager.load_run_state()
	_assert_true(load_result, "load_run_state returns true on success")

	# Test 5: CRITICAL - is_run_active is set to true after successful load
	_assert_true(RunManager.is_run_active, "is_run_active TRUE after successful load")

	# Test 6: State is properly restored
	_assert_eq(RunManager.get_gold(), saved_gold, "Gold restored correctly")
	_assert_eq(RunManager.get_round(), saved_round, "Round restored correctly")

	# Test 7: load_run_state returns false when no save file
	RunManager.clear_run_state()
	_assert_false(RunManager.has_active_run(), "No save file after clear")

	var failed_load = RunManager.load_run_state()
	_assert_false(failed_load, "load_run_state returns false when no save")

	# Test 8: is_run_active stays false after failed load
	_assert_false(RunManager.is_run_active, "is_run_active stays false after failed load")

	print("")


func _run_encounter_tests():
	print("--- ENCOUNTER TESTS ---")

	# Setup a run for encounters
	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Test encounter generation
	var options = EncounterFactory.generate_encounter_options(3)
	_assert_eq(options.size(), 3, "3 encounter options generated")

	for i in range(options.size()):
		var opt = options[i]
		_assert_true(opt is Dictionary, "Option %d is Dictionary" % i)
		_assert_true(opt.has("type") and not opt["type"].is_empty(), "Option %d has type" % i)
		_assert_true(opt.has("name") and not opt["name"].is_empty(), "Option %d has name" % i)

	# Test combat generation
	var combat_opts = RunManager.generate_combat_options(3)
	_assert_eq(combat_opts.size(), 3, "3 combat options generated")

	for i in range(combat_opts.size()):
		var opt = combat_opts[i]
		_assert_true(opt.has("name"), "Combat %d has name" % i)
		# AI options have "difficulty", ghost options have "prestige"
		var has_type_field = opt.has("difficulty") or opt.has("prestige")
		_assert_true(has_type_field, "Combat %d has difficulty or prestige" % i)

	# Cleanup
	RunManager.clear_run_state()

	print("")


# =============================================================================
# ASSERTION HELPERS
# =============================================================================

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		_pass(message)
		return true
	else:
		_fail(message)
		return false


func _assert_false(condition: bool, message: String) -> bool:
	return _assert_true(not condition, message)


func _assert_eq(actual, expected, message: String) -> bool:
	if actual == expected:
		_pass(message)
		return true
	else:
		_fail("%s (expected: %s, got: %s)" % [message, str(expected), str(actual)])
		return false


func _pass(msg: String):
	total_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	total_failed += 1
	all_errors.append(msg)
	print("  FAIL: %s" % msg)


func _print_final_results():
	print("")
	print("============================================================")
	print("FINAL RESULTS: %d passed, %d failed" % [total_passed, total_failed])
	print("============================================================")

	if all_errors.size() > 0:
		print("")
		print("FAILURES:")
		for err in all_errors:
			print("  - %s" % err)
		print("")

	if total_failed == 0:
		print("ALL TESTS PASSED!")
	else:
		print("SOME TESTS FAILED - see errors above")

	print("============================================================")
	print("")

	all_tests_complete.emit(total_passed, total_failed)
