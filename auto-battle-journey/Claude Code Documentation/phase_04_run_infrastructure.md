# Phase 4: Run Infrastructure

**Goal**: Run loop, save/load, core UI  
**Duration**: Days 7-9  
**Deliverable**: Can start run, see team, game saves mid-run

---

## Overview

Phase 4 builds the core run experience:
- Run view UI showing team, stats, and progression
- Phase management (Encounter → Combat cycle)
- Auto-save after each phase
- Mid-run save/load persistence
- Navigation between run phases

This phase establishes the game loop structure without implementing the actual encounters or combat (those come in later phases).

---

## Prerequisites

- Phase 3 complete and tested
- All Phase 3 tests passing
- Git commit created for Phase 3
- Godot project closed (to avoid file conflicts)

---

## Implementation Tasks

### Task 1: Create Run View Scene

Create the main UI displayed during an active run.

#### File: `scenes/ui/run_view.tscn`

Create a scene with this structure:
```
RunView (Control)
├── Background (ColorRect) - Dark background
├── TopBar (Panel)
│   └── MarginContainer
│       └── HBoxContainer
│           ├── RoundLabel (Label) - "ROUND 1"
│           ├── VSeparator
│           ├── ReputationLabel (Label) - "❤️ REPUTATION: 20/20"
│           ├── VSeparator
│           ├── WinsLabel (Label) - "⭐ WINS: 0/10"
│           ├── VSeparator
│           └── GoldLabel (Label) - "💰 GOLD: 9"
├── TeamPanel (Panel)
│   └── MarginContainer
│       └── VBoxContainer
│           ├── TeamTitle (Label) - "YOUR TEAM"
│           └── TeamContainer (HBoxContainer)
│               └── (CharacterCard instances added here)
├── CenterPanel (Panel)
│   └── MarginContainer
│       └── VBoxContainer
│           ├── PhaseLabel (Label) - "ENCOUNTER PHASE" or "COMBAT PHASE"
│           ├── PhaseDescription (Label) - Instructions
│           └── ActionButton (Button) - "CHOOSE ENCOUNTER" or "CHOOSE COMBAT"
└── MenuButton (Button) - Top-right corner, "MENU"
```

#### File: `scenes/ui/run_view.gd`

