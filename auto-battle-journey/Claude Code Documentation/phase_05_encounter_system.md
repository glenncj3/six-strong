# Phase 5: Encounter System

**Goal**: Modular encounter framework with working encounters  
**Duration**: Days 10-13  
**Deliverable**: Can complete encounters, receive rewards, run progresses

---

## Overview

Phase 5 implements the encounter system where players:
- Choose from 3 encounter options
- Interact with different encounter types (shops, XP rewards, minigames)
- Receive rewards (XP, gold, items, skills, health)
- See changes reflected in team state
- Progress through the run

This phase replaces the encounter simulation with real, playable encounters using a modular, extensible system.

---

## Prerequisites

- Phase 4 complete and tested
- All Phase 4 tests passing
- Git commit created for Phase 4
- Godot project closed (to avoid file conflicts)

---

## Implementation Tasks

### Task 1: Create EncounterFactory Singleton

Create the singleton that generates encounter instances.

#### File: `autoloads/encounter_factory.gd`

```gdscript
extends Node
# EncounterFactory Singleton
# Generates random encounter options with difficulty scaling

signal encounter_generated(encounter_type: String)

# Weight system for encounter types
var encounter_weights: Dictionary = {
	"shop": 1.0,
	"xp_reward": 1.0,
	"gold_reward": 0.8,
	"health_restore": 0.6
}


func _ready() -> void:
	pass


func generate_encounter_options(count: int) -> Array:
	"""
	Generate random encounter options
	
	Args:
		count: Number of options to generate (usually 3)
	
	Returns:
		Array of encounter option dictionaries
	"""
	var options = []
	var used_types = []  # Prevent duplicate types in same set
	
	for i in range(count):
		var encounter_type = _select_weighted_encounter_type(used_types)
		used_types.append(encounter_type)
		
		var encounter_data = _create_encounter_data(encounter_type)
		options.append(encounter_data)
	
	print("EncounterFactory: Generated %d encounter options" % options.size())
	return options


func _select_weighted_encounter_type(excluded_types: Array) -> String:
	"""Select a random encounter type using weights"""
	var available_types = []
	var available_weights = []
	
	for encounter_type in encounter_weights.keys():
		if encounter_type not in excluded_types:
			available_types.append(encounter_type)
			available_weights.append(encounter_weights[encounter_type])
	
	if available_types.is_empty():
		# Fallback: Allow duplicates if we've exhausted unique options
		available_types = encounter_weights.keys()
		for t in available_types:
			available_weights.append(encounter_weights[t])
	
	# Weighted random selection
	var total_weight = 0.0
	for w in available_weights:
		total_weight += w
	
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for i in range(available_types.size()):
		cumulative_weight += available_weights[i]
		if random_value <= cumulative_weight:
			return available_types[i]
	
	# Fallback
	return available_types[0]


func _create_encounter_data(encounter_type: String) -> Dictionary:
	"""Create encounter data based on type"""
	var encounter_data = {
		"type": encounter_type,
		"name": "",
		"description": "",
		"image_path": "",
		"data": {}  # Type-specific data
	}
	
	match encounter_type:
		"shop":
			encounter_data["name"] = "Traveling Merchant"
			encounter_data["description"] = "A merchant offers their wares."
			encounter_data["image_path"] = "res://assets/encounters/merchant.png"
			encounter_data["data"] = _generate_shop_inventory()
		
		"xp_reward":
			encounter_data["name"] = "Training Dummy"
			encounter_data["description"] = "Practice your skills and gain experience."
			encounter_data["image_path"] = "res://assets/encounters/training.png"
			encounter_data["data"] = {
				"xp_amount": randi_range(30, 80)
			}
		
		"gold_reward":
			encounter_data["name"] = "Treasure Chest"
			encounter_data["description"] = "You found a chest full of gold!"
			encounter_data["image_path"] = "res://assets/encounters/chest.png"
			encounter_data["data"] = {
				"gold_amount": randi_range(20, 50)
			}
		
		"health_restore":
			encounter_data["name"] = "Healing Fountain"
			encounter_data["description"] = "Restore your team's health."
			encounter_data["image_path"] = "res://assets/encounters/fountain.png"
			encounter_data["data"] = {
				"heal_percentage": 0.5  # Heal 50% of max health
			}
	
	return encounter_data


func _generate_shop_inventory() -> Dictionary:
	"""Generate random shop inventory"""
	var inventory = {
		"items": [],
		"skills": []
	}
	
	# Add 2-4 random items for sale
	var all_items = GameData.get_all_items()
	var all_item_upgrades = GameData.get_all_item_upgrades()
	var combined_items = all_items + all_item_upgrades
	
	combined_items.shuffle()
	var item_count = randi_range(2, 4)
	for i in range(min(item_count, combined_items.size())):
		inventory["items"].append({
			"id": combined_items[i]["id"],
			"cost": randi_range(10, 30),
			"is_upgrade": combined_items[i] in all_item_upgrades
		})
	
	# Add 1-2 random skills for sale
	var all_skills = GameData.get_all_skills()
	all_skills.shuffle()
	var skill_count = randi_range(1, 2)
	for i in range(min(skill_count, all_skills.size())):
		inventory["skills"].append({
			"id": all_skills[i]["id"],
			"cost": randi_range(15, 40)
		})
	
	return inventory


func apply_scaling(encounter_data: Dictionary, round: int) -> void:
	"""Apply difficulty/reward scaling based on round number"""
	# TODO: Scale rewards based on how far into the run the player is
	# For example: XP rewards increase, shop prices adjust, etc.
	pass
```

