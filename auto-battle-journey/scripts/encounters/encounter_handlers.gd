class_name EncounterHandlers
extends RefCounted
# EncounterHandlers - Data-driven encounter type handler registry
# Eliminates hardcoded match statements in encounter_execute.gd
# Each handler defines: setup_ui callback, and immediate_action flag

# Handler definition structure:
# {
#   "create_ui": Callable,  # (encounter_data, context) -> Control
#   "immediate_complete": bool,  # Whether to enable complete button immediately
#   "on_complete": Callable (optional)  # Additional completion logic
# }

static var _handlers: Dictionary = {}
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	"""Initialize handlers on first access."""
	if _initialized:
		return

	_register_default_handlers()
	_initialized = true


static func _register_default_handlers() -> void:
	"""Register all default encounter type handlers."""

	# Shop encounter
	register("shop", {
		"create_ui": _create_shop_ui,
		"immediate_complete": true
	})

	# XP reward encounter
	register("xp_reward", {
		"create_ui": _create_xp_reward_ui,
		"immediate_complete": true
	})

	# Gold reward encounter
	register("gold_reward", {
		"create_ui": _create_gold_reward_ui,
		"immediate_complete": true
	})

	# Health restore encounter
	register("health_restore", {
		"create_ui": _create_health_restore_ui,
		"immediate_complete": true
	})

	# Skill trainer encounter
	register("skill_trainer", {
		"create_ui": _create_skill_trainer_ui,
		"immediate_complete": false  # Must select a character
	})

	# Gamble encounter
	register("gamble", {
		"create_ui": _create_gamble_ui,
		"immediate_complete": false  # Must gamble or decline
	})

	# Elite challenge encounter
	register("elite_challenge", {
		"create_ui": _create_elite_challenge_ui,
		"immediate_complete": false  # Must click complete challenge
	})


static func register(encounter_type: String, handler: Dictionary) -> void:
	"""
	Register a handler for an encounter type.

	Args:
		encounter_type: The type name (e.g., "shop")
		handler: Dictionary with "create_ui" Callable and "immediate_complete" bool
	"""
	_handlers[encounter_type] = handler


static func has_handler(encounter_type: String) -> bool:
	"""Check if a handler exists for this encounter type."""
	_ensure_initialized()
	return _handlers.has(encounter_type)


static func get_handler(encounter_type: String) -> Dictionary:
	"""Get the handler for an encounter type."""
	_ensure_initialized()
	return _handlers.get(encounter_type, {})


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""
	Create UI for an encounter using its registered handler.

	Args:
		encounter_data: The encounter option data
		context: Context dictionary with callbacks (e.g., update_gold_label, on_complete)

	Returns:
		Control node with the encounter UI, or null if no handler
	"""
	_ensure_initialized()

	var encounter_type = encounter_data.get("type", "")
	if not _handlers.has(encounter_type):
		push_error("EncounterHandlers: No handler for type: %s" % encounter_type)
		return null

	var handler = _handlers[encounter_type]
	var create_func: Callable = handler.get("create_ui")
	if create_func.is_valid():
		return create_func.call(encounter_data, context)

	return null


static func should_complete_immediately(encounter_type: String) -> bool:
	"""Check if this encounter type should enable complete button immediately."""
	_ensure_initialized()
	var handler = _handlers.get(encounter_type, {})
	return handler.get("immediate_complete", false)


# =============================================================================
# DEFAULT HANDLER IMPLEMENTATIONS
# =============================================================================

static func _create_shop_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create shop encounter UI."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	var label = Label.new()
	label.text = "Purchase items and skills with gold"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var gold_label = Label.new()
	gold_label.text = "Your Gold: %d" % RunManager.get_gold()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_GOLD_DISPLAY)
	gold_label.modulate = GameConstants.COLOR_GOLD
	vbox.add_child(gold_label)

	# Store gold label reference in context for updates
	if context.has("set_gold_label"):
		context["set_gold_label"].call(gold_label)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

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
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)

	var label = Label.new()
	label.text = "Choose a character to receive XP"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	vbox.add_child(label)

	var xp_amount = encounter_data["data"]["xp_amount"]
	var xp_label = Label.new()
	xp_label.text = "XP Award: +%d" % xp_amount
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_REWARD)
	xp_label.modulate = GameConstants.COLOR_SUCCESS
	vbox.add_child(xp_label)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)

	var team = RunManager.get_team()
	var on_select = context.get("on_xp_select", Callable())

	for i in range(team.size()):
		var char_instance = team[i]
		var button = Button.new()
		button.text = "Give to %s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
		button.custom_minimum_size = Vector2(300, 50)
		if on_select.is_valid():
			button.pressed.connect(on_select.bind(i, xp_amount, button))
		vbox.add_child(button)

	return vbox


static func _create_gold_reward_ui(encounter_data: Dictionary, _context: Dictionary) -> Control:
	"""Create gold reward encounter UI."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)

	var gold_amount = encounter_data["data"]["gold_amount"]

	var label = Label.new()
	label.text = "You found gold!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_HEADING)
	vbox.add_child(label)

	var gold_label = Label.new()
	gold_label.text = "+%d Gold" % gold_amount
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 48)
	gold_label.modulate = GameConstants.COLOR_GOLD
	vbox.add_child(gold_label)

	# Award gold immediately
	RunManager.add_gold(gold_amount)
	print("EncounterHandlers: Awarded %d gold" % gold_amount)

	return vbox


