# Phase 8: Polish & Extensibility

**Goal**: UI polish, testing, documentation, extensibility  
**Duration**: Days 18-20  
**Deliverable**: Polished prototype ready for content expansion and combat implementation

---

## Overview

Phase 8 is the final phase that:
- Adds more content (characters, items, skills, encounter types)
- Polishes the UI with better visual feedback
- Adds developer tools for testing and debugging
- Creates documentation for extending the game
- Fixes any remaining bugs
- Prepares the codebase for future combat implementation

This phase transforms the functional prototype into a polished, extensible foundation.

---

## Prerequisites

- Phase 7 complete and tested
- All Phase 7 tests passing
- Git commit created for Phase 7
- Godot project closed (to avoid file conflicts)

---

## Implementation Tasks

### Task 1: Expand Character Roster

Add more characters to make drafting more interesting.

#### File: `data/characters/characters.json` (UPDATE)

Add 5 more characters (total of 10):

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
        },
        {
          "rank": 3,
          "rewards": [
            {"type": "item_upgrade", "id": "itemup_iron_sword"}
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
        },
        {
          "rank": 2,
          "stat_boost": {"basic_attack_damage": 3},
          "rewards": [
            {"type": "skill", "id": "skill_arcane_blast", "level_requirement": 2}
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
        },
        {
          "rank": 2,
          "stat_boost": {"speed": 2},
          "rewards": [
            {"type": "skill", "id": "skill_dodge", "level_requirement": 2}
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
        },
        {
          "rank": 2,
          "stat_boost": {"health": 15},
          "rewards": [
            {"type": "skill", "id": "skill_vitality", "level_requirement": 1}
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
        },
        {
          "rank": 2,
          "stat_boost": {"speed": 1, "basic_attack_damage": 1},
          "rewards": [
            {"type": "skill", "id": "skill_quick_shot", "level_requirement": 3}
          ]
        }
      ]
    },
    {
      "id": "char_berserker_001",
      "name": "Raging Berserker",
      "image_path": "res://assets/characters/berserker.png",
      "base_stats": {
        "basic_attack_damage": 14,
        "speed": 6,
        "defense": 2,
        "health": 110,
        "income": 2
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_battle_axe"}
          ]
        },
        {
          "rank": 2,
          "stat_boost": {"basic_attack_damage": 4},
          "rewards": [
            {"type": "skill", "id": "skill_rage", "level_requirement": 2}
          ]
        }
      ]
    },
    {
      "id": "char_paladin_001",
      "name": "Divine Paladin",
      "image_path": "res://assets/characters/paladin.png",
      "base_stats": {
        "basic_attack_damage": 9,
        "speed": 4,
        "defense": 10,
        "health": 105,
        "income": 3
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_holy_mace"}
          ]
        },
        {
          "rank": 2,
          "stat_boost": {"defense": 3},
          "rewards": [
            {"type": "skill", "id": "skill_iron_skin", "level_requirement": 4}
          ]
        }
      ]
    },
    {
      "id": "char_necromancer_001",
      "name": "Dark Necromancer",
      "image_path": "res://assets/characters/necromancer.png",
      "base_stats": {
        "basic_attack_damage": 13,
        "speed": 3,
        "defense": 4,
        "health": 75,
        "income": 5
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_skull_staff"}
          ]
        },
        {
          "rank": 2,
          "stat_boost": {"basic_attack_damage": 2, "health": 10},
          "rewards": [
            {"type": "skill", "id": "skill_life_drain", "level_requirement": 3}
          ]
        }
      ]
    },
    {
      "id": "char_monk_001",
      "name": "Zen Monk",
      "image_path": "res://assets/characters/monk.png",
      "base_stats": {
        "basic_attack_damage": 7,
        "speed": 9,
        "defense": 6,
        "health": 85,
        "income": 3
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_fighting_gloves"}
          ]
        },
        {
          "rank": 2,
          "stat_boost": {"speed": 2, "defense": 2},
          "rewards": [
            {"type": "skill", "id": "skill_inner_peace", "level_requirement": 2}
          ]
        }
      ]
    },
    {
      "id": "char_assassin_001",
      "name": "Silent Assassin",
      "image_path": "res://assets/characters/assassin.png",
      "base_stats": {
        "basic_attack_damage": 16,
        "speed": 8,
        "defense": 2,
        "health": 65,
        "income": 4
      },
      "rank_rewards": [
        {
          "rank": 1,
          "rewards": [
            {"type": "item", "id": "item_poison_blade"}
          ]
        },
        {
          "rank": 2,
          "stat_boost": {"basic_attack_damage": 3, "speed": 1},
          "rewards": [
            {"type": "skill", "id": "skill_backstab", "level_requirement": 4}
          ]
        }
      ]
    }
  ]
}
```

**Claude Code Directive**:
```
Update characters.json with 5 additional characters (total of 10).
Each character should have:
- Unique stats that create different play styles
- At least 2 rank rewards
- Appropriate starting items