**Claude Code Directive**:
```
Create the EncounterFactory singleton. This generates random encounter options
with different types. Make sure:
- Weighted random selection prevents too many of the same type
- Each encounter type has appropriate data
- Shop inventory is randomized
- Gold/XP amounts have reasonable ranges

Add this to Project Settings -> Autoload after creation.
```

---

### Task 2: Create Encounter Selection Scene

Create the UI where players choose which encounter to take.

#### File: `scenes/ui/encounter_select.tscn`

Create a scene with this structure:
```
EncounterSelect (Control)
├── Background (ColorRect)
├── MainContainer (VBoxContainer)
│   ├── Title (Label) - "CHOOSE AN ENCOUNTER"
│   ├── Subtitle (Label) - "Select one to proceed"
│   └── OptionsContainer (HBoxContainer)
│       └── (EncounterOption panels x3 added dynamically)
└── BackButton (Button) - "Return to Run" (only shows if testing)
```

#### File: `scenes/ui/encounter_select.gd`

```gdscript
extends Control
# EncounterSelect - Choose from 3 encounter options

@onready var options_container = $MainContainer/OptionsContainer
@onready var back_button = $BackButton

var encounter_options: Array = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = false  # Only for testing
	
	_generate_and_display_options()


func _generate_and_display_options() -> void:
	"""Generate 3 encounter options and display them"""
	# Clear existing
	for child in options_container.get_children():
		child.queue_free()
	
	# Generate options
	encounter_options = EncounterFactory.generate_encounter_options(3)
	
	# Create UI for each option
	for i in range(encounter_options.size()):
		_create_option_panel(encounter_options[i], i)


func _create_option_panel(encounter_data: Dictionary, index: int) -> void:
	"""Create a selectable encounter option panel"""
	var panel = PanelContainer.new()
	options_container.add_child(panel)
	panel.custom_minimum_size = Vector2(200, 300)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var margin = MarginContainer.new()
	vbox.add_child(margin)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	var content = VBoxContainer.new()
	margin.add_child(content)
	
	# Image
	var image = TextureRect.new()
	content.add_child(image)
	image.custom_minimum_size = Vector2(180, 180)
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(encounter_data["image_path"]):
		image.texture = load(encounter_data["image_path"])
	
	# Name
	var name_label = Label.new()
	content.add_child(name_label)
	name_label.text = encounter_data["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	
	# Type
	var type_label = Label.new()
	content.add_child(type_label)
	type_label.text = "[%s]" % encounter_data["type"].to_upper()
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.modulate = Color(0.7, 0.7, 0.7)
	
	# Description
	var desc_label = Label.new()
	content.add_child(desc_label)
	desc_label.text = encounter_data["description"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.y = 40
	
	# Preview rewards (type-specific)
	var preview_label = Label.new()
	content.add_child(preview_label)
	preview_label.text = _get_reward_preview(encounter_data)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.modulate = Color(0.3, 1.0, 0.3)
	
	# Spacer
	var spacer = Control.new()
	content.add_child(spacer)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Select button
	var button = Button.new()
	content.add_child(button)
	button.text = "SELECT"
	button.pressed.connect(_on_encounter_selected.bind(encounter_data))


func _get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get a preview of rewards for this encounter"""
	match encounter_data["type"]:
		"shop":
			var item_count = encounter_data["data"]["items"].size()
			var skill_count = encounter_data["data"]["skills"].size()
			return "%d items, %d skills" % [item_count, skill_count]
		"xp_reward":
			return "+%d XP" % encounter_data["data"]["xp_amount"]
		"gold_reward":
			return "+%d Gold" % encounter_data["data"]["gold_amount"]
		"health_restore":
			return "Restore 50%% HP"
		_:
			return ""


func _on_encounter_selected(encounter_data: Dictionary) -> void:
	"""Handle encounter selection"""
	print("EncounterSelect: Selected %s" % encounter_data["name"])
	
	# Navigate to encounter execution scene
	var main = get_tree().get_root().get_node("Main")
	
	# Store selected encounter data for next scene
	main.set_meta("selected_encounter", encounter_data)
	
	main.change_scene("res://scenes/ui/encounter_execute.tscn")


func _on_back_pressed() -> void:
	"""Return to run view (debug only)"""
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/run_view.tscn")
```

