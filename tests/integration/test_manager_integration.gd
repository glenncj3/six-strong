extends SceneTree
## Cross-manager integration tests.
## Tests flows that span multiple extracted managers:
## - Gold → purchase → inventory
## - Combat rewards → XP → level up
## - Reputation → defeat condition
## - Progression → round advance → phase transitions
## - Serialization round-trip across all managers
##
## Run with: "C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/integration/test_manager_integration.gd

const RunStateScript = preload("res://scripts/managers/run_state.gd")

var tests_passed := 0
var tests_failed := 0
var errors: Array[String] = []


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("MANAGER INTEGRATION TESTS")
	print("========================================\n")

	_test_gold_spend_insufficient()
	_test_gold_spend_and_track()
	_test_xp_to_level_up()
	_test_reputation_to_defeat()
	_test_round_advance_resets_phase()
	_test_encounter_to_combat_transition()
	_test_full_serialization_round_trip()
	_test_win_to_victory()

	_print_results()
	quit(tests_failed)


# =============================================================================
# GOLD INTEGRATION
# =============================================================================

func _test_gold_spend_insufficient():
	print("--- Gold: spend more than available ---")
	var rs = RunStateScript.new()
	rs.add_gold(30)
	var ok = rs.spend_gold(50)
	_assert_false(ok, "Cannot spend 50 when only 30 available")
	_assert_eq(rs.current_gold, 30, "Gold unchanged after failed spend")
	print("")


func _test_gold_spend_and_track():
	print("--- Gold: add and spend ---")
	var rs = RunStateScript.new()
	rs.add_gold(100)
	_assert_eq(rs.current_gold, 100, "Gold is 100 after add")
	var ok = rs.spend_gold(40)
	_assert_true(ok, "Spend 40 succeeds")
	_assert_eq(rs.current_gold, 60, "Gold is 60 after spending 40")
	print("")


# =============================================================================
# XP / LEVEL INTEGRATION
# =============================================================================

func _test_xp_to_level_up():
	print("--- XP: accumulate to level up ---")
	var rs = RunStateScript.new()
	_assert_eq(rs.player_level, 1, "Start at level 1")

	# Add XP just under the threshold
	rs.add_player_xp(GameConstants.XP_PER_LEVEL - 1)
	_assert_eq(rs.player_level, 1, "Still level 1 before threshold")

	# Push over
	var leveled = rs.add_player_xp(1)
	_assert_true(leveled, "Leveled up on threshold XP")
	_assert_eq(rs.player_level, 2, "Now level 2")
	_assert_eq(rs.player_xp, 0, "XP reset after exact level up")
	print("")


# =============================================================================
# REPUTATION / DEFEAT INTEGRATION
# =============================================================================

func _test_reputation_to_defeat():
	print("--- Reputation: drain to defeat ---")
	var rs = RunStateScript.new()
	_assert_eq(rs.reputation, 20, "Start at 20 reputation")
	_assert_false(rs.is_defeated(), "Not defeated at start")

	rs.lose_reputation(15)
	_assert_eq(rs.reputation, 5, "5 reputation remaining")
	_assert_false(rs.is_defeated(), "Not defeated at 5")

	rs.lose_reputation(10)  # Should clamp to 0
	_assert_eq(rs.reputation, 0, "Reputation clamped to 0")
	_assert_true(rs.is_defeated(), "Defeated at 0 reputation")
	print("")


# =============================================================================
# PROGRESSION INTEGRATION
# =============================================================================

func _test_round_advance_resets_phase():
	print("--- Progression: advance round resets phase ---")
	var rs = RunStateScript.new()
	rs.set_phase("combat")
	_assert_eq(rs.current_phase, "combat", "Phase set to combat")

	rs.advance_round()
	_assert_eq(rs.current_round, 2, "Round advanced to 2")
	_assert_eq(rs.current_phase, "encounter", "Phase reset to encounter")
	_assert_eq(rs.encounters_this_round, 0, "Encounters reset to 0")
	print("")


func _test_encounter_to_combat_transition():
	print("--- Progression: encounters trigger combat phase ---")
	var rs = RunStateScript.new()
	_assert_eq(rs.current_phase, "encounter", "Start in encounter phase")

	for i in GameConstants.ENCOUNTERS_PER_ROUND:
		rs.complete_encounter()

	_assert_eq(rs.current_phase, "combat", "Phase switched to combat after all encounters")
	print("")


func _test_win_to_victory():
	print("--- Progression: wins to victory ---")
	var rs = RunStateScript.new()
	for i in GameConstants.WINS_FOR_VICTORY:
		rs.add_win()
	_assert_true(rs.is_victory(), "Victory after required wins")
	_assert_true(rs.is_run_over(), "Run over on victory")
	print("")


# =============================================================================
# SERIALIZATION ROUND-TRIP
# =============================================================================

func _test_full_serialization_round_trip():
	print("--- Serialization: full round-trip ---")
	var rs = RunStateScript.new()
	rs.run_id = "test_integration_123"
	rs.add_gold(75)
	rs.add_win()
	rs.add_loss()
	rs.advance_round()
	rs.add_player_xp(5)
	rs.lose_reputation(3)

	var data = rs.to_dict()
	var rs2 = RunStateScript.from_dict(data)

	_assert_eq(rs2.run_id, "test_integration_123", "run_id preserved")
	_assert_eq(rs2.current_gold, 75, "Gold preserved")
	_assert_eq(rs2.wins, 1, "Wins preserved")
	_assert_eq(rs2.losses, 1, "Losses preserved")
	_assert_eq(rs2.current_round, 2, "Round preserved")
	_assert_eq(rs2.player_xp, 5, "XP preserved")
	_assert_eq(rs2.reputation, 17, "Reputation preserved")
	_assert_eq(rs2.current_phase, "encounter", "Phase preserved")
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
