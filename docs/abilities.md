# Character Abilities

Abilities come in three types:

- **Active**: Trigger automatically when a character's cooldown completes.
- **Passive**: Apply effects once at combat start (e.g., `buff_adjacent_attack`).
- **Triggered**: Fire in response to combat events (e.g., an ally landing a crit). Defined inline on a character, not in `abilities.json`.

## Target Modes

| Mode | Description |
|------|-------------|
| `enemy_single` | One enemy (nearest/highest priority) |
| `enemy_frontline` | All enemies in the front row (falls back to back row if empty) |
| `enemy_all` | All enemies |
| `ally_single` | One ally (nearest/lowest health) |
| `ally_frontline` | All allies in the nearest row |
| `ally_all` | All allies |
| `self` | The caster only |

---

## Damage Abilities

### Basic Attack (`attack_enemy`)
Deals damage to a single enemy. Damage = attack_damage x 1.0.

### Cleave (`attack_enemy_row`)
Deals full damage to all frontline enemies. If no frontline enemies exist, hits all backline enemies instead. Damage = attack_damage x 1.0.

---

## Healing Abilities

All healing abilities restore HP based on the character's `heal_value` stat.

### Heal (`heal_ally`)
Heals a single ally.

### Group Heal (`heal_allies`)
Heals all allies.

### Heal Self (`heal_self`)
Heals self.

---

## Poison Abilities

Applies **poison** stacks based on the character's `poison_value` stat. Poison deals damage equal to its current stacks every 1 second, then loses 1 stack per tick. Stacks are additive (max 99).

### Poison Strike (`poison_enemy`)
Poisons a single enemy.

### Poison Enemy Row (`poison_enemy_row`)
Poisons all enemies in the nearest row.

### Poison All Enemies (`poison_enemies`)
Poisons all enemies.

---

## Burn Abilities

Applies **burn** stacks based on the character's `burn_value` stat. Burn stacks are permanent and additive (max 99). Each time burn is applied, it deals damage equal to the target's **total** burn stacks -- meaning burn damage ramps up with repeated applications.

### Burn Enemy (`burn_enemy`)
Burns a single enemy.

### Burn Enemy Row (`burn_enemy_row`)
Burns all enemies in the nearest row.

### Burn All Enemies (`burn_enemies`)
Burns all enemies.

---

## Shield Abilities

Applies **shield** stacks based on the character's `shield_value` stat. Each stack absorbs 1 point of incoming attack damage. Stacks are additive (max 999) and permanent until consumed.

### Shield Self (`shield_self`)
Shields self.

### Shield Ally (`shield_ally`)
Shields the nearest ally.

### Shield Ally Row (`shield_ally_row`)
Shields all allies in the nearest row.

### Shield All Allies (`shield_allies`)
Shields all allies.

---

## Haste Abilities

Applies **haste** for a duration based on the character's `haste_value` stat (in seconds). Haste doubles the target's cooldown tick rate, making them act twice as fast. Duration extends on reapplication.

### Quicken (`haste_self`)
Applies haste to self.

### Quicken Ally (`haste_ally`)
Applies haste to the nearest ally.

### Haste Ally Row (`haste_ally_row`)
Applies haste to all allies in the nearest row.

### Haste All Allies (`haste_allies`)
Applies haste to all allies.

---

## Slow Abilities

Applies **slow** for a duration based on the character's `slow_value` stat (in seconds). Slow halves the target's cooldown tick rate, making them act at half speed. Duration extends on reapplication.

### Slow Enemy (`slow_enemy`)
Slows a single enemy.

### Slow Enemy Row (`slow_enemy_row`)
Slows all enemies in the nearest row.

### Slow All Enemies (`slow_enemies`)
Slows all enemies.

---

## Freeze Abilities

Applies **freeze** for a duration based on the character's `freeze_value` stat (in seconds). Freeze completely stops the target's cooldown, preventing them from acting. Duration extends on reapplication.

### Freeze Enemy (`freeze_enemy`)
Freezes a single enemy.

### Freeze Enemy Row (`freeze_enemy_row`)
Freezes all enemies in the nearest row.

### Freeze All Enemies (`freeze_enemies`)
Freezes all enemies.

---

## Multistrike