**Claude Code Directive**:
```
Create the EncounterSelect scene with 3 option panels.
Make sure:
- Each panel shows encounter image, name, type, description
- Reward preview gives a hint of what the encounter offers
- Select button navigates to encounter_execute scene
- Selected encounter data is passed to next scene via metadata

Use simple panel styling for now.
```

---

### Task 3: Create Encounter Execution Scene (Framework)

Create the scene where encounters are actually executed.

#### File: `scenes/ui/encounter_execute.tscn`

Create a scene with this structure:
```
EncounterExecute (Control)
├── Background (ColorRect)
├── EncounterContainer (VBoxContainer) - Center of screen
│   ├── TitleLabel (Label) - Encounter name
│   └── ContentContainer (Control)
│       └── (Dynamic encounter UI loaded here)
└── CompleteButton (Button) - Bottom-right, "COMPLETE ENCOUNTER"
```

#### File: `scenes/ui/encounter_execute.gd`

```gdscript
extends Control
# EncounterExecute - Execute the selected encounter

@onready var title_label = $EncounterContainer/TitleLabel
@onready var content_container = $EncounterContainer/ContentContainer
@onready var complete_button = $CompleteButton

var encounter_data: Dictionary = {}
var rewards: Dictionary = {}
var encounter_completed: bool = false


func _ready() -> void:
	complete_button.pressed.connect(_on_complete_pressed)
	complete_button.disabled = true  # Enable after encounter interaction
	
	# Get selected encounter data from Main scene metadata
	var main = get_tree().get_root().get_node("Main")
	if main.has_meta("selected_encounter"):
		encounter_data = main.get_meta("selected_encounter")
		main.remove_meta("selected_encounter")
		_setup_encounter()
	else:
		push_error("EncounterExecute: No encounter data found!")


func _setup_encounter() -> void:
	"""Setup the encounter UI based on type"""
	title_label.text = encounter_data["name"]
	
	match encounter_data["type"]:
		"shop":
			_setup_shop_encounter()
		"xp_reward":
			_setup_xp_reward_encounter()
		"gold_reward":
			_setup_gold_reward_encounter()
		"health_restore":
			_setup_health_restore_encounter()
		_:
			push_error("EncounterExecute: Unknown encounter type: %s" % encounter_data["type"])


func _setup_shop_encounter() -> void:
	"""Setup shop encounter UI"""
	var shop_ui = _create_shop_ui()
	content_container.add_child(shop_ui)


func _setup_xp_reward_encounter() -> void:
	"""Setup XP reward encounter UI"""
	var xp_ui = _create_xp_reward_ui()
	content_container.add_child(xp_ui)
	
	# Enable complete button immediately (no interaction needed)
	complete_button.disabled = false
	encounter_completed = true


func _setup_gold_reward_encounter() -> void:
	"""Setup gold reward encounter UI"""
	var gold_ui = _create_gold_reward_ui()
	content_container.add_child(gold_ui)
	
	# Enable complete button immediately
	complete_button.disabled = false
	encounter_completed = true


func _setup_health_restore_encounter() -> void:
	"""Setup health restore encounter UI"""
	var health_ui = _create_health_restore_ui()
	content_container.add_child(health_ui)
	
	# Enable complete button immediately
	complete_button.disabled = false
	encounter_completed = true


func _create_shop_ui() -> Control:
	"""Create shop UI with purchasable items"""
	var vbox = VBoxContainer.new()
	
	var label = Label.new()
	label.text = "Purchase items and skills with gold"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var gold_label = Label.new()
	gold_label.text = "Your Gold: %d" % RunManager.get_gold()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.name = "GoldLabel"
	vbox.add_child(gold_label)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 400)
	vbox.add_child(scroll)
	
	var inventory_list = VBoxContainer.new()
	scroll.add_child(inventory_list)
	
	# Items for sale
	if encounter_data["data"].has("items"):
		var items_title = Label.new()
		items_title.text = "--- ITEMS FOR SALE ---"
		items_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_list.add_child(items_title)
		
		for item_sale in encounter_data["data"]["items"]:
			var item_row = _create_shop_item_row(item_sale)
			inventory_list.add_child(item_row)
	
	# Skills for sale
	if encounter_data["data"].has("skills"):
		var skills_title = Label.new()
		skills_title.text = "--- SKILLS FOR SALE ---"
		skills_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_list.add_child(skills_title)
		
		for skill_sale in encounter_data["data"]["skills"]:
			var skill_row = _create_shop_skill_row(skill_sale)
			inventory_list.add_child(skill_row)
	
	# Can complete shop after any interaction (or none)
	complete_button.disabled = false
	encounter_completed = true
	
	return vbox


func _create_shop_item_row(item_sale: Dictionary) -> Control:
	"""Create a row for a shop item"""
	var row = HBoxContainer.new()
	
	var item_id = item_sale["id"]
	var cost = item_sale["cost"]
	var is_upgrade = item_sale["is_upgrade"]
	
	var item_data: Dictionary
	if is_upgrade:
		item_data = GameData.get_item_upgrade_by_id(item_id)
	else:
		item_data = GameData.get_item_by_id(item_id)
	
	if item_data.is_empty():
		return row
	
	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(item_data["image_path"]):
		icon.texture = load(item_data["image_path"])
	row.add_child(icon)
	
	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = item_data["name"]
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item_data["description"]
	desc_label.modulate = Color(0.7, 0.7, 0.7)
	info_vbox.add_child(desc_label)
	
	# Character selector
	var char_selector = OptionButton.new()
	char_selector.add_item("Select Character...")
	var team = RunManager.get_team()
	for i in range(team.size()):
		char_selector.add_item("%s (Lv.%d)" % [team[i].get_character_name(), team[i].level])
	row.add_child(char_selector)
	
	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Buy (%d💰)" % cost
	buy_button.pressed.connect(_on_buy_item.bind(item_id, is_upgrade, cost, char_selector, buy_button))
	row.add_child(buy_button)
	
	return row


func _create_shop_skill_row(skill_sale: Dictionary) -> Control:
	"""Create a row for a shop skill"""
	var row = HBoxContainer.new()
	
	var skill_id = skill_sale["id"]
	var cost = skill_sale["cost"]
	
	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		return row
	
	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(skill_data["image_path"]):
		icon.texture = load(skill_data["image_path"])
	row.add_child(icon)
	
	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = skill_data["name"]
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = skill_data["description"]
	desc_label.modulate = Color(0.7, 0.7, 0.7)
	info_vbox.add_child(desc_label)
	
	# Level requirement
	if skill_data.has("level_requirement"):
		var req_label = Label.new()
		req_label.text = "Requires Level %d" % skill_data["level_requirement"]
		req_label.modulate = Color(1.0, 0.5, 0.5)
		info_vbox.add_child(req_label)
	
	# Character selector
	var char_selector = OptionButton.new()
	char_selector.add_item("Select Character...")
	var team = RunManager.get_team()
	for i in range(team.size()):
		char_selector.add_item("%s (Lv.%d)" % [team[i].get_character_name(), team[i].level])
	row.add_child(char_selector)
	
	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Buy (%d💰)" % cost
	buy_button.pressed.connect(_on_buy_skill.bind(skill_id, cost, char_selector, buy_button))
	row.add_child(buy_button)
	
	return row


func _on_buy_item(item_id: String, is_upgrade: bool, cost: int, char_selector: OptionButton, button: Button) -> void:
	"""Handle buying an item"""
	var selected_index = char_selector.selected - 1  # -1 because first item is "Select Character..."
	
	if selected_index < 0:
		print("EncounterExecute: Must select a character first")
		return
	
	if not RunManager.spend_gold(cost):
		print("EncounterExecute: Not enough gold")
		return
	
	var team = RunManager.get_team()
	var char_instance = team[selected_index]
	
	if is_upgrade:
		var success = char_instance.equip_item_upgrade(item_id)
		if success:
			print("EncounterExecute: Purchased and equipped item upgrade: %s" % item_id)
			button.disabled = true
			button.text = "PURCHASED"
			_update_gold_label()
		else:
			# Refund if level requirement not met
			RunManager.add_gold(cost)
			print("EncounterExecute: Cannot equip - level requirement not met")
	else:
		# Add regular item to equipped items (TODO: Better handling)
		# For now, items can't be added during runs (only upgrades)
		print("EncounterExecute: Regular items can't be equipped during runs (placeholder)")
		RunManager.add_gold(cost)  # Refund


func _on_buy_skill(skill_id: String, cost: int, char_selector: OptionButton, button: Button) -> void:
	"""Handle buying a skill"""
	var selected_index = char_selector.selected - 1
	
	if selected_index < 0:
		print("EncounterExecute: Must select a character first")
		return
	
	if not RunManager.spend_gold(cost):
		print("EncounterExecute: Not enough gold")
		return
	
	var team = RunManager.get_team()
	var char_instance = team[selected_index]
	
	var success = char_instance.learn_skill(skill_id)
	if success:
		print("EncounterExecute: Purchased and learned skill: %s" % skill_id)
		button.disabled = true
		button.text = "LEARNED"
		_update_gold_label()
	else:
		# Refund if already learned or level requirement not met
		RunManager.add_gold(cost)
		print("EncounterExecute: Cannot learn skill")


func _update_gold_label() -> void:
	"""Update the gold display in shop"""
	var gold_label = content_container.get_node_or_null("VBoxContainer/GoldLabel")
	if gold_label:
		gold_label.text = "Your Gold: %d" % RunManager.get_gold()


func _create_xp_reward_ui() -> Control:
	"""Create XP reward UI"""
	var vbox = VBoxContainer.new()
	
	var label = Label.new()
	label.text = "Choose a character to receive XP"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var xp_amount = encounter_data["data"]["xp_amount"]
	var xp_label = Label.new()
	xp_label.text = "XP Award: +%d" % xp_amount
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.add_theme_font_size_override("font_size", 24)
	xp_label.modulate = Color(0.3, 1.0, 0.3)
	vbox.add_child(xp_label)
	
	var team = RunManager.get_team()
	for i in range(team.size()):
		var char_instance = team[i]
		var button = Button.new()
		button.text = "Give to %s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
		button.pressed.connect(_on_xp_character_selected.bind(i, xp_amount, button))
		vbox.add_child(button)
	
	return vbox


func _on_xp_character_selected(char_index: int, xp_amount: int, button: Button) -> void:
	"""Give XP to selected character"""
	var team = RunManager.get_team()
	var char_instance = team[char_index]
	
	var leveled_up = char_instance.add_experience(xp_amount)
	
	button.text = "XP Given! %s" % ("(LEVEL UP!)" if leveled_up else "")
	button.disabled = true
	
	print("EncounterExecute: Gave %d XP to %s" % [xp_amount, char_instance.get_character_name()])


func _create_gold_reward_ui() -> Control:
	"""Create gold reward UI"""
	var vbox = VBoxContainer.new()
	
	var gold_amount = encounter_data["data"]["gold_amount"]
	
	var label = Label.new()
	label.text = "You found gold!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var gold_label = Label.new()
	gold_label.text = "+%d Gold" % gold_amount
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 32)
	gold_label.modulate = Color(1.0, 0.84, 0.0)
	vbox.add_child(gold_label)
	
	# Award gold immediately
	RunManager.add_gold(gold_amount)
	
	return vbox


func _create_health_restore_ui() -> Control:
	"""Create health restore UI"""
	var vbox = VBoxContainer.new()
	
	var label = Label.new()
	label.text = "Your team's health is restored!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var heal_percentage = encounter_data["data"]["heal_percentage"]
	var team = RunManager.get_team()
	
	for char_instance in team:
		var heal_amount = int(char_instance.max_health * heal_percentage)
		char_instance.heal(heal_amount)
		
		var char_label = Label.new()
		char_label.text = "%s: +%d HP" % [char_instance.get_character_name(), heal_amount]
		char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		char_label.modulate = Color(0.3, 1.0, 0.3)
		vbox.add_child(char_label)
	
	return vbox


func _on_complete_pressed() -> void:
	"""Complete the encounter and return to run view"""
	if not encounter_completed:
		print("EncounterExecute: Encounter not ready to complete")
		return
	
	print("EncounterExecute: Completing encounter...")
	
	# Save run state
	RunManager.save_run_state()
	
	# Return to run view
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/run_view.tscn")
```

