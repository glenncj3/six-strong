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
