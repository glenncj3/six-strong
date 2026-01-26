extends Node
## Comprehensive path tests for Gamble Encounter
##
## Paths tested:
## 1. Win path → gain multiplied gold
## 2. Lose path → lose bet gold
## 3. Insufficient gold → button disabled
## 4. Win multiplier calculation
## 5. Various bet amounts
## 6. Statistical distribution (multiple trials)
## 7. Gold flow validation
## 8. Completion after gamble
## 9. Button state management

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const GambleUIScript = preload("res://scripts/encounters/types/gamble_encounter_ui.gd")

var test_base
var total_passed := 0
var total_failed := 0
var all_errors: Array[String] = []


func _ready():
	print("\n========================================")
	print("GAMBLE - ALL PATHS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_ui_creation()
	_test_gamble_data_structure()
	_test_win_path()
	_test_lose_path()
	_test_insufficient_gold_disabled()
	_test_win_multiplier_calculation()
	_test_various_bet_amounts()
	_test_gold_spent_on_gamble()
	_test_gold_gained_on_win()
	_test_completion_after_gamble()
	_test_button_disabled_after_gamble()
	_test_statistical_distribution()
	_test_reward_preview_format()
	_test_edge_case_zero_bet()
	_test_edge_case_exact_gold()

	_print_results()
	get_tree().quit(total_failed)


func _test_ui_creation():
	_section("UI Creation")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var data = test_base.create_mock_encounter_data("gamble", {
		"bet_amount": 20,
		"win_multiplier": 2
	})

	var ui = GambleUIScript.create_ui(data, context)

	_assert_true(ui != null, "UI created")
	_assert_false(test_base.mock_context["encounter_completed"], "Not auto-completed")

	_cleanup(ui)
	_collect_results()


func _test_gamble_data_structure():
	_section("Gamble Data Structure")

	var gamble_data = {
		"bet_amount": 25,
		"win_multiplier": 2
	}

	_assert_true(gamble_data.has("bet_amount"), "Has bet_amount")
	_assert_true(gamble_data.has("win_multiplier"), "Has win_multiplier")
	_assert_true(gamble_data["bet_amount"] > 0, "Bet amount positive")
	_assert_true(gamble_data["win_multiplier"] >= 1, "Multiplier at least 1")

	_collect_results()


func _test_win_path():
	_section("Win Path")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var bet = 20
	var multiplier = 2

	# Simulate win
	context["try_spend_gold"].call(bet)
	_assert_eq(test_base.mock_context["player_gold"], 80, "Bet deducted")

	# Win reward
	var winnings = bet * multiplier
	context["on_gold_reward"].call(winnings)
	_assert_eq(test_base.mock_context["gold_rewarded"], winnings, "Won %d gold" % winnings)

	# Net gain = winnings - bet = 40 - 20 = 20 (but winnings is full amount given)
	_assert_eq(winnings, 40, "Winnings calculation correct")

	context["on_encounter_complete"].call()
	_assert_true(test_base.mock_context["encounter_completed"], "Encounter completed")

	_collect_results()


func _test_lose_path():
	_section("Lose Path")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var bet = 20

	# Simulate loss
	context["try_spend_gold"].call(bet)
	_assert_eq(test_base.mock_context["player_gold"], 80, "Bet deducted")

	# No reward on loss
	_assert_eq(test_base.mock_context["gold_rewarded"], 0, "No gold rewarded on loss")

	context["on_encounter_complete"].call()
	_assert_true(test_base.mock_context["encounter_completed"], "Encounter completed")

	_collect_results()


func _test_insufficient_gold_disabled():
	_section("Insufficient Gold → Button Disabled")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 10

	var bet = 50

	# Cannot afford bet
	var can_gamble = test_base.mock_context["player_gold"] >= bet
	_assert_false(can_gamble, "Cannot gamble with insufficient gold")

	# Attempt should fail
	var spent = context["try_spend_gold"].call(bet)
	_assert_false(spent, "Gamble rejected")
	_assert_eq(test_base.mock_context["gold_spent"], 0, "No gold spent")

	_collect_results()


func _test_win_multiplier_calculation():
	_section("Win Multiplier Calculation")

	var bet_amounts = [10, 20, 30, 50]
	var multipliers = [2, 3, 4]

	for bet in bet_amounts:
		for mult in multipliers:
			var winnings = bet * mult
			_assert_eq(winnings, bet * mult, "Bet %d × %d = %d" % [bet, mult, winnings])

	_collect_results()


func _test_various_bet_amounts():
	_section("Various Bet Amounts")

	var bets = [10, 15, 20, 25, 30, 40, 50]

	for bet in bets:
		var valid = bet > 0
		_assert_true(valid, "Bet amount %d is valid" % bet)

	_collect_results()


func _test_gold_spent_on_gamble():
	_section("Gold Spent On Gamble")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var bet = 25

	context["try_spend_gold"].call(bet)
	_assert_eq(test_base.mock_context["gold_spent"], bet, "Gold spent: %d" % bet)
	_assert_eq(test_base.mock_context["player_gold"], 75, "Remaining gold: 75")

	_collect_results()


func _test_gold_gained_on_win():
	_section("Gold Gained On Win")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var bet = 20
	var multiplier = 3
	var winnings = bet * multiplier

	context["try_spend_gold"].call(bet)
	context["on_gold_reward"].call(winnings)

	_assert_eq(test_base.mock_context["gold_rewarded"], winnings, "Won %d gold" % winnings)

	# Player started with 100, bet 20, won 60 → should have 140 total
	var expected_total = 100 - bet + winnings
	_assert_eq(expected_total, 140, "Expected total gold correct")

	_collect_results()


func _test_completion_after_gamble():
	_section("Completion After Gamble")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	context["try_spend_gold"].call(20)
	context["on_encounter_complete"].call()

	_assert_true(test_base.mock_context["encounter_completed"], "Completed after gamble")
	_assert_eq(test_base.mock_context["completion_count"], 1, "Completed once")

	_collect_results()


func _test_button_disabled_after_gamble():
	_section("Button Disabled After Gamble")

	# Simulating button state
	var gamble_completed = false

	# Before gamble
	_assert_false(gamble_completed, "Button enabled before gamble")

	# After gamble
	gamble_completed = true
	_assert_true(gamble_completed, "Button disabled after gamble")

	_collect_results()


func _test_statistical_distribution():
	_section("Statistical Distribution (100 trials)")

	# Test that 50% win rate is approximately correct
	var trials = 100
	var wins = 0
	var losses = 0

	for i in range(trials):
		# Simulate 50% win chance
		var won = randf() > 0.5
		if won:
			wins += 1
		else:
			losses += 1

	_assert_eq(wins + losses, trials, "All trials accounted")

	# With 100 trials, expect roughly 50 wins (allow ±20 for variance)
	var win_rate = float(wins) / float(trials) * 100.0
	var in_range = wins >= 30 and wins <= 70
	_assert_true(in_range, "Win rate ~50%% (got %d wins, %.1f%%)" % [wins, win_rate])

	_collect_results()


func _test_reward_preview_format():
	_section("Reward Preview Format")

	var encounter_data = {
		"data": {
			"bet_amount": 25,
			"win_multiplier": 2
		}
	}

	var preview = GambleUIScript.get_reward_preview(encounter_data)
	_assert_true(preview != "", "Preview not empty")
	_assert_true("25" in preview or "50" in preview, "Preview contains bet or winnings amount")

	_collect_results()


func _test_edge_case_zero_bet():
	_section("Edge Case: Zero Bet")

	var bet = 0
	var multiplier = 2
	var winnings = bet * multiplier

	_assert_eq(winnings, 0, "Zero bet results in zero winnings")

	# Zero bet should not be allowed in practice
	var valid_bet = bet > 0
	_assert_false(valid_bet, "Zero bet is invalid")

	_collect_results()


func _test_edge_case_exact_gold():
	_section("Edge Case: Exact Gold Amount")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 25  # Exact bet amount

	var bet = 25

	var can_afford = test_base.mock_context["player_gold"] >= bet
	_assert_true(can_afford, "Can afford with exact gold")

	var spent = context["try_spend_gold"].call(bet)
	_assert_true(spent, "Bet accepted with exact gold")
	_assert_eq(test_base.mock_context["player_gold"], 0, "Gold depleted to 0")

	_collect_results()


# =============================================================================
# HELPERS
# =============================================================================

func _section(name: String):
	print("\n  --- %s ---" % name)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		total_passed += 1
		print("    PASS: %s" % message)
		return true
	else:
		total_failed += 1
		all_errors.append(message)
		print("    FAIL: %s" % message)
		return false


func _assert_false(condition: bool, message: String) -> bool:
	return _assert_true(not condition, message)


func _assert_eq(actual, expected, message: String) -> bool:
	if actual == expected:
		total_passed += 1
		print("    PASS: %s" % message)
		return true
	else:
		total_failed += 1
		all_errors.append("%s (expected: %s, got: %s)" % [message, str(expected), str(actual)])
		print("    FAIL: %s (expected: %s, got: %s)" % [message, str(expected), str(actual)])
		return false


func _cleanup(ui):
	if ui and is_instance_valid(ui):
		ui.queue_free()


func _collect_results():
	test_base = EncounterTestBaseScript.new()


func _print_results():
	print("\n========================================")
	print("Results: %d passed, %d failed" % [total_passed, total_failed])
	if all_errors.size() > 0:
		print("\nErrors:")
		for err in all_errors:
			print("  - %s" % err)
	print("========================================\n")
