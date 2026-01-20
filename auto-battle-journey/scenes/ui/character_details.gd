extends Panel
# CharacterDetails - Detailed character view with equipment management

@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/TopBar/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/TopBar/InfoContainer/NameLabel
@onready var rank_label: Label = $MarginContainer/VBoxContainer/TopBar/InfoContainer/RankLabel
@onready var rank_progress_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/InfoContainer/RankProgressBar

@onready var health_value: Label = $MarginContainer/VBoxContainer/StatsGrid/HealthValue
@onready var attack_value: Label = $MarginContainer/VBoxContainer/StatsGrid/AttackValue
@onready var defense_value: Label = $MarginContainer/VBoxContainer/StatsGrid/DefenseValue
@onready var speed_value: Label = $MarginContainer/VBoxContainer/StatsGrid/SpeedValue
@onready var income_value: Label = $MarginContainer/VBoxContainer/StatsGrid/IncomeValue

@onready var equipped_items_container: HBoxContainer = $MarginContainer/VBoxContainer/EquippedItemsContainer
@onready var item_list: VBoxContainer = $MarginContainer/VBoxContainer/ItemListContainer/ItemList
@onready var skills_container: GridContainer = $MarginContainer/VBoxContainer/SkillsContainer

var current_character_data: Dictionary = {}

# Preload components
const ItemSlotScene = preload("res://scenes/components/item_slot.tscn")
const SkillIconScene = preload("res://scenes/components/skill_icon.tscn")


func display_character(char_data: Dictionary) -> void:
	"""Display detailed information for a character"""
	current_character_data = char_data

	# Get master data
	var char_master = GameData.get_character_by_id(char_data["id"])
	if char_master.is_empty():
		push_error("CharacterDetails: Character master data not found")
		return

	# Set portrait
	var portrait_path = char_master["image_path"]
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)

	# Set name and rank
	name_label.text = char_master["name"]
	rank_label.text = "Rank %d" % char_data["rank"]

	# Set rank progress (100 XP per rank)
	var xp_per_rank = 100
	rank_progress_bar.max_value = xp_per_rank
	rank_progress_bar.value = char_data["experience"]

	# Calculate and display stats
	_update_stats_display(char_master, char_data)

	# Display equipped items
	_display_equipped_items(char_data)

	# Display unlocked items (for equipping)
	_display_unlocked_items(char_data)

	# Display unlocked skills
	_display_unlocked_skills(char_data)


func _update_stats_display(char_master: Dictionary, char_data: Dictionary) -> void:
	"""Calculate stats with equipped items and display them"""
	var stats = {
		"health": char_master["base_stats"]["health"],
		"basic_attack_damage": char_master["base_stats"]["basic_attack_damage"],
		"defense": char_master["base_stats"]["defense"],
		"speed": char_master["base_stats"]["speed"],
		"income": char_master["base_stats"]["income"]
	}

	# Apply rank stat boosts
	if char_master.has("rank_rewards"):
		for rank_reward in char_master["rank_rewards"]:
			if rank_reward["rank"] <= char_data["rank"]:
				if rank_reward.has("stat_boost"):
					for stat_name in rank_reward["stat_boost"]:
						stats[stat_name] += rank_reward["stat_boost"][stat_name]

	# Apply equipped items
	if char_data.has("equipped_items"):
		for item_id in char_data["equipped_items"]:
			var item_data = GameData.get_item_by_id(item_id)
			if item_data.has("stat_modifiers"):
				for stat_name in item_data["stat_modifiers"]:
					stats[stat_name] += item_data["stat_modifiers"][stat_name]

	# Display stats
	health_value.text = str(stats["health"])
	attack_value.text = str(stats["basic_attack_damage"])
	defense_value.text = str(stats["defense"])
	speed_value.text = str(stats["speed"])
	income_value.text = str(stats["income"])


func _display_equipped_items(char_data: Dictionary) -> void:
	"""Display all currently equipped items"""
	# Clear existing slots
	for child in equipped_items_container.get_children():
		child.queue_free()

	# Add slot for each equipped item
	for item_id in char_data["equipped_items"]:
		var item_slot = ItemSlotScene.instantiate()
		equipped_items_container.add_child(item_slot)
		item_slot.setup(item_id)
		item_slot.slot_clicked.connect(_on_equipped_item_clicked)

	# If no items equipped, show placeholder text
	if char_data["equipped_items"].size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No items equipped"
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		equipped_items_container.add_child(empty_label)


func _display_unlocked_items(char_data: Dictionary) -> void:
	"""Display all unlocked items with equip buttons"""
	# Clear existing items
	for child in item_list.get_children():
		child.queue_free()

	# Add each unlocked item
	for item_id in char_data["unlocked_items"]:
		var item_data = GameData.get_item_by_id(item_id)
		if item_data.is_empty():
			continue

		var item_row = HBoxContainer.new()
		item_list.add_child(item_row)

		# Item icon
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(item_data["image_path"]):
			icon.texture = load(item_data["image_path"])
		item_row.add_child(icon)

		# Item name
		var item_name_label = Label.new()
		item_name_label.text = item_data["name"]
		item_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_row.add_child(item_name_label)

		# Equip/Unequip button
		var button = Button.new()
		var is_equipped = item_id in char_data["equipped_items"]
		button.text = "Unequip" if is_equipped else "Equip"
		button.pressed.connect(_on_item_button_pressed.bind(item_id, is_equipped))
		item_row.add_child(button)


func _display_unlocked_skills(char_data: Dictionary) -> void:
	"""Display all unlocked skills"""
	# Clear existing skills
	for child in skills_container.get_children():
		child.queue_free()

	# Add each unlocked skill
	for skill_id in char_data["unlocked_skills"]:
		var skill_icon = SkillIconScene.instantiate()
		skills_container.add_child(skill_icon)
		skill_icon.setup(skill_id)

	# If no skills unlocked, show placeholder text
	if char_data["unlocked_skills"].size() == 0:
		var empty_label = Label.new()
		empty_label.text = "No skills unlocked"
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		skills_container.add_child(empty_label)


func _on_equipped_item_clicked(item_id: String) -> void:
	"""Handle clicking on an equipped item slot"""
	if item_id.is_empty():
		return
	# Unequip the item
	_unequip_item(item_id)


func _on_item_button_pressed(item_id: String, is_equipped: bool) -> void:
	"""Handle equip/unequip button press"""
	if is_equipped:
		_unequip_item(item_id)
	else:
		_equip_item(item_id)


func _equip_item(item_id: String) -> void:
	"""Equip an item"""
	var success = PlayerAccount.equip_item(current_character_data["id"], item_id)
	if success:
		print("CharacterDetails: Equipped %s" % item_id)
		# Refresh display
		var updated_data = PlayerAccount.get_character_data(current_character_data["id"])
		display_character(updated_data)


func _unequip_item(item_id: String) -> void:
	"""Unequip an item"""
	var success = PlayerAccount.unequip_item(current_character_data["id"], item_id)
	if success:
		print("CharacterDetails: Unequipped %s" % item_id)
		# Refresh display
		var updated_data = PlayerAccount.get_character_data(current_character_data["id"])
		display_character(updated_data)