**Claude Code Directive**:
```
Create the EncounterExecute scene with dynamic encounter UIs.
This is complex - each encounter type has its own UI. Make sure:
- Shop lets you buy items/skills for gold
- Shop only sells item upgrades (not regular items during runs)
- XP reward lets you choose which character gets XP
- Gold reward automatically awards gold
- Health restore automatically heals all characters
- Complete button is only enabled when encounter is resolved
- Returns to run_view after completion

This is the most complex scene so far - test thoroughly!
```

---

### Task 4: Update RunView to Navigate to EncounterSelect

Replace the encounter simulation with real encounter selection.

#### File: `scenes/ui/run_view.gd` (UPDATE)

Replace the `_start_encounter_phase()` method:

```gdscript
func _start_encounter_phase() -> void:
	"""Navigate to encounter selection"""
	print("RunView: Starting encounter phase...")
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/encounter_select.tscn")
```

Remove or comment out the `_simulate_encounter_completion()` method (no longer needed).

**Claude Code Directive**:
```
Update run_view.gd to navigate to encounter_select instead of simulating.
Remove the simulation method.
```

---

### Task 5: Create Placeholder Encounter Images

Create simple placeholder images for encounters.

**Claude Code Directive**:
```
Create simple placeholder images as colored rectangles (128x128):
- res://assets/encounters/merchant.png - Orange square
- res://assets/encounters/training.png - Blue square
- res://assets/encounters/chest.png - Gold/yellow square
- res://assets/encounters/fountain.png - Cyan square

These will be replaced with real art later.
```

