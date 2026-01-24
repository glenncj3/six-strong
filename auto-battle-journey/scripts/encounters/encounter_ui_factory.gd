class_name EncounterUIFactory
extends RefCounted
## Factory for creating encounter UI components.
## Contains all UI creation logic separated from the registry (SRP-2).
##
## Context Interface (passed to create_ui functions):
##   "set_gold_label": Callable(label: Label)  - Store reference to gold label for updates
##   "on_buy_item": Callable(item_id, cost, selector, button)  - Handle item purchase
##   "on_buy_skill": Callable(skill_id, cost, selector, button)  - Handle skill purchase
##   "on_xp_select": Callable(char_index, xp_amount, button)  - Handle XP award selection
##   "on_encounter_complete": Callable()  - Signal that encounter can be completed


# =============================================================================
# REWARD PREVIEW FUNCTIONS (OCP-1: Data-driven reward previews)
# =============================================================================

static func _get_shop_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for shop encounter."""
	var data = encounter_data.get("data", {})
	var item_count = data.get("items", []).size()
	var skill_count = data.get("skills", []).size()
	return "%d items, %d skills" % [item_count, skill_count]


static func _get_xp_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for XP reward encounter."""
	var data = encounter_data.get("data", {})
	return "+%d XP" % data.get("xp_amount", 0)


static func _get_gold_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for gold reward encounter."""
	var data = encounter_data.get("data", {})
	return "+%d Gold" % data.get("gold_amount", 0)


static func _get_health_restore_preview(_encounter_data: Dictionary) -> String:
	"""Get reward preview for health restore encounter."""
	return "Restore 50% HP"


static func _get_skill_trainer_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for skill trainer encounter."""
	var data = encounter_data.get("data", {})
	var skill_data = GameData.get_skill_by_id(data.get("skill_id", ""))
	if not skill_data.is_empty():
		return "Free: %s" % skill_data["name"]
	return "Free Skill"


static func _get_gamble_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for gamble encounter."""
	var data = encounter_data.get("data", {})
	var bet = data.get("bet_amount", 0)
	var mult = data.get("win_multiplier", 2)
	return "Bet %d, Win %d" % [bet, bet * mult]


static func _get_elite_challenge_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for elite challenge encounter."""
	var data = encounter_data.get("data", {})
	var xp = data.get("xp_reward", 0)
	var gold = data.get("gold_reward", 0)
	return "+%d XP (all), +%d Gold" % [xp, gold]


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

static func _disable_all_buttons(container: Control) -> void:
	"""Recursively disable all Button children in a container."""
	for child in container.get_children():
		if child is Button:
			child.disabled = true
		elif child.get_child_count() > 0:
			_disable_all_buttons(child)


# =============================================================================
# UI CREATION FUNCTIONS
# =============================================================================

