# Phase 3: Draft System

**Goal**: Character selection for runs  
**Duration**: Days 5-6  
**Deliverable**: Can draft 3 characters, run initializes with proper team

---

## Overview

Phase 3 implements the character drafting system where players:
- See 3 character options (2 owned, 1 random)
- Can inspect character details before selection
- Spend reroll tokens to regenerate options
- Select 3 different characters for their run
- See their drafted team before confirming

This phase also creates the RunManager singleton and CharacterInstance data class, establishing the foundation for active runs.

---

## Prerequisites

- Phase 2 complete and tested
- All Phase 2 tests passing
- Git commit created for Phase 2
- Godot project closed (to avoid file conflicts)

---

## Implementation Tasks

### Task 1: Create CharacterInstance Data Class

Create the runtime character representation used during runs.

#### File: `scripts/data_classes/character_instance.gd`

```gdscript
class_name CharacterInstance
extends RefCounted
# CharacterInstance - Runtime representation of a character during a run
# This is a CLONE of account data - modifications don't affect the account

# Persistent identifiers
var base_character_id: String = ""

# Runtime progression
var level: int = 1
var experience: int = 0

# Current state
var current_health: int = 0
var max_health: int = 0

# Calculated stats (base + rank boosts + items + skills)
var basic_attack_damage: int = 0
var speed: int = 0
var defense: int = 0
var income: int = 0

# Equipment and skills during this run
var equipped_items: Array[String] = []  # Item IDs from account
var equipped_item_upgrades: Array[String] = []  # Item upgrade IDs found during run
var learned_skills: Array[String] = []  # Skill IDs learned during run


func _init(char_data: Dictionary) -> void:
	"""
	Initialize from player's character data
	
	Args:
		char_data: Character data from PlayerAccount
	"""
	base_character_id = char_data["id"]
	
	# Get master data
	var char_master = GameData.get_character_by_id(base_character_id)
	if char_master.is_empty():
		push_error("CharacterInstance: Master data not found for %s" % base_character_id)
		return
	
	# Copy equipped items from account
	if char_data.has("equipped_items"):
		equipped_items = char_data["equipped_items"].duplicate()
	
	# Calculate initial stats
	_calculate_stats(char_master, char_data)
	
	# Set health to max
	current_health = max_health
	
	print("CharacterInstance created: %s (HP: %d, ATK: %d)" % [base_character_id, max_health, basic_attack_damage])


func _calculate_stats(char_master: Dictionary, char_data: Dictionary) -> void:
	"""Calculate all stats from base, rank boosts, and equipped items"""
	# Start with base stats
	var base_stats = char_master["base_stats"]
	max_health = base_stats["health"]
	basic_attack_damage = base_stats["basic_attack_damage"]
	speed = base_stats["speed"]
	defense = base_stats["defense"]
	income = base_stats["income"]
	
	# Apply rank stat boosts
	if char_master.has("rank_rewards"):
		for rank_reward in char_master["rank_rewards"]:
			if rank_reward["rank"] <= char_data["rank"]:
				if rank_reward.has("stat_boost"):
					for stat_name in rank_reward["stat_boost"]:
						var boost = rank_reward["stat_boost"][stat_name]
						match stat_name:
							"health":
								max_health += boost
							"basic_attack_damage":
								basic_attack_damage += boost
							"speed":
								speed += boost
							"defense":
								defense += boost
							"income":
								income += boost
	
	# Apply equipped items
	for item_id in equipped_items:
		_apply_item_modifiers(item_id)


func _apply_item_modifiers(item_id: String) -> void:
	"""Apply stat modifiers from an item"""
	var item_data = GameData.get_item_by_id(item_id)
	if item_data.is_empty():
		return
	
	if item_data.has("stat_modifiers"):
		for stat_name in item_data["stat_modifiers"]:
			var modifier = item_data["stat_modifiers"][stat_name]
			match stat_name:
				"health":
					max_health += modifier
				"basic_attack_damage":
					basic_attack_damage += modifier
				"speed":
					speed += modifier
				"defense":
					defense += modifier
				"income":
					income += modifier


func add_experience(xp: int) -> bool:
	"""
	Add experience, returns true if leveled up
	Level ups happen every 100 XP for now
	"""
	experience += xp
	var xp_per_level = 100
	
	if experience >= xp_per_level:
		experience -= xp_per_level
		level += 1
		print("CharacterInstance: %s leveled up to %d!" % [base_character_id, level])
		return true
	
	return false


func learn_skill(skill_id: String) -> bool:
	"""Learn a new skill during the run"""
	if skill_id in learned_skills:
		push_warning("CharacterInstance: Skill already learned: %s" % skill_id)
		return false
	
	# Check level requirement
	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		return false
	
	if skill_data.has("level_requirement"):
		if level < skill_data["level_requirement"]:
			push_warning("CharacterInstance: Level too low for skill %s (requires %d)" % [skill_id, skill_data["level_requirement"]])
			return false
	
	learned_skills.append(skill_id)
	_apply_skill_effects(skill_id)
	print("CharacterInstance: %s learned skill: %s" % [base_character_id, skill_id])
	return true


func _apply_skill_effects(skill_id: String) -> void:
	"""Apply skill effects to stats"""
	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		return
	
	if skill_data.has("effects"):
		for effect in skill_data["effects"]:
			var effect_type = effect["type"]
			var stat = effect["stat"]
			var value = effect["value"]
			
			match effect_type:
				"stat_add":
					_modify_stat(stat, value, false)
				"stat_multiply":
					_modify_stat(stat, value, true)


func _modify_stat(stat_name: String, value: float, multiply: bool) -> void:
	"""Modify a stat (used by skills)"""
	match stat_name:
		"health":
			if multiply:
				max_health = int(max_health * value)
			else:
				max_health += int(value)
		"basic_attack_damage":
			if multiply:
				basic_attack_damage = int(basic_attack_damage * value)
			else:
				basic_attack_damage += int(value)
		"speed":
			if multiply:
				speed = int(speed * value)
			else:
				speed += int(value)
		"defense":
			if multiply:
				defense = int(defense * value)
			else:
				defense += int(value)


func equip_item_upgrade(item_upgrade_id: String) -> bool:
	"""
	Equip an item upgrade found during the run
	This REPLACES the item in the same slot
	"""
	var upgrade_data = GameData.get_item_upgrade_by_id(item_upgrade_id)
	if upgrade_data.is_empty():
		return false
	
	# Check level requirement
	if upgrade_data.has("level_requirement"):
		if level < upgrade_data["level_requirement"]:
			push_warning("CharacterInstance: Level too low for upgrade (requires %d)" % upgrade_data["level_requirement"])
			return false
	
	var replaces_slot = upgrade_data["replaces_slot"]
	
	# Remove existing item in that slot
	for item_id in equipped_items:
		var item_data = GameData.get_item_by_id(item_id)
		if item_data["slot"] == replaces_slot:
			equipped_items.erase(item_id)
			_remove_item_modifiers(item_id)
			print("CharacterInstance: Replaced %s with upgrade %s" % [item_id, item_upgrade_id])
			break
	
	# Remove existing upgrade in that slot
	for upgrade_id in equipped_item_upgrades:
		var existing_upgrade = GameData.get_item_upgrade_by_id(upgrade_id)
		if existing_upgrade["replaces_slot"] == replaces_slot:
			equipped_item_upgrades.erase(upgrade_id)
			_remove_item_upgrade_modifiers(upgrade_id)
			break
	
	# Equip new upgrade
	equipped_item_upgrades.append(item_upgrade_id)
	_apply_item_upgrade_modifiers(item_upgrade_id)
	
	return true


func _apply_item_upgrade_modifiers(upgrade_id: String) -> void:
	"""Apply stat modifiers from an item upgrade"""
	var upgrade_data = GameData.get_item_upgrade_by_id(upgrade_id)
	if upgrade_data.is_empty():
		return
	
	if upgrade_data.has("stat_modifiers"):
		for stat_name in upgrade_data["stat_modifiers"]:
			var modifier = upgrade_data["stat_modifiers"][stat_name]
			match stat_name:
				"health":
					max_health += modifier
				"basic_attack_damage":
					basic_attack_damage += modifier
				"speed":
					speed += modifier
				"defense":
					defense += modifier


func _remove_item_modifiers(item_id: String) -> void:
	"""Remove stat modifiers from an item"""
	var item_data = GameData.get_item_by_id(item_id)
	if item_data.is_empty():
		return
	
	if item_data.has("stat_modifiers"):
		for stat_name in item_data["stat_modifiers"]:
			var modifier = item_data["stat_modifiers"][stat_name]
			match stat_name:
				"health":
					max_health -= modifier
				"basic_attack_damage":
					basic_attack_damage -= modifier
				"speed":
					speed -= modifier
				"defense":
					defense -= modifier


func _remove_item_upgrade_modifiers(upgrade_id: String) -> void:
	"""Remove stat modifiers from an item upgrade"""
	var upgrade_data = GameData.get_item_upgrade_by_id(upgrade_id)
	if upgrade_data.is_empty():
		return
	
	if upgrade_data.has("stat_modifiers"):
		for stat_name in upgrade_data["stat_modifiers"]:
			var modifier = upgrade_data["stat_modifiers"][stat_name]
			match stat_name:
				"health":
					max_health -= modifier
				"basic_attack_damage":
					basic_attack_damage -= modifier
				"speed":
					speed -= modifier
				"defense":
					defense -= modifier


func take_damage(amount: int) -> void:
	"""Take damage, clamped to 0"""
	current_health = max(0, current_health - amount)
	if current_health == 0:
		print("CharacterInstance: %s has fallen!" % base_character_id)


func heal(amount: int) -> void:
	"""Heal, clamped to max health"""
	current_health = min(max_health, current_health + amount)


func is_alive() -> bool:
	"""Check if character is still alive"""
	return current_health > 0


func to_dict() -> Dictionary:
	"""Serialize to dictionary for saving"""
	return {
		"base_character_id": base_character_id,
		"level": level,
		"experience": experience,
		"current_health": current_health,
		"max_health": max_health,
		"basic_attack_damage": basic_attack_damage,
		"speed": speed,
		"defense": defense,
		"income": income,
		"equipped_items": equipped_items,
		"equipped_item_upgrades": equipped_item_upgrades,
		"learned_skills": learned_skills
	}


static func from_dict(data: Dictionary) -> CharacterInstance:
	"""Deserialize from dictionary (for loading saves)"""
	# This is a simplified version - we need to reconstruct properly
	# For now, this is a placeholder
	var instance = CharacterInstance.new({
		"id": data["base_character_id"],
		"equipped_items": data["equipped_items"]
	})
	
	# Restore runtime state
	instance.level = data["level"]
	instance.experience = data["experience"]
	instance.current_health = data["current_health"]
	instance.max_health = data["max_health"]
	instance.basic_attack_damage = data["basic_attack_damage"]
	instance.speed = data["speed"]
	instance.defense = data["defense"]
	instance.income = data["income"]
	instance.equipped_item_upgrades = data["equipped_item_upgrades"]
	instance.learned_skills = data["learned_skills"]
	
	return instance


func get_character_name() -> String:
	"""Get the character's name from master data"""
	var char_master = GameData.get_character_by_id(base_character_id)
	if char_master.has("name"):
		return char_master["name"]
	return "Unknown"
```

