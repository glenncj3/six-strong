class_name GambleEncounterUI
extends RefCounted
## UI creation and reward preview for gamble encounters.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create gamble encounter UI."""
	var vbox = UIHelpers.create_vbox_container(12)

	var bet = encounter_data["data"]["bet_amount"]
	var multiplier = encounter_data["data"]["win_multiplier"]
	var current_gold = RunManager.get_gold()

	var wager_text = "The gambler offers a wager: Bet %dg with a 50%% chance to win %dg, and a 50%% chance to lose it all!" % [bet, bet * multiplier]
	var wager_label = UIHelpers.create_label(wager_text, 24, GameConstants.COLOR_TEXT_LIGHT, true)
	wager_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wager_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(wager_label)

	vbox.add_child(UIHelpers.create_spacer(20))

	var result_label = UIHelpers.create_label("", GameConstants.FONT_SIZE_REWARD, Color.WHITE, true)
	result_label.name = "ResultLabel"
	result_label.theme_type_variation = "HeaderLabel"
	vbox.add_child(result_label)

	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	vbox.add_child(buttons_container)

	var on_complete = context.get("on_encounter_complete", Callable())
	var on_gold_spend = context.get("on_gold_spend", Callable())
	var on_gold_reward = context.get("on_gold_reward", Callable())

	var gamble_button = UIContainerHelpers.create_button(
		"GAMBLE!",
		_on_gamble_pressed.bind(bet, multiplier, vbox, on_complete, on_gold_spend, on_gold_reward),
		250, 100
	)
	gamble_button.add_theme_font_size_override("font_size", 64)
	gamble_button.disabled = current_gold < bet
	buttons_container.add_child(gamble_button)

	return vbox


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for gamble encounter."""
	var data = encounter_data.get("data", {})
	var bet = data.get("bet_amount", 0)
	var mult = data.get("win_multiplier", 2)
	return "Bet %d, Win %d" % [bet, bet * mult]


static func _on_gamble_pressed(bet: int, multiplier: int, container: Control, on_complete: Callable, on_gold_spend: Callable, on_gold_reward: Callable) -> void:
	"""Handle gamble."""
	var spent = false
	if on_gold_spend.is_valid():
		spent = on_gold_spend.call(bet)
	else:
		spent = RunManager.spend_gold(bet)
	if not spent:
		return

	var result_label = container.get_node("ResultLabel")

	# 50% chance to win
	var won = randf() > 0.5

	if won:
		var winnings = bet * multiplier
		if on_gold_reward.is_valid():
			on_gold_reward.call(winnings)
		else:
			RunManager.add_gold(winnings)
		result_label.text = "YOU WON! +%d Gold!" % winnings
	else:
		result_label.text = "You lost... -%d Gold" % bet

	UIContainerHelpers.disable_all_buttons(container)
	if on_complete.is_valid():
		on_complete.call()