```gdscript
extends Control
# RunView - Main UI during an active run

@onready var round_label = $TopBar/MarginContainer/HBoxContainer/RoundLabel
@onready var reputation_label = $TopBar/MarginContainer/HBoxContainer/ReputationLabel
@onready var wins_label = $TopBar/MarginContainer/HBoxContainer/WinsLabel
@onready var gold_label = $TopBar/MarginContainer/HBoxContainer/GoldLabel

@onready var team_container = $TeamPanel/MarginContainer/VBoxContainer/TeamContainer
@onready var phase_label = $CenterPanel/MarginContainer/VBoxContainer/PhaseLabel
@onready var phase_description = $CenterPanel/MarginContainer/VBoxContainer/PhaseDescription
@onready var action_button = $CenterPanel/MarginContainer/VBoxContainer/ActionButton
@onready var menu_button = $MenuButton

# Preload scenes
const CharacterCardScene = preload("res://scenes/components/character_card.tscn")

# Phase tracking
enum Phase { ENCOUNTER, COMBAT }
var current_phase: Phase = Phase.ENCOUNTER


func _ready() -> void:
	# Connect signals
	RunManager.round_changed.connect(_on_round_changed)
	RunManager.reputation_changed.connect(_on_reputation_changed)
	RunManager.gold_changed.connect(_on_gold_changed)
	
	action_button.pressed.connect(_on_action_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	# Initialize display
	_update_all_displays()
	_setup_phase()


func _update_all_displays() -> void:
	"""Update all UI elements with current run state"""
	_update_top_bar()
	_update_team_display()


func _update_top_bar() -> void:
	"""Update round, reputation, wins, gold display"""
	var round = RunManager.get_round()
	var reputation = RunManager.get_reputation()
	var wins = RunManager.get_wins()
	var gold = RunManager.get_gold()
	
	round_label.text = "ROUND %d" % (round + 1)  # Display as 1-indexed
	reputation_label.text = "❤️ REPUTATION: %d/20" % reputation
	wins_label.text = "⭐ WINS: %d/10" % wins
	gold_label.text = "💰 GOLD: %d" % gold
	
	# Color code reputation
	if reputation <= 5:
		reputation_label.modulate = Color.RED
	elif reputation <= 10:
		reputation_label.modulate = Color.YELLOW
	else:
		reputation_label.modulate = Color.WHITE


func _update_team_display() -> void:
	"""Display all team members"""
	# Clear existing cards
	for child in team_container.get_children():
		child.queue_free()
	
	# Add card for each team member
	var team = RunManager.get_team()
	for char_instance in team:
		var card = CharacterCardScene.instantiate()
		team_container.add_child(card)
		
		# Create temporary character data for display
		var display_data = {
			"id": char_instance.base_character_id,
			"rank": 1,  # Not relevant for runtime display
			"experience": char_instance.experience,
			"equipped_items": char_instance.equipped_items
		}
		
		card.setup(display_data, false)  # Don't calculate with items (already in stats)
		card.set_clickable(false)
		
		# Manually update stats from instance
		_update_card_with_runtime_stats(card, char_instance)


func _update_card_with_runtime_stats(card: Node, char_instance: CharacterInstance) -> void:
	"""Manually set card stats from CharacterInstance"""
	# Access the stat labels in the card
	var stats_container = card.get_node("MarginContainer/VBoxContainer/StatsContainer")
	
	stats_container.get_node("HealthLabel").text = "❤ %d/%d" % [char_instance.current_health, char_instance.max_health]
	stats_container.get_node("AttackLabel").text = "⚔ %d" % char_instance.basic_attack_damage
	stats_container.get_node("DefenseLabel").text = "🛡 %d" % char_instance.defense
	stats_container.get_node("SpeedLabel").text = "⚡ %d" % char_instance.speed
	stats_container.get_node("IncomeLabel").text = "💰 %d" % char_instance.income
	
	# Show level in name
	var name_label = card.get_node("MarginContainer/VBoxContainer/NameLabel")
	name_label.text = "%s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]


func _setup_phase() -> void:
	"""Setup UI for current phase"""
	match current_phase:
		Phase.ENCOUNTER:
			phase_label.text = "ENCOUNTER PHASE"
			phase_description.text = "Select an encounter to improve your team."
			action_button.text = "CHOOSE ENCOUNTER"
		Phase.COMBAT:
			phase_label.text = "COMBAT PHASE"
			phase_description.text = "Select a battle to fight."
			action_button.text = "CHOOSE COMBAT"


func _on_action_button_pressed() -> void:
	"""Handle phase action button"""
	match current_phase:
		Phase.ENCOUNTER:
			_start_encounter_phase()
		Phase.COMBAT:
			_start_combat_phase()


func _start_encounter_phase() -> void:
	"""Navigate to encounter selection"""
	print("RunView: Starting encounter phase...")
	# TODO: Navigate to encounter_select scene (Phase 5)
	print("RunView: Would navigate to encounter_select here")
	
	# For now, simulate completing encounter
	_simulate_encounter_completion()


func _start_combat_phase() -> void:
	"""Navigate to combat selection"""
	print("RunView: Starting combat phase...")
	# TODO: Navigate to combat_select scene (Phase 6)
	print("RunView: Would navigate to combat_select here")
	
	# For now, simulate completing combat
	_simulate_combat_completion()


func _simulate_encounter_completion() -> void:
	"""Temporary: Simulate completing an encounter"""
	print("RunView: Simulating encounter completion...")
	
	# Award some XP and gold
	var team = RunManager.get_team()
	if team.size() > 0:
		team[0].add_experience(30)
	RunManager.add_gold(10)
	
	# Save state
	RunManager.save_run_state()
	
	# Move to combat phase
	current_phase = Phase.COMBAT
	_setup_phase()
	_update_all_displays()


func _simulate_combat_completion() -> void:
	"""Temporary: Simulate completing combat"""
	print("RunView: Simulating combat completion...")
	
	# For now, always win
	RunManager.add_win()
	
	# Save state
	RunManager.save_run_state()
	
	# Advance round
	RunManager.advance_round()
	
	# Check if run is over
	if RunManager.is_run_over():
		_end_run()
		return
	
	# Move to next encounter phase
	current_phase = Phase.ENCOUNTER
	_setup_phase()
	_update_all_displays()


func _end_run() -> void:
	"""Run is over, show results"""
	print("RunView: Run is over!")
	
	var victory = RunManager.did_player_win()
	
	# TODO: Navigate to run_results scene (Phase 7)
	print("RunView: Would navigate to run_results here (Victory: %s)" % victory)
	
	# For now, end run and return to main menu
	RunManager.end_run(victory)
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/main_menu.tscn")


func _on_menu_button_pressed() -> void:
	"""Open pause menu"""
	# TODO: Create pause menu with forfeit option
	print("RunView: Menu button pressed (pause menu not implemented)")


func _on_round_changed(new_round: int) -> void:
	"""Handle round change signal"""
	_update_top_bar()


func _on_reputation_changed(new_reputation: int) -> void:
	"""Handle reputation change signal"""
	_update_top_bar()


func _on_gold_changed(new_gold: int) -> void:
	"""Handle gold change signal"""
	_update_top_bar()
```