**Claude Code Directive**:
```
Create the CharacterInstance class. This is critical - it's the runtime 
representation of characters during runs. Make sure:
- Stats are properly calculated from base + rank + items
- Skills and item upgrades can be added during runs
- Serialization works for save/load
- No modifications affect the account data (this is a clone)

This class will be heavily used in later phases.
```

---

### Task 2: Create RunManager Singleton

Create the singleton that manages active run state.

#### File: `autoloads/run_manager.gd`

```gdscript
extends Node
# RunManager Singleton
# Manages active run state, team, progression, and save/load

signal run_started
signal round_changed(new_round: int)
signal reputation_changed(new_reputation: int)
signal gold_changed(new_gold: int)

# Save file path
const SAVE_PATH = "user://active_run.json"

# Run state
var is_run_active: bool = false
var run_id: String = ""

# Team
var team: Array[CharacterInstance] = []

# Progression
var current_round: int = 0
var reputation: int = 20
var wins: int = 0
var losses: int = 0
var starting_gold: int = 0
var current_gold: int = 0

# History (for statistics)
var encounter_history: Array = []


func _ready() -> void:
	# Check for existing run on startup
	pass  # Will be called by main scene


func has_active_run() -> bool:
	"""Check if there's a saved run to resume"""
	return FileAccess.file_exists(SAVE_PATH)


func start_new_run(drafted_character_ids: Array) -> void:
	"""
	Start a new run with drafted characters
	
	Args:
		drafted_character_ids: Array of 3 character IDs from PlayerAccount
	"""
	if drafted_character_ids.size() != 3:
		push_error("RunManager: Must draft exactly 3 characters")
		return
	
	print("RunManager: Starting new run with characters: %s" % str(drafted_character_ids))
	
	# Generate run ID
	run_id = "run_%d" % Time.get_unix_time_from_system()
	
	# Initialize team
	team.clear()
	starting_gold = 0
	
	for char_id in drafted_character_ids:
		var char_data = PlayerAccount.get_character_data(char_id)
		if char_data.is_empty():
			push_error("RunManager: Character data not found: %s" % char_id)
			continue
		
		# Create runtime instance
		var char_instance = CharacterInstance.new(char_data)
		team.append(char_instance)
		
		# Add income to starting gold
		starting_gold += char_instance.income
	
	# Initialize run state
	current_round = 0
	reputation = 20
	wins = 0
	losses = 0
	current_gold = starting_gold
	encounter_history.clear()
	is_run_active = true
	
	print("RunManager: Run started with %d characters, starting gold: %d" % [team.size(), starting_gold])
	
	# Save initial state
	save_run_state()
	
	run_started.emit()


func save_run_state() -> void:
	"""Save current run state to file"""
	if not is_run_active:
		return
	
	var save_data = {
		"run_id": run_id,
		"round": current_round,
		"reputation": reputation,
		"wins": wins,
		"losses": losses,
		"starting_gold": starting_gold,
		"current_gold": current_gold,
		"team": [],
		"encounter_history": encounter_history
	}
	
	# Serialize team
	for char_instance in team:
		save_data["team"].append(char_instance.to_dict())
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("RunManager: Could not save run state")
		return
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("RunManager: Run state saved (Round %d, Reputation %d)" % [current_round, reputation])


func load_run_state() -> bool:
	"""Load run state from file, returns true if successful"""
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("RunManager: Could not load run state")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("RunManager: Failed to parse run save file")
		return false
	
	var save_data = json.data
	
	# Restore run state
	run_id = save_data["run_id"]
	current_round = save_data["round"]
	reputation = save_data["reputation"]
	wins = save_data["wins"]
	losses = save_data["losses"]
	starting_gold = save_data["starting_gold"]
	current_gold = save_data["current_gold"]
	encounter_history = save_data["encounter_history"]
	
	# Restore team
	team.clear()
	for char_data in save_data["team"]:
		var char_instance = CharacterInstance.from_dict(char_data)
		team.append(char_instance)
	
	is_run_active = true
	
	print("RunManager: Run state loaded (Round %d, %d characters)" % [current_round, team.size()])
	return true


func end_run(victory: bool) -> void:
	"""
	End the current run and award rewards
	
	Args:
		victory: True if player won (10 combats), false if defeated (0 reputation)
	"""
	print("RunManager: Ending run - %s" % ("VICTORY" if victory else "DEFEAT"))
	
	# Award character rank XP (placeholder: 50 XP per character)
	# TODO: Scale based on performance
	for char_instance in team:
		PlayerAccount.add_character_experience(char_instance.base_character_id, 50)
	
	# Award gems (placeholder)
	if victory:
		PlayerAccount.add_gems(100)
	else:
		PlayerAccount.add_gems(25)
	
	# Clear run state
	_clear_run_state()
	
	print("RunManager: Run ended, rewards distributed")


func _clear_run_state() -> void:
	"""Clear all run state and delete save file"""
	is_run_active = false
	run_id = ""
	team.clear()
	current_round = 0
	reputation = 20
	wins = 0
	losses = 0
	starting_gold = 0
	current_gold = 0
	encounter_history.clear()
	
	# Delete save file
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("RunManager: Run save file deleted")


# Getters

func get_team() -> Array[CharacterInstance]:
	return team


func get_round() -> int:
	return current_round


func get_reputation() -> int:
	return reputation


func get_wins() -> int:
	return wins


func get_losses() -> int:
	return losses


func get_gold() -> int:
	return current_gold


# Run progression

func advance_round() -> void:
	"""Move to next round (after encounter + combat)"""
	current_round += 1
	round_changed.emit(current_round)
	save_run_state()


func add_gold(amount: int) -> void:
	"""Add gold (from combat rewards, etc.)"""
	current_gold += amount
	gold_changed.emit(current_gold)
	save_run_state()


func spend_gold(amount: int) -> bool:
	"""Spend gold (returns false if not enough)"""
	if current_gold >= amount:
		current_gold -= amount
		gold_changed.emit(current_gold)
		save_run_state()
		return true
	return false


func add_win() -> void:
	"""Record a combat victory"""
	wins += 1
	# Award gold and XP (placeholder)
	add_gold(20)
	for char_instance in team:
		char_instance.add_experience(30)  # TODO: Placeholder XP distribution
	save_run_state()


func add_loss() -> void:
	"""Record a combat loss"""
	losses += 1
	save_run_state()


func lose_reputation(amount: int) -> void:
	"""Lose reputation (from combat loss)"""
	reputation = max(0, reputation - amount)
	reputation_changed.emit(reputation)
	print("RunManager: Lost %d reputation (now %d)" % [amount, reputation])
	save_run_state()


func is_run_over() -> bool:
	"""Check if run is over (win or loss condition met)"""
	if wins >= 10:
		return true  # Victory
	if reputation <= 0:
		return true  # Defeat
	return false


func did_player_win() -> bool:
	"""Check if player won (only valid if is_run_over() is true)"""
	return wins >= 10
```

