class_name UIHelpers
extends RefCounted
# UIHelpers - Common UI utility functions
# Eliminates repeated patterns across UI code

# =============================================================================
# CONTAINER MANAGEMENT
# =============================================================================

static func clear_children(container: Node) -> void:
	"""
	Remove and free all children from a container.
	Safer than manual iteration as it handles edge cases.

	Args:
		container: The parent node to clear
	"""
	for child in container.get_children():
		child.queue_free()


static func clear_children_immediate(container: Node) -> void:
	"""
	Remove and free all children immediately (use with caution).
	Use when you need children gone before next frame.

	Args:
		container: The parent node to clear
	"""
	for child in container.get_children():
		container.remove_child(child)
		child.free()


static func get_child_count_of_type(container: Node, type: Variant) -> int:
	"""
	Count children of a specific type.

	Args:
		container: Parent node to search
		type: The class/type to filter by

	Returns:
		Number of matching children
	"""
	var count = 0
	for child in container.get_children():
		if is_instance_of(child, type):
			count += 1
	return count


# =============================================================================
# PLACEHOLDER UI ELEMENTS
# =============================================================================

static func create_empty_placeholder(text: String, color: Color = Color(0.7, 0.7, 0.7)) -> Label:
	"""
	Create a placeholder label for empty states.

	Args:
		text: Text to display (e.g., "No items equipped")
		color: Text color (default gray)

	Returns:
		Configured Label node
	"""
	var label = Label.new()
	label.text = text
	label.modulate = color
	return label


static func add_empty_placeholder(container: Node, text: String) -> void:
	"""
	Add a placeholder label to a container if it's empty.

	Args:
		container: Container to check and potentially add to
		text: Placeholder text if empty
	"""
	if container.get_child_count() == 0:
		var placeholder = create_empty_placeholder(text)
		container.add_child(placeholder)


# =============================================================================
# LOADING HELPERS
# =============================================================================

static func load_texture_safe(path: String) -> Texture2D:
	"""
	Safely load a texture, returning null if not found.

	Args:
		path: Resource path to texture

	Returns:
		Loaded texture or null
	"""
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("UIHelpers: Texture not found: %s" % path)
		return null
	return load(path)


static func set_texture_safe(texture_rect: TextureRect, path: String) -> bool:
	"""
	Safely set a TextureRect's texture from a path.

	Args:
		texture_rect: The TextureRect to update
		path: Resource path to texture

	Returns:
		true if texture was set successfully
	"""
	var texture = load_texture_safe(path)
	if texture != null:
		texture_rect.texture = texture
		return true
	return false


# =============================================================================
# BUTTON HELPERS
# =============================================================================

static func set_button_enabled(button: Button, enabled: bool, disabled_text: String = "") -> void:
	"""
	Enable/disable a button with optional text change.

	Args:
		button: Button to modify
		enabled: Whether button should be enabled
		disabled_text: Optional text to show when disabled (empty = keep current)
	"""
	button.disabled = not enabled
	if not enabled and not disabled_text.is_empty():
		button.text = disabled_text


# =============================================================================
# FORMATTING HELPERS
# =============================================================================

static func format_currency(amount: int, symbol: String = "") -> String:
	"""
	Format a currency amount for display.

	Args:
		amount: The amount to format
		symbol: Optional symbol prefix (e.g., "💎")

	Returns:
		Formatted string
	"""
	if symbol.is_empty():
		return str(amount)
	return "%s %d" % [symbol, amount]


static func format_stat(stat_name: String, value: int) -> String:
	"""
	Format a stat for compact display.

	Args:
		stat_name: Full stat name
		value: Stat value

	Returns:
		Formatted string (e.g., "HP 100")
	"""
	var short_names = {
		GameConstants.STAT_HEALTH: "HP",
		GameConstants.STAT_ATTACK: "ATK",
		GameConstants.STAT_DEFENSE: "DEF",
		GameConstants.STAT_SPEED: "SPD",
		GameConstants.STAT_INCOME: "INC"
	}
	var short = short_names.get(stat_name, stat_name.to_upper().left(3))
	return "%s %d" % [short, value]


# =============================================================================
# TEAM SELECTOR (Issue 9)
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
# SHOP ROW CREATION (Issue 3)
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
	set_texture_safe(icon, data.get("image_path", ""))
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
# OPTION PANEL BASE (Issue 1)
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
	set_texture_safe(image, image_path)

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
