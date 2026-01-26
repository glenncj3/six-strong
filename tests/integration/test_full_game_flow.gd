extends SceneTree
# Integration test for full game flow
# Tests: Draft -> Run Start -> Encounters -> Combat -> Run End
#
# Run with: "C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/integration/test_full_game_flow.gd

var tests_passed := 0
var tests_failed := 0
var errors: Array[String] = []


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("FULL GAME FLOW INTEGRATION TESTS")
	print("========================================\n")

	# Clear any existing run state first
	_cleanup_run_state()

	# Test game data loading
	_test_game_data_loaded()

	# Test player account
	_test_player_account_state()

	# Test legacy draft manager
	_test_legacy_draft_flow()

	# Test run initialization
	_test_run_start_with_legacies()

	# Test run state operations
	_test_run_state_operations()

	# Test encounter generation
	_test_encounter_generation()

	# Test combat generation
	_test_combat_generation()

	# Test run completion
	_test_run_completion()

	# Cleanup
	_cleanup_run_state()

	_print_results()
	quit(tests_failed)


func _cleanup_run_state():
	"""Clean up any existing run state."""
	if RunManager.is_run_active:
		RunManager.clear_run_state()


# =============================================================================
# GAME DATA TESTS
# =============================================================================

func _test_game_data_loaded():
	print("--- Game Data Loading ---")

	var characters = GameData.get_all_characters()
	_assert_true(characters.size() > 0, "Characters loaded: %d" % characters.size())

	var legacies = GameData.get_all_legacies()
	_assert_true(legacies.size() > 0, "Legacies loaded: %d" % legacies.size())

	var items = GameData.get_all_items()
	_assert_true(items.size() > 0, "Items loaded: %d" % items.size())

	var skills = GameData.get_all_skills()
	_assert_true(skills.size() > 0, "Skills loaded: %d" % skills.size())

	var encounters = GameData.get_encounter_types()
	_assert_true(encounters.size() > 0, "Encounter types loaded: %d" % encounters.size())

	print("")


# =============================================================================
# PLAYER ACCOUNT TESTS
# =============================================================================

func _test_player_account_state():
	print("--- Player Account State ---")

	_assert_true(PlayerAccount != null, "PlayerAccount autoload exists")

	var unlocked_legacies = PlayerAccount.get_unlocked_legacies()
	_assert_true(unlocked_legacies.size() >= 3, "At least 3 legacies unlocked for draft: %d" % unlocked_legacies.size())

	# Check each unlocked legacy has required data
	for legacy in unlocked_legacies:
		_assert_true(legacy != null, "Legacy is not null")
		_assert_true(not legacy.id.is_empty(), "Legacy has ID: %s" % legacy.id)
		_assert_true(not legacy.legacy_name.is_empty(), "Legacy has name: %s" % legacy.legacy_name)
		# Only check first 3 to avoid spam
		if unlocked_legacies.find(legacy) >= 3:
			break

	print("")


# =============================================================================
# LEGACY DRAFT TESTS
# =============================================================================

func _test_legacy_draft_flow():
	print("--- Legacy Draft Flow ---")

	var draft_manager = LegacyDraftManager.new()
	_assert_true(draft_manager != null, "Draft manager created")

	# Generate first round options
	var success = draft_manager.generate_options()
	_assert_true(success, "Draft options generated successfully")
	_assert_eq(draft_manager.current_options.size(), 3, "3 options generated")

	# Verify option structure
	for i in range(draft_manager.current_options.size()):
		var option = draft_manager.current_options[i]
		_assert_true(option.has("legacy"), "Option %d has legacy" % i)
		_assert_true(option.has("is_owned"), "Option %d has is_owned" % i)
		_assert_true(option.has("unlock_cost"), "Option %d has unlock_cost" % i)
		_assert_true(option["legacy"] != null, "Option %d legacy is not null" % i)

	# Select all 3 legacies
	var drafted_legacies: Array[LegacyData] = []
	for round_num in range(3):
		# Find an owned option
		var owned_option = null
		for option in draft_manager.current_options:
			if option["is_owned"]:
				owned_option = option
				break

		if owned_option == null:
			_fail("Round %d: No owned option available" % (round_num + 1))
			return

		var legacy = owned_option["legacy"]
		var select_success = draft_manager.select_legacy(legacy)
		_assert_true(select_success, "Round %d: Legacy selected: %s" % [round_num + 1, legacy.legacy_name])
		drafted_legacies.append(legacy)

		if not draft_manager.is_draft_complete():
			draft_manager.generate_options()

	_assert_true(draft_manager.is_draft_complete(), "Draft completed after 3 selections")
	_assert_eq(draft_manager.get_drafted_legacies().size(), 3, "3 legacies drafted")

	# Test starting gold calculation
	var starting_gold = draft_manager.calculate_starting_gold()
	_assert_true(starting_gold >= 0, "Starting gold calculated: %d" % starting_gold)

	print("")


# =============================================================================
# RUN INITIALIZATION TESTS
# =============================================================================

