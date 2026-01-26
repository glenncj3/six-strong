extends Control
# LegacyCollection - Browse and manage legacy collection
# Portrait mobile layout with full-screen details overlay
# Replaces the old character-centric collection screen (Phase 8)

@onready var background = $Background
@onready var title_label = $MainContainer/VBoxContainer/Title
@onready var legacy_list: VBoxContainer = $MainContainer/VBoxContainer/LegacyListScroll/LegacyList
@onready var legacy_details_panel: Panel = $LegacyDetailsPanel
@onready var details_background = $LegacyDetailsPanel/DetailsBackground
@onready var details_scroll: ScrollContainer = $LegacyDetailsPanel/DetailsMargin/DetailsContainer/DetailsScroll
@onready var details_content: VBoxContainer = $LegacyDetailsPanel/DetailsMargin/DetailsContainer/DetailsScroll/DetailsContent
@onready var details_title = $LegacyDetailsPanel/DetailsMargin/DetailsContainer/DetailsTitle
@onready var back_button: Button = $HeaderBar/MarginContainer/HBoxContainer/LeftSection/BackButton
@onready var gems_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GemsLabel
@onready var reroll_tokens_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/RerollTokensLabel

# Preload scenes
const LegacyTileScene = preload("res://scenes/components/legacy_tile.tscn")

var selected_legacy: LegacyData = null
var legacy_tiles: Array = []  # References to tile nodes


func _ready() -> void:
	_apply_visual_styling()

	back_button.pressed.connect(_on_back_pressed)

	# Hide details panel initially
	legacy_details_panel.visible = false

	# Initialize currency display
	_update_currency_display()
	PlayerAccount.gems_changed.connect(_on_gems_changed)
	PlayerAccount.reroll_tokens_changed.connect(_on_reroll_tokens_changed)

	# Connect legacy-specific signals
	PlayerAccount.legacy_unlocked.connect(_on_legacy_unlocked)
	PlayerAccount.legacy_prestige_up.connect(_on_legacy_prestige_up)

	_populate_legacy_list()
	_play_entrance_animations()


func _exit_tree() -> void:
	# Disconnect from autoload signals to prevent memory leaks
	if PlayerAccount.gems_changed.is_connected(_on_gems_changed):
		PlayerAccount.gems_changed.disconnect(_on_gems_changed)
	if PlayerAccount.reroll_tokens_changed.is_connected(_on_reroll_tokens_changed):
		PlayerAccount.reroll_tokens_changed.disconnect(_on_reroll_tokens_changed)
	if PlayerAccount.legacy_unlocked.is_connected(_on_legacy_unlocked):
		PlayerAccount.legacy_unlocked.disconnect(_on_legacy_unlocked)
	if PlayerAccount.legacy_prestige_up.is_connected(_on_legacy_prestige_up):
		PlayerAccount.legacy_prestige_up.disconnect(_on_legacy_prestige_up)


func _play_entrance_animations() -> void:
	"""Play entrance animations for UI elements."""
	AnimationManager.fade_in(title_label, GameConstants.ANIM_DURATION_NORMAL, 0.0)

	# Cascade fade in legacy tiles
	var delay = 0.1
	for tile in legacy_tiles:
		AnimationManager.fade_in(tile, GameConstants.ANIM_DURATION_NORMAL, delay)
		delay += 0.03


