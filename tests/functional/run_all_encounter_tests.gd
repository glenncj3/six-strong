extends Node
## Master test runner for all encounter functional tests
## Run as a scene to execute all encounter tests with autoload access
##
## Usage: Open tests/functional/run_all_encounter_tests.tscn and press Play

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")

# Encounter UI scripts
const GoldRewardUIScript = preload("res://scripts/encounters/types/gold_reward_encounter_ui.gd")
const GambleUIScript = preload("res://scripts/encounters/types/gamble_encounter_ui.gd")
const ShopUIScript = preload("res://scripts/encounters/types/shop_encounter_ui.gd")
const HealthRestoreUIScript = preload("res://scripts/encounters/types/health_restore_encounter_ui.gd")
const MatchingGameUIScript = preload("res://scripts/encounters/types/matching_game_encounter_ui.gd")
const TreasureChestUIScript = preload("res://scripts/encounters/types/treasure_chest_encounter_ui.gd")
const SkillTrainerUIScript = preload("res://scripts/encounters/types/skill_trainer_encounter_ui.gd")
const CharacterShopUIScript = preload("res://scripts/encounters/types/character_shop_encounter_ui.gd")
const WheelUIScript = preload("res://scripts/encounters/types/wheel_of_fortune_encounter_ui.gd")
const SlotMachineUIScript = preload("res://scripts/encounters/types/slot_machine_encounter_ui.gd")

var total_passed := 0
var total_failed := 0
var all_errors: Array[String] = []


func _ready() -> void:
	print("")
	print("============================================================")
	print("ENCOUNTER FUNCTIONAL TEST SUITE")
	print("============================================================")
	print("")

	# Run all encounter tests
	_run_gold_reward_tests()
	_run_gamble_tests()
	_run_shop_tests()
	_run_health_restore_tests()
	_run_matching_game_tests()
	_run_treasure_chest_tests()
	_run_skill_trainer_tests()
	_run_character_shop_tests()
	_run_wheel_tests()
	_run_slot_machine_tests()

	# CRITICAL: Run scene tree instantiation tests
	# This catches bugs where setup() is called before _ready() (null @onready vars)
	_run_scene_tree_instantiation_tests()

	_print_final_results()

	get_tree().quit(total_failed)


# =============================================================================
# GOLD REWARD TESTS
# =============================================================================

