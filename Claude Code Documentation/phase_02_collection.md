# Phase 2: Collection & Character Management

**Goal**: View and equip characters in collection  
**Duration**: Days 3-4  
**Deliverable**: Can browse collection, equip items, see stat changes

---

## Overview

Phase 2 builds the character collection system where players can:
- View all unlocked characters in a grid
- Select a character to see detailed stats
- View rank progression and rewards
- Equip/unequip starting items
- See stat changes in real-time

This phase introduces reusable UI components (CharacterCard, ItemSlot) that will be used throughout the game.

---

## Prerequisites

- Phase 1 complete and tested
- All Phase 1 tests passing
- Git commit created for Phase 1
- Godot project closed (to avoid file conflicts)

---

## Implementation Tasks

### Task 1: Create CharacterCard Component

Create a reusable component for displaying character information across all screens.

#### File: `scenes/components/character_card.tscn`

Create a scene with this structure:
```
CharacterCard (PanelContainer)
├── MarginContainer
│   └── VBoxContainer
│       ├── Portrait (TextureRect) - 128x128, expand mode: keep aspect centered
│       ├── NameLabel (Label) - Center aligned
│       └── StatsContainer (VBoxContainer)
│           ├── HealthLabel (Label) - "❤ 100"
│           ├── AttackLabel (Label) - "⚔ 10"
│           ├── DefenseLabel (Label) - "🛡 8"
│           ├── SpeedLabel (Label) - "⚡ 5"
│           └── IncomeLabel (Label) - "💰 3"
```

**Styling Notes**:
- PanelContainer should have a visible border
- Portrait should be square and centered
- Stats should be compact and readable
- Card should have a minimum size (e.g., 160x240)

#### File: `scenes/components/character_card.gd`

```gdscript
extends PanelContainer
# CharacterCard - Reusable component for displaying character info
# Used in: Collection, Draft, Run View

signal card_clicked(character_data: Dictionary)

@onready var portrait = $MarginContainer/VBoxContainer/Portrait
@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var health_label = $MarginContainer/VBoxContainer/StatsContainer/HealthLabel
@onready var attack_label = $MarginContainer/VBoxContainer/StatsContainer/AttackLabel
@onready var defense_label = $MarginContainer/VBoxContainer/StatsContainer/DefenseLabel
@onready var speed_label = $MarginContainer/VBoxContainer/StatsContainer/SpeedLabel
@onready var income_label = $MarginContainer/VBoxContainer/StatsContainer/IncomeLabel

var character_data: Dictionary = {}
var clickable: bool = true


func _ready() -> void:
	if clickable:
		gui_input.connect(_on_gui_input)


func setup(char_data: Dictionary, with_equipped_items: bool = false) -> void:
	"""
	Configure the card with character data
	
	Args:
		char_data: Player's character data (from PlayerAccount)
		with_equipped_items: If true, calculate stats with equipped items
	"""
	character_data = char_data
	
	# Get master character data
	var char_master = GameData.get_character_by_id(char_data["id"])
	if char_master.is_empty():
		push_error("CharacterCard: Character master data not found: %s" % char_data["id"])
		return
	
	# Set portrait
	var portrait_path = char_master["image_path"]
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	
	# Set name
	name_label.text = char_master["name"]
	
	# Calculate stats
	var stats = _calculate_stats(char_master, char_data, with_equipped_items)
	
	# Display stats
	health_label.text = "❤ %d" % stats["health"]
	attack_label.text = "⚔ %d" % stats["basic_attack_damage"]
	defense_label.text = "🛡 %d" % stats["defense"]
	speed_label.text = "⚡ %d" % stats["speed"]
	income_label.text = "💰 %d" % stats["income"]


func _calculate_stats(char_master: Dictionary, char_data: Dictionary, with_items: bool) -> Dictionary:
	"""Calculate character stats, optionally including equipped items"""
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
	
	# Apply equipped items if requested
	if with_items and char_data.has("equipped_items"):
		for item_id in char_data["equipped_items"]:
			var item_data = GameData.get_item_by_id(item_id)
			if item_data.has("stat_modifiers"):
				for stat_name in item_data["stat_modifiers"]:
					stats[stat_name] += item_data["stat_modifiers"][stat_name]
	
	return stats


func set_clickable(enabled: bool) -> void:
	"""Enable or disable click interaction"""
	clickable = enabled
	mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(character_data)


func highlight(enabled: bool) -> void:
	"""Visually highlight the card (for selection states)"""
	if enabled:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
```