Also create placeholder images for the new characters:
- res://assets/characters/berserker.png - Orange square
- res://assets/characters/paladin.png - White/silver square
- res://assets/characters/necromancer.png - Dark purple square
- res://assets/characters/monk.png - Brown/tan square
- res://assets/characters/assassin.png - Black square
```

---

### Task 2: Expand Items and Skills

Add more items and skills to support the new characters and provide variety.

#### File: `data/items/items.json` (UPDATE)

Add items for new characters:

```json
{
  "items": [
    {
      "id": "item_rusty_sword",
      "name": "Rusty Sword",
      "description": "A weathered blade. Better than nothing.",
      "image_path": "res://assets/items/rusty_sword.png",
      "stat_modifiers": {"basic_attack_damage": 3},
      "slot": "weapon"
    },
    {
      "id": "item_rusty_dagger",
      "name": "Rusty Dagger",
      "description": "A small, quick blade.",
      "image_path": "res://assets/items/rusty_dagger.png",
      "stat_modifiers": {"basic_attack_damage": 2, "speed": 1},
      "slot": "weapon"
    },
    {
      "id": "item_wooden_staff",
      "name": "Wooden Staff",
      "description": "A simple magical focus.",
      "image_path": "res://assets/items/wooden_staff.png",
      "stat_modifiers": {"basic_attack_damage": 4, "defense": 1},
      "slot": "weapon"
    },
    {
      "id": "item_prayer_book",
      "name": "Prayer Book",
      "description": "Divine protection through faith.",
      "image_path": "res://assets/items/prayer_book.png",
      "stat_modifiers": {"defense": 3, "health": 10},
      "slot": "weapon"
    },
    {
      "id": "item_short_bow",
      "name": "Short Bow",
      "description": "Quick and deadly at range.",
      "image_path": "res://assets/items/short_bow.png",
      "stat_modifiers": {"basic_attack_damage": 5, "speed": 2},
      "slot": "weapon"
    },
    {
      "id": "item_leather_armor",
      "name": "Leather Armor",
      "description": "Basic protection.",
      "image_path": "res://assets/items/leather_armor.png",
      "stat_modifiers": {"defense": 2, "health": 5},
      "slot": "armor"
    },
    {
      "id": "item_battle_axe",
      "name": "Battle Axe",
      "description": "Heavy and brutal.",
      "image_path": "res://assets/items/battle_axe.png",
      "stat_modifiers": {"basic_attack_damage": 6},
      "slot": "weapon"
    },
    {
      "id": "item_holy_mace",
      "name": "Holy Mace",
      "description": "Blessed by the divine.",
      "image_path": "res://assets/items/holy_mace.png",
      "stat_modifiers": {"basic_attack_damage": 4, "defense": 2},
      "slot": "weapon"
    },
    {
      "id": "item_skull_staff",
      "name": "Skull Staff",
      "description": "Channels dark energy.",
      "image_path": "res://assets/items/skull_staff.png",
      "stat_modifiers": {"basic_attack_damage": 5, "health": 5},
      "slot": "weapon"
    },
    {
      "id": "item_fighting_gloves",
      "name": "Fighting Gloves",
      "description": "For those who fight with their fists.",
      "image_path": "res://assets/items/fighting_gloves.png",
      "stat_modifiers": {"basic_attack_damage": 2, "speed": 2, "defense": 1},
      "slot": "weapon"
    },
    {
      "id": "item_poison_blade",
      "name": "Poison Blade",
      "description": "Coated in deadly toxin.",
      "image_path": "res://assets/items/poison_blade.png",
      "stat_modifiers": {"basic_attack_damage": 6, "speed": 1},
      "slot": "weapon"
    },
    {
      "id": "item_chainmail",
      "name": "Chainmail",
      "description": "Solid metal protection.",
      "image_path": "res://assets/items/chainmail.png",
      "stat_modifiers": {"defense": 4, "health": 10, "speed": -1},
      "slot": "armor"
    },
    {
      "id": "item_lucky_charm",
      "name": "Lucky Charm",
      "description": "A mysterious trinket.",
      "image_path": "res://assets/items/lucky_charm.png",
      "stat_modifiers": {"income": 2},
      "slot": "accessory"
    }
  ]
}
```

#### File: `data/items/item_upgrades.json` (UPDATE)

Add more item upgrades:

```json
{
  "item_upgrades": [
    {
      "id": "itemup_flaming_sword",
      "name": "Flaming Sword",
      "description": "A blade wreathed in fire.",
      "image_path": "res://assets/items/flaming_sword.png",
      "replaces_slot": "weapon",
      "stat_modifiers": {"basic_attack_damage": 15},
      "level_requirement": 4
    },
    {
      "id": "itemup_iron_sword",
      "name": "Iron Sword",
      "description": "A reliable, well-forged blade.",
      "image_path": "res://assets/items/iron_sword.png",
      "replaces_slot": "weapon",
      "stat_modifiers": {"basic_attack_damage": 8},
      "level_requirement": 2
    },
    {
      "id": "itemup_arcane_staff",
      "name": "Arcane Staff",
      "description": "Pulses with magical energy.",
      "image_path": "res://assets/items/arcane_staff.png",
      "replaces_slot": "weapon",
      "stat_modifiers": {"basic_attack_damage": 12, "defense": 2},
      "level_requirement": 3
    },
    {
      "id": "itemup_shadow_cloak",
      "name": "Shadow Cloak",
      "description": "Melts into darkness.",
      "image_path": "res://assets/items/shadow_cloak.png",
      "replaces_slot": "armor",
      "stat_modifiers": {"speed": 4, "defense": 3},
      "level_requirement": 3
    },
    {
      "id": "itemup_plate_armor",
      "name": "Plate Armor",
      "description": "Heavy but impenetrable.",
      "image_path": "res://assets/items/plate_armor.png",
      "replaces_slot": "armor",
      "stat_modifiers": {"defense": 10, "health": 25, "speed": -2},
      "level_requirement": 4
    },
    {
      "id": "itemup_vampiric_blade",
      "name": "Vampiric Blade",
      "description": "Drains life from foes.",
      "image_path": "res://assets/items/vampiric_blade.png",
      "replaces_slot": "weapon",
      "stat_modifiers": {"basic_attack_damage": 10, "health": 15},
      "level_requirement": 5
    }
  ]
}
```

#### File: `data/skills/skills.json` (UPDATE)

Add skills for new characters:

```json
{
  "skills": [
    {
      "id": "skill_power_strike",
      "name": "Power Strike",
      "description": "Increases attack damage by 20%.",
      "image_path": "res://assets/skills/power_strike.png",
      "effects": [{"type": "stat_multiply", "stat": "basic_attack_damage", "value": 1.2}],
      "level_requirement": 3
    },
    {
      "id": "skill_dodge",
      "name": "Dodge",
      "description": "Increases speed by 15%.",
      "image_path": "res://assets/skills/dodge.png",
      "effects": [{"type": "stat_multiply", "stat": "speed", "value": 1.15}],
      "level_requirement": 2
    },
    {
      "id": "skill_iron_skin",
      "name": "Iron Skin",
      "description": "Increases defense by 3.",
      "image_path": "res://assets/skills/iron_skin.png",
      "effects": [{"type": "stat_add", "stat": "defense", "value": 3}],
      "level_requirement": 4
    },
    {
      "id": "skill_vitality",
      "name": "Vitality",
      "description": "Increases max health by 20.",
      "image_path": "res://assets/skills/vitality.png",
      "effects": [{"type": "stat_add", "stat": "health", "value": 20}],
      "level_requirement": 1
    },
    {
      "id": "skill_arcane_blast",
      "name": "Arcane Blast",
      "description": "Increases attack damage by 25%.",
      "image_path": "res://assets/skills/arcane_blast.png",
      "effects": [{"type": "stat_multiply", "stat": "basic_attack_damage", "value": 1.25}],
      "level_requirement": 2
    },
    {
      "id": "skill_quick_shot",
      "name": "Quick Shot",
      "description": "Increases speed by 2 and attack by 2.",
      "image_path": "res://assets/skills/quick_shot.png",
      "effects": [
        {"type": "stat_add", "stat": "speed", "value": 2},
        {"type": "stat_add", "stat": "basic_attack_damage", "value": 2}
      ],
      "level_requirement": 3
    },
    {
      "id": "skill_rage",
      "name": "Rage",
      "description": "Increases attack by 30% but reduces defense by 2.",
      "image_path": "res://assets/skills/rage.png",
      "effects": [
        {"type": "stat_multiply", "stat": "basic_attack_damage", "value": 1.3},
        {"type": "stat_add", "stat": "defense", "value": -2}
      ],
      "level_requirement": 2
    },
    {
      "id": "skill_life_drain",
      "name": "Life Drain",
      "description": "Increases attack by 3 and health by 15.",
      "image_path": "res://assets/skills/life_drain.png",
      "effects": [
        {"type": "stat_add", "stat": "basic_attack_damage", "value": 3},
        {"type": "stat_add", "stat": "health", "value": 15}
      ],
      "level_requirement": 3
    },
    {
      "id": "skill_inner_peace",
      "name": "Inner Peace",
      "description": "Balanced improvement to all stats.",
      "image_path": "res://assets/skills/inner_peace.png",
      "effects": [
        {"type": "stat_add", "stat": "basic_attack_damage", "value": 1},
        {"type": "stat_add", "stat": "speed", "value": 1},
        {"type": "stat_add", "stat": "defense", "value": 1},
        {"type": "stat_add", "stat": "health", "value": 5}
      ],
      "level_requirement": 2
    },
    {
      "id": "skill_backstab",
      "name": "Backstab",
      "description": "Massive attack increase.",
      "image_path": "res://assets/skills/backstab.png",
      "effects": [{"type": "stat_multiply", "stat": "basic_attack_damage", "value": 1.4}],
      "level_requirement": 4
    },
    {
      "id": "skill_battle_cry",
      "name": "Battle Cry",
      "description": "Increases attack and health.",
      "image_path": "res://assets/skills/battle_cry.png",
      "effects": [
        {"type": "stat_add", "stat": "basic_attack_damage", "value": 3},
        {"type": "stat_add", "stat": "health", "value": 10}
      ],
      "level_requirement": 2
    },
    {
      "id": "skill_swiftness",
      "name": "Swiftness",
      "description": "Greatly increases speed.",
      "image_path": "res://assets/skills/swiftness.png",
      "effects": [{"type": "stat_multiply", "stat": "speed", "value": 1.3}],
      "level_requirement": 3
    }
  ]
}
```

**Claude Code Directive**:
```
Update items.json, item_upgrades.json, and skills.json with expanded content.
Create placeholder images for all new items and skills (64x64 colored squares).
This gives players more variety in encounters and character builds.
```

---

### Task 3: Add More Encounter Types

Expand the encounter system with additional encounter types.

#### File: `autoloads/encounter_factory.gd` (UPDATE)

Add new encounter types:

```gdscript
# Update the encounter_weights dictionary at the top:
var encounter_weights: Dictionary = {
	"shop": 1.0,
	"xp_reward": 1.0,
	"gold_reward": 0.8,
	"health_restore": 0.6,
	"skill_trainer": 0.7,
	"gamble": 0.5,
	"elite_challenge": 0.4
}

