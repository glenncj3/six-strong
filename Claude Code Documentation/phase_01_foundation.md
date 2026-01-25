# Phase 1: Foundation

**Goal**: Data loading, account system, main menu  
**Duration**: Days 1-2  
**Deliverable**: Can launch game, see main menu, currencies persist

---

## Overview

Phase 1 establishes the core infrastructure:
- Project structure (folders and organization)
- Master data loading system (characters, items, skills from JSON)
- Player account system (progression, currencies, unlocks)
- Main menu UI with navigation
- Local save/load system (designed for future cloud migration)

By the end of Phase 1, you should be able to launch the game, see a functional main menu displaying your gems and reroll tokens, and have those currencies persist between game sessions.

---

## Prerequisites

- Fresh Godot 4.x project created
- Claude Code launched in project directory
- Git initialized: `git init && git add . && git commit -m "Initial Godot project"`
- Project closed in Godot editor (to avoid file conflicts)

---

## Implementation Tasks

### Task 1: Create Project Structure

Create the following folder structure:

```
res://
├── autoloads/
├── data/
│   ├── characters/
│   ├── items/
│   ├── skills/
│   └── encounters/
├── scenes/
│   ├── ui/
│   └── components/
├── scripts/
│   ├── data_classes/
│   └── encounters/
├── assets/
│   ├── characters/
│   ├── items/
│   ├── skills/
│   └── ui/
└── saves/
```

**Claude Code Directive**:
```
Create the complete folder structure for the project as specified in Phase 1.
Create all folders even if they're empty - we'll populate them soon.
```

---

### Task 2: Create Test Data Files

Create placeholder JSON files with minimal test data (2-3 characters, 5-6 items, 3-4 skills).

#### File: `data/characters/characters.json`

```json
{
  "characters": [
    {
      "id": "char_warrior_001",
      "name": "Brave Knight",
      "image_path": "res://assets/characters/knight.png",
      "base_stats": {
        "basic_attack_damage": 10,
        "speed": 5,
        "defense": 8,
        "health": 100,
        "income": 3
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_rusty_sword"}
          ]
        },
        {
          "rank": 2,
          "stat_boost": {"basic_attack_damage": 2},
          "rewards": [
            {"type": "skill", "id": "skill_power_strike", "level_requirement": 3}
          ]
        }
      ]
    },
    {
      "id": "char_mage_001",
      "name": "Mystic Sage",
      "image_path": "res://assets/characters/mage.png",
      "base_stats": {
        "basic_attack_damage": 15,
        "speed": 4,
        "defense": 3,
        "health": 70,
        "income": 4
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_wooden_staff"}
          ]
        }
      ]
    },
    {
      "id": "char_rogue_001",
      "name": "Shadow Thief",
      "image_path": "res://assets/characters/rogue.png",
      "base_stats": {
        "basic_attack_damage": 8,
        "speed": 10,
        "defense": 4,
        "health": 80,
        "income": 5
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_rusty_dagger"}
          ]
        }
      ]
    },
    {
      "id": "char_cleric_001",
      "name": "Holy Priest",
      "image_path": "res://assets/characters/cleric.png",
      "base_stats": {
        "basic_attack_damage": 6,
        "speed": 4,
        "defense": 6,
        "health": 90,
        "income": 3
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_prayer_book"}
          ]
        }
      ]
    },
    {
      "id": "char_ranger_001",
      "name": "Forest Scout",
      "image_path": "res://assets/characters/ranger.png",
      "base_stats": {
        "basic_attack_damage": 12,
        "speed": 7,
        "defense": 5,
        "health": 85,
        "income": 4
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_short_bow"}
          ]
        }
      ]
    }
  ]
}
```

#### File: `data/items/items.json`