**Claude Code Directive**:
```
Create the RunView scene with comprehensive run state display.
This is the main screen during runs. Make sure:
- Top bar shows all important run stats
- Team display shows all 3 characters with current stats
- Phase system alternates between Encounter and Combat
- For now, use simulation functions that advance the run
- UI updates properly when signals fire
- Auto-save happens after each phase

This scene will be the hub for all run activity.
```

---

### Task 2: Update Main Menu to Navigate to Run View

Connect the resume run functionality to actually load the run view.

#### File: `scenes/ui/main_menu.gd` (UPDATE)

Update the `_on_play_pressed()` method:

```gdscript
func _on_play_pressed() -> void:
	# Check if there's an active run to resume
	if RunManager.has_active_run():
		print("MainMenu: Resuming active run...")
		RunManager.load_run_state()
		get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/run_view.tscn")
	else:
		print("MainMenu: Starting new run (draft)...")
		get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/draft.tscn")
```

**Claude Code Directive**:
```
Update main_menu.gd to properly navigate to run_view when resuming a run.
```

---

### Task 3: Update Draft to Navigate to Run View

Connect the draft completion to navigate to run view instead of main menu.

#### File: `scenes/ui/draft.gd` (UPDATE)

Update the `_on_confirm_pressed()` method:

```gdscript
func _on_confirm_pressed() -> void:
	"""Start the run with drafted characters"""
	if drafted_characters.size() != 3:
		push_error("Draft: Must select exactly 3 characters")
		return
	
	print("Draft: Starting run with drafted team...")
	
	# Extract character IDs
	var char_ids = []
	for char_data in drafted_characters:
		char_ids.append(char_data["id"])
	
	# Start run
	RunManager.start_new_run(char_ids)
	
	# Navigate to run view
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/run_view.tscn")
```

**Claude Code Directive**:
```
Update draft.gd to navigate to run_view instead of main menu after starting a run.
```

---

### Task 4: Enhance RunManager with Better State Tracking

Add some helper methods to make run management cleaner.

#### File: `autoloads/run_manager.gd` (UPDATE)

Add these methods to RunManager:

```gdscript
func get_phase_name() -> String:
	"""Get current phase name for display"""
	# Even rounds = encounter, odd rounds = combat
	# Round 0 starts with encounter
	var phase_index = current_round % 2
	if phase_index == 0:
		return "encounter"
	else:
		return "combat"


func get_team_summary() -> Dictionary:
	"""Get summary stats for the team"""
	var summary = {
		"total_health": 0,
		"max_health": 0,
		"average_level": 0.0,
		"total_attack": 0
	}
	
	if team.is_empty():
		return summary
	
	for char_instance in team:
		summary["total_health"] += char_instance.current_health
		summary["max_health"] += char_instance.max_health
		summary["average_level"] += char_instance.level
		summary["total_attack"] += char_instance.basic_attack_damage
	
	summary["average_level"] /= team.size()
	
	return summary


func get_character_by_index(index: int) -> CharacterInstance:
	"""Get a team member by index (0-2)"""
	if index >= 0 and index < team.size():
		return team[index]
	return null
```

**Claude Code Directive**:
```
Add these utility methods to RunManager to make it easier to work with run state.
These will be useful in later phases.
```

