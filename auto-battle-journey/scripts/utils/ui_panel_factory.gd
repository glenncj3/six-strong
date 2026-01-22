class_name UIPanelFactory
extends RefCounted
## Factory for creating option panels and shop UI elements.


## Type of option panel to create
enum OptionPanelType { COMBAT, ENCOUNTER }


# =============================================================================
# TEAM SELECTOR
# =============================================================================

static func create_team_selector(team: Array) -> OptionButton:
	"""
	Create a character selector dropdown for the current team.

	Args:
		team: Array of CharacterInstance objects

	Returns:
		Configured OptionButton with team members
	"""
	var selector = OptionButton.new()
	selector.add_item("Select Character...")
	for i in range(team.size()):
		selector.add_item("%s (Lv.%d)" % [team[i].get_character_name(), team[i].level])
	return selector


# =============================================================================
# SHOP ROW CREATION
# =============================================================================

static func create_shop_row(
	data: Dictionary,
	cost: int,
	team: Array,
	buy_callback: Callable,
	content_type: String = "item"
) -> Control:
	"""
	Create a shop row for items or skills.

	Args:
		data: Item or skill data dictionary
		cost: Cost in gold
		team: Array of CharacterInstance for team selector
		buy_callback: Callback for buy button (receives: id, cost, selector, button)
		content_type: "item" or "skill" for labeling

	Returns:
		HBoxContainer with shop row UI
	"""
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", GameConstants.SHOP_ROW_SEPARATION)

	var item_id = data.get("id", "")

	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(GameConstants.SHOP_ICON_SIZE, GameConstants.SHOP_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIContainerHelpers.set_texture_safe(icon, data.get("image_path", ""))
	row.add_child(icon)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = data.get("name", "Unknown %s" % content_type.capitalize())
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = data.get("description", "")
	desc_label.modulate = GameConstants.COLOR_DISABLED
	desc_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_TINY)
	info_vbox.add_child(desc_label)

	# Level requirement
	var level_req = data.get("level_requirement", 1)
	if level_req > 1:
		var req_label = Label.new()
		req_label.text = "Requires Level %d" % level_req
		req_label.modulate = GameConstants.COLOR_ERROR
		req_label.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(req_label)

	# Character selector
	var char_selector = create_team_selector(team)
	row.add_child(char_selector)

	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Buy (%d G)" % cost
	buy_button.custom_minimum_size = Vector2(80, 40)
	buy_button.pressed.connect(buy_callback.bind(item_id, cost, char_selector, buy_button))
	row.add_child(buy_button)

	return row


# =============================================================================
# OPTION PANEL BASE
# =============================================================================

static func create_option_panel_base(image_path: String, image_size: Vector2) -> Dictionary:
	"""
	Create the base structure for an option panel (encounter/combat selection).

	Args:
		image_path: Path to the panel image
		image_size: Size of the image

	Returns:
		Dictionary with "panel", "content" (VBoxContainer), and "image" (TextureRect)
	"""
	var panel = PanelContainer.new()

	var margin = MarginContainer.new()
	panel.add_child(margin)
	margin.add_theme_constant_override("margin_left", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_right", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_top", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_bottom", GameConstants.PANEL_MARGIN)

	var content = VBoxContainer.new()
	margin.add_child(content)
	content.add_theme_constant_override("separation", GameConstants.CONTENT_SEPARATION)

	# Image
	var image = TextureRect.new()
	content.add_child(image)
	image.custom_minimum_size = image_size
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIContainerHelpers.set_texture_safe(image, image_path)

	return {
		"panel": panel,
		"content": content,
		"image": image
	}


static func add_option_panel_labels(
	content: VBoxContainer,
	name_text: String,
	type_text: String,
	description: String
) -> void:
	"""
	Add standard labels to an option panel.

	Args:
		content: The VBoxContainer to add labels to
		name_text: Name to display
		type_text: Type tag (e.g., "SHOP", "AI")
		description: Description text
	"""
	# Name
	var name_label = Label.new()
	content.add_child(name_label)
	name_label.text = name_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)

	# Type
	var type_label = Label.new()
	content.add_child(type_label)
	type_label.text = "[%s]" % type_text
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_TINY)
	type_label.modulate = GameConstants.COLOR_DISABLED

	# Description
	var desc_label = Label.new()
	content.add_child(desc_label)
	desc_label.text = description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.y = 40


# =============================================================================
# OPTION PANEL CREATION (Unified)
# =============================================================================

