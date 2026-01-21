extends Panel
# CharacterDetails - Detailed character view with equipment management
# Refactored to use StatCalculator, UIHelpers, and GameConstants
# Updated for no-scroll layout with height constraints

@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/TopBar/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/TopBar/InfoContainer/NameLabel
@onready var prestige_label: Label = $MarginContainer/VBoxContainer/TopBar/InfoContainer/RankLabel
@onready var prestige_progress_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/InfoContainer/RankProgressBar

@onready var health_value: Label = $MarginContainer/VBoxContainer/StatsSection/StatsGrid/HealthValue
@onready var attack_value: Label = $MarginContainer/VBoxContainer/StatsSection/StatsGrid/AttackValue
@onready var defense_value: Label = $MarginContainer/VBoxContainer/StatsSection/StatsGrid/DefenseValue
@onready var speed_value: Label = $MarginContainer/VBoxContainer/StatsSection/StatsGrid/SpeedValue
@onready var income_value: Label = $MarginContainer/VBoxContainer/StatsSection/StatsGrid/IncomeValue

@onready var equipped_items_container: HBoxContainer = $MarginContainer/VBoxContainer/EquipmentSection/EquippedItemsContainer
@onready var items_grid: GridContainer = $MarginContainer/VBoxContainer/ItemsSection/ItemsGrid
@onready var skills_grid: GridContainer = $MarginContainer/VBoxContainer/SkillsSection/SkillsGrid

@onready var back_button: Button = $BackButton

var current_character_data: Dictionary = {}

# Preload components
const ItemSlotScene = preload("res://scenes/components/item_slot.tscn")
const SkillIconScene = preload("res://scenes/components/skill_icon.tscn")


func _ready() -> void:
	_apply_visual_styling()
	back_button.pressed.connect(_on_back_pressed)