static func _create_health_restore_ui(encounter_data: Dictionary, _context: Dictionary) -> Control:
	"""Create health restore encounter UI."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)

	var label = Label.new()
	label.text = "Your team's health is restored!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_HEADING)
	vbox.add_child(label)

	var heal_percentage = encounter_data["data"]["heal_percentage"]
	var team = RunManager.get_team()

	for char_instance in team:
		var heal_amount = int(char_instance.max_health * heal_percentage)
		char_instance.heal(heal_amount)

		var char_label = Label.new()
		char_label.text = "%s: +%d HP (%d/%d)" % [
			char_instance.get_character_name(),
			heal_amount,
			char_instance.current_health,
			char_instance.max_health
		]
		char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		char_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
		char_label.modulate = GameConstants.COLOR_SUCCESS
		vbox.add_child(char_label)

	print("EncounterHandlers: Healed all characters by %d%%" % int(heal_percentage * 100))

	return vbox


static func _create_skill_trainer_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create skill trainer encounter UI."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)

	var skill_id = encounter_data["data"]["skill_id"]
	var skill_data = GameData.get_skill_by_id(skill_id)

	if skill_data.is_empty():
		var error_label = Label.new()
		error_label.text = "No skill available..."
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(error_label)
		# Allow completion even with error
		if context.has("on_encounter_complete"):
			context["on_encounter_complete"].call()
		return vbox

	var label = Label.new()
	label.text = "The trainer offers to teach:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	vbox.add_child(label)

	var skill_name_label = Label.new()
	skill_name_label.text = skill_data["name"]
	skill_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_name_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_REWARD)
	skill_name_label.modulate = GameConstants.COLOR_SUCCESS
	vbox.add_child(skill_name_label)

	var skill_desc_label = Label.new()
	skill_desc_label.text = skill_data["description"]
	skill_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_desc_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	vbox.add_child(skill_desc_label)

	if skill_data.has("level_requirement"):
		var req_label = Label.new()
		req_label.text = "(Requires Level %d)" % skill_data["level_requirement"]
		req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_label.modulate = GameConstants.COLOR_WARNING
		vbox.add_child(req_label)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)

	var char_label = Label.new()
	char_label.text = "Choose a character to learn this skill:"
	char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(char_label)

	var team = RunManager.get_team()
	var on_complete = context.get("on_encounter_complete", Callable())

	for i in range(team.size()):
		var char_instance = team[i]
		var button = Button.new()
		button.text = "Teach %s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
		button.custom_minimum_size = Vector2(300, 50)
		button.pressed.connect(_on_skill_trainer_selected.bind(i, skill_id, button, vbox, on_complete))
		vbox.add_child(button)

	return vbox


static func _on_skill_trainer_selected(char_index: int, skill_id: String, button: Button, container: VBoxContainer, on_complete: Callable) -> void:
	"""Handle skill trainer selection."""
	var team = RunManager.get_team()
	var char_instance = team[char_index]

	var success = char_instance.learn_skill(skill_id)
	if success:
		button.text = "Skill Learned!"
		button.disabled = true
		# Disable all buttons after successful learn
		for child in container.get_children():
			if child is Button:
				child.disabled = true
		if on_complete.is_valid():
			on_complete.call()
		print("EncounterHandlers: %s learned %s from trainer" % [char_instance.get_character_name(), skill_id])
	else:
		button.text = "Cannot Learn (Level/Already Known)"
		button.disabled = true


static func _create_gamble_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create gamble encounter UI."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)

	var bet = encounter_data["data"]["bet_amount"]
	var multiplier = encounter_data["data"]["win_multiplier"]
	var current_gold = RunManager.get_gold()

	var label = Label.new()
	label.text = "The gambler offers a wager..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_HEADING)
	vbox.add_child(label)

	var bet_label = Label.new()
	bet_label.text = "Bet: %d Gold" % bet
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	vbox.add_child(bet_label)

	var odds_label = Label.new()
	odds_label.text = "Win: %dx your bet (%d Gold)" % [multiplier, bet * multiplier]
	odds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	odds_label.modulate = GameConstants.COLOR_SUCCESS
	vbox.add_child(odds_label)

	var lose_label = Label.new()
	lose_label.text = "Lose: You lose your bet"
	lose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lose_label.modulate = GameConstants.COLOR_DANGER
	vbox.add_child(lose_label)

	var chance_label = Label.new()
	chance_label.text = "(50% chance to win)"
	chance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chance_label.modulate = GameConstants.COLOR_MUTED
	vbox.add_child(chance_label)

	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "Your Gold: %d" % current_gold
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.modulate = GameConstants.COLOR_GOLD
	vbox.add_child(gold_label)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)

	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = ""
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_REWARD)
	vbox.add_child(result_label)

	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	vbox.add_child(buttons_container)

	var on_complete = context.get("on_encounter_complete", Callable())

	var gamble_button = Button.new()
	gamble_button.text = "GAMBLE!"
	gamble_button.custom_minimum_size = Vector2(150, 50)
	gamble_button.disabled = current_gold < bet
	gamble_button.pressed.connect(_on_gamble_pressed.bind(bet, multiplier, vbox, on_complete))
	buttons_container.add_child(gamble_button)

	var decline_button = Button.new()
	decline_button.text = "Decline"
	decline_button.custom_minimum_size = Vector2(150, 50)
	decline_button.pressed.connect(_on_gamble_declined.bind(vbox, on_complete))
	buttons_container.add_child(decline_button)

	return vbox


static func _on_gamble_pressed(bet: int, multiplier: int, container: Control, on_complete: Callable) -> void:
	"""Handle gamble."""
	if not RunManager.spend_gold(bet):
		print("EncounterHandlers: Not enough gold to gamble")
		return

	var result_label = container.get_node("ResultLabel")
	var gold_label = container.get_node("GoldLabel")

	# 50% chance to win
	var won = randf() > 0.5

	if won:
		var winnings = bet * multiplier
		RunManager.add_gold(winnings)
		result_label.text = "YOU WON! +%d Gold!" % winnings
		result_label.modulate = GameConstants.COLOR_SUCCESS
		print("EncounterHandlers: Gamble won! +%d gold" % winnings)
	else:
		result_label.text = "You lost... -%d Gold" % bet
		result_label.modulate = GameConstants.COLOR_DANGER
		print("EncounterHandlers: Gamble lost! -%d gold" % bet)

	gold_label.text = "Your Gold: %d" % RunManager.get_gold()

	# Disable gamble buttons
	for child in container.get_children():
		if child is HBoxContainer:
			for button in child.get_children():
				if button is Button:
					button.disabled = true

	if on_complete.is_valid():
		on_complete.call()


static func _on_gamble_declined(container: Control, on_complete: Callable) -> void:
	"""Handle declining to gamble."""
	# Disable buttons
	for child in container.get_children():
		if child is HBoxContainer:
			for button in child.get_children():
				if button is Button:
					button.disabled = true

	var result_label = container.get_node("ResultLabel")
	result_label.text = "You walk away..."
	result_label.modulate = GameConstants.COLOR_MUTED

	if on_complete.is_valid():
		on_complete.call()
	print("EncounterHandlers: Declined to gamble")


static func _create_elite_challenge_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create elite challenge encounter UI."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)

	var xp_reward = encounter_data["data"]["xp_reward"]
	var gold_reward = encounter_data["data"]["gold_reward"]

	var label = Label.new()
	label.text = "An elite challenge awaits!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_HEADING)
	vbox.add_child(label)

	var desc_label = Label.new()
	desc_label.text = "Complete this trial for great rewards."
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	vbox.add_child(desc_label)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)

	var rewards_label = Label.new()
	rewards_label.text = "Rewards:"
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	vbox.add_child(rewards_label)

	var xp_label = Label.new()
	xp_label.text = "+%d XP to ALL characters" % xp_reward
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.modulate = GameConstants.COLOR_SUCCESS
	xp_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	vbox.add_child(xp_label)

	var gold_label = Label.new()
	gold_label.text = "+%d Gold" % gold_reward
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.modulate = GameConstants.COLOR_GOLD
	gold_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	vbox.add_child(gold_label)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 20
	vbox.add_child(spacer2)

	var on_complete = context.get("on_encounter_complete", Callable())

	var challenge_button = Button.new()
	challenge_button.text = "COMPLETE CHALLENGE"
	challenge_button.custom_minimum_size = Vector2(300, 60)
	challenge_button.pressed.connect(_on_elite_challenge_completed.bind(xp_reward, gold_reward, challenge_button, on_complete))
	vbox.add_child(challenge_button)

	return vbox


static func _on_elite_challenge_completed(xp_reward: int, gold_reward: int, button: Button, on_complete: Callable) -> void:
	"""Handle elite challenge completion."""
	# Award XP to all characters
	var team = RunManager.get_team()
	for char_instance in team:
		char_instance.add_experience(xp_reward)

	# Award gold
	RunManager.add_gold(gold_reward)

	button.text = "Challenge Complete!"
	button.disabled = true

	if on_complete.is_valid():
		on_complete.call()

	print("EncounterHandlers: Elite challenge completed! +%d XP to all, +%d gold" % [xp_reward, gold_reward])
