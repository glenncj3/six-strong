# Game Design Update: Legacy System

This document describes a major architectural shift in the roguelike auto-battler. Read this fully before planning implementation.

---

## The Core Conceptual Shift

**Before:** Characters were the center of progression. Players collected characters, equipped items and skills to them, and characters carried prestige/fame/income. Runs began by drafting 3 characters.

**After:** Legacies are the center of progression. Players collect Legacies, which act as content bundles and meta-progression anchors. Characters become run-time game objects (like items currently are). Runs begin by drafting 3 Legacies.

Think of it this way:
- **Legacy** = a "faction" or "deck" the player builds over time (meta-progression lives here)
- **Character** = a unit you acquire during a run, like an item in The Bazaar or a minion in Hearthstone Battlegrounds

---

## What is a Legacy?

A Legacy is a new entity that bundles content and owns meta-progression.

### Legacy Contains:
- **Characters** (pool of characters that can appear during runs when this Legacy is drafted)
- **Items** (pool of items that can appear during runs)
- **Skills** (pool of skills that can appear during runs)
- **Unique Encounters** (special encounters added to the encounter pool when drafted)
- **Starting Character** (optional; given immediately when Legacy is drafted)
- **Starting Item** (optional; given immediately when Legacy is drafted)
- **Income Value** (contributes to starting gold when drafted)

### Legacy Owns Meta-Progression:
- **Prestige** (account-level, persistent; unlocks content within this Legacy)
- **Fame** (earned at run end; 100 fame = +1 prestige, same formula as before)
- **Unlock State** (which characters/items/skills/encounters within this Legacy are unlocked)

### How Drafting Works:
1. Player is offered 3 Legacies to choose from (3 rounds, pick 1 each round = 3 total)
2. When a Legacy is drafted:
   - Its starting character (if any) is immediately given to the player
   - Its starting item (if any) is immediately given to the player
   - Its income value is added to starting gold calculation
   - Its unlocked characters, items, skills are added to the **run pool** (can appear in shops, encounters, etc.)
   - Its unique encounters are added to the **encounter pool** (weighted; weighting improves with prestige)

---

## How Characters Change

### Characters Lose:
- `income` stat (moved to Legacy)
- `prestige` (moved to Legacy)
- `fame` tracking (moved to Legacy)
- `itemSlots` (items no longer equip to characters)
- Ability to equip items
- Ability to equip skills
- Role as meta-progression anchor

### Characters Keep:
- `health`
- `mana`
- `defendRate`
- `level` (per-run progression; gates when content appears)
- Base stats and combat identity

### Characters Gain:
- **Grid Position**: Characters are placed in a 2-row, 3-column grid (6 slots max)
- **Drag-and-Drop Repositioning**: Players can move characters freely between slots (swap or fill empty)
- Position will matter for combat (combat system is currently stubbed; grid mechanics will be implemented separately)

### Character Lifecycle (New):
1. Character exists in a Legacy's content pool
2. Legacy is drafted → character enters the run pool
3. Character is acquired during run (shop, encounter, etc.)
4. Character is placed in the player's 2x3 grid
5. Character participates in auto-battles based on grid position

---

## How Items Change

### Before:
- Items equipped to specific characters
- Each character had limited item slots
- Items modified the stats of their equipped character

### After:
- Items belong to the **player**, not characters
- No slot limit; player accumulates items throughout run (like Relics in Slay the Spire)
- Items provide effects at the player/team level
- Items are still acquired from Legacies' content pools

---

## How Skills Change

### Before:
- Skills equipped to characters (max 6 per character)
- Skills provided passive effects via `stat_add` or `stat_multiply`
- Skills were level-gated

### After:
- Skills are **one-shot effects** resolved immediately when acquired
- No passive stat modifiers; skills do something and are consumed
- Some skills may have **lingering effects** (e.g., "the next character you draft gains +10 health")
- No cap on skills; they resolve on acquisition, so there's nothing to accumulate
- Skills are still acquired from Legacies' content pools

---

## How Encounters Change

### Base Encounters:
- The 8 existing encounter types (Shop, Skill Trainer, Health Restore, etc.) remain
- These form the base encounter pool available in all runs

### Legacy-Unique Encounters:
- Legacies can define unique encounters specific to their theme/identity
- When a Legacy is drafted, its unique encounters are **added to the encounter pool** (not guaranteed to appear)
- Weighting for unique encounters is special and scales with Legacy prestige (higher prestige = more likely to see that Legacy's unique encounters)

---

## What Does NOT Change

- **Run structure**: Draft phase → Encounter phase → Combat phase loop
- **Victory/defeat conditions**: 10 wins to victory, 0 reputation = defeat
- **Reputation system**: Start at 20, lose on combat defeat
- **Gold/XP as run currencies**
- **Combat stub**: Still auto-resolves; grid-based combat will be a separate update
- **Account currencies**: Gems, reroll tokens still exist at account level
- **Data-driven architecture**: JSON files, singletons, signal-based communication
- **Encounter types**: The 8 base types still function the same way

---

## Summary of Entity Responsibilities

| Entity | Progression | Content Pool | Run Lifecycle |
|--------|-------------|--------------|---------------|
| **Legacy** | Prestige, Fame, Unlocks | Characters, Items, Skills, Encounters | Drafted at run start; determines available content |
| **Character** | Level (per-run only) | — | Acquired during run; placed in 2x3 grid |
| **Item** | — | — | Acquired during run; belongs to player; no cap |
| **Skill** | — | — | Acquired during run; resolves immediately |

---

## Key Implementation Implications

These are observations, not directives. Use your judgment on implementation approach.

1. **New data structure needed**: Legacies need a JSON definition and runtime representation
2. **Meta-progression migration**: Prestige/fame/unlocks move from Character to Legacy
3. **Character simplification**: Remove equipment system, income, meta-progression from characters
4. **Player-level inventory**: Items need a new home (player/run state, not character)
5. **Skill rework**: Skills become one-shot effects, not passive modifiers
6. **Draft phase update**: Draft Legacies instead of Characters
7. **Run pool system**: Content pools are composed from drafted Legacies' unlocked content
8. **Grid UI**: New 2x3 character grid with drag-and-drop
9. **Encounter pool composition**: Base encounters + weighted Legacy-unique encounters

---

## Questions This Document Does NOT Answer

These require separate design decisions or are out of scope for this update:

- How does grid position affect combat? (Combat is stubbed; tackle separately)
- What are the specific Legacies and their contents? (Content design, not architecture)
- How exactly is encounter weighting calculated? (Tuning decision)
- What do specific skills do now that they're one-shots? (Content design)

Focus on the structural changes that enable this system. Content population comes later.