Multistrike is a character stat (`multistrike_value`), not an ability. When a character with multistrike finishes their cooldown, they execute their full ability list once as normal, then repeat it a number of additional times equal to their `multistrike_value`. A character with `multistrike_value` of 3 and an `attack_enemy` ability would strike 4 total times per cooldown. Targets are re-resolved between each strike, so if a target dies, the next strike picks a new valid target. Extra strikes stop if the attacking character dies mid-sequence.

---

## Triggered Abilities

Triggered abilities are **composed inline** on a character's `abilities` array in `characters.json`. They are not defined in `abilities.json` — instead you build them from pieces: a trigger, a target mode, an effect, and optional filters.

Triggered abilities fire independently of the character's cooldown. When the trigger event occurs, the ability executes immediately.

### Structure

```json
{
  "name": "<display_name>",
  "description": "<description_text>",
  "type": "triggered",
  "trigger": "<trigger_name>",
  "target_mode": "<target_mode>",
  "action": "<action_type>",
  // ... action-specific fields (see below)
  "require_ability_category": "<category>"  // optional filter
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name shown in the character inspect popup |
| `description` | No | Description text shown in the character inspect popup |
| `type` | Yes | Must be `"triggered"` |
| `trigger` | Yes | The combat event that fires this ability (see Available Triggers) |
| `target_mode` | Yes | Who to apply the effect to (see Target Modes above) |
| `action` | No | What the ability does (defaults to `"buff_stat"`) |
| `require_ability_category` | No | Only affect targets that have an ability of this category |

### Actions

The `action` field determines what the triggered ability does. Each action has its own required fields.

#### `buff_stat` (default)
Permanently modifies a stat on targets.

| Field | Required | Description |
|-------|----------|-------------|
| `buff_stat` | Yes | The stat to modify (e.g., `"burn_value"`, `"damage"`) |
| `buff_modifier_type` | Yes | `"flat"` (additive) or `"percent"` (multiplicative) |
| `buff_value` | Yes | Amount to modify the stat by |

#### `deal_damage`
Deals damage to targets. Damage goes through normal resolution (can crit, blocked by shields, etc.).

| Field | Required | Description |
|-------|----------|-------------|
| `damage_value` | No* | Flat damage amount |
| `damage_from` | No* | Stat to read damage from (e.g., `"damage"`, `"burn_value"`) |

*One of `damage_value` or `damage_from` is required.

#### `heal`
Heals targets.

| Field | Required | Description |
|-------|----------|-------------|
| `heal_value` | No* | Flat heal amount |
| `heal_from` | No* | Stat to read heal amount from (e.g., `"heal_value"`) |

*One of `heal_value` or `heal_from` is required.

#### `apply_effect`
Applies a status effect (poison, burn, shield, haste, etc.) to targets.

| Field | Required | Description |
|-------|----------|-------------|
| `applies_effect` | Yes | Status effect ID from `status_effects.json` (e.g., `"poison"`, `"burn"`) |
| `stacks_from` | No | Stat to read stack count from (e.g., `"poison_value"`) |
| `duration_from` | No | Stat to read duration from (e.g., `"haste_value"`) |

### Available Triggers

#### Combat Triggers

These triggers fire during combat and are processed by `CombatManager`:

| Trigger | Fires When | Fires On |
|---------|------------|----------|
| `on_cooldown` | Character's cooldown completes (before abilities execute) | The character whose cooldown completed |
| `on_ally_crit` | Any ally on the same team lands a critical hit | All living allies |
| `on_front_ally_strike` | The front-row ally in the same column completes their cooldown | The back-row character directly behind |
| `on_damage_taken` | Character takes damage | The character that took damage |
| `on_heal` | Character is healed | The character that was healed |
| `on_death` | Character dies | The dying character (before removal) |
| `on_ally_death` | Any ally dies | All living allies |
| `on_enemy_death` | Any enemy dies | All living enemies |
| `on_<effect_id>` | Character receives a status effect (e.g., `on_haste`) | The character receiving the effect |
| `on_ally_<effect_id>` | Any ally receives a status effect (e.g., `on_ally_haste`) | All living allies |
| `on_enemy_<effect_id>` | Any enemy receives a status effect (e.g., `on_enemy_haste`) | All living enemies |

More combat triggers can be added by emitting `_process_triggered_effects` calls in `combat_manager.gd` for new combat events.

#### Run-Time Triggers

These triggers fire outside of combat and are processed by `RunTriggeredAbilities`:

| Trigger | Fires When | Fires On |
|---------|------------|----------|
| `on_recruit` | This character is recruited to the team | The recruited character |
| `on_ally_recruit` | Any character is recruited (including self) | All characters on the team |

See the [Run-Time Triggers](#run-time-triggers) section for full documentation.

### Trigger: `on_cooldown`

Fires when a character's cooldown completes, **before** their abilities execute. Useful for effects that should happen at the start of a character's turn.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `character` | The character whose cooldown completed |

### Trigger: `on_damage_taken`

Fires when a character takes damage (after shields absorb, before death check).

**Trigger Data:**
| Key | Value |
|-----|-------|
| `target` | The character that took damage |
| `amount` | The damage amount after mitigation |
| `source` | The character/effect that dealt the damage |

### Trigger: `on_heal`

Fires when a character is healed.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `target` | The character that was healed |
| `amount` | The actual heal amount (capped by missing health) |
| `source` | The character that provided the healing |

### Trigger: `on_death`

Fires on a character when they die, before they are removed from combat. Allows "on death" effects like explosions or buffs to remaining allies.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `character` | The dying character |

### Trigger: `on_ally_death`

Fires on all living allies when an ally dies.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `dead_character` | The ally that died |

### Trigger: `on_enemy_death`

Fires on all living enemies when an enemy dies.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `dead_character` | The enemy that died |

### Effect Application Triggers (`on_<effect_id>`)

Triggers with the pattern `on_<effect_id>` fire automatically when the corresponding status effect is applied to a character. This works for any effect defined in `status_effects.json`:

- `on_haste` - Fires on the character receiving haste
- `on_poison` - Fires on the character receiving poison
- `on_burn` - Fires on the character receiving burn
- `on_shield` - Fires on the character receiving shield
- `on_slow` - Fires on the character receiving slow
- `on_freeze` - Fires on the character receiving freeze

**Key behavior:** The trigger fires on **every application**, including when the effect is already active and gets extended/stacked. For example, if a character is hasted for 3 seconds, then hasted again for 2 seconds before the first expires, `on_haste` fires twice.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `target` | The character receiving the effect |
| `effect` | The active effect (after merging, if applicable) |

### Ally/Enemy Effect Triggers (`on_ally_<effect_id>`, `on_enemy_<effect_id>`)

In addition to `on_<effect_id>` (which fires on the affected character), two broader triggers fire on team-wide observers:

- `on_ally_<effect_id>` - Fires on **all living allies** (including the affected character) when any ally receives the effect
- `on_enemy_<effect_id>` - Fires on **all living enemies** when an enemy receives the effect

**Examples:**
- `on_ally_haste` - Fires on all allies when any ally is hasted (including self)
- `on_enemy_haste` - Fires on all enemies when an enemy is hasted
- `on_ally_poison` - Fires on all allies when any ally is poisoned
- `on_enemy_shield` - Fires on all enemies when an enemy gains shield

**Multi-target behavior:** When an ability affects multiple targets (e.g., poisoning 3 enemies), the trigger fires **once per target**. For example, if "Poison All Enemies" poisons 3 enemies, `on_enemy_poison` fires 3 times on all living allies. This allows effects to scale with the number of targets affected.

**Trigger Data:**
| Key | Value |
|-----|-------|
| `target` | The character who received the effect |
| `effect` | The active effect (after merging, if applicable) |

**Example: Speed Synergy**

A character that buffs allies whenever any ally gets hasted:

```json
{
  "id": "TEMPO_MASTER",
  "name": "Tempo Master",
  "abilities": [
    "attack_enemy",
    {
      "name": "Speed Synergy",
      "description": "When any ally is hasted, all allies gain +5% damage",
      "type": "triggered",
      "trigger": "on_ally_haste",
      "target_mode": "ally_all",
      "action": "buff_stat",
      "buff_stat": "damage",
      "buff_modifier_type": "percent",
      "buff_value": 0.05
    }
  ],
  "base_stats": { ... }
}
```

**Example: Haste Disruptor**

A character that reacts when enemies get speed buffs:

```json
{
  "id": "HASTE_DISRUPTOR",
  "name": "Haste Disruptor",
  "abilities": [
    "attack_enemy",
    {
      "name": "Disruption Field",
      "description": "When an enemy is hasted, deal 8 damage to them",
      "type": "triggered",
      "trigger": "on_enemy_haste",
      "target_mode": "enemy_single",
      "action": "deal_damage",
      "damage_value": 8
    }
  ],
  "base_stats": { ... }
}
```

**Example: Self-Haste Trigger**

A character that deals damage whenever they personally receive haste:

```json
{
  "id": "SPEED_DEMON",
  "name": "Speed Demon",
  "abilities": [
    "attack_enemy",
    {
      "name": "Adrenaline Rush",
      "description": "When hasted, deal 10 damage to a random enemy",
      "type": "triggered",
      "trigger": "on_haste",
      "target_mode": "enemy_single",
      "action": "deal_damage",
      "damage_value": 10
    }
  ],
  "base_stats": { ... }
}
```

### Trigger: `on_front_ally_strike`

This positional trigger creates synergy between front and back row characters in the same column. It fires when a front-row character's cooldown completes (they "strike"), triggering abilities on the back-row ally directly behind them.

**Requirements:**
- The character with this trigger must be in the **back row**
- There must be a living ally in the **front row, same column**
- The front ally's cooldown must complete (any ability type: attack, burn, poison, heal, etc.)

**Trigger Data:**
| Key | Value |
|-----|-------|
| `front_ally` | The front-row character that just acted |
| `character` | The back-row character receiving the trigger |

**Example: Backstab Archer**

A back-row archer that deals bonus damage whenever their front-line partner attacks:

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

**How it works:**
1. Place this character in the back row (row 1) with an ally in front (row 0, same column).
2. When the front ally's cooldown completes and they act, this trigger fires.
3. The archer's "Opportunist" ability executes, dealing 5 damage to an enemy.
4. This happens in addition to the archer's normal cooldown-based attacks.

### Example: Crit Synergy Burn

A character that gives all burn-capable allies +1 `burn_value` whenever any teammate crits:

```json
{
  "id": "PYRO_CMD",
  "name": "Pyro Commander",
  "abilities": [
    "attack_enemy",
    {
      "name": "Flame Resonance",
      "description": "When an ally crits, all allies with burn abilities gain +1 burn value",
      "type": "triggered",
      "trigger": "on_ally_crit",
      "target_mode": "ally_all",
      "action": "buff_stat",
      "buff_stat": "burn_value",
      "buff_modifier_type": "flat",
      "buff_value": 1,
      "require_ability_category": "burn"
    }
  ],
  "base_stats": { ... }
}
```

**How it works:**
1. At combat start, the triggered ability is registered as a `CombatEffect` on this character.
2. When any ally crits, the game checks all living allies for `on_ally_crit` effects.
3. This character's effect fires: it resolves `ally_all` targets, filters to only those with a `burn`-category ability, and gives each a permanent +1 flat `burn_value` modifier.
4. Those allies' future burn ability casts now apply 1 extra burn stack.

### Filtering with `require_ability_category`

The `require_ability_category` field filters targets to only characters that have at least one ability with a matching `category`. This lets you write effects like "buff all allies that have burn abilities" without affecting healers or attackers.

Categories match the `category` field in `abilities.json` (e.g., `attack`, `heal`, `poison`, `burn`, `shield`, `haste`, `slow`, `freeze`).

### Duration

Stat modifiers applied by triggered abilities are currently **permanent** (persist for the rest of the run). The triggered effect itself lasts for the duration of combat. A `"combat"`-only duration for the stat modifiers can be added in the future.

---

## Run-Time Triggers

Some triggers fire outside of combat, during the run itself. These are processed by `RunTriggeredAbilities` when the corresponding event occurs.

### Available Run-Time Triggers

| Trigger | Fires When | Fires On |
|---------|------------|----------|
| `on_recruit` | This character is recruited to the team | The recruited character |
| `on_ally_recruit` | Any character is recruited (including self) | All characters on the team |

### Run-Time Target Modes

Run-time triggers support a subset of target modes:

| Mode | Description |
|------|-------------|
| `self` | The character with the triggered ability |
| `recruited` | The character that was just recruited |
| `ally_all` | All characters on the team |
| `ally_other` | All characters except the trigger owner |

### Run-Time Actions

| Action | Description | Fields |
|--------|-------------|--------|
| `buff_stat` | Permanently modify a stat | `buff_stat`, `buff_modifier_type`, `buff_value` |
| `heal` | Restore health | `heal_value` or `heal_from` |
| `grant_gold` | Give gold to the player | `gold_value` |

### Example: Welcome Bonus

A character that grants gold when recruited:

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

A character that buffs all allies (including the new recruit) whenever any character joins:

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

### Example: Self-Improvement on Recruit

A character that buffs themselves when another character joins:

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