```json
{
  "items": [
    {
      "id": "item_rusty_sword",
      "name": "Rusty Sword",
      "description": "A weathered blade. Better than nothing.",
      "image_path": "res://assets/items/rusty_sword.png",
      "stat_modifiers": {
        "basic_attack_damage": 3
      },
      "slot": "weapon"
    },
    {
      "id": "item_rusty_dagger",
      "name": "Rusty Dagger",
      "description": "A small, quick blade.",
      "image_path": "res://assets/items/rusty_dagger.png",
      "stat_modifiers": {
        "basic_attack_damage": 2,
        "speed": 1
      },
      "slot": "weapon"
    },
    {
      "id": "item_wooden_staff",
      "name": "Wooden Staff",
      "description": "A simple magical focus.",
      "image_path": "res://assets/items/wooden_staff.png",
      "stat_modifiers": {
        "basic_attack_damage": 4,
        "defense": 1
      },
      "slot": "weapon"
    },
    {
      "id": "item_prayer_book",
      "name": "Prayer Book",
      "description": "Divine protection through faith.",
      "image_path": "res://assets/items/prayer_book.png",
      "stat_modifiers": {
        "defense": 3,
        "health": 10
      },
      "slot": "weapon"
    },
    {
      "id": "item_short_bow",
      "name": "Short Bow",
      "description": "Quick and deadly at range.",
      "image_path": "res://assets/items/short_bow.png",
      "stat_modifiers": {
        "basic_attack_damage": 5,
        "speed": 2
      },
      "slot": "weapon"
    },
    {
      "id": "item_leather_armor",
      "name": "Leather Armor",
      "description": "Basic protection.",
      "image_path": "res://assets/items/leather_armor.png",
      "stat_modifiers": {
        "defense": 2,
        "health": 5
      },
      "slot": "armor"
    }
  ]
}
```

#### File: `data/items/item_upgrades.json`

```json
{
  "item_upgrades": [
    {
      "id": "itemup_flaming_sword",
      "name": "Flaming Sword",
      "description": "Replaces equipped weapon with burning fury.",
      "image_path": "res://assets/items/flaming_sword.png",
      "replaces_slot": "weapon",
      "stat_modifiers": {
        "basic_attack_damage": 15
      },
      "level_requirement": 4
    },
    {
      "id": "itemup_iron_sword",
      "name": "Iron Sword",
      "description": "A reliable, well-forged blade.",
      "image_path": "res://assets/items/iron_sword.png",
      "replaces_slot": "weapon",
      "stat_modifiers": {
        "basic_attack_damage": 8
      },
      "level_requirement": 2
    }
  ]
}
```

#### File: `data/skills/skills.json`

```json
{
  "skills": [
    {
      "id": "skill_power_strike",
      "name": "Power Strike",
      "description": "Increases attack damage by 20%.",
      "image_path": "res://assets/skills/power_strike.png",
      "effects": [
        {
          "type": "stat_multiply",
          "stat": "basic_attack_damage",
          "value": 1.2
        }
      ],
      "level_requirement": 3
    },
    {
      "id": "skill_dodge",
      "name": "Dodge",
      "description": "Increases speed by 15%.",
      "image_path": "res://assets/skills/dodge.png",
      "effects": [
        {
          "type": "stat_multiply",
          "stat": "speed",
          "value": 1.15
        }
      ],
      "level_requirement": 2
    },
    {
      "id": "skill_iron_skin",
      "name": "Iron Skin",
      "description": "Increases defense by 3.",
      "image_path": "res://assets/skills/iron_skin.png",
      "effects": [
        {
          "type": "stat_add",
          "stat": "defense",
          "value": 3
        }
      ],
      "level_requirement": 4
    },
    {
      "id": "skill_vitality",
      "name": "Vitality",
      "description": "Increases max health by 20.",
      "image_path": "res://assets/skills/vitality.png",
      "effects": [
        {
          "type": "stat_add",
          "stat": "health",
          "value": 20
        }
      ],
      "level_requirement": 1
    }
  ]
}
```

#### File: `data/encounters/encounter_types.json`

```json
{
  "encounter_types": [
    {
      "type": "shop",
      "name": "Traveling Merchant",
      "description": "Buy items and upgrades with gold.",
      "image_path": "res://assets/encounters/merchant.png"
    },
    {
      "type": "xp_reward",
      "name": "Training Dummy",
      "description": "Practice combat and gain experience.",
      "image_path": "res://assets/encounters/training.png"
    }
  ]
}
```

**Claude Code Directive**:
```
Create all the test data JSON files as specified above. These are placeholder 
data files - we'll expand them in later phases. Make sure JSON is valid and 
properly formatted.
```

---

### Task 3: Implement GameData Singleton

Create the master data loader that reads all JSON files and provides access to game content.

#### File: `autoloads/game_data.gd`