---

## Configuration Steps (Manual)

After Claude Code creates all the files:

### Add EncounterFactory Autoload

Open Godot and go to: **Project → Project Settings → Autoload**

Add:

| Path | Node Name |
|------|-----------|
| `res://autoloads/encounter_factory.gd` | `EncounterFactory` |

Place it after RunManager in the autoload order.

---

## Testing Instructions

### Test 1: Encounter Selection Displays

1. Start a run (draft 3 characters)
2. In run view, click **CHOOSE ENCOUNTER**
3. **Expected Result**:
   - Encounter selection screen loads
   - Shows 3 different encounter options
   - Each shows: image, name, type, description, reward preview
   - All options are different types (no duplicates)

**If it fails**:
- Check scene path in run_view.gd
- Verify EncounterFactory is loaded as autoload
- Check generate_encounter_options() works

### Test 2: Encounter Types Are Varied

1. View encounter options multiple times (use debug keys to cycle through)
2. **Expected Result**:
   - See different combinations of: Shop, Training Dummy, Treasure Chest, Healing Fountain
   - No more than 1 of each type per set of 3 options
   - Types are somewhat randomized

**If variety is low**:
- Check weighted selection in EncounterFactory
- Verify exclude list works correctly
- Check weights are reasonable

### Test 3: Shop Encounter Works