---

### Task 5: Create ItemInstance and SkillInstance Data Classes

Create the other data classes for runtime items and skills (used in later phases).

#### File: `scripts/data_classes/item_instance.gd`

```gdscript
class_name ItemInstance
extends RefCounted
# ItemInstance - Runtime representation of an item

var item_id: String = ""
var name: String = ""
var description: String = ""
var image_path: String = ""
var stat_modifiers: Dictionary = {}
var slot: String = ""  # For regular items, not upgrades


func _init(item_data_id: String, is_upgrade: bool = false) -> void:
	"""
	Initialize from item or item upgrade data
	
	Args:
		item_data_id: Item or item upgrade ID from GameData
		is_upgrade: True if this is an item upgrade, false for regular item
	"""
	item_id = item_data_id
	
	var item_data: Dictionary
	if is_upgrade:
		item_data = GameData.get_item_upgrade_by_id(item_id)
	else:
		item_data = GameData.get_item_by_id(item_id)
	
	if item_data.is_empty():
		push_error("ItemInstance: Item data not found: %s" % item_id)
		return
	
	name = item_data["name"]
	description = item_data["description"]
	image_path = item_data["image_path"]
	
	if item_data.has("stat_modifiers"):
		stat_modifiers = item_data["stat_modifiers"].duplicate()
	
	if item_data.has("slot"):
		slot = item_data["slot"]
	elif item_data.has("replaces_slot"):
		slot = item_data["replaces_slot"]


func to_dict() -> Dictionary:
	"""Serialize for saving"""
	return {
		"item_id": item_id,
		"name": name,
		"description": description,
		"image_path": image_path,
		"stat_modifiers": stat_modifiers,
		"slot": slot
	}


static func from_dict(data: Dictionary) -> ItemInstance:
	"""Deserialize from save data"""
	var instance = ItemInstance.new(data["item_id"])
	# Data is already populated from GameData, but restore any runtime changes if needed
	return instance
```

**Claude Code Directive**:
```
Create the ItemInstance class. This is simpler than CharacterInstance since items
don't have complex runtime state. Used primarily for organization and future extensibility.
```

---

#### File: `scripts/data_classes/skill_instance.gd`

```gdscript
class_name SkillInstance
extends RefCounted
# SkillInstance - Runtime representation of a skill

var skill_id: String = ""
var name: String = ""
var description: String = ""
var image_path: String = ""
var effects: Array = []


func _init(skill_data_id: String) -> void:
	"""Initialize from skill data"""
	skill_id = skill_data_id
	
	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		push_error("SkillInstance: Skill data not found: %s" % skill_id)
		return
	
	name = skill_data["name"]
	description = skill_data["description"]
	image_path = skill_data["image_path"]
	
	if skill_data.has("effects"):
		effects = skill_data["effects"].duplicate(true)


func apply_to_character(char_instance: CharacterInstance) -> void:
	"""Apply this skill's effects to a character"""
	for effect in effects:
		var effect_type = effect["type"]
		var stat = effect["stat"]
		var value = effect["value"]
		
		match effect_type:
			"stat_add":
				_modify_stat(char_instance, stat, value, false)
			"stat_multiply":
				_modify_stat(char_instance, stat, value, true)


func _modify_stat(char_instance: CharacterInstance, stat_name: String, value: float, multiply: bool) -> void:
	"""Modify a character stat"""
	match stat_name:
		"health":
			if multiply:
				char_instance.max_health = int(char_instance.max_health * value)
			else:
				char_instance.max_health += int(value)
		"basic_attack_damage":
			if multiply:
				char_instance.basic_attack_damage = int(char_instance.basic_attack_damage * value)
			else:
				char_instance.basic_attack_damage += int(value)
		"speed":
			if multiply:
				char_instance.speed = int(char_instance.speed * value)
			else:
				char_instance.speed += int(value)
		"defense":
			if multiply:
				char_instance.defense = int(char_instance.defense * value)
			else:
				char_instance.defense += int(value)


func to_dict() -> Dictionary:
	"""Serialize for saving"""
	return {
		"skill_id": skill_id,
		"name": name,
		"description": description,
		"image_path": image_path,
		"effects": effects
	}


static func from_dict(data: Dictionary) -> SkillInstance:
	"""Deserialize from save data"""
	var instance = SkillInstance.new(data["skill_id"])
	return instance
```

