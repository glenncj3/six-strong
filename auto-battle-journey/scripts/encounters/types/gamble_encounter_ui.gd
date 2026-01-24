class_name GambleEncounterUI
extends RefCounted
## UI creation and reward preview for gamble encounters.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create gamble encounter UI."""
	var vbox = UIHelpers.create_vbox_container(12)

	var bet = encounter_data["data"]["bet_amount"]
	var multiplier = encounter_data["data"]["win_multiplier"]
	var current_gold = RunManager.get_gold()

	vbox.add_child(UIHelpers.create_label("The gambler offers a wager...", GameConstants.FONT_SIZE_HEADING, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label("Bet: %d Gold" % bet, GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label("Win: %dx your bet (%d Gold)" % [multiplier, bet * multiplier], GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_SUCCESS, true))
	vbox.add_child(UIHelpers.create_label("Lose: You lose your bet", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_DANGER, true))
	vbox.add_child(UIHelpers.create_label("(50% chance to win)", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_MUTED, true))

	var gold_label = UIHelpers.create_label("Your Gold: %d" % current_gold, GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_GOLD, true)
	gold_label.name = "GoldLabel"
	vbox.add_child(gold_label)

	vbox.add_child(UIHelpers.create_spacer(20))

	var result_label = UIHelpers.create_label("", GameConstants.FONT_SIZE_REWARD, GameConstants.COLOR_TEXT_LIGHT, true)
	result_label.name = "ResultLabel"
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
		GameConstants.BUTTON_WIDTH_SMALL
	)
	gamble_button.disabled = current_gold < bet
	buttons_container.add_child(gamble_button)

	var decline_button = UIContainerHelpers.create_button(
		"Decline",
		_on_gamble_declined.bind(vbox, on_complete),
		GameConstants.BUTTON_WIDTH_SMALL
	)
	buttons_container.add_child(decline_button)

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
	var gold_label = container.get_node("GoldLabel")

	# 50% chance to win
	var won = randf() > 0.5

	if won:
		var winnings = bet * multiplier
		if on_gold_reward.is_valid():
			on_gold_reward.call(winnings)
		else:
			RunManager.add_gold(winnings)
		result_label.text = "YOU WON! +%d Gold!" % winnings
		result_label.modulate = GameConstants.COLOR_SUCCESS
	else:
		result_label.text = "You lost... -%d Gold" % bet
		result_label.modulate = GameConstants.COLOR_DANGER

	gold_label.text = "Your Gold: %d" % RunManager.get_gold()

	UIContainerHelpers.disable_all_buttons(container)
	if on_complete.is_valid():
		on_complete.call()


static func _on_gamble_declined(container: Control, on_complete: Callable) -> void:
	"""Handle declining to gamble."""
	UIContainerHelpers.disable_all_buttons(container)

	var result_label = container.get_node("ResultLabel")
	result_label.text = "You walk away..."
	result_label.modulate = GameConstants.COLOR_MUTED

	if on_complete.is_valid():
		on_complete.call()