1. Select a "Traveling Merchant" (shop) encounter
2. **Expected Result**:
   - Shows title "Traveling Merchant"
   - Lists 2-4 items for sale
   - Lists 1-2 skills for sale
   - Each has: icon, name, description, character selector, buy button
   - Shows current gold amount
3. Select a character from dropdown
4. Click buy button
5. **Expected Result**:
   - Gold decreases by cost
   - Item upgrade or skill is applied to selected character
   - Button changes to "PURCHASED" or "LEARNED"
   - Gold label updates
6. Click **COMPLETE ENCOUNTER**
7. **Expected Result**:
   - Returns to run view
   - Phase switches to Combat
   - Changes are saved

**If shop doesn't work**:
- Check _create_shop_ui() builds UI correctly
- Verify _on_buy_item() and _on_buy_skill() logic
- Check RunManager.spend_gold() works
- Check CharacterInstance.equip_item_upgrade() and learn_skill()

### Test 4: XP Reward Encounter Works

1. Select a "Training Dummy" encounter
2. **Expected Result**:
   - Shows XP amount (+30 to +80)
   - Shows 3 buttons, one for each character
3. Click a character button
4. **Expected Result**:
   - Character receives XP
   - Button shows "XP Given!" and possibly "(LEVEL UP!)"
   - Button becomes disabled
   - Console confirms XP award
