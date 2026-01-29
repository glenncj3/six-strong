# CSV Character Import Guide

This guide explains how to create and import character data from CSV files into the game using the CSV Character Import plugin.

## Using the Import Plugin

The plugin lives in `addons/csv_character_import/` and adds a dock panel in the Godot editor.

1. Open the project in Godot
2. Find the **CSV Characters** dock in the bottom panel
3. Click **Select CSV...** and choose your `.csv` file
4. Review the preview for warnings or errors
5. Click one of:
   - **Import to JSON (Replace)** -- overwrites `data/characters/characters.json` entirely
   - **Merge into JSON** -- updates existing characters by `id`, adds new ones, keeps others unchanged
   - **Export JSON -> CSV** -- exports the current JSON back out to CSV (useful for round-tripping)

## CSV Column Format

The CSV must have a header row with these exact column names in this exact order:

```
id,name,description,image_path,cost,level_requirement,health,charges,agility,speed,damage,crit_chance,heal_value,shield_value,burn_value,poison_value,haste_value,slow_value,freeze_value,multistrike_value,is_generic,display_color,tags,ability
```

### Column Reference

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | string | Yes | Unique identifier, e.g. `char_warrior_001` |
| `name` | string | Yes | Display name |
| `description` | string | No | Flavor text |
| `image_path` | string | No | Resource path, e.g. `res://assets/characters/knight.png` |
| `cost` | int | No | Draft cost (default: 0) |
| `level_requirement` | int | No | Minimum level to appear in run (default: 0) |
| `health` | int | No | Base HP |
| `charges` | int | No | Number of ability uses |
| `agility` | float | No | Agility modifier |
| `speed` | float | No | Cooldown timer speed |
| `damage` | float | No | Base damage value |
| `crit_chance` | float | No | Crit probability (0.0-1.0) |
| `heal_value` | float | No | Healing amount per tick |
| `shield_value` | float | No | Shield amount applied |
| `burn_value` | float | No | Burn damage applied |
| `poison_value` | float | No | Poison damage applied |
| `haste_value` | float | No | Haste buff value |
| `slow_value` | float | No | Slow debuff value |
| `freeze_value` | float | No | Freeze debuff value |
| `multistrike_value` | int | No | Extra hits per action |
| `is_generic` | bool | No | `true` or `false` (default: false) |
| `display_color` | string | No | Hex color, e.g. `#ff4444` |
| `tags` | string | No | Pipe-separated tags, e.g. `fire\|lightning` |
| `ability` | string | No | Ability ID(s), pipe-separated for multiple (default: `attack_enemy`) |

### Value Types

- **int columns**: `cost`, `level_requirement`, `health`, `charges`, `multistrike_value` -- whole numbers only
- **float columns**: `agility`, `speed`, `damage`, `crit_chance`, `heal_value`, `shield_value`, `burn_value`, `poison_value`, `haste_value`, `slow_value`, `freeze_value` -- decimal numbers
- **bool columns**: `is_generic` -- must be exactly `true` or `false` (case-insensitive)

## Abilities

The `ability` column in the CSV accepts one or more ability IDs separated by pipes (`|`). The importer converts this into an `"abilities"` array in JSON.

- Single ability: `attack_enemy` becomes `"abilities": ["attack_enemy"]`
- Multiple abilities: `attack_enemy|shield_self` becomes `"abilities": ["attack_enemy", "shield_self"]`

Exporting from JSON back to CSV preserves multiple abilities using the same pipe format, so you won't lose data when round-tripping.

### Available Ability IDs

| Ability ID | What It Does |
|------------|-------------|
| `attack_enemy` | Deals damage to a single enemy |
| `attack_enemy_row` | Deals damage to an enemy row |
| `heal_ally` | Heals a single ally |
| `heal_allies` | Heals all allies |
| `heal_self` | Heals self |
| `poison_enemy` | Poisons a single enemy |
| `poison_enemy_row` | Poisons an enemy row |
| `poison_enemies` | Poisons all enemies |
| `haste_self` | Applies haste to self |
| `haste_ally` | Applies haste to a single ally |
| `haste_ally_row` | Applies haste to an ally row |
| `haste_allies` | Applies haste to all allies |
| `shield_self` | Shields self |
| `shield_ally` | Shields a single ally |
| `shield_ally_row` | Shields an ally row |
| `shield_allies` | Shields all allies |
| `slow_enemy` | Slows a single enemy |
| `slow_enemy_row` | Slows an enemy row |
| `slow_enemies` | Slows all enemies |

Ability definitions are in `data/abilities/abilities.json`.

## Example CSV

```csv
id,name,description,image_path,cost,level_requirement,health,charges,agility,speed,damage,crit_chance,heal_value,shield_value,burn_value,poison_value,haste_value,slow_value,freeze_value,multistrike_value,is_generic,display_color,tags,ability
char_warrior_001,"Brave Knight","A stalwart defender",res://assets/characters/knight.png,40,1,100,5,0.15,3.0,15,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,false,,earth|holy,attack_enemy
char_healer_001,"Forest Druid","Heals and protects allies",res://assets/characters/druid.png,50,1,65,4,0.1,4.5,5,0.0,20.0,10.0,0.0,0.0,0.0,0.0,0.0,0,false,#44ff44,nature|holy,heal_allies|shield_ally
```

Notes on the example:
- The Brave Knight has a single ability (`attack_enemy`)
- The Forest Druid has two abilities (`heal_allies|shield_ally`)
- Tags use pipes: `earth|holy`
- Quoted fields handle commas in descriptions
- Empty optional fields can be left blank

## Tips

- Use the **Export** feature first to get a CSV of your current characters as a formatting reference
- The **Merge** mode is safer than **Replace** when updating a few characters -- it won't delete others
- The preview panel shows warnings for malformed rows before you commit the import
- Stat values left blank default to `0` (int) or `0.0` (float)
- The `id` and `name` columns are required; rows missing an `id` are skipped
