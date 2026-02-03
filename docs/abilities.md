# Character Abilities

This document describes the ability system for Six Strong, a roguelike auto-battler. Abilities define what characters do during combat and at key moments during a run.

## Table of Contents

- [Overview](#overview)
- [File Locations](#file-locations)
- [Ability Types](#ability-types)
- [Active Abilities](#active-abilities)
  - [Target Modes](#target-modes)
  - [Damage Abilities](#damage-abilities)
  - [Healing Abilities](#healing-abilities)
  - [Status Effect Abilities](#status-effect-abilities)
- [Passive Abilities](#passive-abilities)
- [Triggered Abilities](#triggered-abilities)
  - [Structure](#structure)
  - [Actions](#actions)
  - [Combat Triggers](#combat-triggers)
  - [Run-Time Triggers](#run-time-triggers)
- [Status Effects Reference](#status-effects-reference)
- [Character Stats Reference](#character-stats-reference)
- [Quick Reference](#quick-reference)

---

## Overview

The ability system has three layers:

1. **Active abilities** execute automatically when a character's cooldown completes during combat
2. **Passive abilities** apply effects once at combat start (e.g., buffing adjacent allies)
3. **Triggered abilities** fire in response to specific events (combat or run-time)

Characters are defined in JSON with an `abilities` array that can contain:
- String references to abilities in `abilities.json` (e.g., `"attack_enemy"`)
- Inline triggered ability objects (for custom reactive behaviors)

---

## File Locations

| File | Purpose |
|------|---------|
| `data/abilities/abilities.json` | Defines reusable active/passive abilities |
| `data/characters/characters.json` | Character definitions with ability references |
| `data/status_effects/status_effects.json` | Status effect definitions (poison, burn, etc.) |
| `scripts/combat/combat_manager.gd` | Processes combat triggers |
| `scripts/combat/ability_executor.gd` | Executes active abilities |
| `scripts/managers/run_triggered_abilities.gd` | Processes run-time triggers |

---

## Ability Types

| Type | When It Runs | Defined In |
|------|--------------|------------|
| `active` | Every cooldown completion | `abilities.json` |
| `passive` | Once at combat start | `abilities.json` |
| `triggered` | When trigger event occurs | Inline on character |

---

## Active Abilities

Active abilities execute automatically when a character's cooldown timer reaches zero. The cooldown is based on the character's `speed` stat.

### Target Modes

Target modes determine who an ability affects:

| Mode | Description | Use Case |
|------|-------------|----------|
| `enemy_single` | One enemy (nearest/highest priority) | Single-target damage |
| `enemy_frontline` | All enemies in front row (falls back to back row if empty) | Cleave attacks |
| `enemy_all` | All living enemies | AoE damage/effects |
| `ally_single` | One ally (lowest health, excludes self) | Single-target heals |
| `ally_frontline` | All allies in nearest row | Row-based buffs |
| `ally_all` | All living allies (includes self) | Team-wide effects |
| `self` | The caster only | Self-buffs/heals |

### Damage Abilities

Damage abilities use the character's `damage` stat multiplied by `damage_multiplier`.

| ID | Name | Target | Multiplier | Notes |
|----|------|--------|------------|-------|
| `attack_enemy` | Basic Attack | `enemy_single` | 1.0 | Standard attack |
| `attack_enemy_row` | Cleave | `enemy_frontline` | 1.0 | Hits all frontline enemies |

**Example definition in `abilities.json`:**
```json
{
  "id": "attack_enemy",
  "name": "Basic Attack",
  "description": "Deals damage to a single enemy",
  "type": "active",
  "category": "attack",
  "target_mode": "enemy_single",
  "damage_multiplier": 1.0
}
```

### Healing Abilities

Healing abilities restore HP based on the character's `heal_value` stat.

| ID | Name | Target | Notes |
|----|------|--------|-------|
| `heal_ally` | Heal | `ally_single` | Heals lowest-health ally |
| `heal_allies` | Group Heal | `ally_all` | Heals entire team |
| `heal_self` | Heal Self | `self` | Self-heal only |

**Example:**
```json
{
  "id": "heal_ally",
  "name": "Heal",
  "description": "Heals the most injured ally",
  "type": "active",
  "category": "heal",
  "target_mode": "ally_single",
  "heal_from": "heal_value"
}
```

### Status Effect Abilities

These abilities apply status effects from `status_effects.json`. The stack count or duration comes from the character's corresponding stat.

#### Poison Abilities

Applies **poison** stacks based on `poison_value` stat. Poison deals damage equal to its stack count every 1 second, then loses 1 stack per tick. Stacks are additive (max 99).

| ID | Target |
|----|--------|
| `poison_enemy` | `enemy_single` |
| `poison_enemy_row` | `enemy_frontline` |
| `poison_enemies` | `enemy_all` |

#### Burn Abilities

Applies **burn** stacks based on `burn_value` stat. Burn stacks are permanent. Each application deals damage equal to the target's **total** burn stacks (damage ramps up over time).

| ID | Target |
|----|--------|
| `burn_enemy` | `enemy_single` |
| `burn_enemy_row` | `enemy_frontline` |
| `burn_enemies` | `enemy_all` |

#### Shield Abilities

Applies **shield** stacks based on `shield_value` stat. Each stack absorbs 1 point of attack damage. Stacks are permanent until consumed (max 999).

| ID | Target |
|----|--------|
| `shield_self` | `self` |
| `shield_ally` | `ally_single` |
| `shield_ally_row` | `ally_frontline` |
| `shield_allies` | `ally_all` |

#### Haste Abilities

Applies **haste** for duration based on `haste_value` stat (seconds). Haste doubles cooldown tick rate (2x attack speed). Duration extends on reapplication.

| ID | Target |
|----|--------|
| `haste_self` | `self` |
| `haste_ally` | `ally_single` |
| `haste_ally_row` | `ally_frontline` |
| `haste_allies` | `ally_all` |

#### Slow Abilities

Applies **slow** for duration based on `slow_value` stat (seconds). Slow halves cooldown tick rate (0.5x attack speed). Duration extends on reapplication.

| ID | Target |
|----|--------|
| `slow_enemy` | `enemy_single` |
| `slow_enemy_row` | `enemy_frontline` |
| `slow_enemies` | `enemy_all` |

#### Freeze Abilities

Applies **freeze** for duration based on `freeze_value` stat (seconds). Freeze completely stops cooldown (0x attack speed). Duration extends on reapplication.

| ID | Target |
|----|--------|
| `freeze_enemy` | `enemy_single` |
| `freeze_enemy_row` | `enemy_frontline` |
| `freeze_enemies` | `enemy_all` |

---

## Passive Abilities

Passive abilities apply once at combat start. Currently supported:

| ID | Effect |
|----|--------|
| `buff_adjacent_attack` | Buffs attack damage of adjacent allies |

Passive abilities are defined in `abilities.json` with `"type": "passive"` and processed by `CombatManager._apply_combat_start_effects()`.

---

## Triggered Abilities

Triggered abilities are **defined inline** on a character's `abilities` array in `characters.json`. They fire when specific events occur, independent of the character's cooldown.

### Structure

```json
{
  "name": "Ability Display Name",
  "description": "Description shown in UI",
  "type": "triggered",
  "trigger": "<trigger_name>",
  "target_mode": "<target_mode>",
  "action": "<action_type>",
  // ... action-specific fields
  "require_ability_category": "<category>"  // optional filter
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name in character inspect UI |
| `description` | No | Description text in UI |
| `type` | Yes | Must be `"triggered"` |
| `trigger` | Yes | Event that fires this ability |
| `target_mode` | Yes | Who to affect (see target modes) |
| `action` | No | What to do (defaults to `"buff_stat"`) |
| `require_ability_category` | No | Filter targets by ability category |

### Actions

#### `buff_stat` (default)

Permanently modifies a stat on targets.

| Field | Required | Description |
|-------|----------|-------------|
| `buff_stat` | Yes | Stat name (e.g., `"damage"`, `"burn_value"`) |
| `buff_modifier_type` | Yes | `"flat"` (additive) or `"percent"` (multiplicative) |
| `buff_value` | Yes | Amount to modify |

**Example:** +5 flat damage
```json
{
  "action": "buff_stat",
  "buff_stat": "damage",
  "buff_modifier_type": "flat",
  "buff_value": 5
}
```

**Example:** +10% damage
```json
{
  "action": "buff_stat",
  "buff_stat": "damage",
  "buff_modifier_type": "percent",
  "buff_value": 0.1
}
```

#### `deal_damage`

Deals damage to targets (combat only). Goes through normal damage resolution (can crit, blocked by shields).

| Field | Required | Description |
|-------|----------|-------------|
| `damage_value` | No* | Fixed damage amount |
| `damage_from` | No* | Stat to read damage from |

*One of these is required.

**Example:** Deal 15 fixed damage
```json
{
  "action": "deal_damage",
  "damage_value": 15
}
```

**Example:** Deal damage equal to burn_value stat
```json
{
  "action": "deal_damage",
  "damage_from": "burn_value"
}
```

#### `heal`

Heals targets.

| Field | Required | Description |
|-------|----------|-------------|
| `heal_value` | No* | Fixed heal amount |
| `heal_from` | No* | Stat to read heal from |

*One of these is required.

#### `apply_effect`

Applies a status effect to targets (combat only).

| Field | Required | Description |
|-------|----------|-------------|
| `applies_effect` | Yes | Effect ID from `status_effects.json` |
| `stacks_from` | No | Stat to read stack count from |
| `duration_from` | No | Stat to read duration from |

#### `grant_gold` (run-time only)

Gives gold to the player.

| Field | Required | Description |
|-------|----------|-------------|
| `gold_value` | Yes | Amount of gold to grant |

---

## Combat Triggers

These triggers fire during combat. Processed by `CombatManager`.

### Trigger Reference Table

| Trigger | Fires When | Fires On |
|---------|------------|----------|
| `on_cooldown` | Character's cooldown completes | That character |
| `on_ally_crit` | Any ally lands a critical hit | All living allies |
| `on_front_ally_strike` | Front-row ally in same column acts | Back-row character behind |
| `on_damage_taken` | Character takes damage | That character |
| `on_heal` | Character is healed | That character |
| `on_death` | Character dies | The dying character |
| `on_ally_death` | Any ally dies | All living allies |
| `on_enemy_death` | Any enemy dies | All living enemies |
| `on_<effect_id>` | Character receives status effect | That character |
| `on_ally_<effect_id>` | Any ally receives status effect | All living allies |
| `on_enemy_<effect_id>` | Any enemy receives status effect | All living enemies |

### Trigger: `on_cooldown`

Fires when a character's cooldown completes, **before** their abilities execute.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `character` | The character whose cooldown completed |

### Trigger: `on_ally_crit`

Fires on all living allies when any ally lands a critical hit (including the critting character).

**Trigger Data:**
| Key | Value |
|-----|-------|
| `source` | The character that landed the crit |
| `target` | The character that was hit |

**Example: Crit Synergy**
```json
{
  "id": "CRIT_COMMANDER",
  "name": "Crit Commander",
  "abilities": [
    "attack_enemy",
    {
      "name": "Critical Momentum",
      "description": "When any ally crits, all allies gain +2 damage",
      "type": "triggered",
      "trigger": "on_ally_crit",
      "target_mode": "ally_all",
      "action": "buff_stat",
      "buff_stat": "damage",
      "buff_modifier_type": "flat",
      "buff_value": 2
    }
  ],
  "base_stats": { ... }
}
```

### Trigger: `on_front_ally_strike`

Creates front/back row synergy. Fires on a back-row character when the front-row character in the same column acts.

**Requirements:**
- Trigger owner must be in **back row** (row 1)
- Must have living ally in **front row, same column** (row 0)

**Trigger Data:**
| Key | Value |
|-----|-------|
| `front_ally` | The front-row character that acted |
| `character` | The back-row character receiving the trigger |

**Example: Backstab Archer**
```json
{
  "id": "BACKSTAB_ARCHER",
  "name": "Backstab Archer",
  "abilities": [
    "attack_enemy",
    {
      "name": "Opportunist",
      "description": "When front ally strikes, deal 5 damage to an enemy",
      "type": "triggered",
      "trigger": "on_front_ally_strike",
      "target_mode": "enemy_single",
      "action": "deal_damage",
      "damage_value": 5
    }
  ],
  "base_stats": { ... }
}
```

### Trigger: `on_damage_taken`

Fires when a character takes damage (after shield absorption, before death check).

**Trigger Data:**
| Key | Value |
|-----|-------|
| `target` | The character that took damage |
| `amount` | Damage amount after mitigation |
| `source` | The damage source |

### Trigger: `on_heal`

Fires when a character is healed.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `target` | The healed character |
| `amount` | Actual heal amount (capped by missing health) |
| `source` | The healing source |

### Trigger: `on_death`

Fires on a character when they die, before removal from combat.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `character` | The dying character |

### Trigger: `on_ally_death` / `on_enemy_death`

Fires on all living allies/enemies when a character dies.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `dead_character` | The character that died |

### Effect Triggers (`on_<effect_id>`)

Fires when a character receives a status effect. Works for any effect in `status_effects.json`:

- `on_haste`, `on_poison`, `on_burn`, `on_shield`, `on_slow`, `on_freeze`

**Key behavior:** Fires on **every application**, including when extending/stacking an existing effect.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `target` | The character receiving the effect |
| `effect` | The active effect (after merging) |

### Team Effect Triggers (`on_ally_<effect_id>`, `on_enemy_<effect_id>`)

Fires on all allies/enemies when any character on the team receives an effect.

**Multi-target behavior:** If an ability affects multiple targets (e.g., poisoning 3 enemies), the trigger fires **once per target**.

**Example: Poison Counter**
```json
{
  "name": "Toxic Revenge",
  "description": "When an enemy is poisoned, deal 3 damage to them",
  "type": "triggered",
  "trigger": "on_enemy_poison",
  "target_mode": "enemy_single",
  "action": "deal_damage",
  "damage_value": 3
}
```

---

## Run-Time Triggers

These triggers fire outside combat, during the run. Processed by `RunTriggeredAbilities`.

### Trigger Reference Table

| Trigger | Fires When | Fires On |
|---------|------------|----------|
| `on_recruit` | This character is recruited | The recruited character |
| `on_ally_recruit` | Any character is recruited | All team members |

### Run-Time Target Modes

| Mode | Description |
|------|-------------|
| `self` | The trigger owner |
| `recruited` | The newly recruited character |
| `ally_all` | All team members |
| `ally_other` | All except trigger owner |

### Run-Time Actions

| Action | Fields | Description |
|--------|--------|-------------|
| `buff_stat` | `buff_stat`, `buff_modifier_type`, `buff_value` | Modify a stat |
| `heal` | `heal_value` or `heal_from` | Restore health |
| `grant_gold` | `gold_value` | Give gold to player |

### Example: Welcome Bonus

Character grants gold when recruited:

```json
{
  "id": "MERCHANT",
  "name": "Traveling Merchant",
  "abilities": [
    "attack_enemy",
    {
      "name": "Welcome Bonus",
      "description": "When recruited, gain 50 gold",
      "type": "triggered",
      "trigger": "on_recruit",
      "target_mode": "self",
      "action": "grant_gold",
      "gold_value": 50
    }
  ],
  "base_stats": { ... }
}
```

### Example: Team Synergy

Character buffs all allies when anyone joins:

```json
{
  "id": "RALLY_CAPTAIN",
  "name": "Rally Captain",
  "abilities": [
    "attack_enemy",
    {
      "name": "Rally the Troops",
      "description": "When any ally is recruited, all allies gain +2 damage",
      "type": "triggered",
      "trigger": "on_ally_recruit",
      "target_mode": "ally_all",
      "action": "buff_stat",
      "buff_stat": "damage",
      "buff_modifier_type": "flat",
      "buff_value": 2
    }
  ],
  "base_stats": { ... }
}
```

### Example: Self-Buff on New Recruit

Character buffs self when others join:

```json
{
  "id": "JEALOUS_WARRIOR",
  "name": "Jealous Warrior",
  "abilities": [
    "attack_enemy",
    {
      "name": "Competitive Spirit",
      "description": "When another ally is recruited, gain +5% damage",
      "type": "triggered",
      "trigger": "on_ally_recruit",
      "target_mode": "self",
      "action": "buff_stat",
      "buff_stat": "damage",
      "buff_modifier_type": "percent",
      "buff_value": 0.05
    }
  ],
  "base_stats": { ... }
}
```

---

## Status Effects Reference

Defined in `data/status_effects/status_effects.json`.

| Effect | Stat | Behavior |
|--------|------|----------|
| `poison` | `poison_value` | Deals stack damage per second, loses 1 stack per tick |
| `burn` | `burn_value` | Permanent stacks, deals total-stack damage on each application |
| `shield` | `shield_value` | Absorbs attack damage, permanent until consumed |
| `haste` | `haste_value` | 2x cooldown speed for duration (seconds) |
| `slow` | `slow_value` | 0.5x cooldown speed for duration (seconds) |
| `freeze` | `freeze_value` | 0x cooldown speed for duration (seconds) |

---

## Character Stats Reference

Characters have these stats that affect abilities:

| Stat | Effect |
|------|--------|
| `health` | Maximum HP |
| `damage` | Base attack damage |
| `speed` | Cooldown duration (lower = faster) |
| `crit_chance` | Chance to deal 1.5x damage (0.0-1.0) |
| `agility` | Chance to dodge attacks (0.0-1.0) |
| `heal_value` | Amount healed by heal abilities |
| `poison_value` | Poison stacks applied |
| `burn_value` | Burn stacks applied |
| `shield_value` | Shield stacks applied |
| `haste_value` | Haste duration (seconds) |
| `slow_value` | Slow duration (seconds) |
| `freeze_value` | Freeze duration (seconds) |
| `multistrike_value` | Extra ability executions per cooldown |

### Multistrike

`multistrike_value` is a stat, not an ability. When a character's cooldown completes, they execute their abilities `1 + multistrike_value` times. Targets are re-resolved between strikes.

---

## Quick Reference

### Adding a New Active Ability

1. Add to `data/abilities/abilities.json`:
```json
{
  "id": "my_ability",
  "name": "My Ability",
  "description": "Does something",
  "type": "active",
  "category": "attack",
  "target_mode": "enemy_single",
  "damage_multiplier": 1.5
}
```

2. Reference in character's abilities array:
```json
"abilities": ["my_ability"]
```

### Adding a Triggered Ability to a Character

Add inline to character's abilities array in `characters.json`:
```json
"abilities": [
  "attack_enemy",
  {
    "name": "My Trigger",
    "description": "Reacts to events",
    "type": "triggered",
    "trigger": "on_ally_crit",
    "target_mode": "ally_all",
    "action": "buff_stat",
    "buff_stat": "damage",
    "buff_modifier_type": "flat",
    "buff_value": 1
  }
]
```

### Filtering Targets

Use `require_ability_category` to only affect characters with specific ability types:
```json
{
  "type": "triggered",
  "trigger": "on_ally_crit",
  "target_mode": "ally_all",
  "action": "buff_stat",
  "buff_stat": "burn_value",
  "buff_modifier_type": "flat",
  "buff_value": 1,
  "require_ability_category": "burn"
}
```
This only buffs allies that have at least one `"category": "burn"` ability.

### Testing Abilities

Run ability tests:
```bash
"C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --path . --script tests/test_ability_executor.gd
"C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --path . --script tests/test_triggered_abilities.gd
"C:\Program Files\Godot\Godot_v4.5.1-stable_win64.exe" --headless --path . --script tests/test_run_triggered_abilities.gd
```
