extends Panel
# CharacterDetails - Detailed character view with equipment management
# Refactored to use StatCalculator, UIHelpers, and GameConstants

@onready var portrait: TextureRect = $ScrollContainer/MarginContainer/VBoxContainer/TopBar/Portrait
@onready var name_label: Label = $ScrollContainer/MarginContainer/VBoxContainer/TopBar/InfoContainer/NameLabel
@onready var rank_label: Label = $ScrollContainer/MarginContainer/VBoxContainer/TopBar/InfoContainer/RankLabel
@onready var rank_progress_bar: ProgressBar = $ScrollContainer/MarginContainer/VBoxContainer/TopBar/InfoContainer/RankProgressBar

@onready var health_value: Label = $ScrollContainer/MarginContainer/VBoxContainer/StatsGrid/HealthValue
@onready var attack_value: Label = $ScrollContainer/MarginContainer/VBoxContainer/StatsGrid/AttackValue
@onready var defense_value: Label = $ScrollContainer/MarginContainer/VBoxContainer/StatsGrid/DefenseValue
@onready var speed_value: Label = $ScrollContainer/MarginContainer/VBoxContainer/StatsGrid/SpeedValue
@onready var income_value: Label = $ScrollContainer/MarginContainer/VBoxContainer/StatsGrid/IncomeValue

@onready var equipped_items_container: HBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer/EquippedItemsContainer
@onready var item_list: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer/ItemListContainer/ItemList
@onready var skills_container: GridContainer = $ScrollContainer/MarginContainer/VBoxContainer/SkillsContainer

var current_character_data: Dictionary = {}

# Preload components
const ItemSlotScene = preload("res://scenes/components/item_slot.tscn")
const SkillIconScene = preload("res://scenes/components/skill_icon.tscn")


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

	# Set name and rank
	name_label.text = char_master.get("name", "Unknown")
	rank_label.text = "Rank %d" % char_data.get("rank", 1)

	# Set rank progress
	rank_progress_bar.max_value = GameConstants.XP_PER_RANK
	rank_progress_bar.value = char_data.get("experience", 0)

	# Calculate and display stats using StatCalculator
	_update_stats_display(char_master, char_data)

	# Display equipped items
	_display_equipped_items(char_data)

	# Display unlocked items (for equipping)
	_display_unlocked_items(char_data)

	# Display unlocked skills
	_display_unlocked_skills(char_data)


func _update_stats_display(char_master: Dictionary, char_data: Dictionary) -> void:
	"""Calculate stats with equipped items and display them."""
	# Use StatCalculator - single source of truth
	var stats = StatCalculator.calculate_character_stats(char_master, char_data, true)

	# Display stats
	health_value.text = str(stats.get(GameConstants.STAT_HEALTH, 0))
	attack_value.text = str(stats.get(GameConstants.STAT_ATTACK, 0))
	defense_value.text = str(stats.get(GameConstants.STAT_DEFENSE, 0))
	speed_value.text = str(stats.get(GameConstants.STAT_SPEED, 0))
	income_value.text = str(stats.get(GameConstants.STAT_INCOME, 0))


func _display_equipped_items(char_data: Dictionary) -> void:
	"""Display all currently equipped items."""
	# Clear existing slots using UIHelpers
	UIHelpers.clear_children(equipped_items_container)

	var equipped = char_data.get("equipped_items", [])

	# Add slot for each equipped item
	for item_id in equipped:
		var item_slot = ItemSlotScene.instantiate()
		equipped_items_container.add_child(item_slot)
		item_slot.setup(item_id)
		item_slot.slot_clicked.connect(_on_equipped_item_clicked)

	# If no items equipped, show placeholder text
	if equipped.size() == 0:
		var placeholder = UIHelpers.create_empty_placeholder("No items equipped")
		equipped_items_container.add_child(placeholder)


func _display_unlocked_items(char_data: Dictionary) -> void:
	"""Display all unlocked items with equip buttons."""
	# Clear existing items using UIHelpers
	UIHelpers.clear_children(item_list)

	var unlocked = char_data.get("unlocked_items", [])
	var equipped = char_data.get("equipped_items", [])

	# Add each unlocked item
	for item_id in unlocked:
		var item_data = GameData.get_item_by_id(item_id)
		if item_data.is_empty():
			continue

		var item_row = HBoxContainer.new()
		item_list.add_child(item_row)

		# Item icon (using mobile-friendly size)
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(GameConstants.SKILL_ICON_IMAGE_SIZE, GameConstants.SKILL_ICON_IMAGE_SIZE)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		UIHelpers.set_texture_safe(icon, item_data.get("image_path", ""))
		item_row.add_child(icon)

		# Item name
		var item_name_label = Label.new()
		item_name_label.text = item_data.get("name", "Unknown")
		item_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_row.add_child(item_name_label)

		# Equip/Unequip button
		var button = Button.new()
		var is_equipped = item_id in equipped
		button.text = "Unequip" if is_equipped else "Equip"
		button.pressed.connect(_on_item_button_pressed.bind(item_id, is_equipped))
		item_row.add_child(button)


func _display_unlocked_skills(char_data: Dictionary) -> void:
	"""Display all unlocked skills."""
	# Clear existing skills using UIHelpers
	UIHelpers.clear_children(skills_container)

	var unlocked = char_data.get("unlocked_skills", [])

	# Add each unlocked skill
	for skill_id in unlocked:
		var skill_icon = SkillIconScene.instantiate()
		skills_container.add_child(skill_icon)
		skill_icon.setup(skill_id)

	# If no skills unlocked, show placeholder text
	if unlocked.size() == 0:
		var placeholder = UIHelpers.create_empty_placeholder("No skills unlocked")
		skills_container.add_child(placeholder)


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