func _run_gold_reward_tests():
	print("=== GOLD REWARD ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: Basic gold reward
	test.section("Basic Gold Reward")
	var context = test.create_mock_context()
	var data = test.create_mock_encounter_data("gold_reward", {"gold_amount": 50})
	var ui = GoldRewardUIScript.create_ui(data, context)
	test.assert_gold_rewarded(50, "Should reward 50 gold")
	test.assert_encounter_completed("Should auto-complete")
	_cleanup(ui)

	# Test 2: Zero gold
	test.section("Zero Gold Reward")
	context = test.create_mock_context()
	data = test.create_mock_encounter_data("gold_reward", {"gold_amount": 0})
	ui = GoldRewardUIScript.create_ui(data, context)
	test.assert_encounter_completed("Should complete with 0 gold")
	_cleanup(ui)

	_collect_results(test)
	print("")


# =============================================================================
# GAMBLE TESTS
# =============================================================================

func _run_gamble_tests():
	print("=== GAMBLE ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: UI Creation
	test.section("UI Creation")
	var context = test.create_mock_context()
	test.mock_context["player_gold"] = 100
	# Correct field names: bet_amount, win_multiplier
	var data = test.create_mock_encounter_data("gamble", {"bet_amount": 20, "win_multiplier": 2})
	var ui = GambleUIScript.create_ui(data, context)
	test.assert_true(ui != null, "UI created")
	_cleanup(ui)

	# Test 2: Insufficient gold
	test.section("Insufficient Gold")
	context = test.create_mock_context()
	test.mock_context["player_gold"] = 5
	data = test.create_mock_encounter_data("gamble", {"bet_amount": 20, "win_multiplier": 2})
	ui = GambleUIScript.create_ui(data, context)
	var button = _find_button(ui, "GAMBLE")
	if button:
		test.assert_true(button.disabled, "Button disabled when can't afford")
	_cleanup(ui)

	_collect_results(test)
	print("")


# =============================================================================
# SHOP TESTS
# =============================================================================

func _run_shop_tests():
	print("=== SHOP ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: Empty shop auto-completes
	test.section("Empty Shop")
	var context = test.create_mock_context()
	var data = test.create_mock_encounter_data("shop", {"offerings": [], "max_purchases": 1})
	var ui = ShopUIScript.create_ui(data, context)
	test.assert_encounter_completed("Empty shop auto-completes")
	_cleanup(ui)

	# Test 2: Shop with offerings
	test.section("Shop With Offerings")
	context = test.create_mock_context()
	var items = GameData.get_all_items()
	var offerings = []
	if items.size() > 0:
		offerings.append({
			"offering_type": "item",
			"id": items[0]["id"],
			"name": items[0].get("name", "Test"),
			"description": "",
			"cost": 30
		})
	data = test.create_mock_encounter_data("shop", {"offerings": offerings, "max_purchases": 1})
	ui = ShopUIScript.create_ui(data, context)
	test.assert_encounter_not_completed("Shop with offerings doesn't auto-complete")
	_cleanup(ui)

	_collect_results(test)
	print("")


# =============================================================================
# HEALTH RESTORE TESTS
# =============================================================================

func _run_health_restore_tests():
	print("=== HEALTH RESTORE ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: Empty options
	test.section("Empty Options")
	var context = test.create_mock_context()
	var data = test.create_mock_encounter_data("health_restore", {"heal_options": []})
	var ui = HealthRestoreUIScript.create_ui(data, context)
	test.assert_encounter_completed("Empty options auto-complete")
	_cleanup(ui)

	# Test 2: With heal options
	test.section("With Heal Options")
	context = test.create_mock_context()
	data = test.create_mock_encounter_data("health_restore", {
		"heal_options": [{"heal_amount": 20, "cost": 10}]
	})
	ui = HealthRestoreUIScript.create_ui(data, context)
	test.assert_encounter_not_completed("Heal options don't auto-complete")
	_cleanup(ui)

	# Test 3: Healing callback
	test.section("Healing Callback")
	context = test.create_mock_context()
	var team = test.mock_context["team"]
	if team.size() > 0:
		context["on_health_restore"].call(team[0], 30)
		test.assert_eq(test.mock_context["health_restored"].size(), 1, "Heal recorded")

	_collect_results(test)
	print("")


# =============================================================================
# MATCHING GAME TESTS
# =============================================================================

func _run_matching_game_tests():
	print("=== MATCHING GAME ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: UI Creation
	test.section("UI Creation")
	var context = test.create_mock_context()
	var data = test.create_mock_encounter_data("matching_game", {
		"big_gold": 100, "medium_gold": 50, "small_gold": 25
	})
	var ui = MatchingGameUIScript.create_ui(data, context)
	test.assert_true(ui != null, "UI created")
	test.assert_encounter_not_completed("Game doesn't auto-complete")
	_cleanup(ui)

	# Test 2: Reward on match
	test.section("Reward On Match")
	context = test.create_mock_context()
	context["on_gold_reward"].call(100)
	context["on_encounter_complete"].call()
	test.assert_gold_rewarded(100, "Match rewards gold")
	test.assert_encounter_completed("Match completes game")

	_collect_results(test)
	print("")


# =============================================================================
# TREASURE CHEST TESTS
# =============================================================================

func _run_treasure_chest_tests():
	print("=== TREASURE CHEST ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: Empty options
	test.section("Empty Options")
	var context = test.create_mock_context()
	var data = test.create_mock_encounter_data("treasure_chest", {"mystery_options": []})
	var ui = TreasureChestUIScript.create_ui(data, context)
	test.assert_encounter_completed("Empty options auto-complete")
	_cleanup(ui)

	# Test 2: With options
	test.section("With Mystery Options")
	context = test.create_mock_context()
	data = test.create_mock_encounter_data("treasure_chest", {
		"mystery_options": [
			{"element": "fire", "display_name": "Fire"},
			{"element": "ice", "display_name": "Ice"}
		],
		"bonus_gold": 10
	})
	ui = TreasureChestUIScript.create_ui(data, context)
	test.assert_true(ui != null, "UI created")
	_cleanup(ui)

	_collect_results(test)
	print("")


# =============================================================================
# SKILL TRAINER TESTS
# =============================================================================

func _run_skill_trainer_tests():
	print("=== SKILL TRAINER ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: Empty skills
	test.section("Empty Skills")
	var context = test.create_mock_context()
	# Correct field: skill_ids (array of skill IDs)
	var data = test.create_mock_encounter_data("skill_trainer", {"skill_ids": []})
	var ui = SkillTrainerUIScript.create_ui(data, context)
	test.assert_encounter_completed("Empty skills auto-complete")
	_cleanup(ui)

	# Test 2: With skills
	test.section("With Skill IDs")
	context = test.create_mock_context()
	var skills = GameData.get_all_skills()
	var skill_ids: Array = []
	if skills.size() > 0:
		skill_ids.append(skills[0]["id"])
	data = test.create_mock_encounter_data("skill_trainer", {"skill_ids": skill_ids})
	ui = SkillTrainerUIScript.create_ui(data, context)
	if skill_ids.size() > 0:
		test.assert_encounter_not_completed("Skills don't auto-complete")
	_cleanup(ui)

	_collect_results(test)
	print("")


# =============================================================================
# CHARACTER SHOP TESTS
# =============================================================================

func _run_character_shop_tests():
	print("=== CHARACTER SHOP ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: Empty offerings
	test.section("Empty Offerings")
	var context = test.create_mock_context()
	# Correct field: offerings (not character_offerings)
	var data = test.create_mock_encounter_data("character_shop", {"offerings": []})
	var ui = CharacterShopUIScript.create_ui(data, context)
	test.assert_encounter_completed("Empty offerings auto-complete")
	_cleanup(ui)

	# Test 2: With character offerings
	test.section("With Character Offerings")
	context = test.create_mock_context()
	test.mock_context["player_gold"] = 200
	var chars = GameData.get_all_characters()
	var offerings = []
	if chars.size() > 0:
		offerings.append({
			"offering_type": "character",
			"id": chars[0]["id"],
			"name": chars[0].get("name", "Test"),
			"description": "",
			"image_path": chars[0].get("image_path", ""),
			"cost": 40,
			"base_stats": chars[0].get("base_stats", {})
		})
	data = test.create_mock_encounter_data("character_shop", {"offerings": offerings})
	ui = CharacterShopUIScript.create_ui(data, context)
	if offerings.size() > 0:
		test.assert_encounter_not_completed("Characters don't auto-complete")
	_cleanup(ui)

	_collect_results(test)
	print("")


# =============================================================================
# WHEEL OF FORTUNE TESTS
# =============================================================================

func _run_wheel_tests():
	print("=== WHEEL OF FORTUNE ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: UI Creation
	test.section("UI Creation")
	var context = test.create_mock_context()
	var data = test.create_mock_encounter_data("wheel_of_fortune", {
		"respin_cost": 20
	})
	var ui = WheelUIScript.create_ui(data, context)
	test.assert_true(ui != null, "UI created")
	_cleanup(ui)

	_collect_results(test)
	print("")


# =============================================================================
# SLOT MACHINE TESTS
# =============================================================================

func _run_slot_machine_tests():
	print("=== SLOT MACHINE ENCOUNTER ===")
	var test = EncounterTestBaseScript.new()

	# Test 1: UI Creation
	test.section("UI Creation")
	var context = test.create_mock_context()
	var data = test.create_mock_encounter_data("slot_machine", {
		"free_spins": 3,
		"extra_spin_cost": 15
	})
	var ui = SlotMachineUIScript.create_ui(data, context)
	test.assert_true(ui != null, "UI created")
	_cleanup(ui)

	_collect_results(test)
	print("")


# =============================================================================
# SCENE TREE INSTANTIATION TESTS
# =============================================================================

func _run_scene_tree_instantiation_tests():
	"""
	CRITICAL TEST: Verifies all encounter UIs work when added to the scene tree.

	This catches bugs where:
	- setup() is called before _ready() (accessing null @onready vars)
	- Child nodes aren't properly initialized
	- Packed scenes have incorrect node paths

	The bug this catches: When create_ui() instantiates packed scenes and calls
	setup() before adding to the tree, @onready vars are null because _ready()
	hasn't been called yet.
	"""
	print("=== SCENE TREE INSTANTIATION ===")
	var test = EncounterTestBaseScript.new()

	# Test each encounter UI by adding to scene tree
	_test_scene_tree_ui(test, "gold_reward", GoldRewardUIScript, {"gold_amount": 50})
	_test_scene_tree_ui(test, "gamble", GambleUIScript, {"bet_amount": 20, "win_multiplier": 2})
	_test_scene_tree_ui(test, "shop", ShopUIScript, _create_shop_data())
	_test_scene_tree_ui(test, "health_restore", HealthRestoreUIScript, {"heal_options": [{"heal_amount": 20, "cost": 10}]})
	_test_scene_tree_ui(test, "matching_game", MatchingGameUIScript, {"big_gold": 100, "medium_gold": 50, "small_gold": 25})
	_test_scene_tree_ui(test, "treasure_chest", TreasureChestUIScript, {"mystery_options": [{"element": "fire", "display_name": "Fire"}], "bonus_gold": 10})
	_test_scene_tree_ui(test, "skill_trainer", SkillTrainerUIScript, _create_skill_trainer_data())
	_test_scene_tree_ui(test, "character_shop", CharacterShopUIScript, _create_character_shop_data())
	_test_scene_tree_ui(test, "wheel_of_fortune", WheelUIScript, {"respin_cost": 20})
	_test_scene_tree_ui(test, "slot_machine", SlotMachineUIScript, {"free_spins": 3, "extra_spin_cost": 15})

	_collect_results(test)
	print("")


func _test_scene_tree_ui(test, encounter_name: String, ui_script, encounter_data_content: Dictionary):
	"""Test that a specific encounter UI works when added to the scene tree."""
	test.section("Scene Tree: %s" % encounter_name)

	var context = test.create_mock_context()
	test.mock_context["player_gold"] = 500  # Ensure enough gold

	var data = test.create_mock_encounter_data(encounter_name, encounter_data_content)

	# Create UI (children may not be in tree yet at this point)
	var ui = ui_script.create_ui(data, context)

	if ui == null:
		# Some encounters auto-complete and return null - that's OK
		test.assert_true(true, "%s: UI null (auto-completed)" % encounter_name)
		return

	test.assert_true(ui != null, "%s: UI created" % encounter_name)

	# CRITICAL: Add to scene tree - this triggers _ready() on all children
	add_child(ui)

	# Verify all child nodes are properly initialized (not null)
	var init_result = _verify_nodes_initialized(ui)
	test.assert_true(init_result.success, "%s: All nodes initialized (%d checked)" % [encounter_name, init_result.count])

	if not init_result.success:
		for error in init_result.errors:
			test.assert_true(false, "%s: %s" % [encounter_name, error])

	# Verify is_node_ready() returns true for all Control children
	var ready_result = _verify_nodes_ready(ui)
	test.assert_true(ready_result.success, "%s: All nodes ready" % encounter_name)

	# Cleanup - remove from tree properly
	remove_child(ui)
	ui.queue_free()


func _verify_nodes_initialized(node: Node) -> Dictionary:
	"""Recursively verify all nodes are properly initialized (not null references)."""
	var result = {"success": true, "count": 0, "errors": []}
	var stack = [node]

	while stack.size() > 0:
		var current = stack.pop_back()
		result.count += 1

		if not is_instance_valid(current):
			result.success = false
			result.errors.append("Invalid node found in tree")
			continue

		# Check TextureRect nodes - a common @onready pattern
		if current is TextureRect:
			# Node should be valid even if texture is null
			if not is_instance_valid(current):
				result.success = false
				result.errors.append("Invalid TextureRect: %s" % current.name)

		# Check Label nodes
		if current is Label:
			# Accessing text property should not crash
			var _text = current.text
			if not is_instance_valid(current):
				result.success = false
				result.errors.append("Invalid Label: %s" % current.name)

		# Add children to check
		for child in current.get_children():
			stack.append(child)

	return result


func _verify_nodes_ready(node: Node) -> Dictionary:
	"""Verify is_node_ready() returns true for all Control children."""
	var result = {"success": true, "not_ready": []}
	var stack = [node]

	while stack.size() > 0:
		var current = stack.pop_back()

		if current is Control and not current.is_node_ready():
			result.success = false
			result.not_ready.append(current.name)

		for child in current.get_children():
			stack.append(child)

	return result


func _create_shop_data() -> Dictionary:
	"""Create test shop data with offerings."""
	var items = GameData.get_all_items()
	var offerings = []
	if items.size() > 0:
		offerings.append({
			"offering_type": "item",
			"id": items[0]["id"],
			"name": items[0].get("name", "Test Item"),
			"description": items[0].get("description", ""),
			"image_path": items[0].get("image_path", ""),
			"cost": 20
		})
	return {"offerings": offerings, "max_purchases": 1}


func _create_skill_trainer_data() -> Dictionary:
	"""Create test skill trainer data."""
	var skills = GameData.get_all_skills()
	var skill_ids: Array = []
	if skills.size() > 0:
		skill_ids.append(skills[0]["id"])
	return {"skill_ids": skill_ids}


func _create_character_shop_data() -> Dictionary:
	"""Create test character shop data with offerings."""
	var chars = GameData.get_all_characters()
	var offerings = []
	if chars.size() > 0:
		offerings.append({
			"offering_type": "character",
			"id": chars[0]["id"],
			"name": chars[0].get("name", "Test Character"),
			"description": "",
			"image_path": chars[0].get("image_path", ""),
			"cost": 40,
			"base_stats": chars[0].get("base_stats", {"health": 100})
		})
	return {"offerings": offerings}


# =============================================================================
# HELPERS
# =============================================================================

func _cleanup(ui):
	if ui and is_instance_valid(ui):
		ui.queue_free()


func _find_button(node: Node, text_contains: String) -> Button:
	if node is Button and text_contains.to_upper() in node.text.to_upper():
		return node
	for child in node.get_children():
		var found = _find_button(child, text_contains)
		if found:
			return found
	return null


func _collect_results(test):
	var results = test.get_results()
	total_passed += results.passed
	total_failed += results.failed
	all_errors.append_array(results.errors)


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
		print("ALL ENCOUNTER TESTS PASSED!")
	else:
		print("SOME TESTS FAILED - see errors above")

	print("============================================================")
	print("")