```gdscript
extends Node
# GameData Singleton
# Loads and caches all master data (characters, items, skills, encounters)
# This is the single source of truth for all game content definitions

# Cached data dictionaries
var characters: Dictionary = {}  # id -> character_data
var items: Dictionary = {}  # id -> item_data
var item_upgrades: Dictionary = {}  # id -> item_upgrade_data
var skills: Dictionary = {}  # id -> skill_data
var encounter_types: Array = []  # Array of encounter type definitions

# Data file paths
const CHARACTERS_PATH = "res://data/characters/characters.json"
const ITEMS_PATH = "res://data/items/items.json"
const ITEM_UPGRADES_PATH = "res://data/items/item_upgrades.json"
const SKILLS_PATH = "res://data/skills/skills.json"
const ENCOUNTERS_PATH = "res://data/encounters/encounter_types.json"


func _ready() -> void:
	load_all_data()


func load_all_data() -> void:
	"""Load all master data from JSON files"""
	print("GameData: Loading all master data...")
	
	_load_characters()
	_load_items()
	_load_item_upgrades()
	_load_skills()
	_load_encounter_types()
	
	print("GameData: All data loaded successfully")
	print("  - Characters: %d" % characters.size())
	print("  - Items: %d" % items.size())
	print("  - Item Upgrades: %d" % item_upgrades.size())
	print("  - Skills: %d" % skills.size())
	print("  - Encounter Types: %d" % encounter_types.size())


func _load_characters() -> void:
	var data = _load_json_file(CHARACTERS_PATH)
	if data and data.has("characters"):
		for char_data in data["characters"]:
			characters[char_data["id"]] = char_data


func _load_items() -> void:
	var data = _load_json_file(ITEMS_PATH)
	if data and data.has("items"):
		for item_data in data["items"]:
			items[item_data["id"]] = item_data


func _load_item_upgrades() -> void:
	var data = _load_json_file(ITEM_UPGRADES_PATH)
	if data and data.has("item_upgrades"):
		for item_data in data["item_upgrades"]:
			item_upgrades[item_data["id"]] = item_data


func _load_skills() -> void:
	var data = _load_json_file(SKILLS_PATH)
	if data and data.has("skills"):
		for skill_data in data["skills"]:
			skills[skill_data["id"]] = skill_data


func _load_encounter_types() -> void:
	var data = _load_json_file(ENCOUNTERS_PATH)
	if data and data.has("encounter_types"):
		encounter_types = data["encounter_types"]


func _load_json_file(path: String) -> Variant:
	"""Generic JSON file loader with error handling"""
	if not FileAccess.file_exists(path):
		push_error("GameData: File not found: %s" % path)
		return null
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameData: Could not open file: %s" % path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("GameData: JSON parse error in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	
	return json.data


# Public API for accessing game data

func get_character_by_id(id: String) -> Dictionary:
	"""Get character data by ID"""
	if characters.has(id):
		return characters[id]
	push_warning("GameData: Character not found: %s" % id)
	return {}


func get_item_by_id(id: String) -> Dictionary:
	"""Get item data by ID"""
	if items.has(id):
		return items[id]
	push_warning("GameData: Item not found: %s" % id)
	return {}


func get_item_upgrade_by_id(id: String) -> Dictionary:
	"""Get item upgrade data by ID"""
	if item_upgrades.has(id):
		return item_upgrades[id]
	push_warning("GameData: Item upgrade not found: %s" % id)
	return {}


func get_skill_by_id(id: String) -> Dictionary:
	"""Get skill data by ID"""
	if skills.has(id):
		return skills[id]
	push_warning("GameData: Skill not found: %s" % id)
	return {}


func get_all_characters() -> Array:
	"""Get array of all character data"""
	return characters.values()


func get_all_items() -> Array:
	"""Get array of all item data"""
	return items.values()


func get_all_item_upgrades() -> Array:
	"""Get array of all item upgrade data"""
	return item_upgrades.values()


func get_all_skills() -> Array:
	"""Get array of all skill data"""
	return skills.values()


func get_encounter_types() -> Array:
	"""Get array of all encounter type definitions"""
	return encounter_types
```

**Claude Code Directive**:
```
Implement the GameData singleton exactly as specified. This is a critical 
foundation piece - make sure all JSON loading has proper error handling and 
that the public API methods are clean and well-documented.
```

---

### Task 4: Implement PlayerAccount Singleton

Create the player progression system that tracks unlocks, currencies, and saves locally.