**Claude Code Directive**:
```
Create the RunManager singleton. This is the central hub for all run state.
Make sure:
- Team is properly created from drafted characters
- Starting gold is sum of character income values
- Save/load system works correctly
- Win/loss conditions are checked properly
- All state changes trigger saves

Add this to Project Settings -> Autoload after creation.
```

---

### Task 3: Create Draft Scene

Create the character drafting interface.

#### File: `scenes/ui/draft.tscn`

Create a scene with this structure:
```
Draft (Control)
├── Background (ColorRect) - Dark background
├── MainContainer (VBoxContainer) - Center aligned
│   ├── TopSection (VBoxContainer)
│   │   ├── InstructionLabel (Label) - "SELECT CHARACTER 1 OF 3"
│   │   └── SelectedDisplay (HBoxContainer) - Shows drafted characters
│   │       └── (CharacterCard instances added dynamically)
│   ├── Spacer (Control)
│   ├── OptionsTitle (Label) - "AVAILABLE CHARACTERS"
│   ├── OptionsContainer (HBoxContainer) - 3 character options
│   │   └── (DraftOption panels added dynamically)
│   ├── Spacer2 (Control)
│   └── BottomButtons (HBoxContainer)
│       ├── RerollButton (Button) - "REROLL (🎫)"
│       └── ConfirmButton (Button) - "START RUN" (initially hidden)
└── BackButton (Button) - Top-left corner
```