**Claude Code Directive**:
```
Create the CharacterCard component with the specified structure and script.
This is a critical reusable component - make sure:
- Stats calculation properly includes rank boosts and equipped items
- The card is visually distinct and readable
- Click detection works properly
- The highlight effect is subtle but visible

Use simple panel styling for now. Focus on functionality and clean code.
```

---

### Task 2: Create ItemSlot Component

Create a reusable component for displaying and interacting with item slots.

#### File: `scenes/components/item_slot.tscn`

Create a scene with this structure:
```
ItemSlot (PanelContainer)
├── MarginContainer
│   └── VBoxContainer
│       ├── ItemIcon (TextureRect) - 64x64, expand mode: keep aspect centered
│       ├── ItemName (Label) - Center aligned, small font
│       └── SlotLabel (Label) - Center aligned, very small font, "WEAPON"
```

#### File: `scenes/components/item_slot.gd`

```gdscript
extends PanelContainer
# ItemSlot - Reusable component for displaying item slots
# Shows equipped item or empty slot

signal slot_clicked(slot_type: String, item_id: String)

@onready var item_icon = $MarginContainer/VBoxContainer/ItemIcon
@onready var item_name = $MarginContainer/VBoxContainer/ItemName
@onready var slot_label = $MarginContainer/VBoxContainer/SlotLabel

var slot_type: String = ""  # "weapon", "armor", "accessory"
var equipped_item_id: String = ""
var clickable: bool = true


func _ready() -> void:
	if clickable:
		gui_input.connect(_on_gui_input)


func setup(slot: String, item_id: String = "") -> void:
	"""
	Configure the slot
	
	Args:
		slot: Type of slot ("weapon", "armor", "accessory")
		item_id: ID of equipped item, or empty string for empty slot
	"""
	slot_type = slot
	equipped_item_id = item_id
	
	# Set slot label
	slot_label.text = slot.to_upper()
	
	if item_id.is_empty():
		_show_empty_slot()
	else:
		_show_equipped_item(item_id)


func _show_empty_slot() -> void:
	"""Display an empty slot"""
	item_icon.texture = null
	item_name.text = "[Empty]"
	modulate = Color(0.7, 0.7, 0.7)


func _show_equipped_item(item_id: String) -> void:
	"""Display an equipped item"""
	var item_data = GameData.get_item_by_id(item_id)
	if item_data.is_empty():
		push_error("ItemSlot: Item not found: %s" % item_id)
		_show_empty_slot()
		return
	
	# Set icon
	var icon_path = item_data["image_path"]
	if ResourceLoader.exists(icon_path):
		item_icon.texture = load(icon_path)
	
	# Set name
	item_name.text = item_data["name"]
	
	# Normal color for equipped items
	modulate = Color.WHITE


func set_clickable(enabled: bool) -> void:
	"""Enable or disable click interaction"""
	clickable = enabled
	mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicked.emit(slot_type, equipped_item_id)


func highlight(enabled: bool) -> void:
	"""Visually highlight the slot"""
	if enabled:
		modulate = Color(1.3, 1.3, 1.0)  # Yellow tint
	else:
		if equipped_item_id.is_empty():
			modulate = Color(0.7, 0.7, 0.7)
		else:
			modulate = Color.WHITE
```

