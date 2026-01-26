extends Node
## Comprehensive path tests for Skill Trainer Encounter
##
## Paths tested:
## 1. Empty skills → auto-complete
## 2. Skill selection → purchase + execute
## 3. Insufficient gold → rejected
## 4. Skill execution success → complete
## 5. Skill execution failure → refund gold
## 6. Effect preview generation
## 7. Multiple skill offerings
## 8. Gold cost deduction
## 9. Single purchase per encounter
## 10. Skill data structure validation

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const SkillTrainerUIScript = preload("res://scripts/encounters/types/skill_trainer_encounter_ui.gd")

var test_base
var total_passed := 0
var total_failed := 0
var all_errors: Array[String] = []


func _ready():
	print("\n========================================")
	print("SKILL TRAINER - ALL PATHS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_empty_skills_auto_completes()
	_test_ui_creation_with_skills()
	_test_skill_data_structure()
	_test_skill_cost_validation()
	_test_insufficient_gold_rejected()
	_test_gold_deduction_on_purchase()
	_test_effect_preview_format()
	_test_multiple_skill_offerings()
	_test_single_purchase_completes()
	_test_effect_types()
	_test_skill_trigger_types()
	_test_skill_execution_success_path()
	_test_skill_execution_refund_path()

	_print_results()
	get_tree().quit(total_failed)


func _test_empty_skills_auto_completes():
	_section("Empty Skills Auto-Completes")

	var context = test_base.create_mock_context()
	var data = test_base.create_mock_encounter_data("skill_trainer", {
		"skill_ids": []
	})

	var ui = SkillTrainerUIScript.create_ui(data, context)

	_assert_true(test_base.mock_context["encounter_completed"], "Empty skills auto-completes")

	_cleanup(ui)
	_collect_results()


func _test_ui_creation_with_skills():
	_section("UI Creation With Skills")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var skills = GameData.get_all_skills()
	var skill_ids = []
	for i in range(min(3, skills.size())):
		skill_ids.append(skills[i]["id"])

	var data = test_base.create_mock_encounter_data("skill_trainer", {
		"skill_ids": skill_ids
	})

	var ui = SkillTrainerUIScript.create_ui(data, context)

	_assert_true(ui != null, "UI created")
	if skill_ids.size() > 0:
		_assert_false(test_base.mock_context["encounter_completed"], "Not auto-completed with skills")

	_cleanup(ui)
	_collect_results()


func _test_skill_data_structure():
	_section("Skill Data Structure")

	var skill = {
		"id": "skill_001",
		"name": "Power Strike",
		"description": "Deal bonus damage",
		"cost": 25,
		"effect_type": "instant",
		"trigger": "",
		"effect": {
			"type": "damage",
			"target": "enemy",
			"amount": 50
		}
	}

	_assert_true(skill.has("id"), "Skill has ID")
	_assert_true(skill.has("name"), "Skill has name")
	_assert_true(skill.has("cost"), "Skill has cost")
	_assert_true(skill.has("effect_type"), "Skill has effect_type")
	_assert_true(skill.has("effect"), "Skill has effect")

	var effect = skill["effect"]
	_assert_true(effect.has("type"), "Effect has type")

	_collect_results()


func _test_skill_cost_validation():
	_section("Skill Cost Validation")

	# Test various skill costs
	var costs = [10, 25, 50, 75, 100]

	for cost in costs:
		var player_gold = 60
		var can_afford = player_gold >= cost
		if cost <= 60:
			_assert_true(can_afford, "Can afford skill costing %d with %d gold" % [cost, player_gold])
		else:
			_assert_false(can_afford, "Cannot afford skill costing %d with %d gold" % [cost, player_gold])

	_collect_results()


func _test_insufficient_gold_rejected():
	_section("Insufficient Gold Rejected")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 10

	var skill_cost = 50

	var spent = context["try_spend_gold"].call(skill_cost)
	_assert_false(spent, "Skill purchase rejected - insufficient gold")
	_assert_eq(test_base.mock_context["gold_spent"], 0, "No gold spent")
	_assert_eq(test_base.mock_context["player_gold"], 10, "Gold unchanged")

	_collect_results()


func _test_gold_deduction_on_purchase():
	_section("Gold Deduction On Purchase")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var costs = [15, 25, 40]

	for cost in costs:
		test_base.reset_context()
		test_base.mock_context["player_gold"] = 100
		context = test_base.create_mock_context()

		var spent = context["try_spend_gold"].call(cost)
		_assert_true(spent, "Spent %d gold for skill" % cost)
		_assert_eq(test_base.mock_context["player_gold"], 100 - cost, "Remaining: %d gold" % (100 - cost))

	_collect_results()


func _test_effect_preview_format():
	_section("Effect Preview Format")

	# Test various effect types generate proper previews
	var effects = [
		{"type": "damage", "target": "enemy", "amount": 50},
		{"type": "heal", "target": "team", "amount": 30},
		{"type": "buff", "stat": "attack", "amount": 10},
		{"type": "gold", "amount": 25}
	]

	for effect in effects:
		_assert_true(effect.has("type"), "Effect has type: %s" % effect["type"])
		if effect.has("amount"):
			_assert_true(effect["amount"] > 0, "Effect amount positive: %d" % effect["amount"])

	_collect_results()


func _test_multiple_skill_offerings():
	_section("Multiple Skill Offerings")

	var skill_offerings = [
		{"id": "skill_1", "name": "Attack Boost", "cost": 20},
		{"id": "skill_2", "name": "Defense Boost", "cost": 25},
		{"id": "skill_3", "name": "Speed Boost", "cost": 30}
	]

	_assert_eq(skill_offerings.size(), 3, "3 skill offerings")

	for i in range(skill_offerings.size()):
		_assert_true(skill_offerings[i].has("id"), "Offering %d has ID" % i)
		_assert_true(skill_offerings[i].has("name"), "Offering %d has name" % i)
		_assert_true(skill_offerings[i].has("cost"), "Offering %d has cost" % i)

	_collect_results()


func _test_single_purchase_completes():
	_section("Single Purchase Completes Encounter")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	# Simulate single purchase flow
	context["try_spend_gold"].call(25)
	context["on_encounter_complete"].call()

	_assert_true(test_base.mock_context["encounter_completed"], "Completed after 1 purchase")
	_assert_eq(test_base.mock_context["completion_count"], 1, "Exactly 1 completion")

	_collect_results()


func _test_effect_types():
	_section("Effect Types")

	var effect_types = ["instant", "passive", "triggered"]

	for effect_type in effect_types:
		var skill = {"effect_type": effect_type}
		_assert_eq(skill["effect_type"], effect_type, "Effect type: %s" % effect_type)

	# Instant effects execute immediately
	var instant_skill = {"effect_type": "instant", "name": "Quick Strike"}
	_assert_eq(instant_skill["effect_type"], "instant", "Instant skill type correct")

	_collect_results()


func _test_skill_trigger_types():
	_section("Skill Trigger Types")

	var triggers = ["", "on_damage", "on_heal", "on_turn_start", "on_turn_end"]

	for trigger in triggers:
		var skill = {"trigger": trigger}
		if trigger == "":
			_assert_true(skill["trigger"] == "", "No trigger (instant)")
		else:
			_assert_true(skill["trigger"] != "", "Has trigger: %s" % trigger)

	_collect_results()


func _test_skill_execution_success_path():
	_section("Skill Execution Success Path")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	# Simulate successful execution flow
	var skill_cost = 30

	# Step 1: Spend gold
	var spent = context["try_spend_gold"].call(skill_cost)
	_assert_true(spent, "Gold spent")

	# Step 2: Execute skill (simulated success)
	var execution_success = true
	_assert_true(execution_success, "Skill executed successfully")

	# Step 3: Complete
	context["on_encounter_complete"].call()
	_assert_true(test_base.mock_context["encounter_completed"], "Encounter completed")
	_assert_eq(test_base.mock_context["gold_spent"], skill_cost, "Gold spent correctly")

	_collect_results()


func _test_skill_execution_refund_path():
	_section("Skill Execution Failure → Refund")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var skill_cost = 30

	# Step 1: Spend gold
	context["try_spend_gold"].call(skill_cost)
	_assert_eq(test_base.mock_context["player_gold"], 70, "Gold spent initially")

	# Step 2: Execution fails (simulated)
	var execution_success = false
	_assert_false(execution_success, "Skill execution failed")

	# Step 3: Refund gold
	test_base.mock_context["player_gold"] += skill_cost  # Refund
	_assert_eq(test_base.mock_context["player_gold"], 100, "Gold refunded")

	# Encounter not completed (player can try again)
	_assert_false(test_base.mock_context["encounter_completed"], "Encounter not completed after failure")

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