5. Click **COMPLETE ENCOUNTER**
6. **Expected Result**:
   - Returns to run view
   - Character's level may have increased
   - Phase switches to Combat

**If XP reward doesn't work**:
- Check _create_xp_reward_ui() logic
- Verify CharacterInstance.add_experience() works
- Check level up detection

### Test 5: Gold Reward Encounter Works

1. Select a "Treasure Chest" encounter
2. **Expected Result**:
   - Shows gold amount (+20 to +50)
   - Gold is immediately awarded
   - No interaction needed
3. Click **COMPLETE ENCOUNTER**
4. **Expected Result**:
   - Returns to run view
   - Gold in top bar reflects the increase

**If gold reward doesn't work**:
- Check _create_gold_reward_ui() calls RunManager.add_gold()
- Verify gold updates in run view

### Test 6: Health Restore Encounter Works

1. First, damage your characters (use combat stub losses, or manually edit save file)
2. Select a "Healing Fountain" encounter
3. **Expected Result**:
   - Shows healing for each character
   - Characters are immediately healed by 50% of max health
   - Lists each character with "+X HP"
4. Click **COMPLETE ENCOUNTER**
5. **Expected Result**:
   - Returns to run view
   - Character cards show increased current health

**If health restore doesn't work**:
- Check _create_health_restore_ui() calls char_instance.heal()
- Verify healing calculation (50% of max)
- Check run view displays updated health

### Test 7: Shop Level Requirements

1. Start a run with level 1 characters
2. Find a shop selling a skill with level requirement
3. Try to buy the skill for a level 1 character
4. **Expected Result**:
   - Purchase fails
   - Gold is refunded
   - Console shows "Cannot learn skill"
5. Level up that character to required level (use debug key X)
6. Go through another shop encounter
7. Buy the same skill type
8. **Expected Result**:
   - Purchase succeeds
   - Skill is learned

**If level requirements don't work**:
- Check CharacterInstance.learn_skill() validates level
- Verify refund happens on failure

### Test 8: Shop Item Upgrades

1. In a shop, buy an item upgrade for a character
2. **Expected Result**:
   - Character's item in that slot is replaced
   - Stats update (visible in run view after completing encounter)
   - Console shows which item was replaced
3. Later in the run, buy another upgrade for the same slot
4. **Expected Result**:
   - Previous upgrade is replaced
   - Only one item per slot

**If upgrades don't work**:
- Check CharacterInstance.equip_item_upgrade() logic
- Verify slot replacement works
- Check stat recalculation

### Test 9: Cannot Buy Without Gold

1. Spend all your gold in encounters
2. Try to buy something expensive
3. **Expected Result**:
   - Purchase fails
   - Console shows "Not enough gold"
   - Button remains enabled
   - No gold deducted

**If this doesn't work**:
- Check RunManager.spend_gold() returns false when insufficient
- Verify purchase logic checks return value

### Test 10: Multiple Encounters in a Run

1. Complete 2-3 encounters in a row
2. **Expected Result**:
   - Each encounter works correctly
   - Changes accumulate (gold, XP, items, skills)
   - State saves after each encounter
   - Can close and resume mid-run
   - Run view updates correctly after each encounter

**If multiple encounters fail**:
- Check save_run_state() is called properly
- Verify load_run_state() restores all changes
- Check that character modifications persist

### Test 11: Encounter Rewards Persist

1. Complete an encounter (buy items, gain XP, etc.)
2. Complete combat (use stub)
3. Close game completely
4. Reopen and resume run
5. **Expected Result**:
   - All changes from encounter are still present
   - Characters have the items/skills/XP they gained
   - Gold amount is correct

**If rewards don't persist**:
- Check RunManager.save_run_state() after encounter
- Verify CharacterInstance serialization includes new items/skills
- Check load restores everything correctly

### Test 12: Full Encounter → Combat Cycle

1. Start from round 1, encounter phase
2. Complete encounter → phase switches to combat
3. Complete combat (stub) → round advances, phase switches to encounter
4. Repeat several times
5. **Expected Result**:
   - Cycle works smoothly
   - No errors or crashes
   - State always saves correctly
   - Can resume at any point

**If cycle breaks**:
- Check phase tracking in run_view
- Verify round advancement works
- Check save/load at each step

---

## Git Checkpoint

Once all tests pass, commit your work:

