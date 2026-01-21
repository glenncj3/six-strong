class_name UIHelpers
extends RefCounted
# UIHelpers - Common UI utility functions
# Eliminates repeated patterns across UI code

# =============================================================================
# CONTAINER MANAGEMENT
# =============================================================================

# =============================================================================
# VBOX AND SPACER HELPERS (Issue 2)
# =============================================================================

static func create_vbox_container(separation: int = GameConstants.CONTENT_SEPARATION, full_rect: bool = true) -> VBoxContainer:
	"""
	Create a configured VBoxContainer with standard settings.

	Args:
		separation: Vertical separation between children (default: CONTENT_SEPARATION)
		full_rect: Whether to set PRESET_FULL_RECT anchor (default: true)

	Returns:
		Configured VBoxContainer
	"""
	var vbox = VBoxContainer.new()
	if full_rect:
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", separation)
	return vbox


static func create_spacer(height: int = 20) -> Control:
	"""
	Create a vertical spacer control.

	Args:
		height: Minimum height of the spacer (default: 20)

	Returns:
		Control configured as a spacer
	"""
	var spacer = Control.new()
	spacer.custom_minimum_size.y = height
	return spacer


static func create_label(
	text: String,
	font_size: int = GameConstants.FONT_SIZE_BODY,
	color: Color = Color.WHITE,
	centered: bool = false
) -> Label:
	"""
	Create a configured label with common settings.

	Args:
		text: Label text
		font_size: Font size override (default: FONT_SIZE_BODY)
		color: Text color via modulate (default: white)
		centered: Whether to center the text horizontally (default: false)

	Returns:
		Configured Label node
	"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		label.modulate = color
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


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


# =============================================================================
# COMBAT OPTION PANEL (Issue 1 Extension)
# =============================================================================

static func create_combat_option_panel(combat_data: Dictionary, on_select: Callable) -> PanelContainer:
	"""
	Create a complete combat option panel with all standard elements.
	Extends create_option_panel_base() for combat-specific layouts.

	Args:
		combat_data: Combat option dictionary with type, name, description, etc.
		on_select: Callback when fight button is pressed (receives combat_data)

	Returns:
		Complete PanelContainer with combat option UI
	"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = UIScaler.get_option_panel_height()
	panel.clip_contents = true

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	hbox.add_theme_constant_override("separation", 12)

	# Left margin with image
	var margin = MarginContainer.new()
	hbox.add_child(margin)
	margin.add_theme_constant_override("margin_left", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_right", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_top", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_bottom", GameConstants.PANEL_MARGIN)

	# Image
	var image = TextureRect.new()
	margin.add_child(image)
	image.custom_minimum_size = Vector2(GameConstants.COMBAT_IMAGE_SIZE, GameConstants.COMBAT_IMAGE_SIZE)
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_texture_safe(image, combat_data.get("image_path", ""))

	# Info section
	var info_vbox = VBoxContainer.new()
	hbox.add_child(info_vbox)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)

	# Name
	var name_label = Label.new()
	info_vbox.add_child(name_label)
	name_label.text = combat_data.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 20)

	# Type
	var type_label = Label.new()
	info_vbox.add_child(type_label)
	type_label.text = "[%s]" % combat_data.get("type", "").to_upper()
	type_label.modulate = GameConstants.COLOR_DISABLED
	type_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Description
	var desc_label = Label.new()
	info_vbox.add_child(desc_label)
	desc_label.text = combat_data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
	desc_label.max_lines_visible = 2  # Limit to prevent overflow

	# Difficulty or Rank (type-specific)
	if combat_data.get("type") == "ai":
		var diff_label = Label.new()
		info_vbox.add_child(diff_label)
		diff_label.text = "Difficulty: %s" % combat_data.get("difficulty", "Unknown")
		diff_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
		diff_label.modulate = get_difficulty_color(combat_data.get("difficulty", ""))

	elif combat_data.get("type") == "ghost":
		var rank_label = Label.new()
		info_vbox.add_child(rank_label)
		rank_label.text = "Player Rank: %d" % combat_data.get("rank", 0)
		rank_label.modulate = GameConstants.COLOR_GHOST_RANK
		rank_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Rewards
	var reward_label = Label.new()
	info_vbox.add_child(reward_label)
	reward_label.text = "Rewards: +%d Gold  +%d XP" % [
		combat_data.get("reward_gold", 0),
		combat_data.get("reward_xp", 0)
	]
	reward_label.modulate = GameConstants.COLOR_SUCCESS
	reward_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Spacer
	var spacer = Control.new()
	info_vbox.add_child(spacer)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Fight button
	var fight_button = Button.new()
	info_vbox.add_child(fight_button)
	fight_button.text = "FIGHT"
	fight_button.custom_minimum_size = Vector2(100, 40)
	if on_select.is_valid():
		fight_button.pressed.connect(on_select.bind(combat_data))

	return panel