**Claude Code Directive**:
```
Create the ItemSlot component with the specified structure and script.
Make sure:
- Empty slots are visually distinct from filled slots
- Item icons display correctly
- The slot type label is clear
- Click detection works

Keep styling simple but functional.
```

---

### Task 3: Create SkillIcon Component

Create a simple component for displaying skill icons.

#### File: `scenes/components/skill_icon.tscn`

Create a scene with this structure:
```
SkillIcon (PanelContainer)
├── MarginContainer
│   └── VBoxContainer
│       ├── Icon (TextureRect) - 48x48, expand mode: keep aspect centered
│       └── SkillName (Label) - Center aligned, small font
```

#### File: `scenes/components/skill_icon.gd`

```gdscript
extends PanelContainer
# SkillIcon - Simple display component for skills

@onready var icon = $MarginContainer/VBoxContainer/Icon
@onready var skill_name = $MarginContainer/VBoxContainer/SkillName

var skill_id: String = ""


func setup(skill_data_id: String) -> void:
	"""Configure the skill icon"""
	skill_id = skill_data_id
	
	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		push_error("SkillIcon: Skill not found: %s" % skill_id)
		return
	
	# Set icon
	var icon_path = skill_data["image_path"]
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	
	# Set name
	skill_name.text = skill_data["name"]


func set_locked(locked: bool) -> void:
	"""Visual indicator for locked skills"""
	if locked:
		modulate = Color(0.5, 0.5, 0.5)
	else:
		modulate = Color.WHITE
```

**Claude Code Directive**:
```
Create the SkillIcon component. This is simpler than the others - just a 
display component with no interaction for now. Make it clean and minimal.
```

---

### Task 4: Create CharacterDetails Scene

Create the detailed character view that shows all stats, items, and skills.

#### File: `scenes/ui/character_details.tscn`

Create a scene with this structure:
```
CharacterDetails (Panel)
├── MarginContainer
│   └── VBoxContainer
│       ├── TopBar (HBoxContainer)
│       │   ├── Portrait (TextureRect) - 128x128
│       │   └── InfoContainer (VBoxContainer)
│       │       ├── NameLabel (Label) - Large font
│       │       ├── RankLabel (Label) - "Rank 3"
│       │       └── RankProgressBar (ProgressBar)
│       ├── HSeparator
│       ├── StatsTitle (Label) - "STATS"
│       ├── StatsGrid (GridContainer) - 2 columns
│       │   ├── HealthLabel (Label) - "Health:"
│       │   ├── HealthValue (Label) - "100"
│       │   ├── AttackLabel (Label) - "Attack:"
│       │   ├── AttackValue (Label) - "13"
│       │   ├── DefenseLabel (Label) - "Defense:"
│       │   ├── DefenseValue (Label) - "8"
│       │   ├── SpeedLabel (Label) - "Speed:"
│       │   ├── SpeedValue (Label) - "5"
│       │   ├── IncomeLabel (Label) - "Income:"
│       │   └── IncomeValue (Label) - "3"
│       ├── HSeparator2
│       ├── ItemsTitle (Label) - "EQUIPMENT"
│       ├── ItemSlotsContainer (HBoxContainer)
│       │   └── (ItemSlot instances will be added here)
│       ├── ItemListContainer (ScrollContainer)
│       │   └── ItemList (VBoxContainer)
│       │       └── (Unlocked items displayed here)
│       ├── HSeparator3
│       ├── SkillsTitle (Label) - "UNLOCKED SKILLS"
│       └── SkillsContainer (GridContainer) - 4 columns
│           └── (SkillIcon instances will be added here)
```

#### File: `scenes/ui/character_details.gd`