#### File: `autoloads/player_account.gd`

```gdscript
extends Node
# PlayerAccount Singleton
# Manages player progression, unlocks, currencies, and character collection
# TODO: Replace local save/load with cloud API calls in future

signal gems_changed(new_amount: int)
signal reroll_tokens_changed(new_amount: int)
signal character_unlocked(char_id: String)
signal character_ranked_up(char_id: String, new_rank: int)

# Save file path
# TODO: Replace with cloud service endpoint
const SAVE_PATH = "user://player_account.json"

# Player data structure
var player_data: Dictionary = {
	"player_id": "",
	"currencies": {
		"gems": 0,
		"reroll_tokens": 0
	},
	"characters": [],
	"unlocked_character_ids": []
}


func _ready() -> void:
	load_account()


func create_default_account() -> void:
	"""Create a new player account with starting characters unlocked"""
	print("PlayerAccount: Creating default account...")
	
	player_data["player_id"] = "player_%d" % Time.get_unix_time_from_system()
	player_data["currencies"]["gems"] = 1000  # Starting gems
	player_data["currencies"]["reroll_tokens"] = 0
	
	# Unlock 5 starting characters
	var starting_chars = ["char_warrior_001", "char_mage_001", "char_rogue_001", "char_cleric_001", "char_ranger_001"]
	for char_id in starting_chars:
		_create_character_data(char_id)
	
	save_account()
	print("PlayerAccount: Default account created with %d characters" % starting_chars.size())


func _create_character_data(char_id: String) -> void:
	"""Create character data entry in player account"""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("PlayerAccount: Cannot create character data - master data not found: %s" % char_id)
		return
	
	# Get rank 1 unlocked items
	var unlocked_items = []
	if char_master.has("rank_rewards") and char_master["rank_rewards"].size() > 0:
		var rank_1_rewards = char_master["rank_rewards"][0]
		if rank_1_rewards.has("rewards"):
			for reward in rank_1_rewards["rewards"]:
				if reward["type"] == "item":
					unlocked_items.append(reward["id"])
	
	var char_data = {
		"id": char_id,
		"unlocked": true,
		"rank": 1,
		"experience": 0,
		"equipped_items": [],
		"unlocked_items": unlocked_items,
		"unlocked_item_upgrades": [],
		"unlocked_skills": []
	}
	
	player_data["characters"].append(char_data)
	player_data["unlocked_character_ids"].append(char_id)


func save_account() -> void:
	"""Save player account to local JSON file"""
	# TODO: Replace with cloud API call
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PlayerAccount: Could not open save file for writing")
		return
	
	var json_string = JSON.stringify(player_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("PlayerAccount: Account saved to %s" % SAVE_PATH)


func load_account() -> void:
	"""Load player account from local JSON file"""
	# TODO: Replace with cloud API call
	if not FileAccess.file_exists(SAVE_PATH):
		print("PlayerAccount: No save file found, creating default account")
		create_default_account()
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("PlayerAccount: Could not open save file for reading")
		create_default_account()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("PlayerAccount: Failed to parse save file, creating default account")
		create_default_account()
		return
	
	player_data = json.data
	print("PlayerAccount: Account loaded successfully")
	print("  - Gems: %d" % player_data["currencies"]["gems"])
	print("  - Reroll Tokens: %d" % player_data["currencies"]["reroll_tokens"])
	print("  - Unlocked Characters: %d" % player_data["unlocked_character_ids"].size())


# Currency management

func get_gems() -> int:
	return player_data["currencies"]["gems"]


func get_reroll_tokens() -> int:
	return player_data["currencies"]["reroll_tokens"]


func add_gems(amount: int) -> void:
	player_data["currencies"]["gems"] += amount
	gems_changed.emit(player_data["currencies"]["gems"])
	save_account()


func spend_gems(amount: int) -> bool:
	if player_data["currencies"]["gems"] >= amount:
		player_data["currencies"]["gems"] -= amount
		gems_changed.emit(player_data["currencies"]["gems"])
		save_account()
		return true
	return false


func add_reroll_token() -> void:
	player_data["currencies"]["reroll_tokens"] += 1
	reroll_tokens_changed.emit(player_data["currencies"]["reroll_tokens"])
	save_account()


func spend_reroll_token() -> bool:
	if player_data["currencies"]["reroll_tokens"] > 0:
		player_data["currencies"]["reroll_tokens"] -= 1
		reroll_tokens_changed.emit(player_data["currencies"]["reroll_tokens"])
		save_account()
		return true
	return false


# Character collection management

func get_unlocked_characters() -> Array:
	"""Get array of all unlocked character data"""
	var unlocked = []
	for char_data in player_data["characters"]:
		if char_data["unlocked"]:
			unlocked.append(char_data)
	return unlocked


func get_character_data(char_id: String) -> Dictionary:
	"""Get player's data for a specific character"""
	for char_data in player_data["characters"]:
		if char_data["id"] == char_id:
			return char_data
	return {}


func is_character_unlocked(char_id: String) -> bool:
	return char_id in player_data["unlocked_character_ids"]


func unlock_character(char_id: String, cost: int) -> bool:
	"""Unlock a character by spending gems"""
	if is_character_unlocked(char_id):
		push_warning("PlayerAccount: Character already unlocked: %s" % char_id)
		return false
	
	if not spend_gems(cost):
		push_warning("PlayerAccount: Not enough gems to unlock character")
		return false
	
	_create_character_data(char_id)
	character_unlocked.emit(char_id)
	save_account()
	return true


# Item/Skill management

func equip_item(char_id: String, item_id: String) -> bool:
	"""Equip an item to a character"""
	var char_data = get_character_data(char_id)
	if char_data.is_empty():
		return false
	
	# Check if item is unlocked for this character
	if item_id not in char_data["unlocked_items"]:
		push_warning("PlayerAccount: Item not unlocked for character: %s" % item_id)
		return false
	
	# Get item slot
	var item_master = GameData.get_item_by_id(item_id)
	if item_master.is_empty():
		return false
	
	var slot = item_master["slot"]
	
	# Unequip any item in the same slot
	for equipped_id in char_data["equipped_items"]:
		var equipped_item = GameData.get_item_by_id(equipped_id)
		if equipped_item["slot"] == slot:
			char_data["equipped_items"].erase(equipped_id)
			break
	
	# Equip new item
	char_data["equipped_items"].append(item_id)
	save_account()
	return true


func unequip_item(char_id: String, item_id: String) -> bool:
	"""Unequip an item from a character"""
	var char_data = get_character_data(char_id)
	if char_data.is_empty():
		return false
	
	if item_id in char_data["equipped_items"]:
		char_data["equipped_items"].erase(item_id)
		save_account()
		return true
	
	return false


func add_character_experience(char_id: String, xp: int) -> void:
	"""Add experience to a character, may cause rank up"""
	var char_data = get_character_data(char_id)
	if char_data.is_empty():
		return
	
	char_data["experience"] += xp
	
	# Check for rank up (100 XP per rank for now)
	var xp_per_rank = 100
	while char_data["experience"] >= xp_per_rank:
		char_data["experience"] -= xp_per_rank
		char_data["rank"] += 1
		print("PlayerAccount: Character ranked up! %s is now rank %d" % [char_id, char_data["rank"]])
		_apply_rank_rewards(char_id, char_data["rank"])
		character_ranked_up.emit(char_id, char_data["rank"])
	
	save_account()


func _apply_rank_rewards(char_id: String, new_rank: int) -> void:
	"""Apply rewards for reaching a new rank"""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		return
	
	var char_data = get_character_data(char_id)
	
	# Find rewards for this rank
	if not char_master.has("rank_rewards"):
		return
	
	for rank_reward in char_master["rank_rewards"]:
		if rank_reward["rank"] == new_rank:
			print("PlayerAccount: Applying rank %d rewards for %s" % [new_rank, char_id])
			
			# Unlock items, skills, etc.
			if rank_reward.has("rewards"):
				for reward in rank_reward["rewards"]:
					match reward["type"]:
						"item":
							if reward["id"] not in char_data["unlocked_items"]:
								char_data["unlocked_items"].append(reward["id"])
								print("  - Unlocked item: %s" % reward["id"])
						"item_upgrade":
							if reward["id"] not in char_data["unlocked_item_upgrades"]:
								char_data["unlocked_item_upgrades"].append(reward["id"])
								print("  - Unlocked item upgrade: %s" % reward["id"])
						"skill":
							if reward["id"] not in char_data["unlocked_skills"]:
								char_data["unlocked_skills"].append(reward["id"])
								print("  - Unlocked skill: %s" % reward["id"])
			
			break


func unlock_content_for_character(char_id: String, content_type: String, content_id: String, cost: int) -> bool:
	"""Unlock an item, skill, or upgrade for a character by spending gems"""
	if not spend_gems(cost):
		return false
	
	var char_data = get_character_data(char_id)
	if char_data.is_empty():
		return false
	
	match content_type:
		"item":
			if content_id not in char_data["unlocked_items"]:
				char_data["unlocked_items"].append(content_id)
		"item_upgrade":
			if content_id not in char_data["unlocked_item_upgrades"]:
				char_data["unlocked_item_upgrades"].append(content_id)
		"skill":
			if content_id not in char_data["unlocked_skills"]:
				char_data["unlocked_skills"].append(content_id)
		_:
			push_error("PlayerAccount: Unknown content type: %s" % content_type)
			return false
	
	save_account()
	return true
```