static func create_option_panel(data: Dictionary, panel_type: OptionPanelType, on_select: Callable) -> ClickableOptionPanel:
	"""
	Create an option panel for combat or encounter selection.
	The entire panel is clickable with hover/pressed states.

	Args:
		data: Option data dictionary with type, name, description, etc.
		panel_type: COMBAT or ENCOUNTER
		on_select: Callback when panel is clicked (receives data)

	Returns:
		Configured ClickableOptionPanel
	"""
	var panel = ClickableOptionPanel.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true

	# Common style setup from data (with defaults)
	var bg_color = Color(data.get("bg_color", "#3D2E24"))
	var hover_color = Color(data.get("hover_color", "#5D4E44"))
	var pressed_color = Color(data.get("pressed_color", "#2D1E14"))
	var border_color = Color(data.get("border_color", "#B88726"))

	var styles = UIStyles.create_clickable_panel_styles(bg_color, hover_color, pressed_color, border_color)
	panel.setup(data, styles)

	if on_select.is_valid():
		panel.panel_clicked.connect(on_select)

	# Common structure
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	hbox.add_theme_constant_override("separation", 12)

	# Image section
	var margin = _create_option_image_section(data)
	hbox.add_child(margin)

	# Info section with common labels
	var info_vbox = _create_option_info_section(data, panel_type)
	hbox.add_child(info_vbox)

	# Type-specific labels
	match panel_type:
		OptionPanelType.COMBAT:
			_add_combat_labels(info_vbox, data)
		OptionPanelType.ENCOUNTER:
			_add_encounter_labels(info_vbox, data)

	return panel


static func _create_option_image_section(data: Dictionary) -> MarginContainer:
	"""Create the image section for an option panel."""
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_right", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_top", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_bottom", GameConstants.PANEL_MARGIN)

	var image = TextureRect.new()
	margin.add_child(image)
	image.custom_minimum_size = Vector2(GameConstants.COMBAT_IMAGE_SIZE, GameConstants.COMBAT_IMAGE_SIZE)
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIContainerHelpers.set_texture_safe(image, data.get("image_path", ""))

	return margin


static func _create_option_info_section(data: Dictionary, panel_type: OptionPanelType) -> VBoxContainer:
	"""Create the info section (name, type, description) for an option panel."""
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)

	# Name
	var name_label = Label.new()
	info_vbox.add_child(name_label)
	name_label.text = data.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 20)

	# Type (encounter types replace underscores with spaces)
	var type_label = Label.new()
	info_vbox.add_child(type_label)
	var type_text = data.get("type", "").to_upper()
	if panel_type == OptionPanelType.ENCOUNTER:
		type_text = type_text.replace("_", " ")
	type_label.text = "[%s]" % type_text
	type_label.modulate = GameConstants.COLOR_DISABLED
	type_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Description
	var desc_label = Label.new()
	info_vbox.add_child(desc_label)
	desc_label.text = data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
	desc_label.max_lines_visible = 2

	return info_vbox


static func _add_combat_labels(info_vbox: VBoxContainer, data: Dictionary) -> void:
	"""Add combat-specific labels (difficulty/prestige and rewards)."""
	# Difficulty or prestige based on combat type
	if data.get("type") == "ai":
		var diff_label = Label.new()
		info_vbox.add_child(diff_label)
		diff_label.text = "Difficulty: %s" % data.get("difficulty", "Unknown")
		diff_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
		diff_label.modulate = UIFormattingHelpers.get_difficulty_color(data.get("difficulty", ""))
	elif data.get("type") == "ghost":
		var prestige_label = Label.new()
		info_vbox.add_child(prestige_label)
		prestige_label.text = "Player Prestige: %d" % data.get("prestige", 0)
		prestige_label.modulate = GameConstants.COLOR_GHOST_PRESTIGE
		prestige_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Rewards
	var reward_label = Label.new()
	info_vbox.add_child(reward_label)
	reward_label.text = "Rewards: +%d Gold  +%d XP" % [
		data.get("reward_gold", 0),
		data.get("reward_xp", 0)
	]
	reward_label.modulate = GameConstants.COLOR_SUCCESS
	reward_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)


static func _add_encounter_labels(info_vbox: VBoxContainer, data: Dictionary) -> void:
	"""Add encounter-specific labels (reward preview)."""
	var reward_label = Label.new()
	info_vbox.add_child(reward_label)
	reward_label.text = _get_encounter_reward_preview(data)
	reward_label.modulate = GameConstants.COLOR_SUCCESS
	reward_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)


static func _get_encounter_reward_preview(encounter_data: Dictionary) -> String:
	"""Get a preview of rewards for this encounter using the registry (OCP-1)."""
	return EncounterRegistry.get_reward_preview(encounter_data)


# Backwards-compatible aliases
static func create_combat_option_panel(combat_data: Dictionary, on_select: Callable) -> ClickableOptionPanel:
	"""Create a combat option panel. Alias for create_option_panel with COMBAT type."""
	return create_option_panel(combat_data, OptionPanelType.COMBAT, on_select)


static func create_encounter_option_panel(encounter_data: Dictionary, on_select: Callable) -> ClickableOptionPanel:
	"""Create an encounter option panel. Alias for create_option_panel with ENCOUNTER type."""
	return create_option_panel(encounter_data, OptionPanelType.ENCOUNTER, on_select)
