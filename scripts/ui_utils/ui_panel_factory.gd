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
		selector.add_item(team[i].get_character_name())
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
	name_label.theme_type_variation = "HeaderLabel"
	UIStyles.style_label(name_label, GameConstants.FONT_SIZE_GOLD_DISPLAY)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = data.get("description", "")
	UIStyles.style_label(desc_label, GameConstants.FONT_SIZE_TINY, GameConstants.COLOR_DISABLED)
	info_vbox.add_child(desc_label)

	# Level requirement
	var level_req = data.get("level_requirement", 1)
	if level_req > 1:
		var req_label = Label.new()
		req_label.text = "Requires Level %d" % level_req
		UIStyles.style_label(req_label, GameConstants.FONT_SIZE_TINY, GameConstants.COLOR_ERROR)
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

	# Full-art background image (border to border)
	_add_full_art_background(panel, data)

	# Info overlay on top of the art
	var info_vbox = _create_option_info_section(data, panel_type)
	panel.add_child(info_vbox)

	# Type-specific labels
	if panel_type == OptionPanelType.COMBAT:
		_add_combat_labels(info_vbox, data)
		_add_combat_rewards_overlay(panel, data)

	return panel


static func _add_full_art_background(panel: PanelContainer, data: Dictionary) -> void:
	"""Add a full-art background image inset within the panel border."""
	var image_path = data.get("image_path", "")
	if image_path.is_empty():
		return

	var content_margin = MarginContainer.new()
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.clip_contents = true
	UIStyles.set_margin_all(content_margin, UIStyles.BORDER_WIDTH_NORMAL)
	panel.add_child(content_margin)

	var image = TextureRect.new()
	content_margin.add_child(image)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	UIContainerHelpers.set_texture_safe(image, image_path)


static func _create_option_info_section(data: Dictionary, panel_type: OptionPanelType) -> VBoxContainer:
	"""Create the info section (name, type, description) overlaid on the panel art."""
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vbox.add_theme_constant_override("separation", 4)

	# Push text to the bottom of the panel
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(spacer)

	# Bottom text container with padding and gradient background
	var bottom_margin = MarginContainer.new()
	bottom_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_margin.add_theme_constant_override("margin_left", 12)
	bottom_margin.add_theme_constant_override("margin_right", 12)
	bottom_margin.add_theme_constant_override("margin_bottom", 8)
	info_vbox.add_child(bottom_margin)

	var text_vbox = VBoxContainer.new()
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_theme_constant_override("separation", 2)
	bottom_margin.add_child(text_vbox)

	# Name
	var name_label = Label.new()
	text_vbox.add_child(name_label)
	name_label.text = data.get("name", "Unknown")
	name_label.theme_type_variation = "HeaderLabel"
	UIStyles.style_label(name_label, GameConstants.FONT_SIZE_REWARD)
	var outline_size := 4
	UIStyles.apply_text_outline(name_label, Color.BLACK, outline_size)
	UIStyles.apply_text_glow(name_label)

	# Description
	var desc_label = Label.new()
	text_vbox.add_child(desc_label)
	desc_label.text = data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.max_lines_visible = 2
	UIStyles.style_label(desc_label, GameConstants.FONT_SIZE_HEADING)
	UIStyles.apply_text_outline(desc_label, Color.BLACK, outline_size)
	UIStyles.apply_text_glow(desc_label)

	return info_vbox


static func _add_combat_labels(info_vbox: VBoxContainer, data: Dictionary) -> void:
	"""Add combat-specific labels (difficulty as stars)."""
	var star_count := 1
	if data.get("type") == "ai":
		var difficulty = data.get("difficulty", "Easy")
		match difficulty:
			"Easy":
				star_count = 1
			"Medium":
				star_count = 2
			"Hard":
				star_count = 3
	elif data.get("type") == "ghost":
		star_count = clampi(data.get("prestige", 1), 1, 5)

	var diff_label = Label.new()
	info_vbox.add_child(diff_label)
	diff_label.add_theme_constant_override("margin_left", 8)
	diff_label.text = "  " + "★".repeat(star_count)
	UIStyles.style_label(diff_label, GameConstants.FONT_SIZE_HEADING, Color("#FFD700"))
	# Gold 3D effect via outline and shadow
	diff_label.add_theme_color_override("font_outline_color", Color("#8B6914"))
	diff_label.add_theme_constant_override("outline_size", 3)
	UIStyles.apply_text_outline(diff_label, Color("#4A3800"), 3)
	UIStyles.apply_text_glow(diff_label)


static func _add_combat_rewards_overlay(panel: PanelContainer, data: Dictionary) -> void:
	"""Add reward icons with quantities in the bottom-right corner of the panel."""
	var overlay = Control.new()
	panel.add_child(overlay)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var rewards_label = Label.new()
	overlay.add_child(rewards_label)
	rewards_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var gold = data.get("reward_gold", 0)
	var xp = data.get("reward_xp", 0)
	rewards_label.text = "%s%d  %s%d" % [GameConstants.EMOJI_GOLD, gold, GameConstants.EMOJI_STAR, xp]
	UIStyles.style_label(rewards_label, GameConstants.FONT_SIZE_HEADING)
	UIStyles.apply_text_outline(rewards_label)
	UIStyles.apply_text_glow(rewards_label)

	# Anchor to bottom-right
	rewards_label.anchor_left = 1.0
	rewards_label.anchor_top = 1.0
	rewards_label.anchor_right = 1.0
	rewards_label.anchor_bottom = 1.0
	rewards_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	rewards_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	rewards_label.offset_left = -18
	rewards_label.offset_right = -10
	rewards_label.offset_top = -13
	rewards_label.offset_bottom = -5



# Backwards-compatible aliases
static func create_combat_option_panel(combat_data: Dictionary, on_select: Callable) -> ClickableOptionPanel:
	"""Create a combat option panel. Alias for create_option_panel with COMBAT type."""
	return create_option_panel(combat_data, OptionPanelType.COMBAT, on_select)


static func create_encounter_option_panel(encounter_data: Dictionary, on_select: Callable) -> ClickableOptionPanel:
	"""Create an encounter option panel. Alias for create_option_panel with ENCOUNTER type."""
	return create_option_panel(encounter_data, OptionPanelType.ENCOUNTER, on_select)