#### File: `scenes/ui/draft.gd`

```gdscript
extends Control
# Draft - Character selection for starting a run

@onready var instruction_label = $MainContainer/TopSection/InstructionLabel
@onready var selected_display = $MainContainer/TopSection/SelectedDisplay
@onready var options_container = $MainContainer/OptionsContainer
@onready var reroll_button = $MainContainer/BottomButtons/RerollButton
@onready var confirm_button = $MainContainer/BottomButtons/ConfirmButton
@onready var back_button = $BackButton

# Preload scenes
const CharacterCardScene = preload("res://scenes/components/character_card.tscn")

# Draft state
var drafted_characters: Array = []  # Array of character data dictionaries
var current_options: Array = []  # Current 3 options
var selection_count: int = 0  # How many characters selected (0-3)


func _ready() -> void:
	reroll_button.pressed.connect(_on_reroll_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	confirm_button.visible = false
	
	_generate_options()
	_update_instruction()
	_update_reroll_button()


func _generate_options() -> void:
	"""Generate 3 character options (2 owned, 1 random)"""
	# Clear existing options
	for child in options_container.get_children():
		child.queue_free()
	
	current_options.clear()
	
	# Get owned characters
	var owned_chars = PlayerAccount.get_unlocked_characters()
	var all_chars = GameData.get_all_characters()
	
	if owned_chars.size() < 2:
		push_error("Draft: Player must have at least 2 owned characters")
		return
	
	# Generate 2 owned options
	var owned_pool = owned_chars.duplicate()
	owned_pool.shuffle()
	
	for i in range(2):
		if owned_pool.size() > 0:
			current_options.append({
				"char_data": owned_pool.pop_front(),
				"is_owned": true,
				"unlock_cost": 0
			})
	
	# Generate 1 random option (may be owned or not)
	all_chars.shuffle()
	var random_char = all_chars[0]
	var random_char_id = random_char["id"]
	var is_owned = PlayerAccount.is_character_unlocked(random_char_id)
	
	# Get character data
	var random_char_data = null
	if is_owned:
		random_char_data = PlayerAccount.get_character_data(random_char_id)
	else:
		# Create temporary data for display
		random_char_data = {
			"id": random_char_id,
			"unlocked": false,
			"rank": 1,
			"experience": 0,
			"equipped_items": [],
			"unlocked_items": [],
			"unlocked_item_upgrades": [],
			"unlocked_skills": []
		}
	
	current_options.append({
		"char_data": random_char_data,
		"is_owned": is_owned,
		"unlock_cost": 500  # Placeholder cost
	})
	
	# Create UI for each option
	for option in current_options:
		_create_option_panel(option)
	
	print("Draft: Generated %d options" % current_options.size())


func _create_option_panel(option: Dictionary) -> void:
	"""Create a selectable character option panel"""
	var panel = PanelContainer.new()
	options_container.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Character card
	var card = CharacterCardScene.instantiate()
	vbox.add_child(card)
	card.setup(option["char_data"], true)  # Show with equipped items
	card.set_clickable(false)  # Will use button instead
	
	# Select/Unlock button
	var button = Button.new()
	vbox.add_child(button)
	
	if option["is_owned"]:
		button.text = "SELECT"
		button.pressed.connect(_on_character_selected.bind(option["char_data"]))
	else:
		button.text = "UNLOCK (%d 💎)" % option["unlock_cost"]
		button.pressed.connect(_on_unlock_and_select.bind(option["char_data"], option["unlock_cost"]))
	
	# Disable button if character already drafted
	if _is_character_drafted(option["char_data"]["id"]):
		button.disabled = true
		button.text = "SELECTED"


func _is_character_drafted(char_id: String) -> bool:
	"""Check if character is already in drafted array"""
	for char_data in drafted_characters:
		if char_data["id"] == char_id:
			return true
	return false


func _on_character_selected(char_data: Dictionary) -> void:
	"""Handle selecting an owned character"""
	if _is_character_drafted(char_data["id"]):
		print("Draft: Character already selected")
		return
	
	if drafted_characters.size() >= 3:
		print("Draft: Already have 3 characters")
		return
	
	drafted_characters.append(char_data)
	selection_count += 1
	
	print("Draft: Selected %s (%d/3)" % [char_data["id"], selection_count])
	
	_update_selected_display()
	_update_instruction()
	_regenerate_options()
	
	if selection_count == 3:
		_show_confirm_button()


func _on_unlock_and_select(char_data: Dictionary, cost: int) -> void:
	"""Handle unlocking and selecting a character"""
	if drafted_characters.size() >= 3:
		print("Draft: Already have 3 characters")
		return
	
	# Attempt to unlock
	var success = PlayerAccount.unlock_character(char_data["id"], cost)
	if not success:
		print("Draft: Failed to unlock character (not enough gems)")
		return
	
	# Now select the newly unlocked character
	var unlocked_char_data = PlayerAccount.get_character_data(char_data["id"])
	_on_character_selected(unlocked_char_data)


func _update_selected_display() -> void:
	"""Update the display showing drafted characters"""
	# Clear existing
	for child in selected_display.get_children():
		child.queue_free()
	
	# Add card for each drafted character
	for char_data in drafted_characters:
		var card = CharacterCardScene.instantiate()
		selected_display.add_child(card)
		card.setup(char_data, true)
		card.set_clickable(false)
		card.custom_minimum_size = Vector2(120, 180)  # Smaller for display


func _update_instruction() -> void:
	"""Update instruction text"""
	if selection_count < 3:
		instruction_label.text = "SELECT CHARACTER %d OF 3" % (selection_count + 1)
	else:
		instruction_label.text = "TEAM COMPLETE - READY TO START"


func _regenerate_options() -> void:
	"""Regenerate options after a selection"""
	_generate_options()


func _show_confirm_button() -> void:
	"""Show the confirm button when 3 characters are selected"""
	confirm_button.visible = true
	reroll_button.visible = false  # Hide reroll when ready to confirm


func _on_reroll_pressed() -> void:
	"""Handle reroll button press"""
	if PlayerAccount.spend_reroll_token():
		print("Draft: Rerolling options...")
		_generate_options()
		_update_reroll_button()
	else:
		print("Draft: No reroll tokens available")


func _update_reroll_button() -> void:
	"""Update reroll button text with token count"""
	var tokens = PlayerAccount.get_reroll_tokens()
	reroll_button.text = "REROLL (🎫 %d)" % tokens
	reroll_button.disabled = (tokens == 0)


func _on_confirm_pressed() -> void:
	"""Start the run with drafted characters"""
	if drafted_characters.size() != 3:
		push_error("Draft: Must select exactly 3 characters")
		return
	
	print("Draft: Starting run with drafted team...")
	
	# Extract character IDs
	var char_ids = []
	for char_data in drafted_characters:
		char_ids.append(char_data["id"])
	
	# Start run
	RunManager.start_new_run(char_ids)
	
	# Navigate to run view
	# TODO: Will create run_view scene in Phase 4
	print("Draft: Run started! (Would navigate to run_view here)")
	# For now, just go back to main menu
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/main_menu.tscn")


func _on_back_pressed() -> void:
	"""Return to main menu"""
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/main_menu.tscn")
```