# Add these new case handlers in _create_encounter_data():
		"skill_trainer":
			encounter_data["name"] = "Skill Trainer"
			encounter_data["description"] = "Learn a random skill for free!"
			encounter_data["image_path"] = "res://assets/encounters/trainer.png"
			encounter_data["data"] = _generate_skill_trainer_data()
		
		"gamble":
			encounter_data["name"] = "Mysterious Gambler"
			encounter_data["description"] = "Risk gold for a chance at greater rewards."
			encounter_data["image_path"] = "res://assets/encounters/gambler.png"
			encounter_data["data"] = {
				"bet_amount": randi_range(20, 40),
				"win_multiplier": 3
			}
		
		"elite_challenge":
			encounter_data["name"] = "Elite Challenge"
			encounter_data["description"] = "A difficult trial with great rewards."
			encounter_data["image_path"] = "res://assets/encounters/elite.png"
			encounter_data["data"] = {
				"xp_reward": randi_range(80, 120),
				"gold_reward": randi_range(40, 60)
			}


# Add these helper methods:
func _generate_skill_trainer_data() -> Dictionary:
	"""Generate a random skill for the trainer to offer"""
	var all_skills = GameData.get_all_skills()
	all_skills.shuffle()
	
	if all_skills.size() > 0:
		return {"skill_id": all_skills[0]["id"]}
	return {"skill_id": ""}
```

**Claude Code Directive**:
```
Update encounter_factory.gd with 3 new encounter types:
- Skill Trainer: Free skill for one character
- Gamble: Risk gold to potentially triple it
- Elite Challenge: High XP and gold reward

Also create placeholder images:
- res://assets/encounters/trainer.png - Green square
- res://assets/encounters/gambler.png - Pink/magenta square  
- res://assets/encounters/elite.png - Red/gold square
```

---

### Task 4: Implement New Encounter UIs

Add UI handling for the new encounter types.

#### File: `scenes/ui/encounter_execute.gd` (UPDATE)

Add handling for new encounter types in `_setup_encounter()`:

```gdscript
# Add these cases to _setup_encounter():
		"skill_trainer":
			_setup_skill_trainer_encounter()
		"gamble":
			_setup_gamble_encounter()
		"elite_challenge":
			_setup_elite_challenge_encounter()