```gdscript
extends Panel
# CharacterDetails - Detailed character view with equipment management

@onready var portrait = $MarginContainer/VBoxContainer/TopBar/Portrait
@onready var name_label = $MarginContainer/VBoxContainer/TopBar/InfoContainer/NameLabel
@onready var rank_label = $MarginContainer/VBoxContainer/TopBar/InfoContainer/RankLabel
@onready var rank_progress_bar = $MarginContainer/VBoxContainer/TopBar/InfoContainer/RankProgressBar

@onready var health_value = $MarginContainer/VBoxContainer/StatsGrid/HealthValue
@onready var attack_value = $MarginContainer/VBoxContainer/StatsGrid/AttackValue
@onready var defense_value = $MarginContainer/VBoxContainer/StatsGrid/DefenseValue
@onready var speed_value = $MarginContainer/VBoxContainer/StatsGrid/SpeedValue
@onready var income_value = $MarginContainer/VBoxContainer/StatsGrid/IncomeValue

@onready var item_slots_container = $MarginContainer/VBoxContainer/ItemSlotsContainer
@onready var item_list = $MarginContainer/VBoxContainer/ItemListContainer/ItemList
@onready var skills_container = $MarginContainer/VBoxContainer/SkillsContainer

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
	
	# Display equipment slots
	_setup_equipment_slots(char_data)
	
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


func _setup_equipment_slots(char_data: Dictionary) -> void:
	"""Create item slots for weapon, armor, accessory"""
	# Clear existing slots
	for child in item_slots_container.get_children():
		child.queue_free()
	
	# Define slot types
	var slot_types = ["weapon", "armor", "accessory"]
	
	for slot in slot_types:
		var item_slot = ItemSlotScene.instantiate()
		item_slots_container.add_child(item_slot)
		
		# Find equipped item for this slot
		var equipped_item_id = ""
		for item_id in char_data["equipped_items"]:
			var item_data = GameData.get_item_by_id(item_id)
			if item_data["slot"] == slot:
				equipped_item_id = item_id
				break
		
		item_slot.setup(slot, equipped_item_id)
		item_slot.slot_clicked.connect(_on_item_slot_clicked)


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
		var name_label = Label.new()
		name_label.text = item_data["name"]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_row.add_child(name_label)
		
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


func _on_item_slot_clicked(slot_type: String, item_id: String) -> void:
	"""Handle clicking on an equipment slot"""
	if item_id.is_empty():
		print("CharacterDetails: Empty slot clicked: %s" % slot_type)
	else:
		print("CharacterDetails: Equipped item clicked: %s" % item_id)
		# Unequip
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
```

**Claude Code Directive**:
```
Create the CharacterDetails scene with comprehensive character information.
This is a complex UI with multiple sections. Make sure:
- Stats display properly calculates equipped item bonuses
- Equipment slots show current equipment
- Item list shows all unlocked items with equip/unequip buttons
- Skills display in a grid
- UI updates when items are equipped/unequipped

Use ScrollContainer for the item list since it may be long.
Keep the layout organized with separators between sections.
```

---

### Task 5: Create Collection Scene

Create the main collection screen with character grid and details panel.

#### File: `scenes/ui/collection.tscn`

Create a scene with this structure:
```
Collection (Control)
├── Background (ColorRect) - Dark background
├── HSplitContainer
│   ├── LeftPanel (VBoxContainer)
│   │   ├── Title (Label) - "CHARACTER COLLECTION"
│   │   └── CharacterListScroll (ScrollContainer)
│   │       └── CharacterGrid (GridContainer) - 3 columns
│   │           └── (CharacterCard instances added dynamically)
│   └── RightPanel (VBoxContainer)
│       ├── DetailsTitle (Label) - "CHARACTER DETAILS"
│       └── CharacterDetailsPanel (Control)
│           └── (CharacterDetails instance added dynamically)
└── BackButton (Button) - Top-left corner
```

#### File: `scenes/ui/collection.gd`