**Claude Code Directive**:
```
Create the SkillInstance class. Similar to ItemInstance but with effect application
logic. Will be used when characters learn skills during encounters.
```

---

### Task 6: Add Debug Commands for Testing

Add some debug keyboard shortcuts to help test run progression.

#### File: `scenes/ui/run_view.gd` (UPDATE)

Add this method to run_view.gd:

```gdscript
func _input(event: InputEvent) -> void:
	"""Debug controls for testing"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E:  # Complete encounter phase
				if current_phase == Phase.ENCOUNTER:
					print("RunView: [DEBUG] Completing encounter phase")
					_simulate_encounter_completion()
			KEY_C:  # Complete combat phase
				if current_phase == Phase.COMBAT:
					print("RunView: [DEBUG] Completing combat phase")
					_simulate_combat_completion()
			KEY_G:  # Add gold
				print("RunView: [DEBUG] Adding 50 gold")
				RunManager.add_gold(50)
			KEY_X:  # Add XP to first character
				var team = RunManager.get_team()
				if team.size() > 0:
					print("RunView: [DEBUG] Adding 50 XP to first character")
					team[0].add_experience(50)
					_update_team_display()
			KEY_L:  # Lose reputation
				print("RunView: [DEBUG] Losing 5 reputation")
				RunManager.lose_reputation(5)
```

**Claude Code Directive**:
```
Add debug keyboard shortcuts to run_view.gd for testing.
These will make testing much faster. Document them in comments.

Debug Keys:
- E: Complete encounter phase
- C: Complete combat phase  
- G: Add 50 gold
- X: Add 50 XP to first character
- L: Lose 5 reputation
```

---

## Testing Instructions

### Test 1: Run View Loads After Draft

1. Launch game
2. Click **PLAY** → Draft 3 characters → Click **START RUN**
3. **Expected Result**:
   - Run view scene loads
   - Top bar shows: ROUND 1, REPUTATION: 20/20, WINS: 0/10, GOLD: [9-15]
   - Team panel shows all 3 drafted characters
   - Center panel shows "ENCOUNTER PHASE" with "CHOOSE ENCOUNTER" button
   - Menu button visible in corner

**If it fails**:
- Check scene path in draft.gd
- Verify run_view.tscn exists
- Check RunManager.start_new_run() completed successfully

### Test 2: Team Display Shows Correct Stats

1. In run view, examine the 3 character cards
2. **Expected Result**:
   - Each card shows character portrait, name with level
   - Stats show current calculated values (base + rank + items)
   - Health shows current/max format (e.g., "❤ 100/100")
   - All 3 characters display correctly

**If stats are wrong**:
- Check _update_card_with_runtime_stats() logic
- Verify CharacterInstance has correct calculated stats
- Add print statements in _update_team_display()

### Test 3: Top Bar Shows Correct Values

1. Check all values in top bar
2. **Expected Result**:
   - Round shows "ROUND 1" (0-indexed internally, displayed as 1-indexed)
   - Reputation is 20/20
   - Wins is 0/10
   - Gold equals sum of character income (verify manually)

**If values are wrong**:
- Check RunManager getter methods
- Verify _update_top_bar() pulls correct values
- Check starting state in RunManager.start_new_run()

### Test 4: Phase Simulation Works

1. In run view, click **CHOOSE ENCOUNTER** button
2. **Expected Result**:
   - Console prints "Simulating encounter completion..."
   - First character gains 30 XP (check console)
   - Gold increases by 10
   - Phase changes to "COMBAT PHASE"
   - Button changes to "CHOOSE COMBAT"
   - Team display updates (first character may level up)
3. Click **CHOOSE COMBAT** button
4. **Expected Result**:
   - Console prints "Simulating combat completion..."
   - Wins increases to 1/10
   - Round advances to ROUND 2
   - Phase changes back to "ENCOUNTER PHASE"
   - Gold increases (from combat reward)

**If simulation doesn't work**:
- Check _simulate_encounter_completion() and _simulate_combat_completion()
- Verify phase enum and current_phase tracking
- Check RunManager methods (add_win, advance_round, etc.)

