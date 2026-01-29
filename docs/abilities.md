# Character Abilities

All abilities are **active** and trigger automatically when a character's cooldown completes. The target is determined by the ability's **target mode**.

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