static func _create_shop_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create shop encounter UI."""
	var vbox = UIHelpers.create_vbox_container()

	vbox.add_child(UIHelpers.create_label("Purchase items and skills with gold", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	var gold_label = UIHelpers.create_label("Your Gold: %d" % RunManager.get_gold(), GameConstants.FONT_SIZE_GOLD_DISPLAY, GameConstants.COLOR_GOLD, true)
	vbox.add_child(gold_label)

	# Store gold label reference in context for updates
	if context.has("set_gold_label"):
		context["set_gold_label"].call(gold_label)

	vbox.add_child(UIHelpers.create_spacer(10))

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 400)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", GameConstants.CONTENT_SEPARATION)
	scroll.add_child(inventory_list)

	var team = RunManager.get_team()

	# Items for sale
	if encounter_data["data"].has("items") and encounter_data["data"]["items"].size() > 0:
		var items_title = Label.new()
		items_title.text = "--- ITEM UPGRADES FOR SALE ---"
		items_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_title.modulate = GameConstants.COLOR_MUTED
		inventory_list.add_child(items_title)

		for item_sale in encounter_data["data"]["items"]:
			var item_data = GameData.get_item_upgrade_by_id(item_sale["id"])
			if not item_data.is_empty():
				var item_row = UIHelpers.create_shop_row(
					item_data,
					item_sale["cost"],
					team,
					context.get("on_buy_item", Callable()),
					"item"
				)
				inventory_list.add_child(item_row)

	# Skills for sale
	if encounter_data["data"].has("skills") and encounter_data["data"]["skills"].size() > 0:
		var skills_title = Label.new()
		skills_title.text = "--- SKILLS FOR SALE ---"
		skills_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skills_title.modulate = GameConstants.COLOR_MUTED
		inventory_list.add_child(skills_title)

		for skill_sale in encounter_data["data"]["skills"]:
			var skill_data = GameData.get_skill_by_id(skill_sale["id"])
			if not skill_data.is_empty():
				var skill_row = UIHelpers.create_shop_row(
					skill_data,
					skill_sale["cost"],
					team,
					context.get("on_buy_skill", Callable()),
					"skill"
				)
				inventory_list.add_child(skill_row)

	return vbox


static func _create_xp_reward_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create XP reward encounter UI."""
	var vbox = UIHelpers.create_vbox_container(16)

	vbox.add_child(UIHelpers.create_label("Choose a character to receive XP", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	var xp_amount = encounter_data["data"]["xp_amount"]
	vbox.add_child(UIHelpers.create_label("XP Award: +%d" % xp_amount, GameConstants.FONT_SIZE_REWARD, GameConstants.COLOR_SUCCESS, true))

	vbox.add_child(UIHelpers.create_spacer(20))

	var team = RunManager.get_team()
	var on_select = context.get("on_xp_select", Callable())

	for i in range(team.size()):
		var char_instance = team[i]
		var button = Button.new()
		button.text = "Give to %s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
		button.custom_minimum_size = Vector2(GameConstants.BUTTON_WIDTH_STANDARD, GameConstants.BUTTON_HEIGHT_STANDARD)
		UIStyles.setup_button(button)
		if on_select.is_valid():
			button.pressed.connect(on_select.bind(i, xp_amount, button))
		vbox.add_child(button)

	return vbox


static func _create_gold_reward_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create gold reward encounter UI."""
	var vbox = UIHelpers.create_vbox_container(16)

	var gold_amount = encounter_data["data"]["gold_amount"]

	vbox.add_child(UIHelpers.create_label("You found gold!", GameConstants.FONT_SIZE_HEADING, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label("+%d Gold" % gold_amount, 48, GameConstants.COLOR_GOLD, true))

	# Award gold via context callback
	var on_gold_reward = context.get("on_gold_reward", Callable())
	if on_gold_reward.is_valid():
		on_gold_reward.call(gold_amount)

	return vbox


static func _create_health_restore_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create health restore encounter UI."""
	var vbox = UIHelpers.create_vbox_container(16)

	vbox.add_child(UIHelpers.create_label("Your team's health is restored!", GameConstants.FONT_SIZE_HEADING, GameConstants.COLOR_TEXT_LIGHT, true))

	var heal_percentage = encounter_data["data"]["heal_percentage"]
	var team = RunManager.get_team()
	var on_health_restore = context.get("on_health_restore", Callable())

	for char_instance in team:
		var heal_amount = int(char_instance.max_health * heal_percentage)
		if on_health_restore.is_valid():
			on_health_restore.call(char_instance, heal_amount)

		var char_label = UIHelpers.create_label(
			"%s: +%d HP (%d/%d)" % [
				char_instance.get_character_name(),
				heal_amount,
				char_instance.current_health,
				char_instance.max_health
			],
			GameConstants.FONT_SIZE_BODY,
			GameConstants.COLOR_SUCCESS,
			true
		)
		vbox.add_child(char_label)

	return vbox


static func _create_skill_trainer_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create skill trainer encounter UI."""
	var vbox = UIHelpers.create_vbox_container(12)

	var skill_id = encounter_data["data"]["skill_id"]
	var skill_data = GameData.get_skill_by_id(skill_id)
	var on_complete = context.get("on_encounter_complete", Callable())
	var on_skill_learn = context.get("on_skill_learn", Callable())

	if skill_data.is_empty():
		vbox.add_child(UIHelpers.create_label("No skill available...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if on_complete.is_valid():
			on_complete.call()
		return vbox

	vbox.add_child(UIHelpers.create_label("The trainer offers to teach:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label(skill_data["name"], GameConstants.FONT_SIZE_REWARD, GameConstants.COLOR_SUCCESS, true))
	vbox.add_child(UIHelpers.create_label(skill_data["description"], GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	if skill_data.has("level_requirement"):
		vbox.add_child(UIHelpers.create_label("(Requires Level %d)" % skill_data["level_requirement"], GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_WARNING, true))

	vbox.add_child(UIHelpers.create_spacer(20))
	vbox.add_child(UIHelpers.create_label("Choose a character to learn this skill:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	var team = RunManager.get_team()

	for i in range(team.size()):
		var char_instance = team[i]
		var button = Button.new()
		button.text = "Teach %s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
		button.custom_minimum_size = Vector2(GameConstants.BUTTON_WIDTH_STANDARD, GameConstants.BUTTON_HEIGHT_STANDARD)
		UIStyles.setup_button(button)
		button.pressed.connect(_on_skill_trainer_selected.bind(i, skill_id, button, vbox, on_complete, on_skill_learn))
		vbox.add_child(button)

	return vbox


static func _on_skill_trainer_selected(char_index: int, skill_id: String, button: Button, container: VBoxContainer, on_complete: Callable, on_skill_learn: Callable) -> void:
	"""Handle skill trainer selection."""
	var team = RunManager.get_team()
	var char_instance = team[char_index]

	var success = false
	if on_skill_learn.is_valid():
		success = on_skill_learn.call(char_instance, skill_id)
	else:
		success = char_instance.learn_skill(skill_id)

	if success:
		button.text = "Skill Learned!"
		_disable_all_buttons(container)
		if on_complete.is_valid():
			on_complete.call()
	else:
		button.text = "Cannot Learn (Level/Already Known)"
		button.disabled = true


static func _create_gamble_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
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

	var gamble_button = Button.new()
	gamble_button.text = "GAMBLE!"
	gamble_button.custom_minimum_size = Vector2(GameConstants.BUTTON_WIDTH_SMALL, GameConstants.BUTTON_HEIGHT_STANDARD)
	gamble_button.disabled = current_gold < bet
	UIStyles.setup_button(gamble_button)
	gamble_button.pressed.connect(_on_gamble_pressed.bind(bet, multiplier, vbox, on_complete, on_gold_spend, on_gold_reward))
	buttons_container.add_child(gamble_button)

	var decline_button = Button.new()
	decline_button.text = "Decline"
	decline_button.custom_minimum_size = Vector2(GameConstants.BUTTON_WIDTH_SMALL, GameConstants.BUTTON_HEIGHT_STANDARD)
	UIStyles.setup_button(decline_button)
	decline_button.pressed.connect(_on_gamble_declined.bind(vbox, on_complete))
	buttons_container.add_child(decline_button)

	return vbox


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

	_disable_all_buttons(container)
	if on_complete.is_valid():
		on_complete.call()


static func _on_gamble_declined(container: Control, on_complete: Callable) -> void:
	"""Handle declining to gamble."""
	_disable_all_buttons(container)

	var result_label = container.get_node("ResultLabel")
	result_label.text = "You walk away..."
	result_label.modulate = GameConstants.COLOR_MUTED

	if on_complete.is_valid():
		on_complete.call()


static func _create_elite_challenge_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create elite challenge encounter UI."""
	var vbox = UIHelpers.create_vbox_container(12)

	var xp_reward = encounter_data["data"]["xp_reward"]
	var gold_reward = encounter_data["data"]["gold_reward"]

	vbox.add_child(UIHelpers.create_label("An elite challenge awaits!", GameConstants.FONT_SIZE_HEADING, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label("Complete this trial for great rewards.", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	vbox.add_child(UIHelpers.create_spacer(20))

	vbox.add_child(UIHelpers.create_label("Rewards:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label("+%d XP to ALL characters" % xp_reward, GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_SUCCESS, true))
	vbox.add_child(UIHelpers.create_label("+%d Gold" % gold_reward, GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_GOLD, true))

	vbox.add_child(UIHelpers.create_spacer(20))

	var on_complete = context.get("on_encounter_complete", Callable())
	var on_xp_reward_all = context.get("on_xp_reward_all", Callable())
	var on_gold_reward = context.get("on_gold_reward", Callable())

	var challenge_button = Button.new()
	challenge_button.text = "COMPLETE CHALLENGE"
	challenge_button.custom_minimum_size = Vector2(GameConstants.BUTTON_WIDTH_STANDARD, GameConstants.BUTTON_HEIGHT_STANDARD)
	UIStyles.setup_button(challenge_button)
	challenge_button.pressed.connect(_on_elite_challenge_completed.bind(xp_reward, gold_reward, challenge_button, on_complete, on_xp_reward_all, on_gold_reward))
	vbox.add_child(challenge_button)

	return vbox


static func _on_elite_challenge_completed(xp_reward: int, gold_reward: int, button: Button, on_complete: Callable, on_xp_reward_all: Callable, on_gold_reward: Callable) -> void:
	"""Handle elite challenge completion."""
	# Award XP to all characters via callback
	if on_xp_reward_all.is_valid():
		on_xp_reward_all.call(xp_reward)

	# Award gold via callback
	if on_gold_reward.is_valid():
		on_gold_reward.call(gold_reward)

	button.text = "Challenge Complete!"
	button.disabled = true

	if on_complete.is_valid():
		on_complete.call()