**Claude Code Directive**:
```
Create the Draft scene with character selection logic.
Make sure:
- 2 owned characters + 1 random character are shown
- Random character may require gem unlock
- Can't select same character twice
- Reroll button works (spends token, regenerates options)
- Selected characters display at top
- Confirm button only appears when 3 selected
- Run starts correctly when confirmed

This is a complex UI with lots of state management - test thoroughly!
```

---

### Task 4: Connect Draft to Main Menu

Update main menu to start the draft process.

#### File: `scenes/ui/main_menu.gd` (UPDATE)

Update the `_ready()` method and `_on_play_pressed()` method:

```gdscript
func _ready() -> void:
	# Update currency display
	_update_currency_display()
	
	# Connect signals
	PlayerAccount.gems_changed.connect(_on_gems_changed)
	PlayerAccount.reroll_tokens_changed.connect(_on_reroll_tokens_changed)
	
	# Connect buttons
	play_button.pressed.connect(_on_play_pressed)
	collection_button.pressed.connect(_on_collection_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Check for active run to resume
	if RunManager.has_active_run():
		play_button.text = "RESUME RUN"
	else:
		play_button.text = "PLAY"
	
	# Focus play button
	play_button.grab_focus()


func _on_play_pressed() -> void:
	# Check if there's an active run to resume
	if RunManager.has_active_run():
		print("MainMenu: Resuming active run...")
		RunManager.load_run_state()
		# TODO: Navigate to run_view scene (Phase 4)
		print("MainMenu: Would navigate to run_view here")
	else:
		print("MainMenu: Starting new run (draft)...")
		get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/draft.tscn")
```