### Test 5: Run State Auto-Saves

1. Complete an encounter phase (press E key or click button)
2. Check console for save confirmation
3. Check user:// directory for updated active_run.json
4. **Expected Result**:
   - Console shows "RunManager: Run state saved"
   - active_run.json reflects changes (increased gold, XP, phase advancement)
5. Complete combat phase
6. **Expected Result**:
   - Another save occurs
   - Round advances in save file
   - Wins increments

**If auto-save doesn't work**:
- Check save_run_state() is called after each phase
- Verify file writes successfully
- Check JSON structure in save file

### Test 6: Mid-Run Save/Load

1. Start a run, complete 2-3 phases
2. Note current state (round, gold, wins, character stats)
3. Close game completely
4. Reopen game, click **RESUME RUN**
5. **Expected Result**:
   - Run view loads with exact saved state
   - Round, reputation, wins, gold all correct
   - Team stats match (XP, health, levels)
   - Current phase is correct (encounter or combat)
6. Continue the run from where you left off

**If resume doesn't work**:
- Check RunManager.load_run_state()
- Verify CharacterInstance.from_dict() works
- Check that run_view displays loaded state correctly

### Test 7: Debug Commands Work

1. In run view, press various debug keys:
   - **E**: Complete encounter (if in encounter phase)
   - **C**: Complete combat (if in combat phase)
   - **G**: Add 50 gold
   - **X**: Add 50 XP to first character
   - **L**: Lose 5 reputation
2. **Expected Result**:
   - Each key performs its action
   - Console prints debug messages
   - UI updates immediately
   - Changes persist (save after each action)

**If debug commands don't work**:
- Check _input() method is in run_view.gd
- Verify key codes are correct
- Check that methods are called correctly

### Test 8: Character Level Up

1. Use **X** key repeatedly to add XP to first character
2. **Expected Result**:
   - After 100 XP, character levels up
   - Console prints "CharacterInstance: [char_id] leveled up to 2!"
   - Name updates to show new level: "Brave Knight (Lv.2)"
   - Team display refreshes

**If level up doesn't work**:
- Check CharacterInstance.add_experience() logic
- Verify level up happens at 100 XP
- Check that _update_team_display() is called after XP gain

### Test 9: Run Completion - Victory

1. Use debug keys to complete phases rapidly
2. Get to 10 wins (use **E** then **C** repeatedly)
3. **Expected Result**:
   - After 10th win, console prints "RunView: Run is over!"
   - Console prints "Victory: true"
   - Run ends and returns to main menu
   - Rewards awarded (gems to account)
   - No more active run save file
   - Main menu shows "PLAY" not "RESUME RUN"

**If victory doesn't trigger**:
- Check RunManager.is_run_over() logic
- Verify wins >= 10 condition
- Check _end_run() is called

### Test 10: Run Completion - Defeat

1. Start a new run
2. Use **L** key to lose reputation (20 points total)
3. **Expected Result**:
   - After reputation reaches 0, run ends
   - Console prints "Victory: false"
   - Returns to main menu
   - Smaller reward than victory
   - No active run save

**If defeat doesn't trigger**:
- Check reputation loss logic
- Verify reputation <= 0 condition
- Check that run ends properly

### Test 11: Signals Update UI

1. Start run view
2. Use **G** key to add gold
3. **Expected Result**:
   - Gold label updates immediately
   - No need to refresh entire screen
4. Use **L** key to lose reputation
5. **Expected Result**:
   - Reputation label updates
   - Color changes to yellow/red when low

**If signals don't work**:
- Check signal connections in _ready()
- Verify RunManager emits signals
- Check _on_gold_changed() and _on_reputation_changed() methods

### Test 12: Full Run Cycle

1. Complete a full run from draft to victory/defeat
2. **Expected Steps**:
   - Draft 3 characters
   - Run starts with ROUND 1, ENCOUNTER phase
   - Complete encounter → switches to COMBAT
   - Complete combat → wins increase, round advances
   - Repeat 10 times
   - Run ends, returns to main menu with rewards
3. **Expected Result**:
   - Entire flow works smoothly
   - No crashes or errors
   - State saves after each phase
   - Can resume at any point