static func get_difficulty_color(difficulty: String) -> Color:
	"""
	Get the color for a combat difficulty level.

	Args:
		difficulty: Difficulty string ("Easy", "Medium", "Hard")

	Returns:
		Appropriate color from GameConstants
	"""
	match difficulty:
		"Easy":
			return GameConstants.COLOR_DIFFICULTY_EASY
		"Medium":
			return GameConstants.COLOR_DIFFICULTY_MEDIUM
		"Hard":
			return GameConstants.COLOR_DIFFICULTY_HARD
		_:
			return GameConstants.COLOR_DISABLED


# =============================================================================
# ENCOUNTER OPTION PANEL
# =============================================================================

static func create_encounter_option_panel(encounter_data: Dictionary, on_select: Callable) -> PanelContainer:
	"""
	Create a complete encounter option panel with horizontal layout (matching combat panels).

	Args:
		encounter_data: Encounter option dictionary with type, name, description, etc.
		on_select: Callback when select button is pressed (receives encounter_data)

	Returns:
		Complete PanelContainer with encounter option UI
	"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = UIScaler.get_option_panel_height()
	panel.clip_contents = true

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	hbox.add_theme_constant_override("separation", 12)

	# Left margin with image
	var margin = MarginContainer.new()
	hbox.add_child(margin)
	margin.add_theme_constant_override("margin_left", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_right", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_top", GameConstants.PANEL_MARGIN)
	margin.add_theme_constant_override("margin_bottom", GameConstants.PANEL_MARGIN)

	# Image
	var image = TextureRect.new()
	margin.add_child(image)
	image.custom_minimum_size = Vector2(GameConstants.COMBAT_IMAGE_SIZE, GameConstants.COMBAT_IMAGE_SIZE)
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_texture_safe(image, encounter_data.get("image_path", ""))

	# Info section
	var info_vbox = VBoxContainer.new()
	hbox.add_child(info_vbox)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)

	# Name
	var name_label = Label.new()
	info_vbox.add_child(name_label)
	name_label.text = encounter_data.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 20)

	# Type
	var type_label = Label.new()
	info_vbox.add_child(type_label)
	type_label.text = "[%s]" % encounter_data.get("type", "").to_upper().replace("_", " ")
	type_label.modulate = GameConstants.COLOR_DISABLED
	type_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Description
	var desc_label = Label.new()
	info_vbox.add_child(desc_label)
	desc_label.text = encounter_data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
	desc_label.max_lines_visible = 2  # Limit to prevent overflow

	# Reward preview
	var reward_label = Label.new()
	info_vbox.add_child(reward_label)
	reward_label.text = _get_encounter_reward_preview(encounter_data)
	reward_label.modulate = GameConstants.COLOR_SUCCESS
	reward_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Spacer
	var spacer = Control.new()
	info_vbox.add_child(spacer)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Select button
	var select_button = Button.new()
	info_vbox.add_child(select_button)
	select_button.text = "SELECT"
	select_button.custom_minimum_size = Vector2(100, 40)
	if on_select.is_valid():
		select_button.pressed.connect(on_select.bind(encounter_data))

	return panel


static func _get_encounter_reward_preview(encounter_data: Dictionary) -> String:
	"""Get a preview of rewards for this encounter."""
	var encounter_type = encounter_data.get("type", "")
	var data = encounter_data.get("data", {})

	match encounter_type:
		"shop":
			var item_count = data.get("items", []).size()
			var skill_count = data.get("skills", []).size()
			return "%d items, %d skills" % [item_count, skill_count]
		"xp_reward":
			return "+%d XP" % data.get("xp_amount", 0)
		"gold_reward":
			return "+%d Gold" % data.get("gold_amount", 0)
		"health_restore":
			return "Restore 50%% HP"
		"skill_trainer":
			var skill_data = GameData.get_skill_by_id(data.get("skill_id", ""))
			if not skill_data.is_empty():
				return "Free: %s" % skill_data["name"]
			return "Free Skill"
		"gamble":
			var bet = data.get("bet_amount", 0)
			var mult = data.get("win_multiplier", 2)
			return "Bet %d, Win %d" % [bet, bet * mult]
		"elite_challenge":
			var xp = data.get("xp_reward", 0)
			var gold = data.get("gold_reward", 0)
			return "+%d XP (all), +%d Gold" % [xp, gold]
		_:
			return ""


# =============================================================================
# TEAM DISPLAY COMPONENT
# =============================================================================

const CharacterCardScene = preload("res://scenes/components/character_card.tscn")

static func populate_team_display(parent_container: Control, team: Array, title_text: String = "YOUR TEAM") -> void:
	"""
	Populate a container with a team display showing the player's characters.
	The parent_container must already be in the scene tree.

	Args:
		parent_container: Container already in the scene tree to populate
		team: Array of CharacterInstance objects from RunManager.get_team()
		title_text: Title to show above the team (default: "YOUR TEAM")
	"""
	clear_children(parent_container)

	var container = VBoxContainer.new()
	parent_container.add_child(container)
	container.add_theme_constant_override("separation", 8)

	# Title
	var title = Label.new()
	container.add_child(title)
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	title.modulate = GameConstants.COLOR_TEXT_LIGHT

	# Cards container (horizontal)
	var cards_container = HBoxContainer.new()
	container.add_child(cards_container)
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 8)

	# Add cards for each team member
	for char_instance in team:
		var card = CharacterCardScene.instantiate()
		cards_container.add_child(card)

		# Setup card with character data
		var display_data = {
			"id": char_instance.base_character_id,
			"rank": 1,
			"experience": char_instance.experience,
			"equipped_items": char_instance.equipped_items
		}

		card.setup(display_data, false)
		card.set_clickable(false)
		card.set_card_size(UIScaler.CardSize.SMALL)

		# Update with runtime stats
		_update_card_runtime_stats(card, char_instance)


static func _update_card_runtime_stats(card: Node, char_instance) -> void:
	"""Update card display with runtime character stats."""
	var stats_container = card.get_node("MarginContainer/VBoxContainer/StatsContainer")

	# Update health to show current/max
	stats_container.get_node("HealthLabel").text = "HP %d/%d" % [char_instance.current_health, char_instance.max_health]
	stats_container.get_node("AttackLabel").text = format_stat(GameConstants.STAT_ATTACK, char_instance.stats.get(GameConstants.STAT_ATTACK, 0))
	stats_container.get_node("DefenseLabel").text = format_stat(GameConstants.STAT_DEFENSE, char_instance.stats.get(GameConstants.STAT_DEFENSE, 0))
	stats_container.get_node("SpeedLabel").text = format_stat(GameConstants.STAT_SPEED, char_instance.stats.get(GameConstants.STAT_SPEED, 0))
	stats_container.get_node("IncomeLabel").text = format_stat(GameConstants.STAT_INCOME, char_instance.stats.get(GameConstants.STAT_INCOME, 0))

	# Show level in name
	var name_label = card.get_node("MarginContainer/VBoxContainer/NameLabel")
	name_label.text = "%s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