```bash
# Review changes
git status
git diff

# Stage all changes
git add .

# Commit
git commit -m "Phase 5: Encounter System

- Created EncounterFactory singleton for generating encounters
- Implemented weighted random encounter selection
- Created EncounterSelect scene with 3 options display
- Created EncounterExecute scene with dynamic encounter UIs
- Implemented Shop encounter (buy items/skills with gold)
- Implemented XP Reward encounter (choose character for XP)
- Implemented Gold Reward encounter (instant gold)
- Implemented Health Restore encounter (heal all characters)
- Level requirements enforced for skills and item upgrades
- Item upgrades properly replace equipped items
- All encounter rewards persist through save/load
- Encounter → Combat cycle fully functional
- All tests passing: selection, execution, rewards, persistence"

# Optional: Tag this milestone
git tag -a v0.5-phase5 -m "Phase 5 Complete: Encounter System"
```

---

## Success Criteria

Phase 5 is complete when ALL of the following are true:

- ✅ Encounter selection shows 3 different encounter types
- ✅ No duplicate types in same set of 3 options
- ✅ Shop encounter displays items and skills for sale
- ✅ Can buy items/skills with gold, selected character receives them
- ✅ Shop enforces level requirements
- ✅ Item upgrades replace equipped items in same slot
- ✅ XP reward lets player choose which character gets XP
- ✅ Gold reward instantly awards gold
- ✅ Health restore heals all characters
- ✅ Cannot buy without sufficient gold
- ✅ All encounter changes persist through save/load
- ✅ Completing encounter returns to run view
- ✅ Phase switches from Encounter to Combat after encounter
- ✅ Multiple encounters work in sequence
- ✅ Full Encounter → Combat cycle works smoothly
- ✅ No errors during any encounter type
- ✅ Git commit created with all Phase 5 files

---

## Common Issues & Solutions

### Issue: Encounter options show duplicate types
**Solution**:
- Check _select_weighted_encounter_type() excludes used types
- Verify excluded_types list is being built correctly
- Make sure weights allow for variety

### Issue: Shop items don't appear
**Solution**:
- Check _generate_shop_inventory() returns items
- Verify GameData has items and skills
- Check _create_shop_item_row() builds UI correctly

### Issue: Buying in shop doesn't work
**Solution**:
- Verify character selector index calculation (selected - 1)
- Check RunManager.spend_gold() is called
- Check CharacterInstance methods are called correctly
- Add print statements to debug purchase flow

### Issue: Item upgrades don't replace items
**Solution**:
- Check CharacterInstance.equip_item_upgrade() logic
- Verify slot matching works
- Check that old item is removed before new one added

### Issue: XP doesn't apply to character
**Solution**:
- Verify character index is correct
- Check CharacterInstance.add_experience() is called
- Verify XP amount is reasonable

### Issue: Level requirements not enforced
**Solution**:
- Check CharacterInstance.learn_skill() validates level
- Check CharacterInstance.equip_item_upgrade() validates level
- Verify refund happens when requirement not met

### Issue: Encounter rewards don't persist
**Solution**:
- Check save_run_state() is called after encounter
- Verify CharacterInstance.to_dict() includes new items/skills
- Check from_dict() restores all fields

### Issue: Complete button doesn't enable
**Solution**:
- Check encounter_completed flag is set
- Verify button.disabled is set to false
- Check each encounter type enables the button

### Issue: Metadata not passed between scenes
**Solution**:
- Check Main node set_meta() and get_meta() calls
- Verify metadata key matches
- Check remove_meta() is called after retrieval

---

## Next Steps

Once Phase 5 is complete and all tests pass:

1. Review `phase_06_combat_stub.md` for the next phase
2. Consider adding more encounter types for variety
3. Optional: Add visual feedback for purchases/rewards (particles, animations)

**Do not proceed to Phase 6 until all Phase 5 tests pass and the git commit is created.**

---

## Phase 5 Complete! 🎉

You now have:
- ✅ Complete encounter system with 4 different types
- ✅ Modular, extensible encounter framework
- ✅ Working shop with item and skill purchases
- ✅ Reward distribution (XP, gold, healing)
- ✅ Level requirement enforcement
- ✅ Item upgrade replacement system
- ✅ Full persistence through save/load

Total new files created: ~5
Total lines of code: ~900+
Estimated time: 5-7 hours

**Ready for Phase 6: Combat Stub (Combat selection and results)**