**If full cycle has issues**:
- Identify where it breaks
- Check console for errors
- Verify all connections between systems

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
git commit -m "Phase 4: Run Infrastructure

- Created RunView scene with complete run state display
- Implemented phase management (Encounter → Combat cycle)
- Team display shows all characters with runtime stats
- Top bar shows round, reputation, wins, gold
- Auto-save after each phase completion
- Mid-run save/load works correctly
- Resume run navigates to RunView
- Draft completion navigates to RunView
- Added ItemInstance and SkillInstance data classes
- Added debug commands for testing (E, C, G, X, L keys)
- Run completion (victory/defeat) works correctly
- All tests passing: display, phases, save/load, completion"

# Optional: Tag this milestone
git tag -a v0.4-phase4 -m "Phase 4 Complete: Run Infrastructure"
```

---

## Success Criteria

Phase 4 is complete when ALL of the following are true:

- ✅ Run view displays after completing draft
- ✅ Top bar shows all run stats (round, reputation, wins, gold)
- ✅ Team panel shows all 3 characters with correct stats
- ✅ Phase system alternates between Encounter and Combat
- ✅ Simulation functions advance the run properly
- ✅ Auto-save occurs after each phase
- ✅ Mid-run save/load works (can close and resume)
- ✅ Resume run loads RunView with correct state
- ✅ Debug commands work (E, C, G, X, L keys)
- ✅ Character level up works and displays
- ✅ Victory condition (10 wins) ends run properly
- ✅ Defeat condition (0 reputation) ends run properly
- ✅ UI updates via signals (gold, reputation changes)
- ✅ Can complete full run cycle without errors
- ✅ Git commit created with all Phase 4 files

---

## Common Issues & Solutions

### Issue: Run view doesn't load after draft
**Solution**:
- Check scene path in draft.gd (_on_confirm_pressed)
- Verify run_view.tscn is saved
- Check RunManager.start_new_run() completed
- Look for errors in console

### Issue: Team stats don't display correctly
**Solution**:
- Verify CharacterInstance stats are calculated
- Check _update_card_with_runtime_stats() logic
- Make sure node paths to stat labels are correct
- Add print statements to debug

### Issue: Phase doesn't advance
**Solution**:
- Check current_phase tracking
- Verify _simulate_encounter_completion() switches to Combat
- Check _simulate_combat_completion() switches to Encounter
- Make sure _setup_phase() is called after switching

### Issue: Auto-save not working
**Solution**:
- Check save_run_state() is called after each phase
- Verify file permissions
- Check JSON serialization doesn't error
- Look for errors in console during save

### Issue: Resume loads wrong state
**Solution**:
- Check CharacterInstance.from_dict() properly restores
- Verify all fields are saved and loaded
- Check phase tracking is saved/restored
- Compare save file JSON to expected structure

### Issue: Signals don't update UI
**Solution**:
- Verify signal connections in _ready()
- Check RunManager actually emits signals
- Make sure signal handler methods exist
- Test with print statements in handlers

### Issue: Victory/defeat doesn't trigger
**Solution**:
- Check is_run_over() logic
- Verify conditions (wins >= 10, reputation <= 0)
- Make sure _end_run() is called
- Check did_player_win() returns correct value

### Issue: Debug keys don't work
**Solution**:
- Verify _input() method exists in run_view.gd
- Check key code constants (KEY_E, KEY_C, etc.)
- Make sure RunView node receives input
- Test with print statements

---

## Next Steps

Once Phase 4 is complete and all tests pass:

1. Review `phase_05_encounter_system.md` for the next phase
2. Note that the simulation functions will be replaced with real encounter/combat systems
3. Optional: Polish the run view UI (better layout, animations)

**Do not proceed to Phase 5 until all Phase 4 tests pass and the git commit is created.**

---

## Phase 4 Complete! 🎉

You now have:
- ✅ Complete run view UI with all run information
- ✅ Phase management system (Encounter → Combat loop)
- ✅ Auto-save after each phase
- ✅ Full save/load mid-run functionality
- ✅ Run completion with victory/defeat conditions
- ✅ Working game loop structure (ready for real encounters/combat)

Total new files created: ~4
Total lines of code: ~600
Estimated time: 3-5 hours

**Ready for Phase 5: Encounter System (Real encounters, rewards, player choices)**