**Claude Code Directive**:
```
Update main_menu.gd to check for active runs and navigate to draft.
The PLAY button should change to "RESUME RUN" if a save exists.
For now, resume just loads the state and prints (we'll implement run_view in Phase 4).
```

---

### Task 5: Add Test Helper for Reroll Tokens

For testing purposes, add a temporary way to give yourself reroll tokens.

#### File: `scenes/ui/main_menu.gd` (UPDATE)

Add this method and connect it to a debug key:

```gdscript
func _input(event: InputEvent) -> void:
	# Debug: Press T to add reroll token
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			PlayerAccount.add_reroll_token()
			print("MainMenu: Added reroll token (Debug)")
```

**Claude Code Directive**:
```
Add a simple debug input to give reroll tokens for testing.
Press 'T' key to add a token.
This will be removed or disabled later.
```

---

## Configuration Steps (Manual)

After Claude Code creates all the files, you need to manually configure Godot:

### Add RunManager Autoload

Open Godot and go to: **Project → Project Settings → Autoload**

Add:

| Path | Node Name |
|------|-----------|
| `res://autoloads/run_manager.gd` | `RunManager` |

Place it after PlayerAccount in the autoload order.

---

## Testing Instructions

### Test 1: Draft Scene Loads

1. Launch game
2. Click **PLAY** button
3. **Expected Result**:
   - Draft scene loads
   - Shows instruction "SELECT CHARACTER 1 OF 3"
   - Shows 3 character option panels
   - Each panel has a character card and SELECT/UNLOCK button
   - Reroll button shows token count (0)
   - No confirm button visible

