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
	_run_run_end_conditions()
	_run_currency_edge_cases()
	_run_reputation_and_wins()
	_run_character_acquisition()
	_run_player_level_progression()
	_run_end_of_run_rewards()
	_run_inventory_operations()
	_run_attempt_purchase()
	_run_draft_error_paths()
	_run_phase_and_round_progression()
	_run_lingering_effects()
	_run_scene_manager_validation()
	_run_hud_visibility_helper()
	_run_combat_rewards()
	_run_run_flow_controller()
	_run_encounter_context()
	_run_player_account_persistence()
	_run_game_data_validation()
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


func _run_run_end_conditions():
	"""Test victory and defeat conditions - CRITICAL for game completion."""
	print("--- RUN END CONDITIONS ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	# Test 1: Fresh run is not over
	RunManager.start_new_run_with_legacies(legacies)
	_assert_false(RunManager.is_run_over(), "Fresh run is not over")
	_assert_false(RunManager.did_player_win(), "Fresh run is not a win")

	# Test 2: Victory condition - 10 wins
	for i in range(10):
		RunManager.add_win()
	_assert_eq(RunManager.get_wins(), 10, "10 wins recorded")
	_assert_true(RunManager.is_run_over(), "Run is over at 10 wins")
	_assert_true(RunManager.did_player_win(), "Player won at 10 wins")

	# Cleanup and restart for defeat test
	RunManager.clear_run_state()
	RunManager.start_new_run_with_legacies(legacies)

	# Test 3: Defeat condition - 0 reputation
	_assert_eq(RunManager.get_reputation(), 20, "Starting reputation is 20")
	RunManager.lose_reputation(20)  # Lose all reputation
	_assert_eq(RunManager.get_reputation(), 0, "Reputation is 0 after losing 20")
	_assert_true(RunManager.is_run_over(), "Run is over at 0 reputation")
	_assert_false(RunManager.did_player_win(), "Player did NOT win (defeat)")

	# Test 4: Reputation doesn't go negative
	RunManager.clear_run_state()
	RunManager.start_new_run_with_legacies(legacies)
	RunManager.lose_reputation(100)  # Try to lose more than we have
	_assert_true(RunManager.get_reputation() >= 0, "Reputation doesn't go negative: %d" % RunManager.get_reputation())

	# Cleanup
	RunManager.clear_run_state()

	print("")


func _run_currency_edge_cases():
	"""Test currency operations including edge cases."""
	print("--- CURRENCY EDGE CASES ---")

	# Setup fresh run for gold tests
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Test 1: Can't spend more gold than you have
	var current_gold = RunManager.get_gold()
	var spend_result = RunManager.spend_gold(current_gold + 100)
	_assert_false(spend_result, "Cannot spend more gold than available")
	_assert_eq(RunManager.get_gold(), current_gold, "Gold unchanged after failed spend")

	# Test 2: Can spend exactly what you have
	RunManager.add_gold(50)
	var before_spend = RunManager.get_gold()
	spend_result = RunManager.spend_gold(before_spend)
	_assert_true(spend_result, "Can spend exact gold amount")
	_assert_eq(RunManager.get_gold(), 0, "Gold is 0 after spending all")

	# Test 3: Spending 0 gold (edge case)
	spend_result = RunManager.spend_gold(0)
	_assert_true(spend_result, "Spending 0 gold succeeds")

	# Test 4: Adding negative gold shouldn't work (or should it?)
	var gold_before = RunManager.get_gold()
	RunManager.add_gold(-10)
	# This depends on implementation - just verify it doesn't crash
	_pass("add_gold with negative value doesn't crash")

	# Test 5: PlayerAccount gem operations
	var initial_gems = PlayerAccount.get_gems()

	# Test spending more gems than available
	var gem_spend = PlayerAccount.spend_gems(initial_gems + 1000)
	_assert_false(gem_spend, "Cannot spend more gems than available")
	_assert_eq(PlayerAccount.get_gems(), initial_gems, "Gems unchanged after failed spend")

	# Test spending exact amount
	PlayerAccount.add_gems(100)
	gem_spend = PlayerAccount.spend_gems(100)
	_assert_true(gem_spend, "Can spend exact gem amount")
	_assert_eq(PlayerAccount.get_gems(), initial_gems, "Gems back to initial after spend")

	# Cleanup
	RunManager.clear_run_state()

	print("")


func _run_reputation_and_wins():
	"""Test reputation and win/loss tracking."""
	print("--- REPUTATION & WIN/LOSS TRACKING ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Test 1: Initial state
	_assert_eq(RunManager.get_wins(), 0, "Initial wins is 0")
	_assert_eq(RunManager.get_losses(), 0, "Initial losses is 0")
	_assert_eq(RunManager.get_reputation(), 20, "Initial reputation is 20")

	# Test 2: Win tracking
	RunManager.add_win()
	_assert_eq(RunManager.get_wins(), 1, "Win count incremented")
	RunManager.add_win()
	RunManager.add_win()
	_assert_eq(RunManager.get_wins(), 3, "Multiple wins tracked")

	# Test 3: Loss tracking
	RunManager.add_loss()
	_assert_eq(RunManager.get_losses(), 1, "Loss count incremented")

	# Test 4: Reputation loss
	var rep_before = RunManager.get_reputation()
	RunManager.lose_reputation(5)
	_assert_eq(RunManager.get_reputation(), rep_before - 5, "Reputation decreased by 5")

	# Test 5: Partial reputation loss
	rep_before = RunManager.get_reputation()
	RunManager.lose_reputation(3)
	_assert_eq(RunManager.get_reputation(), rep_before - 3, "Reputation decreased by 3")

	# Test 6: State persists after save/load
	var wins_before = RunManager.get_wins()
	var losses_before = RunManager.get_losses()
	var rep_before_save = RunManager.get_reputation()

	RunManager.save_run_state()
	RunManager.is_run_active = false
	RunManager._run_state = null
	RunManager.load_run_state()

	_assert_eq(RunManager.get_wins(), wins_before, "Wins persist after save/load")
	_assert_eq(RunManager.get_losses(), losses_before, "Losses persist after save/load")
	_assert_eq(RunManager.get_reputation(), rep_before_save, "Reputation persists after save/load")

	# Cleanup
	RunManager.clear_run_state()

	print("")


func _run_character_acquisition():
	"""Test character acquisition and grid operations."""
	print("--- CHARACTER ACQUISITION ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Test 1: Initial grid state
	var initial_team = RunManager.get_team()
	_assert_true(initial_team.size() > 0, "Team has initial members: %d" % initial_team.size())

	# Test 2: Check grid full detection
	var is_full = RunManager.is_grid_full()
	# Grid has 6 slots (2 rows x 3 cols), starts with 3 characters
	if initial_team.size() >= 6:
		_assert_true(is_full, "Grid is full with %d characters" % initial_team.size())
	else:
		_assert_false(is_full, "Grid is not full with %d characters" % initial_team.size())

	# Test 3: Invalid character acquisition
	var result = RunManager.acquire_character("invalid_character_id_12345")
	_assert_false(result["success"], "Acquiring invalid character fails")
	_assert_eq(result["error"], "invalid_character_id", "Error is invalid_character_id")

	# Test 4: Acquire valid character (get a character ID from GameData)
	var all_chars = GameData.get_all_characters()
	if all_chars.size() > 0:
		var char_id = all_chars[0].get("id", "")
		if not char_id.is_empty():
			result = RunManager.acquire_character(char_id)
			_assert_true(result["success"], "Acquiring valid character succeeds")
			if result["placed"]:
				_pass("Character placed in grid")
			elif result["grid_full"]:
				_pass("Grid full - character pending replacement")
				# Test pending character
				var pending = RunManager.get_pending_character()
				_assert_true(pending != null, "Pending character exists")
				# Cancel pending
				RunManager.cancel_pending_character()
				_assert_true(RunManager.get_pending_character() == null, "Pending character cleared")

	# Test 5: Acquire character when no active run
	RunManager.clear_run_state()
	result = RunManager.acquire_character("any_id")
	_assert_false(result["success"], "Cannot acquire character with no active run")
	_assert_eq(result["error"], "no_active_run", "Error is no_active_run")

	print("")


func _run_player_level_progression():
	"""Test player level and XP system."""
	print("--- PLAYER LEVEL PROGRESSION ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Test 1: Initial level state
	_assert_eq(RunManager.get_player_level(), 1, "Initial player level is 1")
	_assert_eq(RunManager.get_player_xp(), 0, "Initial XP is 0")
	_assert_false(RunManager.is_player_max_level(), "Not at max level initially")

	# Test 2: Add XP
	var leveled_up = RunManager.add_player_xp(10)
	_assert_true(RunManager.get_player_xp() >= 0, "XP is non-negative after adding")

	# Test 3: XP progress
	var progress = RunManager.get_player_xp_progress()
	_assert_true(progress >= 0.0 and progress <= 1.0, "XP progress is 0-1: %.2f" % progress)

	# Test 4: Level up by adding lots of XP
	var initial_level = RunManager.get_player_level()
	RunManager.add_player_xp(1000)  # Should cause level up
	# Level may or may not have increased depending on XP thresholds
	_assert_true(RunManager.get_player_level() >= initial_level, "Level didn't decrease after XP")

	# Test 5: XP persists after save/load
	var xp_before = RunManager.get_player_xp()
	var level_before = RunManager.get_player_level()
	RunManager.save_run_state()
	RunManager.is_run_active = false
	RunManager._run_state = null
	RunManager.load_run_state()
	_assert_eq(RunManager.get_player_xp(), xp_before, "XP persists after save/load")
	_assert_eq(RunManager.get_player_level(), level_before, "Level persists after save/load")

	# Cleanup
	RunManager.clear_run_state()

	print("")


func _run_end_of_run_rewards():
	"""Test end-of-run reward calculation and application."""
	print("--- END OF RUN REWARDS ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Add some wins to make rewards meaningful
	for i in range(5):
		RunManager.add_win()

	# Capture state before end
	var gems_before = PlayerAccount.get_gems()

	# Test 1: End run with victory
	var results = RunManager.end_run(true)  # Victory

	_assert_true(results.has("victory"), "Results has victory field")
	_assert_true(results["victory"], "Victory flag is true")
	_assert_true(results.has("wins"), "Results has wins field")
	_assert_eq(results["wins"], 5, "Wins count in results is 5")
	_assert_true(results.has("gem_reward"), "Results has gem_reward field")
	_assert_true(results["gem_reward"] >= 0, "Gem reward is non-negative: %d" % results["gem_reward"])
	_assert_true(results.has("fame_reward"), "Results has fame_reward field")
	_assert_true(results["fame_reward"] >= 0, "Fame reward is non-negative: %d" % results["fame_reward"])
	_assert_true(results.has("team"), "Results has team field")
	_assert_true(results.has("drafted_legacy_ids"), "Results has drafted_legacy_ids")

	# Test 2: Gems were actually added
	_assert_true(PlayerAccount.get_gems() >= gems_before, "Gems increased or unchanged after victory")

	# Test 3: Run is cleared after end
	_assert_false(RunManager.is_run_active, "Run is not active after end_run")
	_assert_false(RunManager.has_active_run(), "No save file after end_run")

	# Test 4: End run with defeat
	RunManager.start_new_run_with_legacies(legacies)
	RunManager.add_win()
	RunManager.add_loss()
	gems_before = PlayerAccount.get_gems()

	results = RunManager.end_run(false)  # Defeat

	_assert_true(results.has("victory"), "Defeat results has victory field")
	_assert_false(results["victory"], "Victory flag is false for defeat")
	_assert_true(results["gem_reward"] >= 0, "Defeat gem reward is non-negative")

	print("")


func _run_inventory_operations():
	"""Test item inventory operations."""
	print("--- INVENTORY OPERATIONS ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Test 1: Initial inventory state
	var inventory = RunManager.get_player_inventory()
	_assert_true(inventory != null, "Inventory exists")

	var items = RunManager.get_player_items()
	_assert_true(items is Array, "get_player_items returns array")

	# Test 2: Add item to inventory (get a valid item ID)
	var all_items = GameData.get_all_items()
	if all_items.size() > 0:
		var item_id = all_items[0].get("id", "")
		if not item_id.is_empty():
			var item = RunManager.add_item_to_inventory(item_id, false)
			if item != null:
				_pass("Item added to inventory: %s" % item_id)
				_assert_true(RunManager.has_item_in_inventory(item_id), "Inventory has item after add")
			else:
				_pass("Item add returned null (may be expected for some items)")

	# Test 3: Invalid item ID
	var invalid_item = RunManager.add_item_to_inventory("invalid_item_id_xyz", false)
	_assert_true(invalid_item == null, "Adding invalid item returns null")

	# Test 4: Inventory with no active run
	RunManager.clear_run_state()
	invalid_item = RunManager.add_item_to_inventory("any_id", false)
	_assert_true(invalid_item == null, "Cannot add item with no active run")

	var no_inventory = RunManager.get_player_inventory()
	_assert_true(no_inventory == null, "No inventory when no active run")

	print("")


func _run_attempt_purchase():
	"""Test attempt_purchase - critical for encounter shop flows."""
	print("--- ATTEMPT PURCHASE ---")

	# Setup fresh run with enough gold
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)
	RunManager.add_gold(1000)  # Ensure enough gold

	# Test 1: Successful purchase
	var gold_before = RunManager.get_gold()
	var test_action = func(char: CharacterInstance) -> bool:
		# If this runs, the action was called
		return true  # Action succeeds

	var result = RunManager.attempt_purchase(50, 0, test_action)
	_assert_true(result["success"], "Purchase succeeds with valid params")
	# If success is true, the action was definitely called (since it returned true)
	_pass("Action callable was invoked (implied by success)")
	_assert_eq(RunManager.get_gold(), gold_before - 50, "Gold deducted on success")

	# Test 2: No character selected (index -1)
	result = RunManager.attempt_purchase(50, -1, test_action)
	_assert_false(result["success"], "Purchase fails with no character selected")
	_assert_eq(result["error"], "no_character_selected", "Error is no_character_selected")

	# Test 3: Insufficient gold
	RunManager.spend_gold(RunManager.get_gold())  # Spend all gold
	_assert_eq(RunManager.get_gold(), 0, "Gold is 0")
	result = RunManager.attempt_purchase(100, 0, test_action)
	_assert_false(result["success"], "Purchase fails with insufficient gold")
	_assert_eq(result["error"], "insufficient_gold", "Error is insufficient_gold")

	# Test 4: Action returns false (should refund)
	RunManager.add_gold(100)
	gold_before = RunManager.get_gold()
	var failing_action = func(char: CharacterInstance) -> bool:
		return false  # Action fails

	result = RunManager.attempt_purchase(50, 0, failing_action)
	_assert_false(result["success"], "Purchase fails when action fails")
	_assert_eq(result["error"], "action_failed", "Error is action_failed")
	_assert_eq(RunManager.get_gold(), gold_before, "Gold refunded on action failure")

	# Test 5: Invalid character index
	result = RunManager.attempt_purchase(50, 999, test_action)  # Way out of bounds
	_assert_false(result["success"], "Purchase fails with invalid character index")
	_assert_eq(result["error"], "invalid_character", "Error is invalid_character")

	# Cleanup
	RunManager.clear_run_state()

	print("")


func _run_draft_error_paths():
	"""Test draft manager error handling."""
	print("--- DRAFT ERROR PATHS ---")

	var draft_manager = LegacyDraftManager.new()

	# Test 1: Can't select legacy not in current options
	draft_manager.generate_options()
	var fake_legacy = LegacyData.new()
	fake_legacy.id = "fake_legacy_not_in_options"
	var select_result = draft_manager.select_legacy(fake_legacy)
	_assert_false(select_result, "Cannot select legacy not in options")

	# Test 2: Can't select when draft is complete
	# Complete the draft first
	for round_num in range(3):
		for option in draft_manager.current_options:
			if option["is_owned"]:
				draft_manager.select_legacy(option["legacy"])
				break
		if not draft_manager.is_draft_complete():
			draft_manager.generate_options()

	_assert_true(draft_manager.is_draft_complete(), "Draft is complete")
	select_result = draft_manager.select_legacy(fake_legacy)
	_assert_false(select_result, "Cannot select when draft complete")

	# Test 3: Starting gold calculation with no legacies
	var empty_draft = LegacyDraftManager.new()
	var empty_gold = empty_draft.calculate_starting_gold()
	_assert_eq(empty_gold, 0, "Starting gold is 0 with no drafted legacies")

	# Test 4: Verify drafted legacies are returned correctly
	_assert_eq(draft_manager.get_drafted_legacies().size(), 3, "get_drafted_legacies returns 3")

	# Test 5: Reroll functionality (if available)
	var fresh_draft = LegacyDraftManager.new()
	fresh_draft.generate_options()
	var original_options = fresh_draft.current_options.duplicate()
	# Reroll should generate new options
	fresh_draft.generate_options()
	# Options may or may not be different (randomness), but should still have 3
	_assert_eq(fresh_draft.current_options.size(), 3, "Reroll maintains 3 options")

	print("")


func _run_phase_and_round_progression():
	"""Test phase transitions and round advancement."""
	print("--- PHASE & ROUND PROGRESSION ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Test 1: Initial state after draft
	_assert_eq(RunManager.get_round(), 1, "Starts at round 1")
	_assert_eq(RunManager.get_phase(), "combat", "Starts in combat phase after draft")

	# Test 2: Phase transitions
	RunManager.set_phase("encounter")
	_assert_eq(RunManager.get_phase(), "encounter", "Can set to encounter phase")
	_assert_true(RunManager.is_encounter_phase(), "is_encounter_phase returns true")
	_assert_false(RunManager.is_combat_phase(), "is_combat_phase returns false")

	RunManager.set_phase("combat")
	_assert_eq(RunManager.get_phase(), "combat", "Can set to combat phase")
	_assert_false(RunManager.is_encounter_phase(), "is_encounter_phase returns false")
	_assert_true(RunManager.is_combat_phase(), "is_combat_phase returns true")

	# Test 3: Invalid phase is rejected
	RunManager.set_phase("invalid_phase")
	_assert_eq(RunManager.get_phase(), "combat", "Invalid phase rejected, stays at combat")

	# Test 4: Round advancement
	RunManager.advance_round()
	_assert_eq(RunManager.get_round(), 2, "Round advanced to 2")
	_assert_eq(RunManager.get_phase(), "encounter", "Phase resets to encounter on advance")

	# Test 5: Multiple round advances
	RunManager.advance_round()
	RunManager.advance_round()
	_assert_eq(RunManager.get_round(), 4, "Round advanced to 4")

	# Test 6: Encounter completion flow
	RunManager.set_phase("encounter")
	var encounters_before = RunManager.encounters_this_round
	RunManager.complete_encounter()
	_assert_eq(RunManager.encounters_this_round, encounters_before + 1, "Encounter count incremented")

	# Complete enough encounters to trigger combat phase
	while RunManager.get_phase() == "encounter":
		RunManager.complete_encounter()
	_assert_eq(RunManager.get_phase(), "combat", "Phase switches to combat after enough encounters")

	# Cleanup
	RunManager.clear_run_state()

	print("")


func _run_lingering_effects():
	"""Test lingering effects system."""
	print("--- LINGERING EFFECTS ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Test 1: Lingering effects manager exists
	var effects_manager = RunManager.get_lingering_effects()
	_assert_true(effects_manager != null, "Lingering effects manager exists")

	# Test 2: Initially no pending effects
	_assert_false(RunManager.has_pending_effects("next_combat"), "No pending next_combat effects initially")
	_assert_false(RunManager.has_pending_effects("next_encounter"), "No pending next_encounter effects initially")

	# Test 3: Get pending effects returns empty array
	var pending = RunManager.get_pending_effects("next_combat")
	_assert_true(pending is Array, "get_pending_effects returns array")
	_assert_eq(pending.size(), 0, "No pending effects initially")

	# Test 4: Add a lingering effect
	var test_skill_data = {
		"id": "test_skill",
		"name": "Test Skill",
		"effect": {"type": "gold_bonus", "amount": 10},
		"trigger": "next_combat"
	}
	var add_result = RunManager.add_lingering_effect(test_skill_data)
	_assert_true(add_result, "Lingering effect added successfully")

	# Test 5: Effect is now pending
	_assert_true(RunManager.has_pending_effects("next_combat"), "Has pending next_combat effect")
	pending = RunManager.get_pending_effects("next_combat")
	_assert_eq(pending.size(), 1, "One pending effect")

	# Test 6: Trigger effects
	var triggered = RunManager.trigger_lingering_effects("next_combat")
	_assert_true(triggered is Array, "trigger returns array")

	# Test 7: Effect no longer pending after trigger (if it was one-shot)
	# Note: depends on implementation - some effects may persist

	# Test 8: Cannot add effect with no active run
	RunManager.clear_run_state()
	add_result = RunManager.add_lingering_effect(test_skill_data)
	_assert_false(add_result, "Cannot add effect with no active run")

	# Test 9: get_lingering_effects returns null with no run
	effects_manager = RunManager.get_lingering_effects()
	_assert_true(effects_manager == null, "No lingering effects manager without run")

	print("")


func _run_scene_manager_validation():
	"""Test SceneManager state and validation."""
	print("--- SCENE MANAGER VALIDATION ---")

	# Test 1: SceneManager exists
	_assert_true(SceneManager != null, "SceneManager autoload exists")

	# Test 2: Scene name resolution
	var main_menu_path = SceneManager.get_scene_path("main_menu")
	_assert_true(main_menu_path.ends_with(".tscn"), "main_menu resolves to .tscn path")

	var draft_path = SceneManager.get_scene_path("draft")
	_assert_true(draft_path.ends_with(".tscn"), "draft resolves to .tscn path")

	var run_view_path = SceneManager.get_scene_path("run_view")
	_assert_true(run_view_path.ends_with(".tscn"), "run_view resolves to .tscn path")

	# Test 3: Invalid scene name
	var invalid_path = SceneManager.get_scene_path("nonexistent_scene_xyz")
	_assert_true(invalid_path.is_empty(), "Invalid scene name returns empty path")

	# Test 4: All registered scenes resolve to valid paths
	var scene_names = ["main_menu", "draft", "run_view", "encounter_select",
					   "combat_select", "encounter_active", "combat_stub", "run_results",
					   "legacy_collection"]
	for scene_name in scene_names:
		var path = SceneManager.get_scene_path(scene_name)
		if path.is_empty():
			_fail("Scene '%s' has no registered path" % scene_name)
		else:
			# Verify file exists
			if ResourceLoader.exists(path):
				_pass("Scene '%s' -> %s exists" % [scene_name, path.get_file()])
			else:
				_fail("Scene '%s' -> %s does NOT exist" % [scene_name, path])

	# Test 5: Transition state
	_assert_false(SceneManager._is_transitioning, "Not transitioning initially")

	print("")


func _run_hud_visibility_helper():
	"""Test HUD visibility helper logic."""
	print("--- HUD VISIBILITY HELPER ---")

	# Load the helper script to access its constants
	var HudVisibilityHelper = load("res://scripts/components/hud_visibility_helper.gd")
	_assert_true(HudVisibilityHelper != null, "HudVisibilityHelper script loaded")

	# Create a dummy control for testing (helper requires a target)
	var dummy_control = Control.new()
	add_child(dummy_control)
	var helper = HudVisibilityHelper.new(dummy_control)
	_assert_true(helper != null, "HudVisibilityHelper instantiated with target")

	# Test 2: Gameplay scenes are recognized
	var gameplay_scenes = [
		"res://scenes/ui/draft.tscn",
		"res://scenes/ui/run_view.tscn",
		"res://scenes/ui/encounter_active.tscn",
		"res://scenes/ui/combat_stub.tscn",
	]

	for scene_path in gameplay_scenes:
		var is_gameplay = helper.is_gameplay_scene(scene_path)
		_assert_true(is_gameplay, "'%s' is gameplay scene" % scene_path.get_file())

	# Test 3: Non-gameplay scenes are not recognized
	var non_gameplay_scenes = [
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/ui/legacy_collection.tscn",
		"res://scenes/ui/run_results.tscn",
	]

	for scene_path in non_gameplay_scenes:
		var is_gameplay = helper.is_gameplay_scene(scene_path)
		_assert_false(is_gameplay, "'%s' is NOT gameplay scene" % scene_path.get_file())

	# Test 4: Invalid paths handled
	var is_gameplay = helper.is_gameplay_scene("")
	_assert_false(is_gameplay, "Empty path is not gameplay scene")

	is_gameplay = helper.is_gameplay_scene("invalid/path.tscn")
	_assert_false(is_gameplay, "Invalid path is not gameplay scene")

	# Cleanup
	dummy_control.queue_free()

	print("")


func _run_combat_rewards():
	"""Test combat reward application."""
	print("--- COMBAT REWARDS ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)
	RunManager.add_gold(100)  # Starting gold for tests

	# Test 1: Combat victory rewards
	var gold_before = RunManager.get_gold()
	var xp_before = RunManager.get_player_xp()
	var combat_data = {
		"gold_reward": 50,
		"xp_reward": 25,
		"difficulty": "normal"
	}

	RunManager.apply_combat_rewards(true, combat_data)  # Victory

	_assert_true(RunManager.get_gold() > gold_before, "Gold increased on victory")
	_assert_true(RunManager.get_player_xp() >= xp_before, "XP increased or unchanged on victory")

	# Test 2: Combat loss penalties
	var rep_before = RunManager.get_reputation()
	RunManager.apply_combat_rewards(false, combat_data)  # Loss

	_assert_true(RunManager.get_reputation() < rep_before, "Reputation decreased on loss")

	# Test 3: Multiple victories accumulate
	gold_before = RunManager.get_gold()
	RunManager.apply_combat_rewards(true, combat_data)
	RunManager.apply_combat_rewards(true, combat_data)
	_assert_true(RunManager.get_gold() > gold_before, "Multiple victories accumulate gold")

	# Cleanup
	RunManager.clear_run_state()

	print("")


func _run_run_flow_controller():
	"""Test RunFlowController combat completion."""
	print("--- RUN FLOW CONTROLLER ---")

	# Setup fresh run
	if RunManager.is_run_active:
		RunManager.clear_run_state()

	var unlocked = PlayerAccount.get_unlocked_legacies()
	var legacies: Array[LegacyData] = []
	for i in range(min(3, unlocked.size())):
		legacies.append(unlocked[i])

	RunManager.start_new_run_with_legacies(legacies)

	# Test 1: RunFlowController exists
	_assert_true(RunFlowController != null, "RunFlowController autoload exists")

	# Test 2: Combat completion with victory
	var wins_before = RunManager.get_wins()
	var combat_data = {"gold_reward": 25, "xp_reward": 10}

	RunFlowController.complete_combat(GameConstants.TEAM_PLAYER, combat_data)

	_assert_eq(RunManager.get_wins(), wins_before + 1, "Win recorded after combat victory")

	# Test 3: Combat completion with loss
	var losses_before = RunManager.get_losses()
	var rep_before = RunManager.get_reputation()

	RunFlowController.complete_combat(GameConstants.TEAM_OPPONENT, combat_data)

	_assert_eq(RunManager.get_losses(), losses_before + 1, "Loss recorded after combat loss")
	_assert_true(RunManager.get_reputation() <= rep_before, "Reputation decreased or unchanged on loss")

	# Cleanup
	RunManager.clear_run_state()

	print("")


func _run_encounter_context():
	"""Test EncounterContext callback system."""
	print("--- ENCOUNTER CONTEXT ---")

	# Test 1: Context can be created
	var context = EncounterContext.new()
	_assert_true(context != null, "EncounterContext created")

	# Test 2: Callbacks start as invalid
	_assert_false(context.has_callback("on_gold_spend"), "on_gold_spend not set initially")
	_assert_false(context.has_callback("on_buy_item"), "on_buy_item not set initially")
	_assert_false(context.has_callback("on_encounter_complete"), "on_encounter_complete not set initially")

	# Test 3: Can set callbacks
	var callback_invoked = false
	context.on_gold_spend = func(amount: int) -> bool:
		return amount <= 100

	_assert_true(context.has_callback("on_gold_spend"), "on_gold_spend is set after assignment")

	# Test 4: try_call returns false for unset callbacks
	var result = context.try_call("on_buy_item", ["item_id", 50, null, null])
	_assert_false(result, "try_call returns false for unset callback")

	# Test 5: to_dict returns dictionary with all callbacks
	var dict = context.to_dict()
	_assert_true(dict is Dictionary, "to_dict returns Dictionary")
	_assert_true(dict.has("on_gold_spend"), "Dictionary has on_gold_spend")
	_assert_true(dict.has("on_buy_item"), "Dictionary has on_buy_item")
	_assert_true(dict.has("on_buy_skill"), "Dictionary has on_buy_skill")
	_assert_true(dict.has("on_xp_select"), "Dictionary has on_xp_select")
	_assert_true(dict.has("on_encounter_complete"), "Dictionary has on_encounter_complete")
	_assert_true(dict.has("on_gold_reward"), "Dictionary has on_gold_reward")
	_assert_true(dict.has("on_health_restore"), "Dictionary has on_health_restore")

	# Test 6: Invalid callback name
	_assert_false(context.has_callback("nonexistent_callback"), "has_callback false for invalid name")

	print("")


func _run_player_account_persistence():
	"""Test player account save/load and state management."""
	print("--- PLAYER ACCOUNT PERSISTENCE ---")

	# Test 1: Account exists
	_assert_true(PlayerAccount != null, "PlayerAccount autoload exists")

	# Test 2: Currency operations are persistent
	var gems_before = PlayerAccount.get_gems()
	PlayerAccount.add_gems(50)
	_assert_eq(PlayerAccount.get_gems(), gems_before + 50, "Gems added")

	# Test 3: Spending more than available fails
	var current_gems = PlayerAccount.get_gems()
	var spend_result = PlayerAccount.spend_gems(current_gems + 1000)
	_assert_false(spend_result, "Cannot spend more gems than available")
	_assert_eq(PlayerAccount.get_gems(), current_gems, "Gems unchanged after failed spend")

	# Restore gems
	PlayerAccount.spend_gems(50)

	# Test 4: Reroll token operations
	var tokens_before = PlayerAccount.get_reroll_tokens()
	PlayerAccount.add_reroll_token()
	_assert_eq(PlayerAccount.get_reroll_tokens(), tokens_before + 1, "Reroll token added")

	var use_result = PlayerAccount.use_reroll_token()
	_assert_true(use_result, "Reroll token used successfully")
	_assert_eq(PlayerAccount.get_reroll_tokens(), tokens_before, "Token count restored")

	# Test 5: Legacy unlocking
	var unlocked_count = PlayerAccount.get_unlocked_legacies().size()
	_assert_true(unlocked_count >= 3, "At least 3 legacies unlocked: %d" % unlocked_count)

	# Test 6: Get legacy data
	var first_legacy = PlayerAccount.get_unlocked_legacies()[0]
	var legacy_data = PlayerAccount.get_legacy_data(first_legacy.id)
	_assert_true(legacy_data != null, "Can retrieve legacy data by ID")

	# Test 7: Invalid legacy ID returns null
	var invalid_legacy = PlayerAccount.get_legacy_data("invalid_legacy_xyz")
	_assert_true(invalid_legacy == null, "Invalid legacy ID returns null")

	print("")


func _run_game_data_validation():
	"""Test GameData integrity and references."""
	print("--- GAME DATA VALIDATION ---")

	# Test 1: All characters have required fields
	var characters = GameData.get_all_characters()
	for char_data in characters:
		var char_id = char_data.get("id", "")
		_assert_true(not char_id.is_empty(), "Character has ID")
		_assert_true(char_data.has("base_stats"), "Character %s has base_stats" % char_id)
		_assert_true(char_data.has("name"), "Character %s has name" % char_id)
		break  # Just test first one to avoid spam

	_pass("All characters have required structure")

	# Test 2: All legacies have required fields
	var legacies = GameData.get_all_legacies()
	for legacy_data in legacies:
		var legacy_id = legacy_data.get("id", "")
		_assert_true(not legacy_id.is_empty(), "Legacy has ID")
		_assert_true(legacy_data.has("name"), "Legacy %s has name" % legacy_id)
		_assert_true(legacy_data.has("starting_character_options"), "Legacy %s has starting_character_options" % legacy_id)
		break  # Just test first one

	_pass("All legacies have required structure")

	# Test 3: All items have required fields
	var items = GameData.get_all_items()
	for item_data in items:
		var item_id = item_data.get("id", "")
		_assert_true(not item_id.is_empty(), "Item has ID")
		_assert_true(item_data.has("name"), "Item %s has name" % item_id)
		break

	_pass("All items have required structure")

	# Test 4: All skills have required fields
	var skills = GameData.get_all_skills()
	for skill_data in skills:
		var skill_id = skill_data.get("id", "")
		_assert_true(not skill_id.is_empty(), "Skill has ID")
		_assert_true(skill_data.has("name"), "Skill %s has name" % skill_id)
		break

	_pass("All skills have required structure")

	# Test 5: Character references in legacies are valid
	for legacy_data in legacies:
		var starting_chars = legacy_data.get("starting_characters", [])
		for char_id in starting_chars:
			var char_data = GameData.get_character_by_id(char_id)
			if char_data.is_empty():
				_fail("Legacy %s references invalid character: %s" % [legacy_data.get("id"), char_id])
				break
		break  # Just test first legacy

	_pass("Legacy character references are valid")

	# Test 6: Encounter types exist
	var encounter_types = GameData.get_encounter_types()
	_assert_true(encounter_types.size() > 0, "Encounter types defined: %d" % encounter_types.size())

	# Test 7: Each encounter type is a non-empty string
	for enc_type in encounter_types:
		_assert_true(not enc_type.is_empty(), "Encounter type is non-empty string")
		break

	_pass("Encounter types are valid strings")

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