**Claude Code Directive**:
```
Implement the PlayerAccount singleton exactly as specified. Pay special attention 
to the save/load system and the rank-up logic. Make sure all methods properly 
save after making changes. Add TODO comments for cloud migration points.
```

---

### Task 5: Create Main Scene with Scene Management

Create the entry point scene that handles scene transitions.

#### File: `scenes/main.tscn`

Create a scene with this structure:
```
Main (Node)
├── SceneContainer (Node)
└── TransitionLayer (CanvasLayer)
    └── ColorRect (ColorRect) - Black, full screen, initially transparent
```

#### File: `scenes/main.gd`

```gdscript
extends Node
# Main scene - entry point and scene manager

@onready var scene_container = $SceneContainer
@onready var transition_layer = $TransitionLayer/ColorRect

# Current loaded scene
var current_scene: Node = null

# Scene paths
const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"


func _ready() -> void:
	# Set up transition layer
	transition_layer.color = Color.BLACK
	transition_layer.modulate.a = 0
	
	# Wait for autoloads to initialize
	await get_tree().process_frame
	
	# Load main menu
	change_scene(MAIN_MENU_SCENE)


func change_scene(scene_path: String, fade: bool = true) -> void:
	"""Change to a new scene with optional fade transition"""
	if fade:
		await _fade_out()
	
	# Remove current scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	
	# Load new scene
	var new_scene = load(scene_path).instantiate()
	scene_container.add_child(new_scene)
	current_scene = new_scene
	
	if fade:
		await _fade_in()


func _fade_out() -> void:
	"""Fade to black"""
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 1.0, 0.3)
	await tween.finished


func _fade_in() -> void:
	"""Fade from black"""
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 0.0, 0.3)
	await tween.finished
```