**If it fails**:
- Check scene path in main_menu.gd
- Verify draft.tscn exists and is saved
- Check console for errors

### Test 2: Character Options Generated Correctly

1. In draft scene, examine the 3 options
2. **Expected Result**:
   - First 2 characters are from your owned collection (5 starting characters)
   - Third character may be owned or unowned
   - Owned characters have "SELECT" button
   - Unowned characters have "UNLOCK (500 💎)" button
   - Character cards show correct stats

**If options are wrong**:
- Check _generate_options() logic
- Verify PlayerAccount.get_unlocked_characters() works
- Check GameData.get_all_characters() returns data

### Test 3: Character Selection Works

1. Click **SELECT** on first character
2. **Expected Result**:
   - Character appears in "Selected Display" at top
   - Instruction changes to "SELECT CHARACTER 2 OF 3"
   - Options regenerate (3 new options, excluding selected character)
   - Selected character's button changes to "SELECTED" and is disabled
3. Select 2 more characters
4. **Expected Result**:
   - All 3 characters show at top
   - Instruction changes to "TEAM COMPLETE - READY TO START"
   - Confirm button appears: "START RUN"
   - Reroll button disappears

**If selection doesn't work**:
- Check _on_character_selected() is being called
- Verify drafted_characters array is updating
- Check _update_selected_display() logic

### Test 4: Cannot Select Same Character Twice

1. Select a character
2. After options regenerate, try to select the same character again
3. **Expected Result**:
   - If the same character appears in new options, their button is disabled
   - Shows "SELECTED" instead of "SELECT"
   - Cannot click it

**If duplicate selection is possible**:
- Check _is_character_drafted() logic
- Verify button disabling in _create_option_panel()

### Test 5: Reroll System

1. Press 'T' key to add reroll tokens (debug feature)
2. **Expected Result**: Reroll button updates to show "REROLL (🎫 1)"
3. Click **REROLL** button
4. **Expected Result**:
   - Token count decreases by 1
   - New 3 character options generated
   - Previously selected characters remain selected
   - Button updates to "REROLL (🎫 0)"
   - Button becomes disabled (no tokens left)

**If reroll doesn't work**:
- Check PlayerAccount.spend_reroll_token()
- Verify _on_reroll_pressed() is connected
- Check _update_reroll_button() updates correctly

### Test 6: Unlock Character with Gems

1. Ensure you have at least 500 gems
2. Find an option with "UNLOCK (500 💎)" button
3. Click the unlock button
4. **Expected Result**:
   - Gems decrease by 500
   - Character becomes unlocked in PlayerAccount
   - Character is automatically selected for draft
   - Character appears in selected display
   - Can now find this character in Collection screen

**If unlock doesn't work**:
- Check PlayerAccount.unlock_character() logic
- Verify gems are properly deducted
- Check that character data is created correctly
- Verify _on_unlock_and_select() calls selection after unlock

### Test 7: Start Run

1. Draft 3 characters
2. Click **START RUN** button
3. **Expected Result**:
   - Console prints run start information
   - Shows character IDs and starting gold
   - RunManager creates team of 3 CharacterInstance objects
   - active_run.json file created in user:// directory
   - Returns to main menu (temporary, until Phase 4)
   - PLAY button changes to "RESUME RUN"

**If run doesn't start**:
- Check RunManager.start_new_run() is called
- Verify CharacterInstance is created correctly
- Check save_run_state() works
- Look for errors in console

### Test 8: Run State Saved Correctly

1. After starting a run, close the game
2. Check user:// directory for active_run.json
3. Open the file and verify:
   - run_id exists
   - round is 0
   - reputation is 20
   - wins and losses are 0
   - starting_gold equals sum of character income (should be 9-15 depending on characters)
   - current_gold equals starting_gold
   - team array has 3 character objects with correct data
4. **Expected Result**: All data is present and correct

**If save is wrong**:
- Check to_dict() in CharacterInstance
- Verify save_run_state() in RunManager
- Check JSON structure

### Test 9: Resume Run Detection

1. With an active run saved, relaunch game
2. **Expected Result**:
   - Main menu PLAY button says "RESUME RUN"
