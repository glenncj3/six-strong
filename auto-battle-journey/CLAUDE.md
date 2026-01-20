# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Description

A roguelike auto-battler inspired by The Bazaar, featuring character collection, meta-progression, and asynchronous PvP. Players draft 3 characters per run, navigate encounters to improve their team, and battle through 10 combat rounds.

## Tech Stack

- **Engine**: Godot 4.x
- **Language**: GDScript
- **Platform Target**: Mobile (Portrait 9:16 - 720x1280)
- **Renderer**: Mobile

## Project Structure

- `/scenes/` - Godot scene files (.tscn)
- `/scripts/` - GDScript files (.gd)
- `/assets/` - Game assets (sprites, audio, fonts)
  - `/assets/sprites/` - Character and environment sprites
  - `/assets/audio/` - Sound effects and music
  - `/assets/fonts/` - Custom fonts
- `/project.godot` - Main Godot project file

## Godot Commands

- Open Godot Editor: `godot --editor`
- Run the game: `godot --path . res://main.tscn`
- Export for Windows: `godot --export "Windows Desktop" ./build/game.exe`

## Code Conventions

- Use snake_case for variables and functions (Godot standard)
- Use PascalCase for class names
- Use `@export` for variables editable in the Inspector
- Group related functions together with comment headers

## Important Godot Patterns

- Use signals for communication between nodes
- Prefer `_ready()` for initialization over `_init()`
- Use `_process(delta)` for frame-by-frame updates
- Use `_physics_process(delta)` for physics-related updates
- Always call `queue_free()` to remove nodes, never `free()`

---

## Game Design

### Core Loop

Players build a team of 3 characters, navigate through encounters to improve them, and fight 10 battles to achieve victory.

### Progression Systems

#### Account Progression (Persistent)

- **Character Collection**: Unlock characters using gems
- **Character Ranks**: Increase through XP earned across multiple runs
- **Rank Rewards**: Each rank unlocks new items, item upgrades, and skills (some level-gated)
- **Starting Loadouts**: Equip items before runs to improve starting stats
- **Currencies**: Gems (unlock content), Reroll Tokens (reroll draft options)

#### Run Progression (Per-Session)

- **Character Levels**: Track when unlocked content becomes available during the run
- **Reputation**: Start with 20, lose amount equal to round number on defeat, run ends at 0
- **Gold**: Earned per round based on team composition, spent during encounters

### Game Flow

#### 1. Pre-Run: Main Menu

- View/manage character collection
- Equip starting items for owned characters
- View unlocked skills and item upgrades
- Spend gems to unlock characters and content

#### 2. Draft Phase

- Offered 3 characters at a time, choose 1
  - 2 options from your collection (free)
  - 1 random option from entire game (costs gems if not owned)
- Can spend reroll tokens to regenerate options
- Repeat 3 times to build your team
- Starting gold = sum of selected characters' income values

#### 3. Run Loop (Repeat Until Win/Loss)

Each round consists of **Encounter → Combat**:

**Encounter Phase**
- Choose from 3 encounter options (name, type, description, art)
- Encounter types:
  - Shops: Buy items, skills, or upgrades with gold
  - Minigames: Complete challenges for rewards
  - XP Rewards: Gain experience for characters
  - Many other types (highly extensible system)
- Rewards are flexible: XP, gold, items, skills, item upgrades, health changes, etc.
- Player makes all decisions (which character gets what)
- Can adjust team lineup during encounters

**Combat Phase**
- Choose from 3 combat options:
  - AI Enemies: Name, description, art, difficulty, rewards
  - Ghost Players: Asynchronous human opponent teams with name, description, art, rank, rewards
- Combat is 100% automated (no player input once started)
- All 3 characters fight together as a team
- Win: Gain XP and gold based on performance + other rewards
- Loss: Lose reputation equal to current round number

#### 4. Victory/Defeat Conditions

- **Victory**: Win 10 combats total
- **Defeat**: Reputation reaches 0

#### 5. Post-Run: Results Screen

- Display run statistics (rounds, wins, losses, final gold)
- Award gems
- Award character rank XP to the 3 characters used (persistent progression)
- Characters may rank up, unlocking new content
- Return to main menu

### Key Mechanics

#### Character System

Each character has:
- **Base Stats**: Health, attack damage, speed, defense, income
- **Rank** (persistent): Unlocks content and may boost base stats
- **Level** (per-run): Gates when rank-unlocked content can appear
- **Items** (3 types):
  - Starting items (equipped before run, improve base stats)
  - Item upgrades (found in run, replace starting items, strictly better)
  - Skills (found in run, provide effects/bonuses)

#### Item Replacement System

- Start with equipped items (e.g., "Rusty Sword")
- Find item upgrades during encounters (e.g., "Flaming Sword")
- Upgrades replace items in the same slot, are strictly superior
- Characters start with 0 skills, learn them only during runs

#### Runtime Isolation

- Characters are cloned at run start
- All run modifications happen to clones
- Account data only updated at run end (rank XP awards)
- Run state auto-saves after each encounter/combat

### Design Philosophy

- **The Bazaar-inspired**: Tight encounter/combat loop with market-style character improvement
- **Highly extensible**: Encounters designed as modular plugins
- **Data-driven**: All content defined in JSON (characters, items, skills, encounters)
- **Meta-progression**: Account grows stronger through character ranks unlocking more powerful options

## Mobile UI Design

The game is designed for portrait mobile (9:16 aspect ratio, 720x1280 base resolution):

- **Resolution**: 720x1280 with canvas_items stretch mode
- **Orientation**: Portrait (handheld/orientation = 1)
- **Screen margins**: 16px standard, 8px for tight spaces
- **Touch targets**: Minimum 50px height for buttons

### UI Component Sizes

All sizes defined in `GameConstants`:
- Character card: 200x280 (small: 100x140)
- Item slot: 72x90 with 56px icon
- Skill icon: 56x70 with 40px icon

### Scene Layout Patterns

- **Main Menu**: Centered VBox with large touch-friendly buttons
- **Collection**: Full-screen grid (2 columns) with details as overlay
- **Draft**: Vertical scrolling options, horizontal team display at top
- **Run View**: Top stats bar, team panel in upper half, action panel in lower half

## Known Issues

<!-- Document any quirks or bugs as you discover them -->
