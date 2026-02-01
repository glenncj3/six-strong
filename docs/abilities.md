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
  "type": "triggered",
  "trigger": "<trigger_name>",
  "target_mode": "<target_mode>",
  "buff_stat": "<stat_name>",
  "buff_modifier_type": "flat" | "percent",
  "buff_value": <number>,
  "require_ability_category": "<category>"  // optional filter
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | Must be `"triggered"` |
| `trigger` | Yes | The combat event that fires this ability |
| `target_mode` | Yes | Who to apply the effect to (see Target Modes above) |
| `buff_stat` | Yes | The stat to modify on targets |
| `buff_modifier_type` | Yes | `"flat"` (additive) or `"percent"` (multiplicative) |
| `buff_value` | Yes | Amount to modify the stat by |
| `require_ability_category` | No | Only affect targets that have an ability of this category |

### Available Triggers

| Trigger | Fires When |
|---------|------------|
| `on_ally_crit` | Any ally on the same team lands a critical hit |

More triggers can be added by emitting `_process_triggered_effects` calls in `combat_manager.gd` for new combat events.

### Example: Crit Synergy Burn

A character that gives all burn-capable allies +1 `burn_value` whenever any teammate crits:

```json
{
  "id": "PYRO_CMD",
  "name": "Pyro Commander",
  "abilities": [
    "attack_enemy",
    {
      "type": "triggered",
      "trigger": "on_ally_crit",
      "target_mode": "ally_all",
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