func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling."""
	# Backgrounds
	details_background.color = GameConstants.COLOR_BG_DARK

	# Title styling
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	details_title.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Currency label colors
	gems_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	reroll_tokens_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Button styling
	UIStyles.apply_button_styles(back_button)


func _populate_legacy_list() -> void:
	"""Create legacy tiles in rows of 2."""
	# Clear existing tiles
	UIHelpers.clear_children(legacy_list)
	legacy_tiles.clear()

	# Get all legacies (both unlocked and locked)
	var all_legacies = PlayerAccount.get_all_legacies()

	# Calculate tile size for 2 columns
	var tile_size = UIScaler.calculate_tile_size(size.x, 2, 32.0, 16.0, 180.0, 680.0)

	# Create rows of 2 tiles
	var current_row: HBoxContainer = null
	var tiles_in_row = 0

	for i in range(all_legacies.size()):
		# Create new row every 2 tiles
		if tiles_in_row == 0:
			current_row = HBoxContainer.new()
			current_row.alignment = BoxContainer.ALIGNMENT_CENTER
			current_row.add_theme_constant_override("separation", 16)
			legacy_list.add_child(current_row)

		var legacy: LegacyData = all_legacies[i]
		var tile = LegacyTileScene.instantiate()
		current_row.add_child(tile)
		tile.setup(legacy, tile_size)
		tile.tile_clicked.connect(_on_legacy_tile_clicked)

		# Dim locked legacies
		if not legacy.unlocked:
			tile.set_dimmed(true)

		legacy_tiles.append(tile)

		tiles_in_row += 1
		if tiles_in_row >= 2:
			tiles_in_row = 0


func _on_legacy_tile_clicked(legacy: LegacyData) -> void:
	"""Handle legacy tile selection - show details overlay."""
	_select_legacy(legacy)


func _select_legacy(legacy: LegacyData) -> void:
	"""Display details for selected legacy in full-screen overlay."""
	selected_legacy = legacy

	# Build the details panel content
	_build_legacy_details(legacy)

	# Show the details overlay
	legacy_details_panel.visible = true

	# Highlight selected tile
	_highlight_selected_tile()


func _build_legacy_details(legacy: LegacyData) -> void:
	"""Build the legacy details panel content."""
	UIHelpers.clear_children(details_content)

	# Legacy Name
	var name_label = Label.new()
	name_label.text = legacy.legacy_name
	name_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_HEADING)
	name_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_content.add_child(name_label)

	# Legacy Icon/Portrait
	var portrait_container = CenterContainer.new()
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(120, 120)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIHelpers.set_texture_safe(portrait, legacy.image_path)
	portrait_container.add_child(portrait)
	details_content.add_child(portrait_container)

	# Description
	var desc_label = Label.new()
	desc_label.text = legacy.description
	desc_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	desc_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_content.add_child(desc_label)

	# Spacer
	details_content.add_child(UIHelpers.create_spacer(8))

	# Unlock status / Income / Prestige section
	if legacy.unlocked:
		_build_unlocked_legacy_details(legacy)
	else:
		_build_locked_legacy_details(legacy)


func _build_unlocked_legacy_details(legacy: LegacyData) -> void:
	"""Build details for an unlocked legacy."""
	# Income display
	var income_label = Label.new()
	income_label.text = "Income: %d gold per round" % legacy.income
	income_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	income_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_content.add_child(income_label)

	# Prestige and Fame section
	var prestige_container = VBoxContainer.new()
	prestige_container.add_theme_constant_override("separation", 4)

	var prestige_label = Label.new()
	prestige_label.text = "Prestige Level: %d" % legacy.get_prestige()
	prestige_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	prestige_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	prestige_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prestige_container.add_child(prestige_label)

	# Fame progress bar
	var fame_container = HBoxContainer.new()
	fame_container.alignment = BoxContainer.ALIGNMENT_CENTER
	fame_container.add_theme_constant_override("separation", 8)

	var fame_label = Label.new()
	fame_label.text = "Fame:"
	fame_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
	fame_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
	fame_container.add_child(fame_label)

	var fame_progress = ProgressBar.new()
	fame_progress.custom_minimum_size = Vector2(200, 20)
	fame_progress.max_value = PrestigeTracker.FAME_PER_PRESTIGE
	fame_progress.value = legacy.get_fame()
	fame_progress.show_percentage = false
	UIStyles.apply_progress_bar_styles(fame_progress, GameConstants.COLOR_GOLD)
	fame_container.add_child(fame_progress)

	var fame_value_label = Label.new()
	fame_value_label.text = "%d/%d" % [legacy.get_fame(), PrestigeTracker.FAME_PER_PRESTIGE]
	fame_value_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
	fame_value_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
	fame_container.add_child(fame_value_label)

	prestige_container.add_child(fame_container)
	details_content.add_child(prestige_container)

	# Separator
	details_content.add_child(_create_separator())

	# Starting Character Selection
	_build_starting_character_section(legacy)

	# Starting Item Selection (if legacy has starting items)
	if legacy.has_starting_item():
		_build_starting_item_section(legacy)

	# Separator
	details_content.add_child(_create_separator())

	# Unlocked Content Preview
	_build_unlocked_content_preview(legacy)


func _build_locked_legacy_details(legacy: LegacyData) -> void:
	"""Build details for a locked legacy."""
	var locked_label = Label.new()
	locked_label.text = "LOCKED"
	locked_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_HEADING)
	locked_label.add_theme_color_override("font_color", GameConstants.COLOR_DISABLED)
	locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_content.add_child(locked_label)

	# Show income preview
	var income_label = Label.new()
	income_label.text = "Income: %d gold per round" % legacy.income
	income_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	income_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
	income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_content.add_child(income_label)

	details_content.add_child(UIHelpers.create_spacer(16))

	# Unlock button
	var unlock_cost = GameConstants.LEGACY_UNLOCK_COST
	var can_afford = PlayerAccount.get_gems() >= unlock_cost

	var unlock_button = Button.new()
	unlock_button.text = "UNLOCK - %s %d" % [GameConstants.EMOJI_GEM, unlock_cost]
	unlock_button.custom_minimum_size = Vector2(GameConstants.BUTTON_WIDTH_STANDARD, GameConstants.BUTTON_HEIGHT_STANDARD)

	if can_afford:
		UIStyles.setup_success_button(unlock_button, GameConstants.FONT_SIZE_BUTTON)
		unlock_button.pressed.connect(_on_unlock_pressed.bind(legacy))
	else:
		UIStyles.apply_button_styles(unlock_button)
		unlock_button.disabled = true

	var button_container = CenterContainer.new()
	button_container.add_child(unlock_button)
	details_content.add_child(button_container)


func _build_starting_character_section(legacy: LegacyData) -> void:
	"""Build the starting character selection section."""
	var section_label = Label.new()
	section_label.text = "Starting Character"
	section_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	section_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_content.add_child(section_label)

	var available_chars = legacy.get_available_starting_characters()
	if available_chars.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No characters unlocked yet"
		empty_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
		empty_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		details_content.add_child(empty_label)
		return

	var chars_container = HBoxContainer.new()
	chars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	chars_container.add_theme_constant_override("separation", 8)

	for char_id in available_chars:
		var char_data = GameData.get_character_by_id(char_id)
		var char_button = _create_selection_button(
			char_data.get("name", char_id),
			char_id == legacy.selected_starting_character_id,
			_on_starting_character_selected.bind(legacy, char_id)
		)
		chars_container.add_child(char_button)

	var center_chars = CenterContainer.new()
	center_chars.add_child(chars_container)
	details_content.add_child(center_chars)


func _build_starting_item_section(legacy: LegacyData) -> void:
	"""Build the starting item selection section."""
	var section_label = Label.new()
	section_label.text = "Starting Item"
	section_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	section_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_content.add_child(section_label)

	var available_items = legacy.get_available_starting_items()
	if available_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No starting items unlocked yet"
		empty_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
		empty_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		details_content.add_child(empty_label)
		return

	var items_container = HBoxContainer.new()
	items_container.alignment = BoxContainer.ALIGNMENT_CENTER
	items_container.add_theme_constant_override("separation", 8)

	for item_id in available_items:
		var item_data = GameData.get_item_by_id(item_id)
		var item_button = _create_selection_button(
			item_data.get("name", item_id),
			item_id == legacy.selected_starting_item_id,
			_on_starting_item_selected.bind(legacy, item_id)
		)
		items_container.add_child(item_button)

	var center_items = CenterContainer.new()
	center_items.add_child(items_container)
	details_content.add_child(center_items)


func _create_selection_button(text: String, is_selected: bool, callback: Callable) -> Button:
	"""Create a selection button with selected state styling."""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140, 40)

	if is_selected:
		UIStyles.setup_success_button(button, GameConstants.FONT_SIZE_SMALL)
	else:
		UIStyles.apply_button_styles(button)
		button.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	button.pressed.connect(callback)
	return button


func _build_unlocked_content_preview(legacy: LegacyData) -> void:
	"""Build the unlocked content preview section."""
	var section_label = Label.new()
	section_label.text = "Unlocked Content"
	section_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	section_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_content.add_child(section_label)

	var content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 4)

	# Characters
	if legacy.unlocked_characters.size() > 0:
		var char_names = _get_content_names(legacy.unlocked_characters, GameData.get_character_by_id)
		_add_content_row(content_container, "Characters", char_names)

	# Items
	if legacy.unlocked_items.size() > 0:
		var item_names = _get_content_names(legacy.unlocked_items, GameData.get_item_by_id)
		_add_content_row(content_container, "Items", item_names)

	# Skills
	if legacy.unlocked_skills.size() > 0:
		var skill_names = _get_content_names(legacy.unlocked_skills, GameData.get_skill_by_id)
		_add_content_row(content_container, "Skills", skill_names)

	# Encounters
	if legacy.unlocked_encounters.size() > 0:
		_add_content_row(content_container, "Encounters", ", ".join(legacy.unlocked_encounters))

	if content_container.get_child_count() == 0:
		var empty_label = Label.new()
		empty_label.text = "No content unlocked yet"
		empty_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
		empty_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_container.add_child(empty_label)

	details_content.add_child(content_container)


func _get_content_names(ids: Array, get_data_func: Callable) -> String:
	"""Get display names for a list of content IDs."""
	var names = []
	for id in ids:
		var data = get_data_func.call(id)
		if not data.is_empty():
			names.append(data.get("name", id))
		else:
			names.append(id)
	return ", ".join(names)


func _add_content_row(container: VBoxContainer, label_text: String, content: String) -> void:
	"""Add a content row with label and value."""
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label = Label.new()
	label.text = label_text + ":"
	label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
	label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	label.custom_minimum_size.x = 80
	row.add_child(label)

	var value = Label.new()
	value.text = content
	value.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
	value.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)

	container.add_child(row)


func _create_separator() -> HSeparator:
	"""Create a styled separator."""
	var sep = HSeparator.new()
	sep.custom_minimum_size.y = 2
	sep.add_theme_stylebox_override("separator", UIStyles.create_separator_style())
	return sep


func _on_starting_character_selected(legacy: LegacyData, char_id: String) -> void:
	"""Handle starting character selection."""
	if PlayerAccount.select_legacy_starting_character(legacy.id, char_id):
		# Refresh the details panel
		_build_legacy_details(legacy)
		# Update tile display
		_update_tile_for_legacy(legacy)


func _on_starting_item_selected(legacy: LegacyData, item_id: String) -> void:
	"""Handle starting item selection."""
	if PlayerAccount.select_legacy_starting_item(legacy.id, item_id):
		# Refresh the details panel
		_build_legacy_details(legacy)


func _on_unlock_pressed(legacy: LegacyData) -> void:
	"""Handle legacy unlock button press."""
	var cost = GameConstants.LEGACY_UNLOCK_COST
	if PlayerAccount.unlock_legacy(legacy.id, cost):
		# Refresh the details panel and list
		_build_legacy_details(legacy)
		_update_tile_for_legacy(legacy)


func _update_tile_for_legacy(legacy: LegacyData) -> void:
	"""Update the tile display for a specific legacy."""
	for tile in legacy_tiles:
		if tile.legacy_data and tile.legacy_data.id == legacy.id:
			tile.setup(legacy, tile.custom_minimum_size.x)
			tile.set_dimmed(not legacy.unlocked)
			break


func _on_close_details_pressed() -> void:
	"""Close the details overlay and return to grid view."""
	legacy_details_panel.visible = false
	selected_legacy = null
	_clear_tile_highlights()


func _highlight_selected_tile() -> void:
	"""Highlight the currently selected legacy tile."""
	for tile in legacy_tiles:
		if tile.legacy_data:
			var is_selected = selected_legacy and tile.legacy_data.id == selected_legacy.id
			tile.set_selected(is_selected)


func _clear_tile_highlights() -> void:
	"""Clear all tile highlights."""
	for tile in legacy_tiles:
		tile.set_selected(false)


func refresh_display() -> void:
	"""Refresh the entire collection display."""
	_populate_legacy_list()
	if selected_legacy:
		# Refresh selected legacy data
		selected_legacy = PlayerAccount.get_legacy_data(selected_legacy.id)
		if selected_legacy:
			_build_legacy_details(selected_legacy)


func _update_currency_display() -> void:
	gems_label.text = UIHelpers.format_currency(PlayerAccount.get_gems(), GameConstants.EMOJI_GEM)
	reroll_tokens_label.text = UIHelpers.format_currency(PlayerAccount.get_reroll_tokens(), GameConstants.EMOJI_REROLL)


func _on_gems_changed(new_amount: int) -> void:
	gems_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_GEM)
	# Refresh details if showing a locked legacy (unlock button availability may change)
	if selected_legacy and not selected_legacy.unlocked:
		_build_legacy_details(selected_legacy)


func _on_reroll_tokens_changed(new_amount: int) -> void:
	reroll_tokens_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_REROLL)


func _on_legacy_unlocked(_legacy_id: String) -> void:
	"""Handle legacy unlock signal."""
	refresh_display()


func _on_legacy_prestige_up(_legacy_id: String, _new_prestige: int, _unlocked_content: Dictionary) -> void:
	"""Handle legacy prestige up signal."""
	refresh_display()


func _on_back_pressed() -> void:
	"""Context-aware back: close details if open, else return to main menu."""
	if legacy_details_panel.visible:
		_on_close_details_pressed()
	else:
		var tween = AnimationManager.fade_out(back_button, GameConstants.ANIM_DURATION_NORMAL)
		tween.finished.connect(func(): SceneManager.go_to("main_menu", false))