# Add these new methods:
func _setup_skill_trainer_encounter() -> void:
	"""Setup skill trainer encounter UI"""
	var ui = _create_skill_trainer_ui()
	content_container.add_child(ui)


func _create_skill_trainer_ui() -> Control:
	"""Create skill trainer UI"""
	var vbox = VBoxContainer.new()
	
	var skill_id = encounter_data["data"]["skill_id"]
	var skill_data = GameData.get_skill_by_id(skill_id)
	
	if skill_data.is_empty():
		var error_label = Label.new()
		error_label.text = "No skill available..."
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(error_label)
		complete_button.disabled = false
		encounter_completed = true
		return vbox
	
	var label = Label.new()
	label.text = "The trainer offers to teach:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var skill_name_label = Label.new()
	skill_name_label.text = skill_data["name"]
	skill_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_name_label.add_theme_font_size_override("font_size", 24)
	skill_name_label.modulate = Color(0.3, 1.0, 0.3)
	vbox.add_child(skill_name_label)
	
	var skill_desc_label = Label.new()
	skill_desc_label.text = skill_data["description"]
	skill_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(skill_desc_label)
	
	if skill_data.has("level_requirement"):
		var req_label = Label.new()
		req_label.text = "(Requires Level %d)" % skill_data["level_requirement"]
		req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_label.modulate = Color(1.0, 0.7, 0.3)
		vbox.add_child(req_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	var char_label = Label.new()
	char_label.text = "Choose a character to learn this skill:"
	char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(char_label)
	
	var team = RunManager.get_team()
	for i in range(team.size()):
		var char_instance = team[i]
		var button = Button.new()
		button.text = "Teach %s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
		button.pressed.connect(_on_skill_trainer_selected.bind(i, skill_id, button))
		vbox.add_child(button)
	
	return vbox


func _on_skill_trainer_selected(char_index: int, skill_id: String, button: Button) -> void:
	"""Handle skill trainer selection"""
	var team = RunManager.get_team()
	var char_instance = team[char_index]
	
	var success = char_instance.learn_skill(skill_id)
	if success:
		button.text = "Skill Learned!"
		button.disabled = true
		complete_button.disabled = false
		encounter_completed = true
		print("EncounterExecute: %s learned %s from trainer" % [char_instance.get_character_name(), skill_id])
	else:
		button.text = "Cannot Learn (Level/Already Known)"
		button.disabled = true


func _setup_gamble_encounter() -> void:
	"""Setup gamble encounter UI"""
	var ui = _create_gamble_ui()
	content_container.add_child(ui)


func _create_gamble_ui() -> Control:
	"""Create gamble UI"""
	var vbox = VBoxContainer.new()
	
	var bet = encounter_data["data"]["bet_amount"]
	var multiplier = encounter_data["data"]["win_multiplier"]
	var current_gold = RunManager.get_gold()
	
	var label = Label.new()
	label.text = "The gambler offers a wager..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var bet_label = Label.new()
	bet_label.text = "Bet: %d Gold" % bet
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(bet_label)
	
	var odds_label = Label.new()
	odds_label.text = "Win: %dx your bet (%d Gold)" % [multiplier, bet * multiplier]
	odds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	odds_label.modulate = Color(0.3, 1.0, 0.3)
	vbox.add_child(odds_label)
	
	var lose_label = Label.new()
	lose_label.text = "Lose: You lose your bet"
	lose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lose_label.modulate = Color(1.0, 0.3, 0.3)
	vbox.add_child(lose_label)
	
	var chance_label = Label.new()
	chance_label.text = "(50% chance to win)"
	chance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chance_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(chance_label)
	
	var gold_label = Label.new()
	gold_label.text = "Your Gold: %d" % current_gold
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.name = "GoldLabel"
	vbox.add_child(gold_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	var result_label = Label.new()
	result_label.text = ""
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 24)
	result_label.name = "ResultLabel"
	vbox.add_child(result_label)
	
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons_container)
	
	var gamble_button = Button.new()
	gamble_button.text = "GAMBLE!"
	gamble_button.disabled = current_gold < bet
	gamble_button.pressed.connect(_on_gamble_pressed.bind(bet, multiplier, vbox))
	buttons_container.add_child(gamble_button)
	
	var decline_button = Button.new()
	decline_button.text = "Decline"
	decline_button.pressed.connect(_on_gamble_declined)
	buttons_container.add_child(decline_button)
	
	return vbox


func _on_gamble_pressed(bet: int, multiplier: int, container: Control) -> void:
	"""Handle gamble"""
	if not RunManager.spend_gold(bet):
		print("EncounterExecute: Not enough gold to gamble")
		return
	
	var result_label = container.get_node("ResultLabel")
	var gold_label = container.get_node("GoldLabel")
	
	# 50% chance to win
	var won = randf() > 0.5
	
	if won:
		var winnings = bet * multiplier
		RunManager.add_gold(winnings)
		result_label.text = "YOU WON! +%d Gold!" % winnings
		result_label.modulate = Color(0.3, 1.0, 0.3)
		print("EncounterExecute: Gamble won! +%d gold" % winnings)
	else:
		result_label.text = "You lost... -%d Gold" % bet
		result_label.modulate = Color(1.0, 0.3, 0.3)
		print("EncounterExecute: Gamble lost! -%d gold" % bet)
	
	gold_label.text = "Your Gold: %d" % RunManager.get_gold()
	
	# Disable gamble buttons
	for child in container.get_children():
		if child is HBoxContainer:
			for button in child.get_children():
				if button is Button:
					button.disabled = true
	
	complete_button.disabled = false
	encounter_completed = true


func _on_gamble_declined() -> void:
	"""Handle declining to gamble"""
	print("EncounterExecute: Declined to gamble")
	complete_button.disabled = false
	encounter_completed = true


func _setup_elite_challenge_encounter() -> void:
	"""Setup elite challenge encounter UI"""
	var ui = _create_elite_challenge_ui()
	content_container.add_child(ui)