func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling to the panel."""
	# Background color
	var style = StyleBoxFlat.new()
	style.bg_color = GameConstants.COLOR_BG_DARK
	add_theme_stylebox_override("panel", style)

	# Style the progress bar
	UIStyles.apply_progress_bar_styles(prestige_progress_bar, GameConstants.COLOR_GOLD)

	# Style the back button
	UIStyles.apply_button_styles(back_button)

	# Apply text colors
	name_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	prestige_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)


func display_character(char_data: Dictionary) -> void:
	"""Display detailed information for a character."""
	current_character_data = char_data

	# Get master data
	var char_master = GameData.get_character_by_id(char_data.get("id", ""))
	if char_master.is_empty():
		push_error("CharacterDetails: Character master data not found")
		return

	# Set portrait using UIHelpers
	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))

	# Set name and prestige
	name_label.text = char_master.get("name", "Unknown")
	prestige_label.text = "Prestige %d" % char_data.get("prestige", 1)

	# Set prestige progress (fame)
	prestige_progress_bar.max_value = GameConstants.FAME_PER_PRESTIGE
	prestige_progress_bar.value = char_data.get("fame", 0)

	# Calculate and display stats using StatCalculator
	_update_stats_display(char_master, char_data)

	# Display equipped items (compact mode)
	_display_equipped_items(char_data)

	# Display unlocked items in grid (compact mode)
	_display_unlocked_items(char_data)

	# Display unlocked skills (compact mode)
	_display_unlocked_skills(char_data)


func _update_stats_display(char_master: Dictionary, char_data: Dictionary) -> void:
	"""Calculate stats with equipped items and display them."""
	# Use StatCalculator - single source of truth
	var stats = StatCalculator.calculate_character_stats(char_master, char_data, true)

	# Display stats with gold highlight color
	health_value.text = str(stats.get(GameConstants.STAT_HEALTH, 0))
	attack_value.text = str(stats.get(GameConstants.STAT_ATTACK, 0))
	defense_value.text = str(stats.get(GameConstants.STAT_DEFENSE, 0))
	speed_value.text = str(stats.get(GameConstants.STAT_SPEED, 0))
	income_value.text = str(stats.get(GameConstants.STAT_INCOME, 0))

	# Apply gold color to stat values
	for label in [health_value, attack_value, defense_value, speed_value, income_value]:
		label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)


func _display_equipped_items(char_data: Dictionary) -> void:
	"""Display all currently equipped items in compact mode."""
	# Clear existing slots using UIHelpers
	UIHelpers.clear_children(equipped_items_container)

	var equipped = char_data.get("equipped_items", [])

	# Add slot for each equipped item (compact mode)
	for item_id in equipped:
		var item_slot = ItemSlotScene.instantiate()
		equipped_items_container.add_child(item_slot)
		item_slot.setup(item_id)
		item_slot.set_compact(true)
		item_slot.slot_clicked.connect(_on_equipped_item_clicked)

	# If no items equipped, show placeholder text
	if equipped.size() == 0:
		var placeholder = UIHelpers.create_empty_placeholder("No items equipped")
		placeholder.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
		equipped_items_container.add_child(placeholder)


func _display_unlocked_items(char_data: Dictionary) -> void:
	"""Display all unlocked items in a 4-column grid with compact item slots."""
	# Clear existing items using UIHelpers
	UIHelpers.clear_children(items_grid)

	var unlocked = char_data.get("unlocked_items", [])
	var equipped = char_data.get("equipped_items", [])

	# Add each unlocked item as a compact slot with equip indicator
	for item_id in unlocked:
		var item_data = GameData.get_item_by_id(item_id)
		if item_data.is_empty():
			continue

		var item_container = VBoxContainer.new()
		item_container.add_theme_constant_override("separation", 2)
		items_grid.add_child(item_container)

		# Item slot (compact)
		var item_slot = ItemSlotScene.instantiate()
		item_container.add_child(item_slot)
		item_slot.setup(item_id)
		item_slot.set_compact(true)

		# Small equip/unequip button
		var button = Button.new()
		var is_equipped = item_id in equipped
		button.text = "−" if is_equipped else "+"
		button.custom_minimum_size = Vector2(0, 24)
		button.add_theme_font_size_override("font_size", 12)
		UIStyles.apply_button_styles(button)
		button.pressed.connect(_on_item_button_pressed.bind(item_id, is_equipped))
		item_container.add_child(button)

		# Highlight if equipped
		if is_equipped:
			item_slot.highlight(true)

	# If no items unlocked, show placeholder
	if unlocked.size() == 0:
		var placeholder = UIHelpers.create_empty_placeholder("No items unlocked")
		placeholder.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
		items_grid.add_child(placeholder)


func _display_unlocked_skills(char_data: Dictionary) -> void:
	"""Display all unlocked skills in a 5-column grid."""
	# Clear existing skills using UIHelpers
	UIHelpers.clear_children(skills_grid)

	var unlocked = char_data.get("unlocked_skills", [])

	# Add each unlocked skill (compact mode)
	for skill_id in unlocked:
		var skill_icon = SkillIconScene.instantiate()
		skills_grid.add_child(skill_icon)
		skill_icon.setup(skill_id)
		skill_icon.set_compact(true)

	# If no skills unlocked, show placeholder text
	if unlocked.size() == 0:
		var placeholder = UIHelpers.create_empty_placeholder("No skills unlocked")
		placeholder.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
		skills_grid.add_child(placeholder)


func _on_equipped_item_clicked(item_id: String) -> void:
	"""Handle clicking on an equipped item slot."""
	if item_id.is_empty():
		return
	_unequip_item(item_id)


func _on_item_button_pressed(item_id: String, is_equipped: bool) -> void:
	"""Handle equip/unequip button press."""
	if is_equipped:
		_unequip_item(item_id)
	else:
		_equip_item(item_id)


func _equip_item(item_id: String) -> void:
	"""Equip an item."""
	var char_id = current_character_data.get("id", "")
	var success = PlayerAccount.equip_item(char_id, item_id)
	if success:
		print("CharacterDetails: Equipped %s" % item_id)
		_refresh_display()


func _unequip_item(item_id: String) -> void:
	"""Unequip an item."""
	var char_id = current_character_data.get("id", "")
	var success = PlayerAccount.unequip_item(char_id, item_id)
	if success:
		print("CharacterDetails: Unequipped %s" % item_id)
		_refresh_display()


func _refresh_display() -> void:
	"""Refresh the display with updated character data."""
	var char_id = current_character_data.get("id", "")
	var updated_data = PlayerAccount.get_character_data(char_id)
	display_character(updated_data)


func _on_back_pressed() -> void:
	"""Return to collection screen."""
	SceneManager.go_to_collection()