```gdscript
extends Control
# Collection - Browse and manage character collection

@onready var character_grid = $HSplitContainer/LeftPanel/CharacterListScroll/CharacterGrid
@onready var character_details_panel = $HSplitContainer/RightPanel/CharacterDetailsPanel
@onready var back_button = $BackButton

# Preload scenes
const CharacterCardScene = preload("res://scenes/components/character_card.tscn")
const CharacterDetailsScene = preload("res://scenes/ui/character_details.tscn")

var character_details_instance: Node = null
var selected_character_id: String = ""


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_character_grid()
	
	# Select first character by default
	var unlocked_chars = PlayerAccount.get_unlocked_characters()
	if unlocked_chars.size() > 0:
		_select_character(unlocked_chars[0]["id"])


func _populate_character_grid() -> void:
	"""Create character cards for all unlocked characters"""
	# Clear existing cards
	for child in character_grid.get_children():
		child.queue_free()
	
	# Get unlocked characters
	var unlocked_chars = PlayerAccount.get_unlocked_characters()
	
	print("Collection: Displaying %d characters" % unlocked_chars.size())
	
	# Create a card for each character
	for char_data in unlocked_chars:
		var card = CharacterCardScene.instantiate()
		character_grid.add_child(card)
		
		# Setup card with equipped items
		card.setup(char_data, true)
		
		# Connect click signal
		card.card_clicked.connect(_on_character_card_clicked)


func _on_character_card_clicked(char_data: Dictionary) -> void:
	"""Handle character card selection"""
	_select_character(char_data["id"])


func _select_character(char_id: String) -> void:
	"""Display details for selected character"""
	selected_character_id = char_id
	
	# Get character data
	var char_data = PlayerAccount.get_character_data(char_id)
	if char_data.is_empty():
		push_error("Collection: Character data not found: %s" % char_id)
		return
	
	# Clear existing details
	if character_details_instance:
		character_details_instance.queue_free()
	
	# Create new details panel
	character_details_instance = CharacterDetailsScene.instantiate()
	character_details_panel.add_child(character_details_instance)
	character_details_instance.display_character(char_data)
	
	# Highlight selected card
	_highlight_selected_card()


func _highlight_selected_card() -> void:
	"""Highlight the currently selected character card"""
	for card in character_grid.get_children():
		if card.character_data["id"] == selected_character_id:
			card.highlight(true)
		else:
			card.highlight(false)


func _on_back_pressed() -> void:
	"""Return to main menu"""
	print("Collection: Back button pressed")
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/main_menu.tscn")
```

**Claude Code Directive**:
```
Create the Collection scene with split-panel layout.
Make sure:
- Character grid displays all unlocked characters
- Clicking a character shows their details on the right
- Details panel shows all character info with working equip/unequip
- Back button returns to main menu
- Selected character is highlighted in the grid

Use HSplitContainer for the layout so users can adjust panel sizes if needed.
```

---

### Task 6: Connect Collection to Main Menu

Update the main menu to navigate to the collection screen.

#### File: `scenes/ui/main_menu.gd` (UPDATE)

Update the `_on_collection_pressed()` method:

```gdscript
func _on_collection_pressed() -> void:
	print("MainMenu: Opening collection...")
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/collection.tscn")
```

**Claude Code Directive**:
```
Update the main_menu.gd file to properly navigate to the collection scene.
Replace the placeholder function with the actual scene change.
```

---

## Testing Instructions

### Test 1: Collection Screen Loads

1. Launch game
2. Click **COLLECTION** button
3. **Expected Result**:
   - Collection screen appears
   - Left panel shows 5 character cards in a grid
   - Right panel shows details for first character
   - Back button is visible

**If it fails**: 
- Check console for errors
- Verify collection.tscn scene path is correct
- Ensure CharacterCard component is properly instantiated

### Test 2: Character Cards Display Correctly

1. In collection screen, examine the character cards
2. **Expected Result**:
   - Each card shows character portrait (placeholder colored square)
   - Character name displayed
   - Stats displayed with emoji icons (❤⚔🛡⚡💰)
   - Stats reflect equipped items (e.g., Warrior with Rusty Sword has +3 attack)