**Claude Code Directive**:
```
Create main.tscn and attach main.gd. This is the root scene that will be set 
as the main scene in project settings. Make sure the ColorRect in TransitionLayer 
covers the full screen and has anchors set to fill the entire viewport.
```

---

### Task 6: Create Main Menu Scene

Create the main menu with currency display and navigation buttons.

#### File: `scenes/ui/main_menu.tscn`

Create a scene with this structure:
```
MainMenu (Control)
├── Background (ColorRect) - Dark blue/gray
├── MarginContainer
│   └── VBoxContainer
│       ├── Spacer (Control) - size_flags_vertical = EXPAND
│       ├── Title (Label) - "AUTO BATTLER" - Large font
│       ├── Spacer2 (Control)
│       ├── ButtonContainer (VBoxContainer)
│       │   ├── PlayButton (Button) - "PLAY"
│       │   ├── CollectionButton (Button) - "COLLECTION"
│       │   └── QuitButton (Button) - "QUIT"
│       └── Spacer3 (Control) - size_flags_vertical = EXPAND
└── CurrencyDisplay (MarginContainer) - Anchored top-right
    └── HBoxContainer
        ├── GemsLabel (Label) - "💎 1000"
        └── RerollTokensLabel (Label) - "🎫 0"
```

#### File: `scenes/ui/main_menu.gd`