func _create_elite_challenge_ui() -> Control:
	"""Create elite challenge UI"""
	var vbox = VBoxContainer.new()
	
	var xp_reward = encounter_data["data"]["xp_reward"]
	var gold_reward = encounter_data["data"]["gold_reward"]
	
	var label = Label.new()
	label.text = "An elite challenge awaits!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label)
	
	var desc_label = Label.new()
	desc_label.text = "Complete this trial for great rewards."
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	var rewards_label = Label.new()
	rewards_label.text = "Rewards:"
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rewards_label)
	
	var xp_label = Label.new()
	xp_label.text = "+%d XP to ALL characters" % xp_reward
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.modulate = Color(0.3, 1.0, 0.3)
	vbox.add_child(xp_label)
	
	var gold_label = Label.new()
	gold_label.text = "+%d Gold" % gold_reward
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.modulate = Color(1.0, 0.84, 0.0)
	vbox.add_child(gold_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 20
	vbox.add_child(spacer2)
	
	var challenge_button = Button.new()
	challenge_button.text = "COMPLETE CHALLENGE"
	challenge_button.pressed.connect(_on_elite_challenge_completed.bind(xp_reward, gold_reward))
	vbox.add_child(challenge_button)
	
	return vbox


func _on_elite_challenge_completed(xp_reward: int, gold_reward: int) -> void:
	"""Handle elite challenge completion"""
	# Award XP to all characters
	var team = RunManager.get_team()
	for char_instance in team:
		char_instance.add_experience(xp_reward)
	
	# Award gold
	RunManager.add_gold(gold_reward)
	
	print("EncounterExecute: Elite challenge completed! +%d XP to all, +%d gold" % [xp_reward, gold_reward])
	
	complete_button.disabled = false
	encounter_completed = true
```

**Claude Code Directive**:
```
Update encounter_execute.gd with handlers for the 3 new encounter types.
Each needs setup and interaction logic:
- Skill Trainer: Select character to learn free skill
- Gamble: Button to bet, shows win/lose result
- Elite Challenge: Single button to claim rewards

Make sure all encounters properly enable the complete button when done.
```

---

### Task 5: Create Debug Menu

Add a debug menu accessible from main menu for testing.

#### File: `scenes/ui/debug_menu.tscn`

Create a scene with this structure:
```
DebugMenu (Control)
├── Background (ColorRect) - Semi-transparent dark
├── Panel (Panel)
│   └── MarginContainer
│       └── VBoxContainer
│           ├── Title (Label) - "DEBUG MENU"
│           ├── GemsSection (VBoxContainer)
│           │   ├── GemsLabel (Label) - "Gems: 1000"
│           │   └── GemsButtons (HBoxContainer)
│           │       ├── AddGemsButton (Button) - "+100"
│           │       └── RemoveGemsButton (Button) - "-100"
│           ├── TokensSection (VBoxContainer)
│           │   ├── TokensLabel (Label) - "Tokens: 0"
│           │   └── AddTokenButton (Button) - "+1 Token"
│           ├── CharacterSection (VBoxContainer)
│           │   ├── CharacterLabel (Label) - "Characters"
│           │   ├── UnlockAllButton (Button) - "Unlock All Characters"
│           │   └── RankUpAllButton (Button) - "Rank Up All"
│           ├── RunSection (VBoxContainer)
│           │   ├── RunLabel (Label) - "Run Controls"
│           │   └── ClearRunButton (Button) - "Clear Active Run"
│           ├── HSeparator
│           └── CloseButton (Button) - "CLOSE"
```

#### File: `scenes/ui/debug_menu.gd`

```gdscript
extends Control
# DebugMenu - Developer tools for testing

@onready var gems_label = $Panel/MarginContainer/VBoxContainer/GemsSection/GemsLabel
@onready var tokens_label = $Panel/MarginContainer/VBoxContainer/TokensSection/TokensLabel
@onready var add_gems_button = $Panel/MarginContainer/VBoxContainer/GemsSection/GemsButtons/AddGemsButton
@onready var remove_gems_button = $Panel/MarginContainer/VBoxContainer/GemsSection/GemsButtons/RemoveGemsButton
@onready var add_token_button = $Panel/MarginContainer/VBoxContainer/TokensSection/AddTokenButton
@onready var unlock_all_button = $Panel/MarginContainer/VBoxContainer/CharacterSection/UnlockAllButton
@onready var rank_up_all_button = $Panel/MarginContainer/VBoxContainer/CharacterSection/RankUpAllButton
@onready var clear_run_button = $Panel/MarginContainer/VBoxContainer/RunSection/ClearRunButton
@onready var close_button = $Panel/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	add_gems_button.pressed.connect(_on_add_gems)
	remove_gems_button.pressed.connect(_on_remove_gems)
	add_token_button.pressed.connect(_on_add_token)
	unlock_all_button.pressed.connect(_on_unlock_all)
	rank_up_all_button.pressed.connect(_on_rank_up_all)
	clear_run_button.pressed.connect(_on_clear_run)
	close_button.pressed.connect(_on_close)
	
	_update_labels()


func _update_labels() -> void:
	gems_label.text = "Gems: %d" % PlayerAccount.get_gems()
	tokens_label.text = "Tokens: %d" % PlayerAccount.get_reroll_tokens()


func _on_add_gems() -> void:
	PlayerAccount.add_gems(100)
	_update_labels()
	print("DebugMenu: Added 100 gems")


func _on_remove_gems() -> void:
	PlayerAccount.spend_gems(100)
	_update_labels()
	print("DebugMenu: Removed 100 gems")


func _on_add_token() -> void:
	PlayerAccount.add_reroll_token()
	_update_labels()
	print("DebugMenu: Added reroll token")


func _on_unlock_all() -> void:
	var all_chars = GameData.get_all_characters()
	for char_data in all_chars:
		var char_id = char_data["id"]
		if not PlayerAccount.is_character_unlocked(char_id):
			# Unlock without spending gems
			PlayerAccount.player_data["unlocked_character_ids"].append(char_id)
			PlayerAccount._create_character_data(char_id)
	PlayerAccount.save_account()
	print("DebugMenu: Unlocked all characters")


func _on_rank_up_all() -> void:
	for char_data in PlayerAccount.player_data["characters"]:
		PlayerAccount.add_character_experience(char_data["id"], 100)
	print("DebugMenu: Ranked up all characters")


func _on_clear_run() -> void:
	if RunManager.is_run_active:
		RunManager._clear_run_state()
		print("DebugMenu: Cleared active run")
	else:
		print("DebugMenu: No active run to clear")


func _on_close() -> void:
	queue_free()
```

**Claude Code Directive**:
```
Create the DebugMenu scene with developer controls.
Features:
- Add/remove gems
- Add reroll tokens
- Unlock all characters
- Rank up all characters
- Clear active run

This menu will be spawned as an overlay, not a scene change.
```

---

### Task 6: Add Debug Menu Access to Main Menu

Add a way to open the debug menu from main menu.

#### File: `scenes/ui/main_menu.gd` (UPDATE)

Add debug menu handling (note: main_menu.gd already uses SceneManager and UIHelpers):

```gdscript
# Add at top of file:
const DebugMenuScene = preload("res://scenes/ui/debug_menu.tscn")

# Update _input() - extend the existing method:
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				PlayerAccount.add_reroll_token()
				_update_currency_display()
				print("MainMenu: Added reroll token (Debug)")
			KEY_D:
				_open_debug_menu()


func _open_debug_menu() -> void:
	"""Open the debug menu overlay"""
	var debug_menu = DebugMenuScene.instantiate()
	add_child(debug_menu)
	print("MainMenu: Opened debug menu")
```

**Claude Code Directive**:
```
Update main_menu.gd to open debug menu with 'D' key.
The debug menu is added as a child (overlay), not via SceneManager.
```

---

### Task 7: Create README Documentation

Create comprehensive documentation for the project.

#### File: `README.md`

```markdown
# Auto-Battler Roguelike

A roguelike auto-battler game built in Godot 4, featuring character collection, meta-progression, and asynchronous PvP.

## Game Overview

Players draft a team of 3 characters and navigate through encounters to improve their team, then battle through combat rounds. Win 10 combats for victory, or lose all reputation for defeat.

## How to Play

### Main Menu
- **PLAY**: Start a new run or resume an existing one
- **COLLECTION**: View and manage your character collection
- **QUIT**: Exit the game

### Character Collection
- View all unlocked characters
- Equip starting items for future runs
- See rank progression and unlocked content
- Unlock new items/skills with gems

### Draft Phase
- Choose from 3 character options
- 2 from your collection, 1 random (may require gems to unlock)
- Use reroll tokens to regenerate options
- Build a team of 3 characters

### Run Loop
Each round consists of:
1. **Encounter Phase**: Choose from 3 encounters to improve your team
2. **Combat Phase**: Choose from 3 battles to fight

### Encounter Types
- **Shop**: Buy items and skills with gold
- **Training Dummy**: Gain XP for one character
- **Treasure Chest**: Instant gold reward
- **Healing Fountain**: Restore team health
- **Skill Trainer**: Learn a skill for free
- **Gambler**: Risk gold for big rewards
- **Elite Challenge**: High rewards for all characters

### Combat
- Choose from AI enemies (Easy/Medium/Hard) or Player Ghosts
- Currently stubbed with win/lose buttons for testing
- Victory: Gain gold and XP
- Defeat: Lose reputation equal to round number

### Victory/Defeat
- **Victory**: Win 10 combats
- **Defeat**: Reach 0 reputation
- Earn gems and character rank XP based on performance

## Debug Controls

### Main Menu
- **D**: Open debug menu
- **T**: Add reroll token

### During Run
- **E**: Complete encounter (if in encounter phase)
- **C**: Complete combat (if in combat phase)
- **G**: Add 50 gold
- **X**: Add 50 XP to first character
- **L**: Lose 5 reputation

## Project Structure

```
res://
├── autoloads/           # Singleton managers
│   ├── game_data.gd     # Master data loading
│   ├── player_account.gd # Player progression (facade)
│   ├── run_manager.gd   # Active run state
│   ├── scene_manager.gd # Scene transitions and data passing
│   └── encounter_factory.gd # Encounter generation
├── scripts/
│   ├── constants/
│   │   └── game_constants.gd  # Centralized magic numbers
│   ├── utils/
│   │   ├── stat_calculator.gd # Single source for stat calculations
│   │   ├── json_persistence.gd # Unified JSON load/save
│   │   └── ui_helpers.gd      # Common UI utilities
│   ├── managers/
│   │   ├── currency_manager.gd    # Focused currency handling
│   │   └── character_collection.gd # Character collection with O(1) lookups
│   ├── data_classes/    # Runtime data classes
│   └── encounters/      # Encounter implementations
├── data/                # JSON game data
│   ├── characters/
│   ├── items/
│   ├── skills/
│   └── encounters/
├── scenes/              # Godot scenes
│   ├── main.tscn
│   ├── ui/              # UI screens
│   └── components/      # Reusable components
├── assets/              # Images and art
└── saves/               # Save files (user://)
```

## Extending the Game

### Adding New Characters

1. Add character data to `data/characters/characters.json`
2. Create placeholder image in `assets/characters/`
3. Characters automatically appear in drafts and can be unlocked

```json
{
  "id": "char_new_001",
  "name": "New Character",
  "image_path": "res://assets/characters/new.png",
  "base_stats": {
    "basic_attack_damage": 10,
    "speed": 5,
    "defense": 5,
    "health": 100,
    "income": 3
  },
  "rank_rewards": [
    {
      "rank": 1,
      "rewards": [{"type": "item", "id": "item_starter"}]
    }
  ]
}
```

### Adding New Items

1. Add item data to `data/items/items.json` or `item_upgrades.json`
2. Create placeholder image in `assets/items/`
3. Reference item ID in character rank_rewards

```json
{
  "id": "item_new",
  "name": "New Item",
  "description": "Description here.",
  "image_path": "res://assets/items/new.png",
  "stat_modifiers": {"basic_attack_damage": 5},
  "slot": "weapon"
}
```

### Adding New Skills

1. Add skill data to `data/skills/skills.json`
2. Create placeholder image in `assets/skills/`
3. Reference skill ID in character rank_rewards

```json
{
  "id": "skill_new",
  "name": "New Skill",
  "description": "Effect description.",
  "image_path": "res://assets/skills/new.png",
  "effects": [
    {"type": "stat_add", "stat": "basic_attack_damage", "value": 5}
  ],
  "level_requirement": 2
}
```

Effect types:
- `stat_add`: Add flat value to stat
- `stat_multiply`: Multiply stat by value

### Adding New Encounter Types

1. Add encounter type to `autoloads/encounter_factory.gd`:
   - Add to `encounter_weights` dictionary
   - Add case in `_create_encounter_data()`
2. Add UI handling in `scenes/ui/encounter_execute.gd`:
   - Add case in `_setup_encounter()`
   - Create `_setup_[type]_encounter()` method
   - Create `_create_[type]_ui()` method
   - Use `UIHelpers.clear_children()` for container cleanup
   - Use `UIHelpers.set_texture_safe()` for image loading
3. Create placeholder image in `assets/encounters/`

### Implementing Real Combat

The combat system is currently stubbed. To implement:

1. Create `CombatManager` singleton in `autoloads/`
2. Define combat rules (turn order, damage calculation, abilities)
3. Create `combat_scene.tscn` with animated battle
4. Replace `combat_stub.tscn` with real combat scene
5. Update `combat_select.gd` to use `SceneManager.go_to("combat_scene")`

Key considerations:
- Use `StatCalculator` for all damage/stat calculations (single source of truth)
- Characters have stats via dictionary: `GameConstants.STAT_ATTACK`, `STAT_SPEED`, etc.
- Use `StatCalculator.apply_modifier()` for skill effects during combat
- Skills may provide passive bonuses or active abilities
- Combat is fully automated (no player input during fight)
- Use `SceneManager.set_scene_data()` to pass combat results back

### Cloud Integration

Save/load is designed for easy cloud migration using `JsonPersistence`:

1. In `player_account.gd` (via `CurrencyManager` and `CharacterCollection`):
   - Replace `JsonPersistence.save_json()` with API POST
   - Replace `JsonPersistence.load_json()` with API GET
   - The facade pattern makes this change minimal
2. Add authentication flow before main menu
3. For ghost players:
   - POST team composition after each run
   - GET random ghost teams for combat options

## Known Limitations

- Combat is stubbed (win/lose buttons only)
- No animations or sound effects
- Basic UI styling
- No settings menu
- Ghost players are randomly generated (not real player data)

## Future Enhancements

- [ ] Implement actual combat system
- [ ] Add cloud save/load
- [ ] Real async PvP with ghost players
- [ ] Animations and visual effects
- [ ] Sound effects and music
- [ ] Settings menu
- [ ] More encounter types (minigames)
- [ ] Character abilities in combat
- [ ] Achievement system
- [ ] Daily challenges

## Technical Notes

- Godot 4.x required
- All game data in JSON for easy modification (loaded via `JsonPersistence`)
- Runtime character instances are clones (don't modify account data)
- Auto-save after every encounter and combat
- Modular encounter system for easy expansion
- **Architecture patterns used:**
  - `StatCalculator`: Single source of truth for stat calculations (DRY)
  - `GameConstants`: Centralized magic numbers (no scattered literals)
  - `UIHelpers`: Common UI operations (clear_children, set_texture_safe)
  - `SceneManager`: Clean scene transitions with data passing
  - `PlayerAccount` facade: Delegates to `CurrencyManager` + `CharacterCollection` (SRP)
  - Dictionary-based stats: Open for extension without code changes (OCP)

## Credits

Built as a prototype inspired by The Bazaar and other auto-battler roguelikes.
```

**Claude Code Directive**:
```
Create comprehensive README.md documentation covering:
- How to play the game
- Debug controls
- Project structure
- How to extend (add characters, items, skills, encounters)
- How to implement real combat
- Cloud integration notes
- Known limitations and future enhancements
```

---

## Testing Instructions

### Test 1: Expanded Character Roster

1. Open debug menu (D key), click "Unlock All Characters"
2. Go to Collection
3. **Expected Result**:
   - All 10 characters visible
   - Each has unique stats
   - New characters have appropriate items/skills

**If characters don't appear**:
- Check characters.json is valid JSON
- Verify all character IDs are unique
- Check GameData loads correctly

### Test 2: Expanded Items and Skills

1. Start a run
2. Find a shop encounter
3. **Expected Result**:
   - Variety of items appear
   - New items (battle_axe, holy_mace, etc.) show up
   - New skills appear

**If items/skills don't appear**:
- Check items.json and skills.json
- Verify EncounterFactory reads from GameData correctly

### Test 3: New Encounter Types

1. Start a run
2. Cycle through encounters until you see new types
3. **Expected Results**:
   - **Skill Trainer**: Shows skill, lets you pick character
   - **Gambler**: Shows bet, win/lose with 50% chance
   - **Elite Challenge**: Awards XP to all and gold

**If new encounters don't appear**:
- Check encounter_weights includes new types
- Verify _create_encounter_data handles new types
- Check encounter_execute.gd has UI for each type

### Test 4: Skill Trainer Encounter

1. Select Skill Trainer encounter
2. Choose a character to learn skill
3. **Expected Result**:
   - Character learns skill (if level requirement met)
   - Button shows "Skill Learned!" or error message
   - Can complete encounter after selection

**If skill trainer doesn't work**:
- Check _create_skill_trainer_ui() logic
- Verify CharacterInstance.learn_skill() works
- Check level requirements

### Test 5: Gamble Encounter

1. Select Gambler encounter
2. Click "GAMBLE!"
3. **Expected Result**:
   - 50% chance: "YOU WON!" with gold multiplied
   - 50% chance: "You lost..." with gold deducted
   - Can decline without gambling
   - Gold display updates

**If gamble doesn't work**:
- Check _create_gamble_ui() and _on_gamble_pressed()
- Verify RunManager.spend_gold() and add_gold()
- Check random chance calculation

### Test 6: Elite Challenge Encounter

1. Select Elite Challenge encounter
2. Click "COMPLETE CHALLENGE"
3. **Expected Result**:
   - All characters gain XP (check console)
   - Gold awarded
   - Encounter completes

**If elite challenge doesn't work**:
- Check _create_elite_challenge_ui()
- Verify XP distribution to all characters

### Test 7: Debug Menu

1. From main menu, press **D**
2. **Expected Result**:
   - Debug menu overlay appears
   - Shows current gems and tokens
3. Test each button:
   - **+100 Gems**: Increases gem count
   - **-100 Gems**: Decreases gem count
   - **+1 Token**: Adds reroll token
   - **Unlock All**: All characters become available
   - **Rank Up All**: All characters gain 100 XP
   - **Clear Run**: Removes active run save
4. **Close** button closes menu

**If debug menu doesn't work**:
- Check preload path is correct
- Verify button signal connections
- Check PlayerAccount methods work

### Test 8: Content Variety

1. Play through multiple complete runs
2. **Expected Result**:
   - See all 10 characters in drafts over time
   - See variety of encounter types
   - Different items/skills in shops
   - Good gameplay variety

**If variety is low**:
- Check weighted random selection
- Verify all content is loaded by GameData
- Check encounter generation randomization

### Test 9: New Character Placeholder Images

1. Check assets/characters folder
2. **Expected Result**:
   - All 10 character placeholder images exist
   - Each is a different color
   - No missing texture errors in game

**If images are missing**:
- Create colored squares for missing characters
- Verify image paths in JSON match actual files

### Test 10: Balance Check

1. Play several runs with different team compositions
2. **Expected Result**:
   - Different characters feel distinct
   - Some characters are better early, others scale late
   - Gold income affects strategy
   - No character is completely useless or overpowered

**If balance is off**:
- Adjust base stats in characters.json
- Tune item stat modifiers
- Balance skill effects

### Test 11: README Accuracy

1. Read through README.md
2. Follow instructions for:
   - Adding a new character (create test entry)
   - Adding a new item
   - Adding a new skill
3. **Expected Result**:
   - Instructions are accurate
   - New content appears in game
   - No errors

**If README is inaccurate**:
- Update documentation to match actual implementation
- Fix any discrepancies

### Test 12: Full Integration Test

1. Delete all save files
2. Launch game fresh
3. Play through:
   - View collection (5 characters)
   - Draft team
   - Complete 10 rounds with encounters and combat
   - Win the run
   - Check rewards
   - Start second run
   - Characters have more content (from rank ups)
4. **Expected Result**:
   - Entire flow works smoothly
   - Progress accumulates correctly
   - No crashes or errors

**If integration fails**:
- Identify specific failure point
- Check save/load at each step
- Verify state management

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
git commit -m "Phase 8: Polish & Extensibility

- Expanded character roster to 10 unique characters
- Added new items and item upgrades for variety
- Added new skills with diverse effects
- Implemented 3 new encounter types (Skill Trainer, Gambler, Elite Challenge)
- Created Debug Menu with developer tools
- Added comprehensive README documentation
- Created placeholder assets for all new content
- Full game now feature-complete for prototype stage
- Ready for combat system implementation and content expansion
- All tests passing: content, encounters, debug tools, documentation"

# Tag final prototype version
git tag -a v1.0-prototype -m "Prototype Complete: Full game loop with expanded content"
```

---

## Success Criteria

Phase 8 is complete when ALL of the following are true:

- ✅ 10 characters with unique stats and progression
- ✅ 13+ items (including upgrades) available
- ✅ 12+ skills available
- ✅ 7 encounter types working
- ✅ All placeholder images created
- ✅ Debug menu functional with all options
- ✅ Debug menu accessible via D key
- ✅ Skill Trainer encounter works correctly
- ✅ Gamble encounter works correctly
- ✅ Elite Challenge encounter works correctly
- ✅ Good content variety across runs
- ✅ README documentation complete and accurate
- ✅ Full integration test passes
- ✅ No crashes or errors during normal play
- ✅ Git commit and tag created

---

## Common Issues & Solutions

### Issue: New characters don't appear
**Solution**:
- Validate characters.json syntax
- Check for duplicate IDs
- Verify GameData.get_all_characters() includes new entries

### Issue: New encounters don't generate
**Solution**:
- Check encounter_weights includes new types
- Verify switch cases in _create_encounter_data()
- Check for typos in type strings

### Issue: Encounter UI doesn't work
**Solution**:
- Check _setup_encounter() has case for type
- Verify UI creation method exists
- Check signal connections for buttons

### Issue: Debug menu doesn't open
**Solution**:
- Check preload path matches actual scene location
- Verify _input() handles KEY_D
- Check scene is valid and can instantiate

### Issue: Placeholder images missing
**Solution**:
- Create missing images as colored squares
- Verify paths in JSON match actual files
- Check Godot imports images correctly

### Issue: README instructions don't work
**Solution**:
- Update README to match actual implementation
- Test each instruction personally
- Fix any code samples that are incorrect

---

## Prototype Complete! 🎉

Congratulations! You now have a fully functional auto-battler prototype with:

### Features
- ✅ 10 playable characters with unique stats
- ✅ Character collection and meta-progression
- ✅ Rank system with unlockable content
- ✅ 3-character draft system with rerolls
- ✅ 7 different encounter types
- ✅ Shop system with items and skills
- ✅ Combat selection (stubbed for real implementation)
- ✅ Victory/defeat conditions with rewards
- ✅ Persistent save/load system
- ✅ Debug tools for testing

### Architecture
- ✅ Modular, data-driven design
- ✅ Easy to add new content via JSON
- ✅ Extensible encounter system
- ✅ Prepared for cloud integration
- ✅ Ready for combat implementation

### Documentation
- ✅ Comprehensive README
- ✅ Code comments throughout
- ✅ Clear extension guides

## Next Steps (Beyond Prototype)

1. **Implement Real Combat**
   - Create CombatManager singleton
   - Design turn-based or real-time combat
   - Add combat animations and effects

2. **Cloud Integration**
   - Implement user authentication
   - Replace local saves with cloud storage
   - Implement real ghost player system

3. **Polish**
   - Add animations throughout
   - Implement sound effects and music
   - Create proper art assets
   - Add visual effects

4. **Content Expansion**
   - More characters (20+)
   - More items and skills
   - More encounter types (minigames)
   - Story/lore elements

5. **Monetization** (if applicable)
   - Battle pass system
   - Cosmetics
   - Character unlock packs

---

## Final Statistics

**Total Development Phases**: 8
**Estimated Total Time**: 15-20 days
**Total Files Created**: ~40
**Total Lines of Code**: ~5000+
**Characters**: 10
**Items**: 13+
**Skills**: 12+
**Encounter Types**: 7

Thank you for building this prototype! The foundation is solid and ready for expansion. 🚀
