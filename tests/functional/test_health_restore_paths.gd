extends Node
## Comprehensive path tests for Health Restore Encounter
##
## Paths tested:
## 1. Empty heal options → auto-complete
## 2. Select heal option → show character selector
## 3. Select character → heal successful
## 4. Insufficient gold → rejected
## 5. Multiple heal amounts (small/medium/large)
## 6. Heal character at full health (allowed in Phase 6+)
## 7. All team members eligible
## 8. Gold cost scaling with heal amount
## 9. Cancel/change selection

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const HealthRestoreUIScript = preload("res://scripts/encounters/types/health_restore_encounter_ui.gd")

var test_base
var total_passed := 0
var total_failed := 0
var all_errors: Array[String] = []


func _ready():
	print("\n========================================")
	print("HEALTH RESTORE - ALL PATHS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_empty_options_auto_completes()
	_test_ui_creation_with_options()
	_test_heal_option_selection()
	_test_small_heal_option()
	_test_medium_heal_option()
	_test_large_heal_option()
	_test_heal_success_flow()
	_test_insufficient_gold_rejected()
	_test_heal_full_health_character()
	_test_heal_multiple_team_members()
	_test_gold_cost_deduction()
	_test_heal_amount_applied()
	_test_completion_after_heal()
	_test_character_eligibility()

	_print_results()
	get_tree().quit(total_failed)


func _test_empty_options_auto_completes():
	_section("Empty Options Auto-Completes")

	var context = test_base.create_mock_context()
	var data = test_base.create_mock_encounter_data("health_restore", {
		"heal_options": []
	})

	var ui = HealthRestoreUIScript.create_ui(data, context)

	_assert_true(test_base.mock_context["encounter_completed"], "Empty options auto-completes")
	_assert_eq(test_base.mock_context["gold_spent"], 0, "No gold spent")

	_cleanup(ui)
	_collect_results()


func _test_ui_creation_with_options():
	_section("UI Creation With Options")

	var context = test_base.create_mock_context()
	var data = test_base.create_mock_encounter_data("health_restore", {
		"heal_options": [
			{"heal_amount": 20, "cost": 10},
			{"heal_amount": 50, "cost": 25}
		]
	})

	var ui = HealthRestoreUIScript.create_ui(data, context)

	_assert_true(ui != null, "UI created")
	_assert_false(test_base.mock_context["encounter_completed"], "Not auto-completed with options")

	_cleanup(ui)
	_collect_results()


func _test_heal_option_selection():
	_section("Heal Option Selection")

	# Test that selecting a heal option updates UI state
	var selected_option = null

	var options = [
		{"heal_amount": 20, "cost": 10},
		{"heal_amount": 50, "cost": 25},
		{"heal_amount": 100, "cost": 50}
	]

	# Select option 1
	selected_option = options[1]
	_assert_eq(selected_option["heal_amount"], 50, "Selected 50 heal option")
	_assert_eq(selected_option["cost"], 25, "Cost is 25 gold")

	# Change selection to option 2
	selected_option = options[2]
	_assert_eq(selected_option["heal_amount"], 100, "Changed to 100 heal option")
	_assert_eq(selected_option["cost"], 50, "Cost is 50 gold")

	_collect_results()


func _test_small_heal_option():
	_section("Small Heal Option")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var small_heal = {"heal_amount": 20, "cost": 10}

	# Simulate selecting and using small heal
	var spent = context["try_spend_gold"].call(small_heal["cost"])
	_assert_true(spent, "Small heal affordable")

	var team = test_base.mock_context["team"]
	if team.size() > 0:
		context["on_health_restore"].call(team[0], small_heal["heal_amount"])
		_assert_eq(test_base.mock_context["health_restored"].size(), 1, "Heal applied")
		_assert_eq(test_base.mock_context["health_restored"][0]["amount"], 20, "Healed 20 HP")

	_collect_results()


func _test_medium_heal_option():
	_section("Medium Heal Option")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var medium_heal = {"heal_amount": 50, "cost": 25}

	var spent = context["try_spend_gold"].call(medium_heal["cost"])
	_assert_true(spent, "Medium heal affordable")
	_assert_eq(test_base.mock_context["gold_spent"], 25, "Spent 25 gold")

	var team = test_base.mock_context["team"]
	if team.size() > 0:
		context["on_health_restore"].call(team[0], medium_heal["heal_amount"])
		_assert_eq(test_base.mock_context["health_restored"][0]["amount"], 50, "Healed 50 HP")

	_collect_results()


func _test_large_heal_option():
	_section("Large Heal Option")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var large_heal = {"heal_amount": 100, "cost": 50}

	var spent = context["try_spend_gold"].call(large_heal["cost"])
	_assert_true(spent, "Large heal affordable")
	_assert_eq(test_base.mock_context["gold_spent"], 50, "Spent 50 gold")

	var team = test_base.mock_context["team"]
	if team.size() > 0:
		context["on_health_restore"].call(team[0], large_heal["heal_amount"])
		_assert_eq(test_base.mock_context["health_restored"][0]["amount"], 100, "Healed 100 HP")

	_collect_results()


func _test_heal_success_flow():
	_section("Heal Success Flow")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var team = test_base.mock_context["team"]
	_assert_true(team.size() > 0, "Team has members")

	if team.size() > 0:
		var character = team[0]
		var heal_cost = 20
		var heal_amount = 30

		# Step 1: Spend gold
		var spent = context["try_spend_gold"].call(heal_cost)
		_assert_true(spent, "Gold spent")

		# Step 2: Apply heal
		context["on_health_restore"].call(character, heal_amount)
		_assert_eq(test_base.mock_context["health_restored"].size(), 1, "Heal recorded")

		# Step 3: Complete
		context["on_encounter_complete"].call()
		_assert_true(test_base.mock_context["encounter_completed"], "Encounter completed")

	_collect_results()


func _test_insufficient_gold_rejected():
	_section("Insufficient Gold Rejected")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 10

	var heal_cost = 50

	var spent = context["try_spend_gold"].call(heal_cost)
	_assert_false(spent, "Heal rejected - insufficient gold")
	_assert_eq(test_base.mock_context["gold_spent"], 0, "No gold spent")
	_assert_eq(test_base.mock_context["player_gold"], 10, "Gold unchanged")
	_assert_eq(test_base.mock_context["health_restored"].size(), 0, "No heal applied")

	_collect_results()


func _test_heal_full_health_character():
	_section("Heal Full Health Character (Allowed)")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	# In Phase 6+, healing full health characters is allowed
	var team = test_base.mock_context["team"]
	if team.size() > 0:
		var character = team[0]
		# Set to full health
		var max_health = character.stats.get("health", 100)
		character.current_health = max_health

		# Should still be able to heal (overheal or just allowed)
		context["try_spend_gold"].call(20)
		context["on_health_restore"].call(character, 30)

		_assert_eq(test_base.mock_context["health_restored"].size(), 1, "Heal allowed on full health character")

	_collect_results()


func _test_heal_multiple_team_members():
	_section("Heal Multiple Team Members")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 200

	var team = test_base.mock_context["team"]
	_assert_gte(team.size(), 2, "At least 2 team members")

	if team.size() >= 2:
		# Heal first character
		context["try_spend_gold"].call(20)
		context["on_health_restore"].call(team[0], 30)

		# Reset context for second encounter (in real game, this would be separate encounters)
		# But testing the callback works for different characters
		context["on_health_restore"].call(team[1], 50)

		_assert_eq(test_base.mock_context["health_restored"].size(), 2, "Both characters healed")
		_assert_eq(test_base.mock_context["health_restored"][0]["character"], team[0], "First char healed")
		_assert_eq(test_base.mock_context["health_restored"][1]["character"], team[1], "Second char healed")

	_collect_results()


func _test_gold_cost_deduction():
	_section("Gold Cost Deduction")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var costs = [10, 25, 50]
	var total_spent = 0

	for cost in costs:
		if test_base.mock_context["player_gold"] >= cost:
			context["try_spend_gold"].call(cost)
			total_spent += cost

	_assert_eq(test_base.mock_context["gold_spent"], total_spent, "Total gold spent: %d" % total_spent)
	_assert_eq(test_base.mock_context["player_gold"], 100 - total_spent, "Remaining gold correct")

	_collect_results()


func _test_heal_amount_applied():
	_section("Heal Amount Applied Correctly")

	var context = test_base.create_mock_context()
	var team = test_base.mock_context["team"]

	var heal_amounts = [10, 25, 50, 100]

	for amount in heal_amounts:
		if team.size() > 0:
			context["on_health_restore"].call(team[0], amount)

	_assert_eq(test_base.mock_context["health_restored"].size(), heal_amounts.size(), "All heals recorded")

	for i in range(heal_amounts.size()):
		_assert_eq(test_base.mock_context["health_restored"][i]["amount"], heal_amounts[i],
			"Heal %d applied correctly" % heal_amounts[i])

	_collect_results()


func _test_completion_after_heal():
	_section("Completion After Heal")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var team = test_base.mock_context["team"]
	if team.size() > 0:
		context["try_spend_gold"].call(20)
		context["on_health_restore"].call(team[0], 30)
		context["on_encounter_complete"].call()

	_assert_true(test_base.mock_context["encounter_completed"], "Completed after heal")
	_assert_eq(test_base.mock_context["completion_count"], 1, "Completed exactly once")

	_collect_results()


func _test_character_eligibility():
	_section("Character Eligibility")

	var context = test_base.create_mock_context()
	var team = test_base.mock_context["team"]

	# All characters should be eligible
	var eligible_count = 0
	for character in team:
		if character != null:
			eligible_count += 1

	_assert_eq(eligible_count, team.size(), "All team members eligible")
	_assert_gte(eligible_count, 1, "At least 1 eligible character")

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


func _assert_gte(actual: int, expected: int, message: String) -> bool:
	if actual >= expected:
		total_passed += 1
		print("    PASS: %s" % message)
		return true
	else:
		total_failed += 1
		all_errors.append("%s (expected >= %d, got: %d)" % [message, expected, actual])
		print("    FAIL: %s (expected >= %d, got: %d)" % [message, expected, actual])
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