```gdscript
extends Control
# Main Menu - entry point with navigation and currency display

@onready var gems_label = $CurrencyDisplay/HBoxContainer/GemsLabel
@onready var reroll_tokens_label = $CurrencyDisplay/HBoxContainer/RerollTokensLabel
@onready var play_button = $MarginContainer/VBoxContainer/ButtonContainer/PlayButton
@onready var collection_button = $MarginContainer/VBoxContainer/ButtonContainer/CollectionButton
@onready var quit_button = $MarginContainer/VBoxContainer/ButtonContainer/QuitButton


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
	
	# Focus play button
	play_button.grab_focus()


func _update_currency_display() -> void:
	gems_label.text = "💎 %d" % PlayerAccount.get_gems()
	reroll_tokens_label.text = "🎫 %d" % PlayerAccount.get_reroll_tokens()


func _on_gems_changed(new_amount: int) -> void:
	gems_label.text = "💎 %d" % new_amount


func _on_reroll_tokens_changed(new_amount: int) -> void:
	reroll_tokens_label.text = "🎫 %d" % new_amount


func _on_play_pressed() -> void:
	print("MainMenu: Play button pressed")
	# TODO: Check for active run and resume, or start draft
	# For now, just print
	pass


func _on_collection_pressed() -> void:
	print("MainMenu: Collection button pressed")
	# TODO: Load collection scene
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
```

**Claude Code Directive**:
```
Create main_menu.tscn with the specified node structure and attach main_menu.gd.
Make sure:
- The background fills the entire viewport
- The title is large and centered
- Buttons are nicely sized and centered
- Currency display is in the top-right corner
- Use placeholder styling (we'll polish later)

You can use simple ColorRect and default themes for now. The important thing 
is the structure and functionality, not the visuals yet.
```

---

### Task 7: Create Placeholder Assets

Create simple placeholder graphics so the game can run without missing texture errors.

**Claude Code Directive**:
```
Create simple placeholder images as colored rectangles:

1. Character portraits (128x128):
   - res://assets/characters/knight.png - Red square
   - res://assets/characters/mage.png - Blue square
   - res://assets/characters/rogue.png - Green square
   - res://assets/characters/cleric.png - Yellow square
   - res://assets/characters/ranger.png - Purple square

2. Item icons (64x64):
   - res://assets/items/rusty_sword.png - Gray square
   - res://assets/items/rusty_dagger.png - Gray square
   - res://assets/items/wooden_staff.png - Brown square
   - res://assets/items/prayer_book.png - White square
   - res://assets/items/short_bow.png - Green square
   - res://assets/items/leather_armor.png - Brown square
   - res://assets/items/flaming_sword.png - Red square
   - res://assets/items/iron_sword.png - Silver square

3. Skill icons (64x64):
   - res://assets/skills/power_strike.png - Red square
   - res://assets/skills/dodge.png - Blue square
   - res://assets/skills/iron_skin.png - Gray square
   - res://assets/skills/vitality.png - Green square

Use Godot's Image class to generate these programmatically, or just create 
simple PNG files. The goal is to avoid missing texture errors.
```

---

## Configuration Steps (Manual)

After Claude Code creates all the files, you need to manually configure Godot:

### 1. Add Autoloads

Open Godot and go to: **Project → Project Settings → Autoload**

Add the following in order:

| Path | Node Name |
|------|-----------|
| `res://autoloads/game_data.gd` | `GameData` |
| `res://autoloads/player_account.gd` | `PlayerAccount` |

### 2. Set Main Scene

Go to: **Project → Project Settings → Application → Run**

Set **Main Scene** to: `res://scenes/main.tscn`

### 3. Save Project Settings

Click "Close" to save the project settings.

---

## Testing Instructions

### Test 1: Launch Game

1. Press **F5** or click the Play button in Godot
2. **Expected Result**: 
   - Game launches without errors
   - Main menu appears with title and buttons
   - Background is visible

**If it fails**: Check the console for errors. Most common issues:
- Autoloads not configured correctly
- Main scene not set
- JSON parse errors (check JSON syntax)

### Test 2: Verify Data Loading

1. Look at the Godot console output
2. **Expected Result**: You should see:
   ```
   GameData: Loading all master data...
   GameData: All data loaded successfully
     - Characters: 5
     - Items: 6
     - Item Upgrades: 2
     - Skills: 4
     - Encounter Types: 2
   PlayerAccount: No save file found, creating default account
   PlayerAccount: Creating default account...
   PlayerAccount: Default account created with 5 characters
   PlayerAccount: Account saved to user://player_account.json
   ```

**If data doesn't load**: Check JSON file paths and syntax