func _test_run_start_with_legacies():
	print("--- Run Start With Legacies ---")

	# Get 3 unlocked legacies for the run
	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies_for_run: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies_for_run.append(unlocked[i])

	_assert_eq(legacies_for_run.size(), 3, "Have 3 legacies for run")

	# Start the run
	RunManager.start_new_run_with_legacies(legacies_for_run)

	_assert_true(RunManager.is_run_active, "Run is active")
	_assert_eq(RunManager.get_round(), 1, "Starting round is 1")
	_assert_eq(RunManager.get_reputation(), 20, "Starting reputation is 20")
	_assert_eq(RunManager.get_wins(), 0, "Starting wins is 0")
	_assert_true(RunManager.get_gold() >= 0, "Starting gold: %d" % RunManager.get_gold())

	# Check team was created from legacies
	var team = RunManager.get_team()
	_assert_true(team.size() > 0, "Team has characters: %d" % team.size())

	# Verify team members
	for i in range(team.size()):
		var char_instance = team[i]
		_assert_true(char_instance != null, "Team member %d is not null" % i)
		_assert_true(not char_instance.base_character_id.is_empty(), "Team member %d has base_character_id" % i)

	print("")


# =============================================================================
# RUN STATE OPERATIONS TESTS
# =============================================================================

func _test_run_state_operations():
	print("--- Run State Operations ---")

	if not RunManager.is_run_active:
		_fail("Run not active for state operations test")
		return

	var initial_gold = RunManager.get_gold()

	# Test gold operations
	RunManager.add_gold(50)
	_assert_eq(RunManager.get_gold(), initial_gold + 50, "Gold added correctly")

	var spend_success = RunManager.spend_gold(25)
	_assert_true(spend_success, "Gold spent successfully")
	_assert_eq(RunManager.get_gold(), initial_gold + 25, "Gold after spending")

	# Test phase operations
	_assert_eq(RunManager.get_phase(), "encounter", "Initial phase is encounter")

	RunManager.set_phase("combat")
	_assert_eq(RunManager.get_phase(), "combat", "Phase changed to combat")

	RunManager.set_phase("encounter")
	_assert_eq(RunManager.get_phase(), "encounter", "Phase changed back to encounter")

	# Test player XP
	var initial_level = RunManager.get_player_level()
	RunManager.add_player_xp(10)
	_assert_true(RunManager.get_player_xp() >= 10 or RunManager.get_player_level() > initial_level, "XP added")

	print("")


# =============================================================================
# ENCOUNTER GENERATION TESTS
# =============================================================================

func _test_encounter_generation():
	print("--- Encounter Generation ---")

	if not RunManager.is_run_active:
		_fail("Run not active for encounter test")
		return

	# Test encounter factory
	_assert_true(EncounterFactory != null, "EncounterFactory autoload exists")

	var options = EncounterFactory.generate_encounter_options(3)
	_assert_eq(options.size(), 3, "3 encounter options generated")

	for i in range(options.size()):
		var option = options[i]
		_assert_true(option is EncounterOption, "Option %d is EncounterOption" % i)
		_assert_true(not option.encounter_type.is_empty(), "Option %d has encounter_type: %s" % [i, option.encounter_type])
		_assert_true(not option.name.is_empty(), "Option %d has name: %s" % [i, option.name])

	print("")


# =============================================================================
# COMBAT GENERATION TESTS
# =============================================================================

func _test_combat_generation():
	print("--- Combat Generation ---")

	if not RunManager.is_run_active:
		_fail("Run not active for combat test")
		return

	var combat_options = RunManager.generate_combat_options(3)
	_assert_eq(combat_options.size(), 3, "3 combat options generated")

	for i in range(combat_options.size()):
		var option = combat_options[i]
		_assert_true(option is Dictionary, "Combat option %d is Dictionary" % i)
		_assert_true(option.has("name"), "Combat option %d has name" % i)
		_assert_true(option.has("difficulty"), "Combat option %d has difficulty" % i)

	print("")


# =============================================================================
# RUN COMPLETION TESTS
# =============================================================================

func _test_run_completion():
	print("--- Run Completion ---")

	if not RunManager.is_run_active:
		_fail("Run not active for completion test")
		return

	# Simulate some wins
	for i in range(3):
		RunManager.add_win()
	_assert_eq(RunManager.get_wins(), 3, "Wins recorded: 3")

	# Simulate a loss
	var initial_rep = RunManager.get_reputation()
	RunManager.add_loss()
	RunManager.lose_reputation(1)  # Round 1 loss
	_assert_eq(RunManager.get_losses(), 1, "Losses recorded: 1")
	_assert_eq(RunManager.get_reputation(), initial_rep - 1, "Reputation decreased")

	# Test run end conditions
	_assert_false(RunManager.is_run_over(), "Run not over yet")

	# End the run manually
	var results = RunManager.end_run(false)  # Defeat
	_assert_true(results.has("victory"), "Results has victory field")
	_assert_true(results.has("wins"), "Results has wins field")
	_assert_true(results.has("gem_reward"), "Results has gem_reward field")
	_assert_false(RunManager.is_run_active, "Run no longer active after end")

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
		_fail("%s (expected: %s, got: %s)" % [message, expected, actual])
		return false


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	errors.append(msg)
	print("  FAIL: %s" % msg)


func _print_results():
	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])

	if errors.size() > 0:
		print("\nErrors:")
		for error in errors:
			print("  - %s" % error)

	print("========================================\n")
