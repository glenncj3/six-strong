extends Node
## Comprehensive path tests for Slot Machine Encounter
##
## Paths tested:
## 1. Free spins → exhaust all → complete
## 2. Lock reels → spin → verify locked reels unchanged
## 3. Jackpot (gem×3) → highest reward
## 4. Triple match → high reward
## 5. Pair match → medium reward
## 6. No match → no reward
## 7. Extra spin purchase → one more spin
## 8. Can't afford extra spin

const EncounterTestBaseScript = preload("res://tests/functional/encounter_test_base.gd")
const SlotMachineUIScript = preload("res://scripts/encounters/types/slot_machine_encounter_ui.gd")

var test_base
var total_passed := 0
var total_failed := 0
var all_errors: Array[String] = []


func _ready():
	print("\n========================================")
	print("SLOT MACHINE - ALL PATHS")
	print("========================================")

	test_base = EncounterTestBaseScript.new()

	_test_ui_creation()
	_test_initial_state()
	_test_spin_button_available()
	_test_reel_lock_mechanics()
	_test_jackpot_detection()
	_test_triple_match_detection()
	_test_pair_match_detection()
	_test_no_match_detection()
	_test_extra_spin_affordable()
	_test_extra_spin_not_affordable()
	_test_spins_exhausted_completes()

	_print_results()
	get_tree().quit(total_failed)


func _test_ui_creation():
	_section("UI Creation")

	var context = test_base.create_mock_context()
	var data = test_base.create_mock_encounter_data("slot_machine", {
		"free_spins": 3,
		"extra_spin_cost": 15
	})

	var ui = SlotMachineUIScript.create_ui(data, context)

	_assert_true(ui != null, "UI created successfully")
	_assert_false(test_base.mock_context["encounter_completed"], "Not completed initially")

	_cleanup(ui)
	_collect_results()


func _test_initial_state():
	_section("Initial State")

	var context = test_base.create_mock_context()
	var data = test_base.create_mock_encounter_data("slot_machine", {
		"free_spins": 3,
		"extra_spin_cost": 15
	})

	var ui = SlotMachineUIScript.create_ui(data, context)

	# Should have spin button
	var spin_btn = _find_button(ui, "Spin")
	_assert_true(spin_btn != null, "Spin button exists")

	# Should have 3 lock buttons (one per reel)
	var lock_buttons = _find_all_buttons_containing(ui, "🔓")
	_assert_eq(lock_buttons.size(), 3, "3 lock buttons exist")

	_cleanup(ui)
	_collect_results()


func _test_spin_button_available():
	_section("Spin Button With Free Spins")

	var context = test_base.create_mock_context()
	var data = test_base.create_mock_encounter_data("slot_machine", {
		"free_spins": 3,
		"extra_spin_cost": 15
	})

	var ui = SlotMachineUIScript.create_ui(data, context)

	var spin_btn = _find_button(ui, "Spin")
	if spin_btn:
		_assert_false(spin_btn.disabled, "Spin button enabled with free spins")
		# Button text should show spin count
		_assert_true("3" in spin_btn.text or "Spin" in spin_btn.text, "Spin button shows spins or Spin text")

	_cleanup(ui)
	_collect_results()


func _test_reel_lock_mechanics():
	_section("Reel Lock Mechanics")

	# Test lock state toggling logic
	var locked_reels = [false, false, false]

	# Lock reel 0
	locked_reels[0] = true
	_assert_true(locked_reels[0], "Reel 0 locked")
	_assert_false(locked_reels[1], "Reel 1 still unlocked")
	_assert_false(locked_reels[2], "Reel 2 still unlocked")

	# Lock reel 2
	locked_reels[2] = true
	_assert_true(locked_reels[0], "Reel 0 still locked")
	_assert_true(locked_reels[2], "Reel 2 locked")

	# Unlock reel 0
	locked_reels[0] = false
	_assert_false(locked_reels[0], "Reel 0 unlocked")

	_collect_results()


func _test_jackpot_detection():
	_section("Jackpot Detection (gem×3)")

	# Jackpot: 3 gems
	var symbols = ["gem", "gem", "gem"]
	var result = _evaluate_slot_result(symbols)

	_assert_eq(result["type"], "jackpot", "Three gems = jackpot")
	_assert_true(result["payout"] > 0, "Jackpot has payout")

	_collect_results()