### Test 3: Verify Currency Display

1. Game should show gems and reroll tokens in top-right corner
2. **Expected Result**: 
   - Gems: 💎 1000
   - Reroll Tokens: 🎫 0

**If currencies don't show**: Check that PlayerAccount is loaded before main_menu and that signals are connected

### Test 4: Verify Save Persistence

1. Close the game completely
2. Open Godot console output location: `user://`
   - On Windows: `%APPDATA%\Godot\app_userdata\[project_name]\`
   - On macOS: `~/Library/Application Support/Godot/app_userdata/[project_name]/`
   - On Linux: `~/.local/share/godot/app_userdata/[project_name]/`
3. **Expected Result**: You should see `player_account.json` with your save data
4. Launch game again
5. **Expected Result**: Console shows "PlayerAccount: Account loaded successfully"

**If save doesn't persist**: Check file permissions and that `save_account()` is being called

### Test 5: Test Button Interactions

1. Click each button in the main menu
2. **Expected Result**:
   - **PLAY**: Console prints "MainMenu: Play button pressed"
   - **COLLECTION**: Console prints "MainMenu: Collection button pressed"
   - **QUIT**: Game closes

**If buttons don't work**: Check signal connections in main_menu.gd

---

## Git Checkpoint

Once all tests pass, commit your work:

```bash
# Review changes
git status
git diff

# Stage all changes
git add .

# Commit with descriptive message
git commit -m "Phase 1: Foundation - GameData and PlayerAccount with main menu

- Created project structure (folders and organization)
- Implemented GameData singleton for master data loading
- Implemented PlayerAccount singleton with local save/load
- Created test data (5 characters, 6 items, 2 item upgrades, 4 skills)
- Created main scene with scene management
- Created main menu with currency display
- Generated placeholder assets
- All tests passing: data loads, currencies display, saves persist"

# Optional: Tag this milestone
git tag -a v0.1-phase1 -m "Phase 1 Complete: Foundation"
```

---

## Success Criteria

Phase 1 is complete when ALL of the following are true:

- ✅ Game launches without errors
- ✅ Main menu displays with title and buttons
- ✅ Currencies (gems: 1000, tokens: 0) display correctly
- ✅ Console shows successful data loading for all systems
- ✅ Save file created at `user://player_account.json`
- ✅ Closing and reopening game loads saved data
- ✅ All buttons print to console when clicked
- ✅ No missing texture errors (placeholder assets work)
- ✅ Git commit created with all Phase 1 files

---

## Common Issues & Solutions

### Issue: "Parse Error" in JSON files
**Solution**: Validate JSON syntax at jsonlint.com. Common mistakes:
- Missing commas between array/object elements
- Trailing commas (JSON doesn't allow them)
- Missing quotes around strings

### Issue: "Autoload not found" errors
**Solution**: Double-check autoload paths in Project Settings:
- Must be `res://autoloads/game_data.gd` (not `res://game_data.gd`)
- Node names are case-sensitive: `GameData` not `gamedata`

### Issue: Currencies show "0" instead of "1000"
**Solution**: Check initialization order:
- GameData must load before PlayerAccount
- PlayerAccount must finish `_ready()` before main_menu reads values

### Issue: Save file not persisting
**Solution**: 
- Check that `save_account()` is actually called (add print statement)
- Verify file permissions in user data directory
- Try deleting old save file and recreating

### Issue: Scene transitions cause errors
**Solution**:
- Make sure main scene is set correctly in project settings
- Check that scene paths in main.gd are correct
- Verify SceneContainer node exists and is referenced correctly

---

## Next Steps

Once Phase 1 is complete and all tests pass:

1. Review `phase_02_collection.md` for the next phase
2. Take a break - you've built the foundation! 🎉
3. Consider expanding test data if you want (more characters, items, etc.)
4. Optional: Polish the main menu visuals (better fonts, colors, layout)

**Do not proceed to Phase 2 until all Phase 1 tests pass and the git commit is created.**

---

## Phase 1 Complete! 🎉

You now have:
- ✅ Complete data loading infrastructure
- ✅ Player account system with persistence
- ✅ Main menu with working UI
- ✅ Solid foundation for building the rest of the game

Total files created: ~15
Total lines of code: ~600
Estimated time: 2-4 hours

**Ready for Phase 2: Collection & Character Management**