**If stats are wrong**:
- Check `_calculate_stats()` in character_card.gd
- Verify equipped items are being applied
- Check that base stats match JSON data

### Test 3: Character Selection Works

1. Click on different character cards
2. **Expected Result**:
   - Selected card becomes highlighted
   - Details panel updates to show selected character
   - Can select all 5 characters
   - Selection state persists visually

**If selection doesn't work**:
- Check `card_clicked` signal connections
- Verify `_select_character()` is being called
- Check highlight logic in CharacterCard

### Test 4: Character Details Display

1. Select each character
2. **Expected Result** for each:
   - Portrait displays
   - Name and rank shown
   - Rank progress bar shows current XP (0/100 for new characters)
   - Stats display with correct values
   - Equipment slots show equipped items (Warrior has Rusty Sword, etc.)
   - Item list shows all unlocked items for that character
   - Skills section shows unlocked skills (empty for rank 1 characters except those with rank 1 skills)

**If details don't display**:
- Check CharacterDetails instantiation
- Verify `display_character()` is called correctly
- Check data access from PlayerAccount

### Test 5: Equipment System

1. Select the Warrior (has Rusty Sword equipped)
2. In the item list, click **Unequip** on Rusty Sword
3. **Expected Result**:
   - Button changes to "Equip"
   - Weapon slot shows [Empty]
   - Attack stat decreases by 3 (10 → 13 → 10)
   - Character card in grid updates to show lower attack
4. Click **Equip** on Rusty Sword
5. **Expected Result**:
   - Button changes back to "Unequip"
   - Weapon slot shows Rusty Sword
   - Attack stat increases by 3 (10 → 13)
   - Character card updates

**If equip/unequip doesn't work**:
- Check PlayerAccount.equip_item() and unequip_item()
- Verify signals are connected
- Check that save_account() is being called
- Make sure UI refreshes after equip/unequip

### Test 6: Equipment Slot Swapping

1. Give Warrior the Leather Armor (add to unlocked_items in player_account.json if needed)
2. Equip Leather Armor (armor slot)
3. **Expected Result**:
   - Armor slot shows Leather Armor
   - Stats update: Defense +2, Health +5
4. Try to equip a different weapon (if you have multiple weapon-slot items unlocked)
5. **Expected Result**:
   - Previous weapon automatically unequipped
   - New weapon equipped in weapon slot
   - Only one item per slot at a time

**If slot swapping doesn't work**:
- Check equip_item() logic in PlayerAccount
- Verify slot-based unequipping before equipping new item

### Test 7: Stat Calculation Accuracy

1. Select Warrior
2. Manually verify stats:
   - Base Attack: 10
   - With Rusty Sword: 10 + 3 = 13
3. Select Mage
4. Verify:
   - Base Attack: 15
   - With Wooden Staff: 15 + 4 = 19
   - Defense: 3 + 1 = 4

**If calculations are wrong**:
- Add debug prints to `_calculate_stats()`
- Check item stat modifiers in items.json
- Verify rank boosts aren't applying incorrectly

### Test 8: Save Persistence

1. Equip some items on characters
2. Close the game completely
3. Reopen the game and go to Collection
4. **Expected Result**:
   - All equipped items are still equipped
   - Stats reflect equipped items
   - No items lost or duplicated

**If equipment doesn't persist**:
- Check that save_account() is called in equip/unequip methods
- Verify player_account.json has been updated (check the file manually)
- Check load_account() is working properly on startup

### Test 9: Back Navigation

1. In collection screen, click **BACK** button
2. **Expected Result**:
   - Returns to main menu with fade transition
   - Main menu displays correctly
   - No errors in console

**If back button doesn't work**:
- Check scene change call in collection.gd
- Verify Main node and change_scene() method exist

### Test 10: Stress Test

1. Rapidly click between different characters
2. Rapidly equip/unequip multiple items
3. **Expected Result**:
   - No crashes or errors
   - UI stays responsive
   - Stats always accurate
   - No visual glitches