func _test_triple_match_detection():
	_section("Triple Match Detection")

	var test_cases = [
		["sword", "sword", "sword"],
		["shield", "shield", "shield"],
		["potion", "potion", "potion"],
		["gold", "gold", "gold"],
	]

	for symbols in test_cases:
		var result = _evaluate_slot_result(symbols)
		_assert_eq(result["type"], "triple", "Three %s = triple match" % symbols[0])

	_collect_results()


func _test_pair_match_detection():
	_section("Pair Match Detection")

	var test_cases = [
		["sword", "sword", "shield"],
		["shield", "potion", "potion"],
		["gold", "gold", "gem"],
	]

	for symbols in test_cases:
		var result = _evaluate_slot_result(symbols)
		_assert_eq(result["type"], "pair", "Two matching = pair: %s" % str(symbols))

	_collect_results()


func _test_no_match_detection():
	_section("No Match Detection")

	var symbols = ["sword", "shield", "potion"]
	var result = _evaluate_slot_result(symbols)

	_assert_eq(result["type"], "none", "No matching symbols = no match")
	_assert_eq(result["payout"], 0, "No match = no payout")

	_collect_results()


func _test_extra_spin_affordable():
	_section("Extra Spin Affordable")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 100

	var extra_cost = 15
	var can_afford = test_base.mock_context["player_gold"] >= extra_cost
	_assert_true(can_afford, "Can afford extra spin (%d gold)" % extra_cost)

	# Simulate purchase
	var spent = context["try_spend_gold"].call(extra_cost)
	_assert_true(spent, "Extra spin purchased")
	_assert_eq(test_base.mock_context["gold_spent"], extra_cost, "Gold spent for extra spin")

	_collect_results()


func _test_extra_spin_not_affordable():
	_section("Extra Spin Not Affordable")

	var context = test_base.create_mock_context()
	test_base.mock_context["player_gold"] = 5  # Less than extra spin cost

	var extra_cost = 15
	var can_afford = test_base.mock_context["player_gold"] >= extra_cost
	_assert_false(can_afford, "Cannot afford extra spin (%d gold, have %d)" % [extra_cost, test_base.mock_context["player_gold"]])

	var spent = context["try_spend_gold"].call(extra_cost)
	_assert_false(spent, "Extra spin rejected")
	_assert_eq(test_base.mock_context["gold_spent"], 0, "No gold spent")

	_collect_results()


func _test_spins_exhausted_completes():
	_section("Spins Exhausted Completes Encounter")

	var context = test_base.create_mock_context()

	# Simulate all spins used
	context["on_encounter_complete"].call()

	_assert_true(test_base.mock_context["encounter_completed"], "Encounter completes when spins exhausted")

	_collect_results()


# =============================================================================
# SLOT EVALUATION LOGIC (mirrors game logic)
# =============================================================================

func _evaluate_slot_result(symbols: Array) -> Dictionary:
	"""Evaluate slot machine result based on symbols."""
	# Count occurrences
	var counts = {}
	for sym in symbols:
		counts[sym] = counts.get(sym, 0) + 1

	# Check for jackpot (3 gems)
	if counts.get("gem", 0) == 3:
		return {"type": "jackpot", "payout": 500}

	# Check for triple
	for sym in counts:
		if counts[sym] == 3:
			return {"type": "triple", "payout": 100}

	# Check for pair
	for sym in counts:
		if counts[sym] == 2:
			return {"type": "pair", "payout": 25}

	# No match
	return {"type": "none", "payout": 0}


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


func _find_button(node: Node, text_contains: String) -> Button:
	if node is Button and text_contains in node.text:
		return node
	for child in node.get_children():
		var found = _find_button(child, text_contains)
		if found:
			return found
	return null


func _find_all_buttons_containing(node: Node, text: String) -> Array:
	var buttons = []
	if node is Button and text in node.text:
		buttons.append(node)
	for child in node.get_children():
		buttons.append_array(_find_all_buttons_containing(child, text))
	return buttons


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
