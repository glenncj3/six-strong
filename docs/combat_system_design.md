# Combat System Design Document

## Overview

This document defines the foundational combat system for an auto-battler game. Combat is real-time, automated, and designed to resolve in approximately 30 seconds. Players assemble characters before battle; once combat begins, all actions are executed by the system with no player input.

The system is inspired by The Bazaar's cooldown-based approach (cooldowns, triggers, effects) combined with Once Upon a Galaxy's asynchronous PvP structure (fighting "ghost" snapshots of other players' lineups).

---

## Core Concepts

### Characters

Characters are the fundamental combat entities. They function like The Bazaar's items—with cooldowns, passive effects, and triggers—rather than traditional auto-battler units with fixed attack patterns.

- **All characters have Health.** When a character's health reaches 0, it is destroyed.
- **Some characters have Speed.** Speed determines how frequently a character acts (cooldown duration in seconds).
- **Some characters have Damage.** Damage is the base value dealt when the character's cooldown triggers.
- **Some characters have Effects.** Effects are abilities that trigger under specific conditions.
- **Some characters have Crit Chance.** A percentage chance to deal increased damage.
- **Some characters have Defend Rate.** A percentage chance to negate incoming damage.

Not all characters deal damage. Some exist purely to buff allies, debuff enemies, or provide passive effects.

### Cooldown System

Characters do not "attack" in the traditional sense. Instead:

1. Characters with a `speed` stat have a cooldown timer
2. When the cooldown reaches zero, the character performs its **action**
3. The action might deal damage, buff allies, debuff enemies, or trigger effects
4. The cooldown resets to the character's `speed` value

Characters without a `speed` stat are passive—they provide effects but never act on their own.

---

## Data Structures

### Character (Combat Instance)

At combat start, characters are cloned from their run state into combat instances. Combat modifications do not persist back to the original characters.

```
CombatCharacter {
    id: String                      # Unique identifier
    source_character_id: String     # Original CharacterInstance ID

    # Health
    health: float                   # Current health
    max_health: float               # Maximum health (base + modifiers)

    # Combat stats (null/0 if character doesn't use them)
    speed: float or null            # Seconds between actions (cooldown duration)
    damage: float or null           # Base damage dealt on cooldown
    crit_chance: float              # 0.0 to 1.0, percentage chance to crit
    agility: float              # 0.0 to 1.0, percentage chance to block

    # Positioning
    team: int                       # 0 = player, 1 = opponent
    row: int                        # 0 = front, 1 = back
    column: int                     # 0 = left, 1 = middle, 2 = right

    # State
    is_alive: bool                  # true if health > 0
    cooldown_remaining: float       # Time until next action (for speed-based characters)

    # Effects
    effects: Array<Effect>          # Active effects on this character
}
```

### Effect (Unified System)

Effects can come from any source: character innate abilities, items (applied to characters), or skills (applied to characters). All effects use the same structure.

```
Effect {
    id: String                      # Unique effect instance ID
    source_type: String             # "character", "item", or "skill"
    source_id: String               # ID of the source that created this effect

    # What the effect does
    effect_type: String             # "stat_modifier", "triggered", "on_tick"

    # For stat_modifier effects
    stat: String                    # e.g., "damage", "crit_chance", "agility"
    value: float                    # The modifier value
    modifier_type: String           # "flat" or "percent"

    # For triggered effects
    trigger: String                 # e.g., "on_cooldown", "on_damage_taken", "on_death"
    action: Callable                # What happens when triggered

    # Duration
    duration_type: String           # "seconds", "cooldowns", "permanent", "combat"
    duration_value: float           # Remaining duration (for seconds/cooldowns)

    # Targeting (for effects that apply to others)
    target_type: String             # "self", "source", "specific"
    target_id: String               # If specific
}
```

### Stat Modifier Stacking

When multiple percentage modifiers affect the same stat, they stack additively based on the value before the multiplier.

```
Example: Character with 100 base damage
  - Effect 1: +10% damage
  - Effect 2: +10% damage

Calculation: 100 + (100 * 0.10) + (100 * 0.10) = 120 damage
NOT: 100 * 1.10 * 1.10 = 121 damage
```

If the base value has been additively modified, such as giving a character +100 damage, the modifier is factored in before the multiplier. So a 100 base damage character receiving +100 damage and +10% damage would be dealing 220 damage. (100 + 100) + ((100 + 100) * 0.10)

### Board

```
Board {
    player_characters: Array<CombatCharacter or null>[6]    # 2 rows × 3 columns
    opponent_characters: Array<CombatCharacter or null>[6]  # 2 rows × 3 columns
}
```

**Index mapping:**

```
Index to position:
  Row 0 (Front): indices 0, 1, 2
  Row 1 (Back):  indices 3, 4, 5

Visual representation (as seen in-game):

        Col 0   Col 1   Col 2
       ┌─────┬─────┬─────┐
       │  3  │  4  │  5  │  Opponent Back (row 1)
       ├─────┼─────┼─────┤
       │  0  │  1  │  2  │  Opponent Front (row 0)
       └─────┴─────┴─────┘
              ↕ ↕ ↕
       ┌─────┬─────┬─────┐
       │  0  │  1  │  2  │  Player Front (row 0)
       ├─────┼─────┼─────┤
       │  3  │  4  │  5  │  Player Back (row 1)
       └─────┴─────┴─────┘

Front rows face each other in the center.
Column 0 opposes column 0, column 1 opposes column 1, etc.
```

### CombatState

```
CombatState {
    board: Board
    elapsed_time: float             # Total combat time elapsed
    combat_active: bool             # true while combat is ongoing
    winner: int or null             # null during combat, 0 = player, 1 = opponent, 2 = draw
}
```

---

## Grid and Positioning

### Layout

Each team has a 2×3 grid (uses existing CharacterGrid):
- **2 rows:** Front (row 0) and Back (row 1)
- **3 columns:** Left (0), Middle (1), Right (2)

### Opposition

Column indices map directly between teams:
- Player column 0 faces Opponent column 0
- Player column 1 faces Opponent column 1
- Player column 2 faces Opponent column 2

### Position Helper Functions

```
get_character_at(team: int, row: int, column: int) -> CombatCharacter or null
get_position(character: CombatCharacter) -> {team: int, row: int, column: int}
get_column_distance(column_a: int, column_b: int) -> int
    # Returns: abs(column_a - column_b)
```

---

## Targeting System

### Core Targeting Rules

When a character needs to select a target (enemy for damage/debuffs, ally for buffs), it follows these rules:

#### Enemy Targeting Priority

1. **Front row first:** Only target back-row characters if no front-row characters exist (enemy or ally is a meaningful filter)
2. **Nearest column:** Among valid row targets, select those in the nearest column(s)
3. **Random tiebreaker:** If multiple targets are equally valid, select randomly

#### Algorithm: Get Valid Enemy Targets

```
get_valid_enemy_targets(acting_character: CombatCharacter) -> Array<CombatCharacter>:
    actor_column = acting_character.column
    enemy_team = 1 - acting_character.team

    # Step 1: Get all living enemies by row
    front_row_enemies = get_living_characters(enemy_team, row=0)
    back_row_enemies = get_living_characters(enemy_team, row=1)

    # Step 2: Determine target pool (front row priority)
    if front_row_enemies is not empty:
        target_pool = front_row_enemies
    else if back_row_enemies is not empty:
        target_pool = back_row_enemies
    else:
        return []  # No valid targets

    # Step 3: Find minimum column distance
    min_distance = infinity
    for character in target_pool:
        distance = abs(character.column - actor_column)
        if distance < min_distance:
            min_distance = distance

    # Step 4: Return all characters at minimum distance
    valid_targets = []
    for character in target_pool:
        if abs(character.column - actor_column) == min_distance:
            valid_targets.append(character)

    return valid_targets
```

#### Algorithm: Select Single Target

```
select_enemy_target(acting_character: CombatCharacter) -> CombatCharacter or null:
    valid_targets = get_valid_enemy_targets(acting_character)
    if valid_targets is empty:
        return null
    return random_choice(valid_targets)
```

### Ally Targeting (for Buffs)

Ally targeting follows the same spatial rules but targets friendly characters:

```
get_valid_ally_targets(buffing_character: CombatCharacter, include_self: bool = false) -> Array<CombatCharacter>:
    buffer_column = buffing_character.column
    friendly_team = buffing_character.team

    # Step 1: Get all living allies by row
    front_row_allies = get_living_characters(friendly_team, row=0)
    back_row_allies = get_living_characters(friendly_team, row=1)

    if not include_self:
        front_row_allies.remove(buffing_character)
        back_row_allies.remove(buffing_character)

    # Step 2: Front row priority
    if front_row_allies is not empty:
        target_pool = front_row_allies
    else if back_row_allies is not empty:
        target_pool = back_row_allies
    else:
        return []

    # Step 3: Find minimum column distance
    min_distance = infinity
    for character in target_pool:
        distance = abs(character.column - buffer_column)
        if distance < min_distance:
            min_distance = distance

    # Step 4: Return all characters at minimum distance
    valid_targets = []
    for character in target_pool:
        if abs(character.column - buffer_column) == min_distance:
            valid_targets.append(character)

    return valid_targets
```

### Targeting Examples

Reference layout:
```
Player:       Opponent:
A B C         G H _
D _ F         J _ _
```

**Example 1: G's cooldown triggers**
- G is at column 0
- Front row enemies: A (col 0), B (col 1), C (col 2)
- Nearest to column 0: A (distance 0)
- **G targets A**

**Example 2: G's cooldown triggers after A dies**
- Front row enemies: B (col 1), C (col 2)
- Nearest to column 0: B (distance 1)
- **G targets B**

**Example 3: H's cooldown triggers**
- H is at column 1
- Front row enemies: A (col 0), B (col 1), C (col 2)
- Nearest to column 1: B (distance 0)
- **H targets B**

**Example 4: H's cooldown triggers after B dies**
- Front row enemies: A (col 0), C (col 2)
- Distance from column 1: A is 1, C is 1
- Both equally close
- **H randomly targets A or C**

**Example 5: J buffs an ally**
- J is at column 0
- Front row allies: G (col 0), H (col 1)
- Nearest to column 0: G (distance 0)
- **J buffs G**

---

## Combat Loop

### Initialization

```
initialize_combat(player_team: CharacterGrid, opponent_team: CharacterGrid) -> CombatState:
    state = new CombatState()
    state.board = new Board()

    # Clone player characters into combat instances
    for row in range(2):
        for col in range(3):
            char = player_team.get_character_at(row, col)
            if char is not null:
                combat_char = create_combat_character(char, team=0, row, col)
                state.board.player_characters[row * 3 + col] = combat_char

    # Clone opponent characters into combat instances
    for row in range(2):
        for col in range(3):
            char = opponent_team.get_character_at(row, col)
            if char is not null:
                combat_char = create_combat_character(char, team=1, row, col)
                state.board.opponent_characters[row * 3 + col] = combat_char

    state.elapsed_time = 0
    state.combat_active = true
    state.winner = null

    return state

create_combat_character(source: CharacterInstance, team: int, row: int, col: int) -> CombatCharacter:
    combat_char = new CombatCharacter()
    combat_char.id = generate_unique_id()
    combat_char.source_character_id = source.id

    # Calculate stats from base + all modifiers
    stats = calculate_combat_stats(source)
    combat_char.max_health = stats.health
    combat_char.health = source.current_health  # Preserve current health from run
    combat_char.speed = stats.speed             # May be null
    combat_char.damage = stats.damage           # May be null
    combat_char.crit_chance = stats.crit_chance # Default 0
    combat_char.agility = stats.agility # Default 0

    combat_char.team = team
    combat_char.row = row
    combat_char.column = col
    combat_char.is_alive = true
    combat_char.cooldown_remaining = combat_char.speed or 0
    combat_char.effects = []

    # Apply any combat-start effects from items/skills
    apply_combat_start_effects(combat_char, source)

    return combat_char
```

### Main Loop (Real-Time)

```
update_combat(state: CombatState, delta: float):
    if not state.combat_active:
        return

    state.elapsed_time += delta

    # Update all living characters
    all_characters = get_all_living_characters(state.board)

    for character in all_characters:
        update_character(character, state, delta)

    # Update effect durations
    update_effects(state, delta)

    # Check win condition
    check_win_condition(state)
```

### Character Update

```
update_character(character: CombatCharacter, state: CombatState, delta: float):
    if not character.is_alive:
        return

    # Only process cooldown for characters with speed
    if character.speed is not null and character.speed > 0:
        character.cooldown_remaining -= delta

        if character.cooldown_remaining <= 0:
            # Character is ready to act
            execute_character_action(character, state)

            # Reset cooldown
            character.cooldown_remaining = character.speed

            # Decrement cooldown-based effect durations
            decrement_cooldown_effects(character)
```

### Action Execution Framework

```
execute_character_action(character: CombatCharacter, state: CombatState):
    # Emit event for triggered effects
    emit_event("on_cooldown", {character: character})

    # Default behavior: If character has damage, deal damage to an enemy
    if character.damage is not null and character.damage > 0:
        target = select_enemy_target(character)
        if target is not null:
            execute_damage(character, target, character.damage, state)

    # Characters with custom actions handle them via triggered effects
```

---

## Damage Resolution

### Damage Execution

```
execute_damage(source: CombatCharacter, target: CombatCharacter, base_damage: float, state: CombatState):
    # Step 1: Check for block (defend)
    if target.agility > 0:
        roll = random_float(0.0, 1.0)
        if roll < target.agility:
            # Damage blocked
            emit_event("damage_blocked", {source: source, target: target})
            return

    # Step 2: Calculate final damage
    damage = base_damage
    is_crit = false

    # Step 3: Check for critical hit
    if source.crit_chance > 0:
        roll = random_float(0.0, 1.0)
        if roll < source.crit_chance:
            damage = damage * CRIT_MULTIPLIER
            is_crit = true

    # Step 4: Apply damage
    apply_damage(target, damage, source, state)

    # Step 5: Emit event for visual feedback and triggers
    emit_event("damage_dealt", {
        source: source,
        target: target,
        damage: damage,
        is_crit: is_crit
    })
```

### Damage Application

```
apply_damage(target: CombatCharacter, amount: float, source: CombatCharacter or null, state: CombatState):
    if not target.is_alive:
        return

    target.health -= amount

    emit_event("on_damage_taken", {
        target: target,
        amount: amount,
        source: source
    })

    if target.health <= 0:
        target.health = 0
        kill_character(target, state)
```

### Character Death

```
kill_character(character: CombatCharacter, state: CombatState):
    character.is_alive = false

    # Emit death event (for effects on the dying character itself)
    emit_event("on_death", {character: character})

    # Process on_ally_death triggers for living allies
    for ally in get_living_characters_on_team(state.board, character.team):
        process_triggered_effects(ally, "on_ally_death", {dead_character: character})

    # Process on_enemy_death triggers for living enemies
    enemy_team = 1 - character.team
    for enemy in get_living_characters_on_team(state.board, enemy_team):
        process_triggered_effects(enemy, "on_enemy_death", {dead_character: character})

    # Remove effects that this character was providing to others
    remove_effects_from_source(character.id, state)

    # Clear effects on this character
    character.effects = []
```

---

## Win Condition

```
check_win_condition(state: CombatState):
    player_alive = has_living_characters(state.board, team=0)
    opponent_alive = has_living_characters(state.board, team=1)

    # Check for stalemate (characters alive but can't damage each other)
    if player_alive and opponent_alive:
        if is_stalemate(state):
            state.combat_active = false
            state.winner = 2  # Draw
            emit_event("combat_ended", {winner: 2, reason: "stalemate"})
            return

    if player_alive and not opponent_alive:
        state.combat_active = false
        state.winner = 0  # Player wins
        emit_event("combat_ended", {winner: 0})

    else if opponent_alive and not player_alive:
        state.combat_active = false
        state.winner = 1  # Opponent wins
        emit_event("combat_ended", {winner: 1})

    else if not player_alive and not opponent_alive:
        state.combat_active = false
        state.winner = 2  # Draw (simultaneous elimination)
        emit_event("combat_ended", {winner: 2, reason: "mutual_kill"})

is_stalemate(state: CombatState) -> bool:
    # Check if any living character can deal damage
    for character in get_all_living_characters(state.board):
        if character.damage is not null and character.damage > 0:
            return false
        # Also check for damage-dealing effects
        if has_damage_dealing_effects(character):
            return false
    return true

has_living_characters(board: Board, team: int) -> bool:
    characters = board.player_characters if team == 0 else board.opponent_characters
    for character in characters:
        if character is not null and character.is_alive:
            return true
    return false
```

### Draw Outcome

When combat ends in a draw (mutual kill or stalemate):
- Player takes no reputation damage
- Player earns no win credit
- Combat simply ends with no major consequence

---

## Effect System

### Effect Duration Types

| Type | Description |
|------|-------------|
| `seconds` | Lasts for a specific number of real-time seconds |
| `cooldowns` | Lasts for a specific number of the affected character's cooldown cycles |
| `combat` | Lasts until combat ends |
| `permanent` | Lasts until explicitly removed (e.g., source dies) |

### Effect Update

```
update_effects(state: CombatState, delta: float):
    for character in get_all_characters(state.board):
        for effect in character.effects:
            if effect.duration_type == "seconds":
                effect.duration_value -= delta
                if effect.duration_value <= 0:
                    remove_effect(character, effect)

decrement_cooldown_effects(character: CombatCharacter):
    for effect in character.effects:
        if effect.duration_type == "cooldowns":
            effect.duration_value -= 1
            if effect.duration_value <= 0:
                remove_effect(character, effect)
```

### Applying Effects

```
apply_effect(target: CombatCharacter, effect: Effect):
    target.effects.append(effect)

    # If stat modifier, recalculate stats
    if effect.effect_type == "stat_modifier":
        recalculate_stats(target)

    emit_event("effect_applied", {target: target, effect: effect})

remove_effect(target: CombatCharacter, effect: Effect):
    target.effects.remove(effect)

    if effect.effect_type == "stat_modifier":
        recalculate_stats(target)

    emit_event("effect_removed", {target: target, effect: effect})
```

### Max Health Changes

When an effect modifies max_health:

```
apply_max_health_change(character: CombatCharacter, amount: float, is_buff: bool):
    old_max = character.max_health

    if is_buff:
        character.max_health += amount
        character.health += amount  # Also increase current health
    else:
        character.max_health -= amount
        # Cap current health at new max
        if character.health > character.max_health:
            character.health = character.max_health
```

---

## Trigger Events

The combat system emits events that effects can listen to:

| Event | Data | When |
|-------|------|------|
| `combat_started` | `{state}` | Combat initialization complete |
| `combat_ended` | `{winner, reason}` | Combat resolved |
| `on_cooldown` | `{character}` | Character's cooldown triggered |
| `damage_dealt` | `{source, target, damage, is_crit}` | Damage was applied |
| `damage_blocked` | `{source, target}` | Damage was blocked by defend |
| `on_damage_taken` | `{target, amount, source}` | Character took damage |
| `on_death` | `{character}` | Character died |
| `on_ally_death` | `{dead_character, observer}` | Ally on same team died |
| `on_enemy_death` | `{dead_character, observer}` | Enemy died |
| `effect_applied` | `{target, effect}` | Effect added to character |
| `effect_removed` | `{target, effect}` | Effect removed from character |
| `on_heal` | `{target, amount, source}` | Character was healed |

---

## Constants

```
CRIT_MULTIPLIER = 2.0           # Damage multiplier on critical hits
```

---

## Helper Functions Summary

```
# Character queries
get_all_living_characters(board: Board) -> Array<CombatCharacter>
get_living_characters_on_team(board: Board, team: int) -> Array<CombatCharacter>
get_living_characters(team: int, row: int) -> Array<CombatCharacter>
get_character_at(team: int, row: int, column: int) -> CombatCharacter or null
has_living_characters(board: Board, team: int) -> bool

# Targeting
get_valid_enemy_targets(character: CombatCharacter) -> Array<CombatCharacter>
get_valid_ally_targets(character: CombatCharacter, include_self: bool) -> Array<CombatCharacter>
select_enemy_target(character: CombatCharacter) -> CombatCharacter or null
select_ally_target(character: CombatCharacter, include_self: bool) -> CombatCharacter or null
get_column_distance(col_a: int, col_b: int) -> int

# Combat actions
execute_damage(source: CombatCharacter, target: CombatCharacter, damage: float, state: CombatState)
apply_damage(target: CombatCharacter, amount: float, source: CombatCharacter, state: CombatState)
kill_character(character: CombatCharacter, state: CombatState)

# Effects
apply_effect(target: CombatCharacter, effect: Effect)
remove_effect(target: CombatCharacter, effect: Effect)
recalculate_stats(character: CombatCharacter)
process_triggered_effects(character: CombatCharacter, trigger: String, data: Dictionary)

# State management
initialize_combat(player: CharacterGrid, opponent: CharacterGrid) -> CombatState
update_combat(state: CombatState, delta: float)
check_win_condition(state: CombatState)
```

---

## Implementation Notes for Godot

1. **Combat State:** Implement `CombatState` as a RefCounted resource that exists only during combat.

2. **Character Cloning:** Create `CombatCharacter` as a separate class from `CharacterInstance`. Clone at combat start; discard after combat ends.

3. **Real-Time Loop:** Use `_process(delta)` in a CombatManager node to drive `update_combat()`.

4. **Event System:** Use Godot signals for events. CombatManager emits signals; effects register as listeners.

5. **Randomness:** Use `randf()` for random floats and `array.pick_random()` for random selection.

6. **Visual Separation:** Keep combat logic separate from visualization. Combat system updates state; a separate visualization layer reads state and plays animations.

7. **CharacterGrid Reuse:** Use existing CharacterGrid for both player and opponent teams. Create two instances—one per team.

---

## Stat Definitions Required

The following stats must exist in `stat_definitions.json`:

| Stat | Display | Default | Description |
|------|---------|---------|-------------|
| `health` | HP | 100 | Character's maximum health points |
| `speed` | SPD | null | Seconds between cooldown triggers (null = passive) |
| `damage` | DMG | null | Base damage dealt on cooldown (null = no damage) |
| `crit_chance` | CRIT | 0 | Percentage chance to deal critical damage (0.0-1.0) |
| `agility` | DEF | 0 | Percentage chance to block incoming damage (0.0-1.0) |

**Note:** `charges` may be used for future ability costs but is not part of the core combat loop.

**Removed from characters:** `income`, `itemSlots`, `startingItemSlots` (these belong on Legacies).

**Renamed:** `defendRate` → `agility` (GDScript snake_case convention).

---

## Integration with Run State

### Combat Entry

```
start_combat(run_state: RunState, opponent_grid: CharacterGrid):
    # Player's characters come from run_state.grid
    combat_state = initialize_combat(run_state.grid, opponent_grid)

    # Combat runs independently of run_state
    return combat_state
```

### Combat Exit

```
end_combat(combat_state: CombatState, run_state: RunState):
    # Original CharacterInstances in run_state.grid are UNCHANGED
    # Combat characters are discarded

    if combat_state.winner == 0:  # Player won
        run_state.add_win()
        # Award XP, gold, etc.
    elif combat_state.winner == 1:  # Player lost
        run_state.add_loss()
        run_state.lose_reputation(run_state.current_round)
    # Draw: no win, no loss, no reputation change
```

---

## Expansion Points

This foundation supports future additions:

- **Character Abilities:** Innate triggered effects defined per character
- **Item Combat Effects:** Items apply effects to characters at combat start
- **Skill Combat Effects:** Skills can grant combat-only buffs/effects
- **Type Interactions:** Character types that modify damage or enable synergies
- **Synergies:** Bonuses based on team composition
- **Status Effects:** Complex buffs/debuffs (poison, stun, shield, etc.)
