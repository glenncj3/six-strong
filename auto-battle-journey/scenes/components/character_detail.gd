extends PanelContainer
# CharacterDetail - Detailed view of a single character
# Shows portrait, stats, equipped items, and learned skills
# Used in TeamDisplay focus mode

signal back_pressed
signal item_clicked(item_id: String)
signal skill_clicked(skill_id: String)

const ItemSlotScene = preload("res://scenes/components/item_slot.tscn")
const SkillIconScene = preload("res://scenes/components/skill_icon.tscn")

@onready var main_container: VBoxContainer = $MarginContainer/MainContainer
@onready var top_section: HBoxContainer = $MarginContainer/MainContainer/TopSection
@onready var bottom_section: HBoxContainer = $MarginContainer/MainContainer/BottomSection

# Top left - portrait
@onready var portrait: TextureRect = $MarginContainer/MainContainer/TopSection/Portrait

# Top middle - name, stats
@onready var info_container: VBoxContainer = $MarginContainer/MainContainer/TopSection/InfoContainer
@onready var name_label: Label = $MarginContainer/MainContainer/TopSection/InfoContainer/NameLabel
@onready var stats_container: VBoxContainer = $MarginContainer/MainContainer/TopSection/InfoContainer/StatsContainer

# Top right - back button
@onready var back_button: Button = $MarginContainer/MainContainer/TopSection/BackButton

# Bottom left - items grid
@onready var items_container: GridContainer = $MarginContainer/MainContainer/BottomSection/ItemsContainer

# Bottom right - skills grid
@onready var skills_container: GridContainer = $MarginContainer/MainContainer/BottomSection/SkillsContainer

var char_instance: CharacterInstance = null


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	UIStyles.apply_panel_style(self, UIStyles.create_dark_panel())
	UIStyles.apply_button_styles(back_button)

	# Apply larger sizing for detail view
	_apply_sizing()


func _apply_sizing() -> void:
	"""Apply appropriate sizing for elements to fill space."""
	# Back button
	back_button.custom_minimum_size = Vector2(40, 40)
	back_button.add_theme_font_size_override("font_size", 18)

	# Portrait - match the width of the 3-column item grid
	var slot_width = UIScaler.get_item_slot_size(false).x
	var grid_spacing = 8
	var portrait_size = slot_width * 3 + grid_spacing * 2
	portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)

	# Add top spacer to align name with top of portrait art
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	info_container.add_child(spacer)
	info_container.move_child(spacer, 0)

	# Name label - larger font
	name_label.add_theme_font_size_override("font_size", 32)

	# Items grid spacing
	items_container.add_theme_constant_override("h_separation", 8)
	items_container.add_theme_constant_override("v_separation", 8)

	# Skills grid spacing
	skills_container.add_theme_constant_override("h_separation", 8)
	skills_container.add_theme_constant_override("v_separation", 8)


func setup(character_instance: CharacterInstance) -> void:
	"""
	Configure the detail view with a character instance.

	Args:
		character_instance: The CharacterInstance to display
	"""
	char_instance = character_instance

	# Get master data
	var char_master = GameData.get_character_by_id(char_instance.base_character_id)
	if char_master.is_empty():
		push_error("CharacterDetail: Master data not found: %s" % char_instance.base_character_id)
		return

	# Set portrait
	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))

	# Set name with level
	name_label.text = "%s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
	name_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)

	# Populate stats
	_populate_stats()

	# Populate items grid (3x3)
	_populate_items()

	# Populate skills grid
	_populate_skills()


func _populate_stats() -> void:
	"""Populate the stats display."""
	UIHelpers.clear_children(stats_container)

	var stat_entries = [
		{"name": GameConstants.STAT_HEALTH, "format": "HP %d/%d", "args": [char_instance.current_health, char_instance.max_health]},
		{"name": GameConstants.STAT_MANA, "value": char_instance.stats.get(GameConstants.STAT_MANA, 0)},
		{"name": GameConstants.STAT_INCOME, "value": char_instance.stats.get(GameConstants.STAT_INCOME, 0)},
		{"name": GameConstants.STAT_DEFEND_RATE, "format": "DEF%% %d%%", "args": [char_instance.stats.get(GameConstants.STAT_DEFEND_RATE, 0)]},
	]

	for entry in stat_entries:
		var label = Label.new()
		if entry.has("format"):
			label.text = entry["format"] % entry["args"]
		else:
			label.text = UIHelpers.format_stat(entry["name"], entry["value"])
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stats_container.add_child(label)


func _populate_items() -> void:
	"""Populate the 3x3 items grid."""
	UIHelpers.clear_children(items_container)

	# Combine equipped items and upgrades for display
	var all_item_ids: Array[String] = []
	all_item_ids.append_array(char_instance.equipped_items)
	all_item_ids.append_array(char_instance.equipped_item_upgrades)

	# Create 9 slots (3x3 grid) - use normal size for better visibility
	for i in range(9):
		var slot = ItemSlotScene.instantiate()
		items_container.add_child(slot)

		var item_id = all_item_ids[i] if i < all_item_ids.size() else ""
		var item_data = {}
		if not item_id.is_empty():
			item_data = GameData.get_item_by_id(item_id)
			if item_data.is_empty():
				item_data = GameData.get_item_upgrade_by_id(item_id)

		slot.setup(item_data)
		slot.set_compact(false)  # Use full size for detail view
		slot._label.visible = false  # Icons only, no text
		var slot_width = slot.custom_minimum_size.x
		slot.custom_minimum_size = Vector2(slot_width, slot_width)  # Square slots
		slot.set_clickable(not item_data.is_empty())

		if not item_data.is_empty():
			slot.slot_clicked.connect(_on_item_slot_clicked)


func _populate_skills() -> void:
	"""Populate the skills grid."""
	UIHelpers.clear_children(skills_container)

	# Show learned skills - use normal size for detail view
	for skill_id in char_instance.learned_skills:
		var skill_data = GameData.get_skill_by_id(skill_id)
		if skill_data.is_empty():
			continue

		var skill_icon = SkillIconScene.instantiate()
		skills_container.add_child(skill_icon)
		skill_icon.setup(skill_data)
		skill_icon.set_compact(false)  # Use full size for detail view

		# Make clickable
		skill_icon.gui_input.connect(_on_skill_gui_input.bind(skill_id))
		skill_icon.mouse_filter = Control.MOUSE_FILTER_STOP

	# If no skills, show placeholder
	if char_instance.learned_skills.is_empty():
		var placeholder = Label.new()
		placeholder.text = "No skills learned"
		placeholder.add_theme_font_size_override("font_size", 24)
		placeholder.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
		placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		skills_container.add_child(placeholder)


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_item_slot_clicked(item_id: String) -> void:
	if not item_id.is_empty():
		item_clicked.emit(item_id)


func _on_skill_gui_input(event: InputEvent, skill_id: String) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			skill_clicked.emit(skill_id)