**If there are issues**:
- Check for null reference errors
- Verify proper cleanup when switching characters
- Add debouncing if needed

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
git commit -m "Phase 2: Collection & Character Management

- Created CharacterCard reusable component with stats calculation
- Created ItemSlot component for equipment display
- Created SkillIcon component for skill display
- Created CharacterDetails scene with full character info
- Created Collection scene with grid and details panel
- Implemented equipment system (equip/unequip items)
- Connected collection to main menu navigation
- Stats properly calculate with rank boosts and equipped items
- Equipment persists through save/load system
- All tests passing: display, selection, equipment, persistence"

# Optional: Tag this milestone
git tag -a v0.2-phase2 -m "Phase 2 Complete: Collection & Character Management"
```

---

## Success Criteria

Phase 2 is complete when ALL of the following are true:

- ✅ Collection screen displays with character grid and details panel
- ✅ All 5 starting characters visible in grid
- ✅ Character cards show correct stats (base + equipped items)
- ✅ Clicking character cards updates details panel
- ✅ Selected character is visually highlighted
- ✅ Character details show: portrait, name, rank, progress, stats, equipment, items, skills
- ✅ Equipment slots display current equipment or [Empty]
- ✅ Item list shows all unlocked items with Equip/Unequip buttons
- ✅ Equipping items updates stats immediately in all views
- ✅ Unequipping items updates stats immediately
- ✅ Only one item per slot (weapon/armor/accessory)
- ✅ Equipment changes persist through save/load
- ✅ Back button returns to main menu
- ✅ No console errors during any operation
- ✅ Git commit created with all Phase 2 files

---

## Common Issues & Solutions

### Issue: Character cards don't show stats
**Solution**: 
- Verify CharacterCard.setup() is being called with character data
- Check that GameData.get_character_by_id() returns valid data
- Add print statements in _calculate_stats() to debug

### Issue: Stats don't update when equipping items
**Solution**:
- Make sure display_character() is called after equip/unequip
- Verify that get_character_data() returns updated data
- Check that save_account() is being called in PlayerAccount

### Issue: Multiple items in same slot
**Solution**:
- Review equip_item() logic in PlayerAccount
- Should unequip existing item in same slot before equipping new one
- Check slot matching logic

### Issue: Component scenes fail to instantiate
**Solution**:
- Verify scene paths in preload() statements
- Check that scenes are saved properly
- Make sure scripts are attached to root nodes

### Issue: Details panel doesn't update on selection
**Solution**:
- Verify card_clicked signal is connected
- Check that _select_character() is being called
- Make sure CharacterDetails instance is properly created

### Issue: Item list shows wrong items
**Solution**:
- Verify char_data["unlocked_items"] contains correct item IDs
- Check that rank 1 rewards are being applied correctly
- Review _create_character_data() in PlayerAccount

### Issue: Highlight doesn't show selected character
**Solution**:
- Check highlight() method in CharacterCard
- Verify _highlight_selected_card() is being called
- Make sure modulate changes are visible (try more extreme colors for testing)

---

## Next Steps

Once Phase 2 is complete and all tests pass:

1. Review `phase_03_draft_system.md` for the next phase
2. Consider adding more test data (items, skills) if desired
3. Optional: Improve visual styling (fonts, colors, spacing)

**Do not proceed to Phase 3 until all Phase 2 tests pass and the git commit is created.**

---

## Phase 2 Complete! 🎉

You now have:
- ✅ Reusable UI components (CharacterCard, ItemSlot, SkillIcon)
- ✅ Full character collection browser
- ✅ Detailed character view with all stats and info
- ✅ Working equipment system with immediate stat updates
- ✅ Persistent equipment saves

Total new files created: ~8
Total lines of code: ~800
Estimated time: 3-5 hours

**Ready for Phase 3: Draft System**
