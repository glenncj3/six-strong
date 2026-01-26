# Combat System Design Document

## Overview

This document defines the foundational combat system for an auto-battler game. Combat is real-time, automated, and designed to resolve in approximately 30 seconds. Players assemble units before battle; once combat begins, all actions are executed by the system with no player input.

The system is inspired by The Bazaar's item-based approach (cooldowns, triggers, effects) combined with Once Upon a Galaxy's asynchronous PvP structure (fighting "ghost" snapshots of other players' lineups).

---

## Core Concepts

### Units

Units are the fundamental combat entities. Unlike traditional auto-battlers where units are characters with fixed attack patterns, units here function more like "items" with diverse behaviors:

- **All units have Health.** When a unit's health reaches 0, it is destroyed.
- **Some units have Speed.** Speed determines how frequently a unit acts (cooldown-based).
- **Some units have Damage.** Damage is the base value dealt when the unit attacks.
- **Some units have Effects.** Effects are abilities that trigger under specific conditions.
- **Some units have Crit Chance.** A percentage chance to deal increased damage.
- **Some units have Block Chance.** A percentage chance to negate incoming damage.

Not all units attack. Some exist purely to buff allies, debuff enemies, or provide passive effects.

---

## Data Structures

### Unit

```
Unit {
    id: String                      # Unique identifier
    health: float                   # Current health
    max_health: float               # Maximum health
    
    # Optional combat stats (null/0 if unit doesn't use them)
    speed: float or null            # Seconds between actions (cooldown)
    damage: float or null           # Base damage dealt
    crit_chance: float              # 0.0 to 1.0, percentage chance to crit
    block_chance: float             # 0.0 to 1.0, percentage chance to block
    
    # Positioning
    team: int                       # 0 = player, 1 = opponent
    row: int                        # 0 = front, 1 = back
    column: int                     # 0 = left, 1 = middle, 2 = right
    
    # State
    is_alive: bool                  # true if health > 0
    cooldown_remaining: float       # Time until next action (for speed-based units)
    
    # Type and effects (for future expansion)
    unit_type: String or null       # Optional type tag for ability interactions
    effects: Array<Effect>          # Active effects on this unit
}
```

### Effect (Framework)

```
Effect {
    id: String                      # Effect identifier
    source_unit_id: String          # Unit that applied this effect
    duration: float or null         # Remaining duration (null = permanent until source dies)
    
    # Effect-specific data varies by effect type
    # This structure will be expanded as specific effects are designed
}
```

### Board

```
Board {
    player_units: Array<Unit or null>[6]    # 2 rows × 3 columns, indexed 0-5
    opponent_units: Array<Unit or null>[6]  # 2 rows × 3 columns, indexed 0-5
}
```

**Index mapping for unit arrays:**

```
Player side:          Opponent side (mirrored):
[0][1][2] Front       [0][1][2] Front
[3][4][5] Back        [3][4][5] Back

Visual representation:
     Player                    Opponent
Col: 0   1   2                 0   1   2
    ┌───┬───┬───┐             ┌───┬───┬───┐
Row 0 (Front): │ A │ B │ C │   ←→   │ G │ H │ I │
    ├───┼───┼───┤             ├───┼───┼───┤
Row 1 (Back):  │ D │ E │ F │   ←→   │ J │ K │ L │
    └───┴───┴───┘             └───┴───┴───┘

A directly opposes G (both column 0)
B directly opposes H (both column 1)
C directly opposes I (both column 2)
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

Each player has a 2×3 grid:
- **2 rows:** Front (row 0) and Back (row 1)
- **3 columns:** Left (0), Middle (1), Right (2)

### Mirroring

The opponent's grid is mirrored horizontally in terms of opposition, but column indices remain consistent:
- Player column 0 faces Opponent column 0
- Player column 1 faces Opponent column 1
- Player column 2 faces Opponent column 2

This is NOT a visual mirror—it's a logical opposition where left-side units fight left-side units.

### Position Helper Functions

```
get_unit_at(team: int, row: int, column: int) -> Unit or null
get_position(unit: Unit) -> {team: int, row: int, column: int}
get_column_distance(column_a: int, column_b: int) -> int
    # Returns: abs(column_a - column_b)
```

---

## Targeting System

### Core Targeting Rules

When a unit needs to select a target (enemy for attacks/debuffs, ally for buffs), it follows these rules:

#### Enemy Targeting Priority

1. **Front row first:** Only target back-row enemies if no front-row enemies exist
2. **Nearest column:** Among valid row targets, select those in the nearest column(s)
3. **Random tiebreaker:** If multiple targets are equally valid, select randomly

#### Algorithm: Get Valid Enemy Targets

```
get_valid_enemy_targets(attacking_unit: Unit) -> Array<Unit>:
    attacker_column = attacking_unit.column
    enemy_team = 1 - attacking_unit.team
    
    # Step 1: Get all living enemies by row
    front_row_enemies = get_living_units(enemy_team, row=0)
    back_row_enemies = get_living_units(enemy_team, row=1)
    
    # Step 2: Determine target pool (front row priority)
    if front_row_enemies is not empty:
        target_pool = front_row_enemies
    else if back_row_enemies is not empty:
        target_pool = back_row_enemies
    else:
        return []  # No valid targets
    
    # Step 3: Find minimum column distance
    min_distance = infinity
    for unit in target_pool:
        distance = abs(unit.column - attacker_column)
        if distance < min_distance:
            min_distance = distance
    
    # Step 4: Return all units at minimum distance
    valid_targets = []
    for unit in target_pool:
        if abs(unit.column - attacker_column) == min_distance:
            valid_targets.append(unit)
    
    return valid_targets
```

#### Algorithm: Select Single Target

```
select_enemy_target(attacking_unit: Unit) -> Unit or null:
    valid_targets = get_valid_enemy_targets(attacking_unit)
    if valid_targets is empty:
        return null
    return random_choice(valid_targets)
```

### Ally Targeting (for Buffs)

Ally targeting follows the same spatial rules but targets friendly units:

```
get_valid_ally_targets(buffing_unit: Unit, include_self: bool = false) -> Array<Unit>:
    buffer_column = buffing_unit.column
    friendly_team = buffing_unit.team
    
    # Step 1: Get all living allies by row (excluding self unless specified)
    front_row_allies = get_living_units(friendly_team, row=0)
    back_row_allies = get_living_units(friendly_team, row=1)
    
    if not include_self:
        # Remove the buffing unit from consideration
        front_row_allies.remove(buffing_unit)
        back_row_allies.remove(buffing_unit)
    
    # Step 2: Front row priority
    if front_row_allies is not empty:
        target_pool = front_row_allies
    else if back_row_allies is not empty:
        target_pool = back_row_allies
    else:
        return []
    
    # Step 3: Find minimum column distance
    min_distance = infinity
    for unit in target_pool:
        distance = abs(unit.column - buffer_column)
        if distance < min_distance:
            min_distance = distance
    
    # Step 4: Return all units at minimum distance
    valid_targets = []
    for unit in target_pool:
        if abs(unit.column - buffer_column) == min_distance:
            valid_targets.append(unit)
    
    return valid_targets
```

### Targeting Examples

Reference layout:
```
Player:       Opponent:
A B C         G H _
D _ F         J _ _
```

**Example 1: G attacks**
- G is at column 0
- Front row enemies: A (col 0), B (col 1), C (col 2)
- Nearest to column 0: A (distance 0)
- **G attacks A**

**Example 2: G attacks after A dies**
- Front row enemies: B (col 1), C (col 2)
- Nearest to column 0: B (distance 1)
- **G attacks B**

**Example 3: G attacks after A and B die**
- Front row enemies: C (col 2)
- **G attacks C**

**Example 4: G attacks after A, B, C die**
- Front row enemies: none
- Back row enemies: D (col 0), F (col 2)
- Nearest to column 0: D (distance 0)
- **G attacks D**

**Example 5: H attacks**
- H is at column 1
- Front row enemies: A (col 0), B (col 1), C (col 2)
- Nearest to column 1: B (distance 0)
- **H attacks B**

**Example 6: H attacks after B dies**
- Front row enemies: A (col 0), C (col 2)
- Distance from column 1: A is 1, C is 1
- Both equally close
- **H randomly attacks A or C**

**Example 7: J buffs an ally**
- J is at column 0
- Front row allies: G (col 0), H (col 1)
- Nearest to column 0: G (distance 0)
- **J buffs G**

**Example 8: A buffs an ally**
- A is at column 0
- Front row allies: B (col 1), C (col 2) — A excluded as buffer
- Back row allies: D (col 0), F (col 2)
- Front row has valid targets, so use front row
- Nearest to column 0: B (distance 1)
- **A buffs B**

---

## Combat Loop

### Initialization

```
initialize_combat(player_lineup: Array<Unit>, opponent_lineup: Array<Unit>) -> CombatState:
    state = new CombatState()
    state.board = new Board()
    
    # Place units (lineup arrays should be length 6, with null for empty slots)
    for i in range(6):
        if player_lineup[i] is not null:
            unit = clone(player_lineup[i])
            unit.team = 0
            unit.row = i / 3  # 0-2 = row 0, 3-5 = row 1
            unit.column = i % 3
            unit.is_alive = true
            unit.cooldown_remaining = unit.speed or 0  # Start at full cooldown
            state.board.player_units[i] = unit
        
        if opponent_lineup[i] is not null:
            unit = clone(opponent_lineup[i])
            unit.team = 1
            unit.row = i / 3
            unit.column = i % 3
            unit.is_alive = true
            unit.cooldown_remaining = unit.speed or 0
            state.board.opponent_units[i] = unit
    
    state.elapsed_time = 0
    state.combat_active = true
    state.winner = null
    
    return state
```

### Main Loop (Real-Time)

The combat system runs in real-time using Godot's `_process(delta)` or a fixed timestep.

```
update_combat(state: CombatState, delta: float):
    if not state.combat_active:
        return
    
    state.elapsed_time += delta
    
    # Update all living units
    all_units = get_all_living_units(state.board)
    
    for unit in all_units:
        update_unit(unit, state, delta)
    
    # Check win condition
    check_win_condition(state)
```

### Unit Update

```
update_unit(unit: Unit, state: CombatState, delta: float):
    if not unit.is_alive:
        return
    
    # Only process cooldown for units with speed (cooldown-based units)
    if unit.speed is not null and unit.speed > 0:
        unit.cooldown_remaining -= delta
        
        if unit.cooldown_remaining <= 0:
            # Unit is ready to act
            execute_unit_action(unit, state)
            
            # Reset cooldown
            unit.cooldown_remaining = unit.speed
    
    # Process trigger-based effects (handled by effect system, not here)
    # Process passive effects (handled by effect system, not here)
```

### Action Execution Framework

```
execute_unit_action(unit: Unit, state: CombatState):
    # This is a framework - specific unit behaviors will override/extend this
    
    # Default behavior: If unit has damage, attack an enemy
    if unit.damage is not null and unit.damage > 0:
        target = select_enemy_target(unit)
        if target is not null:
            execute_attack(unit, target, state)
    
    # Units with effects/abilities will have custom action logic
    # defined in their effect/ability definitions
```

---

## Damage Resolution

### Attack Execution

```
execute_attack(attacker: Unit, defender: Unit, state: CombatState):
    # Step 1: Check for block
    if defender.block_chance > 0:
        roll = random_float(0.0, 1.0)
        if roll < defender.block_chance:
            # Attack blocked
            emit_event("attack_blocked", {attacker: attacker, defender: defender})
            return
    
    # Step 2: Calculate damage
    damage = attacker.damage
    is_crit = false
    
    # Step 3: Check for critical hit
    if attacker.crit_chance > 0:
        roll = random_float(0.0, 1.0)
        if roll < attacker.crit_chance:
            damage = damage * CRIT_MULTIPLIER  # Define CRIT_MULTIPLIER as constant (e.g., 2.0)
            is_crit = true
    
    # Step 4: Apply damage
    apply_damage(defender, damage, attacker, state)
    
    # Step 5: Emit event for visual feedback and triggers
    emit_event("attack_executed", {
        attacker: attacker,
        defender: defender,
        damage: damage,
        is_crit: is_crit
    })
```

### Damage Application

```
apply_damage(target: Unit, amount: float, source: Unit or null, state: CombatState):
    if not target.is_alive:
        return
    
    target.health -= amount
    
    emit_event("damage_dealt", {
        target: target,
        amount: amount,
        source: source
    })
    
    if target.health <= 0:
        target.health = 0
        kill_unit(target, state)
```

### Unit Death

```
kill_unit(unit: Unit, state: CombatState):
    unit.is_alive = false
    
    # Remove effects that this unit was providing to others
    # (Implementation depends on effect system design)
    
    # Clear effects on this unit
    unit.effects = []
    
    emit_event("unit_died", {unit: unit})
```

---

## Win Condition

```
check_win_condition(state: CombatState):
    player_alive = has_living_units(state.board, team=0)
    opponent_alive = has_living_units(state.board, team=1)
    
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
        emit_event("combat_ended", {winner: 2})
    
    # If both have living units, combat continues

has_living_units(board: Board, team: int) -> bool:
    units = board.player_units if team == 0 else board.opponent_units
    for unit in units:
        if unit is not null and unit.is_alive:
            return true
    return false
```

---

## Constants

```
CRIT_MULTIPLIER = 2.0           # Damage multiplier on critical hits
MAX_COMBAT_TIME = 30.0          # Optional: Force draw after 30 seconds
```

---

## Event System

The combat system emits events for:
- Visual feedback (animations, particles, UI updates)
- Trigger-based abilities to listen and react
- Logging and replay functionality

### Core Events

| Event Name | Data | Description |
|------------|------|-------------|
| `combat_started` | `{state}` | Combat initialization complete |
| `combat_ended` | `{winner}` | Combat resolved |
| `unit_action` | `{unit}` | Unit executed its action |
| `attack_executed` | `{attacker, defender, damage, is_crit}` | Attack completed |
| `attack_blocked` | `{attacker, defender}` | Attack was blocked |
| `damage_dealt` | `{target, amount, source}` | Damage applied to unit |
| `unit_died` | `{unit}` | Unit health reached 0 |
| `effect_applied` | `{target, effect, source}` | Effect added to unit |
| `effect_removed` | `{target, effect}` | Effect removed from unit |

---

## Helper Functions Summary

```
# Unit queries
get_all_living_units(board: Board) -> Array<Unit>
get_living_units(team: int, row: int) -> Array<Unit>
get_unit_at(team: int, row: int, column: int) -> Unit or null
has_living_units(board: Board, team: int) -> bool

# Targeting
get_valid_enemy_targets(unit: Unit) -> Array<Unit>
get_valid_ally_targets(unit: Unit, include_self: bool) -> Array<Unit>
select_enemy_target(unit: Unit) -> Unit or null
select_ally_target(unit: Unit, include_self: bool) -> Unit or null
get_column_distance(col_a: int, col_b: int) -> int

# Combat actions
execute_attack(attacker: Unit, defender: Unit, state: CombatState)
apply_damage(target: Unit, amount: float, source: Unit, state: CombatState)
kill_unit(unit: Unit, state: CombatState)

# State management
initialize_combat(player: Array, opponent: Array) -> CombatState
update_combat(state: CombatState, delta: float)
check_win_condition(state: CombatState)
```

---

## Implementation Notes for Godot

1. **Combat State:** Implement `CombatState` as a custom Resource or Node that persists through the battle scene.

2. **Unit Representation:** Units should be Nodes (e.g., `Node2D` or `Control`) with attached scripts implementing the Unit data structure.

3. **Real-Time Loop:** Use `_process(delta)` or `_physics_process(delta)` in a CombatManager node to drive `update_combat()`.

4. **Event System:** Use Godot's signal system for events. Create custom signals on the CombatManager and connect unit nodes and UI elements as listeners.

5. **Randomness:** Use `randf()` for random floats and `randi() % array.size()` or `array.pick_random()` for random selection.

6. **Visual Separation:** Keep combat logic separate from visual representation. The combat system updates state; a separate visualization layer reads state and plays animations.

---

## Expansion Points

This foundation is designed to be extended with:

- **Unit Abilities:** Custom action logic per unit type
- **Trigger System:** Effects that fire on specific events (on_hit, on_death, on_ally_death, etc.)
- **Status Effects:** Buffs/debuffs with duration, stacking rules, and stat modifications
- **Type Interactions:** Unit types that modify damage or enable special abilities
- **Synergies:** Bonuses based on unit composition

These systems will build on the event system and action framework defined here.