3. Click **RESUME RUN**
4. **Expected Result**:
   - Console shows "Resuming active run..."
   - RunManager loads run state
   - Console shows run data (round, characters, etc.)
   - Returns to main menu (temporary, until we build run_view)

**If resume doesn't work**:
- Check has_active_run() returns true
- Verify load_run_state() works
- Check from_dict() in CharacterInstance
- Look for parsing errors

### Test 10: Character Stats Calculated Correctly

1. Draft specific characters and check their stats
2. Example: Draft Warrior (ATK 10) with Rusty Sword (+3 ATK)
3. After run starts, check console output or add debug prints
4. **Expected Result**:
   - Warrior's CharacterInstance has basic_attack_damage = 13
   - Max health and current health match
   - All stats properly calculated from base + rank + items

**If stats are wrong**:
- Check _calculate_stats() in CharacterInstance
- Verify item modifiers are applied
- Check rank boosts are applied correctly
- Add print statements to debug calculation

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
git commit -m "Phase 3: Draft System

- Created CharacterInstance data class for runtime characters
- Implemented RunManager singleton for run state management
- Created Draft scene with 3-character selection
- Implemented reroll system with token spending
- Character unlock during draft with gem cost
- Run initialization with proper team and starting gold
- Save/load system for active runs (mid-run persistence)
- Resume run detection on main menu
- Stat calculation includes base + rank + equipped items
- All tests passing: draft, select, reroll, unlock, start, save, resume"

# Optional: Tag this milestone
git tag -a v0.3-phase3 -m "Phase 3 Complete: Draft System"
```

---

## Success Criteria

Phase 3 is complete when ALL of the following are true:

- ✅ Draft scene displays with 3 character options
- ✅ 2 options from owned characters, 1 random (may be unowned)
- ✅ Can select owned characters
- ✅ Can unlock and select unowned characters with gems
- ✅ Cannot select same character twice
- ✅ Selected characters display at top
- ✅ Reroll button works (spends token, regenerates options)
- ✅ Confirm button appears only when 3 characters selected
- ✅ Starting run creates RunManager state with team
- ✅ Starting gold equals sum of character income
- ✅ Run state saves to active_run.json
- ✅ Main menu detects active run (RESUME RUN button)
- ✅ Resume run loads state correctly
- ✅ CharacterInstance stats calculated correctly (base + rank + items)
- ✅ No console errors during any operation
- ✅ Git commit created with all Phase 3 files

---

## Common Issues & Solutions

### Issue: CharacterInstance not found error
**Solution**:
- Make sure class_name is defined at top of character_instance.gd
- Verify the file is in scripts/data_classes/ folder
- Try closing and reopening Godot to refresh script cache

### Issue: Draft options show wrong characters
**Solution**:
- Check that PlayerAccount.get_unlocked_characters() returns correct data
- Verify GameData.get_all_characters() works
- Add print statements in _generate_options() to debug

### Issue: Selected character appears in new options
**Solution**:
- Check _is_character_drafted() logic
- Verify button disabling happens in _create_option_panel()
- Make sure drafted_characters array is properly maintained

### Issue: Reroll doesn't regenerate options
**Solution**:
- Verify PlayerAccount.spend_reroll_token() returns true
- Check that _generate_options() is called in _on_reroll_pressed()
- Make sure token count updates

### Issue: Run doesn't start properly
**Solution**:
- Check that 3 character IDs are passed to start_new_run()
- Verify CharacterInstance._init() doesn't error
- Check GameData has character master data
- Add print statements in RunManager.start_new_run()

### Issue: Stats don't calculate correctly
**Solution**:
- Add debug prints in CharacterInstance._calculate_stats()
- Verify item data has stat_modifiers
- Check rank_rewards are structured correctly
- Make sure equipped_items array is correct

### Issue: Save file is corrupted or won't load
**Solution**:
- Delete active_run.json manually and try again
- Check JSON structure in save_run_state()
- Verify to_dict() returns all required fields
- Test from_dict() with print statements

### Issue: Resume doesn't work
**Solution**:
- Verify active_run.json exists in user:// directory
- Check has_active_run() returns true
- Add prints in load_run_state() to see where it fails
- Verify CharacterInstance.from_dict() works correctly

---

## Next Steps

Once Phase 3 is complete and all tests pass:

1. Review `phase_04_run_infrastructure.md` for the next phase
2. Test thoroughly - this phase is critical for the rest of the game
3. Optional: Add more test data (characters, items) to expand draft variety

**Do not proceed to Phase 4 until all Phase 3 tests pass and the git commit is created.**

---

## Phase 3 Complete! 🎉

You now have:
- ✅ Runtime character system with proper stat calculation
- ✅ Run state management with save/load
- ✅ Complete draft system with selection and reroll
- ✅ Character unlock during draft
- ✅ Run initialization with team and resources
- ✅ Resume run detection and loading

Total new files created: ~3
Total lines of code: ~1000+
Estimated time: 4-6 hours

**Ready for Phase 4: Run Infrastructure (Run Loop, UI, Save System)**
