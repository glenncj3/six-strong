# Phase 6: Combat Stub

**Goal**: Combat selection and stub results  
**Duration**: Days 14-15  
**Deliverable**: Can choose combat, win/loss affects run state, run completes

---

## Overview

Phase 6 implements the combat selection system and a temporary "stub" combat scene where you manually choose win or loss. This allows full run completion while deferring the complex combat implementation to later.

Players will:
- Choose from 3 combat options (AI or Player Ghost)
- See difficulty/rank and rewards
- "Fight" using win/loss buttons (stub)
- Receive rewards on victory
- Lose reputation on defeat
- Complete runs (10 wins = victory, 0 reputation = defeat)

---

## Prerequisites

- Phase 5 complete and tested
- All Phase 5 tests passing
- Git commit created for Phase 5
- Godot project closed (to avoid file conflicts)

---

## Implementation Tasks

### Task 1: Enhance RunManager with Combat Support

Add methods to RunManager for generating combat options.

#### File: `autoloads/run_manager.gd` (UPDATE)

Add these methods to RunManager:

```gdscript
func generate_combat_options(count: int) -> Array:
	"""
	Generate random combat options (AI enemies or Player Ghosts)
	
	Args:
		count: Number of options to generate (usually 3)
	
	Returns:
		Array of combat option dictionaries
	"""
	var options = []
	
	for i in range(count):
		var is_player_ghost = randf() > 0.5  # 50% chance of player ghost
		
		if is_player_ghost:
			options.append(_generate_player_ghost_option())
		else:
			options.append(_generate_ai_combat_option())
	
	return options


func _generate_ai_combat_option() -> Dictionary:
	"""Generate an AI enemy combat option"""
	var difficulties = ["Easy", "Medium", "Hard"]
	var difficulty = difficulties[randi() % difficulties.size()]
	
	var difficulty_index = difficulties.find(difficulty)
	var base_reward = 20 + (difficulty_index * 10)
	
	return {
		"type": "ai",
		"name": "AI Enemy (%s)" % difficulty,
		"description": "Fight an AI-controlled enemy.",
		"image_path": "res://assets/combat/ai_enemy.png",
		"difficulty": difficulty,
		"reward_gold": base_reward,
		"reward_xp": base_reward + 10
	}


func _generate_player_ghost_option() -> Dictionary:
	"""
	Generate a player ghost combat option
	TODO: Replace with actual ghost team loading from server
	"""
	var rank = randi_range(1, 10)
	var base_reward = 25 + (rank * 5)
	
	return {
		"type": "ghost",
		"name": "Player Ghost (Rank %d)" % rank,
		"description": "Fight another player's team.",
		"image_path": "res://assets/combat/player_ghost.png",
		"rank": rank,
		"reward_gold": base_reward,
		"reward_xp": base_reward + 15
	}


func apply_combat_rewards(won: bool, combat_data: Dictionary) -> void:
	"""
	Apply combat rewards or penalties
	
	Args:
		won: True if player won, false if lost
		combat_data: The combat option data
	"""
	if won:
		# Award gold and XP
		var reward_gold = combat_data.get("reward_gold", 20)
		var reward_xp = combat_data.get("reward_xp", 30)
		
		add_gold(reward_gold)
		
		# Distribute XP to all team members (placeholder - equal distribution)
		for char_instance in team:
			char_instance.add_experience(reward_xp)
		
		print("RunManager: Victory! Awarded %d gold, %d XP per character" % [reward_gold, reward_xp])
	else:
		# Lose reputation equal to round number
		var reputation_loss = current_round + 1  # +1 because displayed as 1-indexed
		lose_reputation(reputation_loss)
		
		print("RunManager: Defeat! Lost %d reputation" % reputation_loss)
```

**Claude Code Directive**:
```
Add combat generation and reward methods to RunManager.
This extends RunManager to support combat options and rewards.
Make sure the generate methods return proper dictionaries with all needed fields.
```

---

### Task 2: Create Combat Selection Scene

Create the UI where players choose which combat to fight.

#### File: `scenes/ui/combat_select.tscn`

Create a scene with this structure:
```
CombatSelect (Control)
├── Background (ColorRect)
├── MainContainer (VBoxContainer)
│   ├── Title (Label) - "CHOOSE A BATTLE"
│   ├── Subtitle (Label) - "Select your opponent"
│   └── OptionsContainer (VBoxContainer) - 3 combat options
│       └── (CombatOption panels x3 added dynamically)
└── BackButton (Button) - "Return to Run" (debug only)
```

#### File: `scenes/ui/combat_select.gd`

```gdscript
extends Control
# CombatSelect - Choose from 3 combat options

@onready var options_container = $MainContainer/OptionsContainer
@onready var back_button = $BackButton

var combat_options: Array = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = false  # Only for testing
	
	_generate_and_display_options()


func _generate_and_display_options() -> void:
	"""Generate 3 combat options and display them"""
	# Clear existing
	for child in options_container.get_children():
		child.queue_free()
	
	# Generate options
	combat_options = RunManager.generate_combat_options(3)
	
	# Create UI for each option
	for i in range(combat_options.size()):
		_create_option_panel(combat_options[i])


func _create_option_panel(combat_data: Dictionary) -> void:
	"""Create a selectable combat option panel"""
	var panel = PanelContainer.new()
	options_container.add_child(panel)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var margin = MarginContainer.new()
	hbox.add_child(margin)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	# Image
	var image = TextureRect.new()
	margin.add_child(image)
	image.custom_minimum_size = Vector2(128, 128)
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(combat_data["image_path"]):
		image.texture = load(combat_data["image_path"])
	
	# Info section
	var info_vbox = VBoxContainer.new()
	hbox.add_child(info_vbox)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Name
	var name_label = Label.new()
	info_vbox.add_child(name_label)
	name_label.text = combat_data["name"]
	name_label.add_theme_font_size_override("font_size", 20)
	
	# Type
	var type_label = Label.new()
	info_vbox.add_child(type_label)
	type_label.text = "[%s]" % combat_data["type"].to_upper()
	type_label.modulate = Color(0.7, 0.7, 0.7)
	
	# Description
	var desc_label = Label.new()
	info_vbox.add_child(desc_label)
	desc_label.text = combat_data["description"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 300
	
	# Difficulty or Rank
	if combat_data["type"] == "ai":
		var diff_label = Label.new()
		info_vbox.add_child(diff_label)
		diff_label.text = "Difficulty: %s" % combat_data["difficulty"]
		
		# Color code difficulty
		match combat_data["difficulty"]:
			"Easy":
				diff_label.modulate = Color.GREEN
			"Medium":
				diff_label.modulate = Color.YELLOW
			"Hard":
				diff_label.modulate = Color.RED
	
	elif combat_data["type"] == "ghost":
		var rank_label = Label.new()
		info_vbox.add_child(rank_label)
		rank_label.text = "Player Rank: %d" % combat_data["rank"]
		rank_label.modulate = Color(0.5, 0.5, 1.0)
	
	# Rewards
	var reward_label = Label.new()
	info_vbox.add_child(reward_label)
	reward_label.text = "Rewards: +%d💰 +%dXP" % [combat_data["reward_gold"], combat_data["reward_xp"]]
	reward_label.modulate = Color(0.3, 1.0, 0.3)
	
	# Spacer
	var spacer = Control.new()
	info_vbox.add_child(spacer)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Fight button
	var fight_button = Button.new()
	info_vbox.add_child(fight_button)
	fight_button.text = "FIGHT"
	fight_button.custom_minimum_size = Vector2(100, 40)
	fight_button.pressed.connect(_on_combat_selected.bind(combat_data))


func _on_combat_selected(combat_data: Dictionary) -> void:
	"""Handle combat selection"""
	print("CombatSelect: Selected %s" % combat_data["name"])
	
	# Navigate to combat stub scene
	var main = get_tree().get_root().get_node("Main")
	
	# Store selected combat data for next scene
	main.set_meta("selected_combat", combat_data)
	
	main.change_scene("res://scenes/ui/combat_stub.tscn")


func _on_back_pressed() -> void:
	"""Return to run view (debug only)"""
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/run_view.tscn")
```

**Claude Code Directive**:
```
Create the CombatSelect scene with 3 combat option panels.
Make sure:
- Each panel shows combat image, name, type, description
- AI enemies show difficulty (color-coded)
- Player ghosts show rank
- Rewards are displayed
- Fight button navigates to combat_stub scene
- Selected combat data is passed via metadata
```

---

### Task 3: Create Combat Stub Scene

Create a temporary combat scene with win/loss buttons for testing.

#### File: `scenes/ui/combat_stub.tscn`

Create a scene with this structure:
```
CombatStub (Control)
├── Background (ColorRect)
├── MainContainer (VBoxContainer) - Center of screen
│   ├── Title (Label) - "COMBAT"
│   ├── OpponentLabel (Label) - Shows opponent name
│   ├── Spacer (Control)
│   ├── StubNotice (Label) - "This is a combat stub for testing"
│   ├── InstructionLabel (Label) - "Choose the outcome:"
│   ├── Spacer2 (Control)
│   ├── ButtonContainer (HBoxContainer)
│   │   ├── WinButton (Button) - "WIN"
│   │   └── LoseButton (Button) - "LOSE"
│   └── ResultLabel (Label) - Shows result after button press
```

#### File: `scenes/ui/combat_stub.gd`

```gdscript
extends Control
# CombatStub - Temporary combat scene for testing
# TODO: Replace with actual combat implementation

@onready var title_label = $MainContainer/Title
@onready var opponent_label = $MainContainer/OpponentLabel
@onready var win_button = $MainContainer/ButtonContainer/WinButton
@onready var lose_button = $MainContainer/ButtonContainer/LoseButton
@onready var result_label = $MainContainer/ResultLabel

var combat_data: Dictionary = {}


func _ready() -> void:
	win_button.pressed.connect(_on_win_pressed)
	lose_button.pressed.connect(_on_lose_pressed)
	
	result_label.text = ""
	
	# Get selected combat data from Main scene metadata
	var main = get_tree().get_root().get_node("Main")
	if main.has_meta("selected_combat"):
		combat_data = main.get_meta("selected_combat")
		main.remove_meta("selected_combat")
		_setup_display()
	else:
		push_error("CombatStub: No combat data found!")


func _setup_display() -> void:
	"""Setup the display with combat data"""
	opponent_label.text = "Opponent: %s" % combat_data["name"]


func _on_win_pressed() -> void:
	"""Handle victory"""
	print("CombatStub: Player chose VICTORY")
	
	# Disable buttons
	win_button.disabled = true
	lose_button.disabled = true
	
	# Show result
	result_label.text = "VICTORY!"
	result_label.modulate = Color.GREEN
	
	# Apply rewards
	RunManager.apply_combat_rewards(true, combat_data)
	RunManager.add_win()
	
	# Save state
	RunManager.save_run_state()
	
	# Wait a moment then proceed
	await get_tree().create_timer(1.5).timeout
	_complete_combat()


func _on_lose_pressed() -> void:
	"""Handle defeat"""
	print("CombatStub: Player chose DEFEAT")
	
	# Disable buttons
	win_button.disabled = true
	lose_button.disabled = true
	
	# Show result
	result_label.text = "DEFEAT..."
	result_label.modulate = Color.RED
	
	# Apply penalties
	RunManager.apply_combat_rewards(false, combat_data)
	RunManager.add_loss()
	
	# Save state
	RunManager.save_run_state()
	
	# Wait a moment then proceed
	await get_tree().create_timer(1.5).timeout
	_complete_combat()


func _complete_combat() -> void:
	"""Complete combat and check if run is over"""
	# Check if run is over
	if RunManager.is_run_over():
		_end_run()
	else:
		# Advance to next round
		RunManager.advance_round()
		
		# Return to run view (next round, encounter phase)
		get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/run_view.tscn")


func _end_run() -> void:
	"""Run is over, navigate to results"""
	var victory = RunManager.did_player_win()
	
	print("CombatStub: Run is over! Victory: %s" % victory)
	
	# TODO: Navigate to run_results scene (Phase 7)
	print("CombatStub: Would navigate to run_results here")
	
	# For now, end run and return to main menu
	RunManager.end_run(victory)
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/main_menu.tscn")
```

**Claude Code Directive**:
```
Create the CombatStub scene with win/loss buttons.
This is temporary - it will be replaced with real combat later.
Make sure:
- Shows opponent information
- Win button applies rewards and increments wins
- Lose button applies reputation penalty and increments losses
- Checks for run completion (10 wins or 0 reputation)
- Advances round and returns to run view if continuing
- Ends run if complete
- Auto-saves after combat
```

---

### Task 4: Update RunView to Navigate to CombatSelect

Replace the combat simulation with real combat selection.

#### File: `scenes/ui/run_view.gd` (UPDATE)

Replace the `_start_combat_phase()` method:

```gdscript
func _start_combat_phase() -> void:
	"""Navigate to combat selection"""
	print("RunView: Starting combat phase...")
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/combat_select.tscn")
```

Remove or comment out the `_simulate_combat_completion()` method (no longer needed).

Also remove or comment out the `_end_run()` method since it's now handled by combat_stub.

**Claude Code Directive**:
```
Update run_view.gd to navigate to combat_select instead of simulating.
Remove the combat simulation method and _end_run() method (now in combat_stub).
Keep the _start_encounter_phase() method as it is.
```

---

### Task 5: Create Placeholder Combat Images

Create simple placeholder images for combat opponents.

**Claude Code Directive**:
```
Create simple placeholder images as colored rectangles (128x128):
- res://assets/combat/ai_enemy.png - Red square with "AI" text
- res://assets/combat/player_ghost.png - Purple square with "GHOST" text

These will be replaced with real art later. If possible, add simple text
overlay using Image.blit_rect or just make colored squares.
```

---

## Testing Instructions

### Test 1: Combat Selection Displays

1. Start or resume a run
2. Complete an encounter (any type)
3. Phase should switch to Combat
4. Click **CHOOSE COMBAT** button
5. **Expected Result**:
   - Combat selection screen loads
   - Shows 3 combat options
   - Mix of AI enemies and Player Ghosts (roughly 50/50)
   - Each shows: image, name, type, description, difficulty/rank, rewards

**If it fails**:
- Check scene path in run_view.gd
- Verify RunManager.generate_combat_options() works
- Check combat_select.tscn exists

### Test 2: Combat Options Show Correct Info

1. Examine the 3 combat options
2. **Expected Results for AI enemies**:
   - Name shows difficulty (Easy/Medium/Hard)
   - Difficulty label color-coded (green/yellow/red)
   - Rewards scale with difficulty
3. **Expected Results for Player Ghosts**:
   - Name shows rank (1-10)
   - Rank displayed in blue
   - Rewards scale with rank

**If info is wrong**:
- Check _generate_ai_combat_option() in RunManager
- Check _generate_player_ghost_option() in RunManager
- Verify _create_option_panel() displays all fields correctly

### Test 3: Combat Stub Loads

1. Click **FIGHT** on any combat option
2. **Expected Result**:
   - Combat stub scene loads
   - Shows opponent name
   - Shows "This is a combat stub for testing" notice
   - Shows WIN and LOSE buttons
   - Both buttons are enabled

**If stub doesn't load**:
- Check scene path in combat_select.gd
- Verify combat_stub.tscn exists
- Check metadata passing works

### Test 4: Winning Combat

1. In combat stub, click **WIN** button
2. **Expected Result**:
   - Buttons become disabled
   - Result label shows "VICTORY!" in green
   - Console shows rewards applied (gold, XP)
   - Wins counter increases (check console)
   - After 1.5 seconds, returns to run view
   - Round advances
   - Phase switches to Encounter
   - Top bar shows increased gold and wins count

**If winning doesn't work**:
- Check _on_win_pressed() logic
- Verify RunManager.apply_combat_rewards(true, ...)
- Check RunManager.add_win()
- Verify save and scene transition

### Test 5: Losing Combat

1. Complete an encounter, then lose combat (click LOSE)
2. **Expected Result**:
   - Result label shows "DEFEAT..." in red
   - Console shows reputation loss
   - Reputation decreases by current round number
   - Losses counter increases
   - Returns to run view
   - Round advances
   - Phase switches to Encounter
   - Top bar shows decreased reputation

**If losing doesn't work**:
- Check _on_lose_pressed() logic
- Verify RunManager.apply_combat_rewards(false, ...)
- Check RunManager.lose_reputation() calculation
- Check RunManager.add_loss()

### Test 6: Rewards Scale with Difficulty

1. Note the rewards for Easy vs Medium vs Hard AI enemies
2. **Expected Result**:
   - Easy: ~20 gold, ~30 XP
   - Medium: ~30 gold, ~40 XP
   - Hard: ~40 gold, ~50 XP
3. Note rewards for different Player Ghost ranks
4. **Expected Result**:
   - Higher ranks give more rewards

**If scaling doesn't work**:
- Check reward calculation in _generate_ai_combat_option()
- Check reward calculation in _generate_player_ghost_option()
- Verify formulas are correct

### Test 7: XP Distribution

1. Win a combat
2. Check all 3 characters in run view
3. **Expected Result**:
   - All 3 characters receive equal XP
   - Characters may level up
   - Console shows XP distribution

**If XP doesn't distribute**:
- Check apply_combat_rewards() loops through team
- Verify CharacterInstance.add_experience() is called
- Check level up triggers properly

### Test 8: Reputation Loss Scales with Round

1. Start a new run
2. Lose combat in round 1
3. **Expected Result**: Lose 1 reputation (now 19/20)
4. Continue to round 2, lose combat
5. **Expected Result**: Lose 2 reputation (now 17/20)
6. Continue to round 3, lose combat
7. **Expected Result**: Lose 3 reputation (now 14/20)

**If reputation loss doesn't scale**:
- Check lose_reputation() call in apply_combat_rewards()
- Verify current_round is used for amount
- Check +1 offset for 1-indexed display

### Test 9: Victory Condition (10 Wins)

1. Use debug keys or play through to get 9 wins
2. Win the 10th combat
3. **Expected Result**:
   - After victory, run ends immediately
   - Console shows "Run is over! Victory: true"
   - Returns to main menu (temporary)
   - RunManager.end_run() is called
   - Rewards distributed (gems, character XP)
   - No active run save file remains

**If victory doesn't trigger**:
- Check RunManager.is_run_over() returns true at 10 wins
- Check did_player_win() returns true
- Verify _end_run() is called in combat stub

### Test 10: Defeat Condition (0 Reputation)

1. Start a new run
2. Intentionally lose combats until reputation reaches 0
3. **Expected Result**:
   - Run ends when reputation hits 0
   - Console shows "Run is over! Victory: false"
   - Returns to main menu
   - Smaller rewards than victory
   - No active run save

**If defeat doesn't trigger**:
- Check RunManager.is_run_over() returns true at 0 reputation
- Check did_player_win() returns false
- Verify defeat handling in combat_stub

### Test 11: Combat Rewards Persist

1. Win a combat, gain gold and XP
2. Close game immediately after returning to run view
3. Reopen and resume run
4. **Expected Result**:
   - Gold increase persisted
   - Character XP/levels persisted
   - Wins count correct
   - Round number correct

**If rewards don't persist**:
- Check save_run_state() is called after combat
- Verify CharacterInstance serialization includes XP/level changes
- Check load properly restores state

### Test 12: Full Run Completion

1. Play through a complete run from draft to victory
2. **Expected Steps**:
   - Draft 3 characters
   - Round 1: Encounter → Combat (win)
   - Round 2: Encounter → Combat (win)
   - ... repeat ...
   - Round 10: Encounter → Combat (win)
   - Run ends with victory
3. **Expected Result**:
   - Entire flow works smoothly
   - All phases transition correctly
   - State saves after each step
   - Victory triggers at 10 wins
   - Returns to main menu with rewards

**If full run has issues**:
- Identify where it breaks
- Check console for errors
- Verify all transitions work

### Test 13: Full Run Defeat

1. Start a run and intentionally lose to deplete reputation
2. With 20 reputation and losing specific amounts:
   - Round 1 loss: -1 (19 left)
   - Round 2 loss: -2 (17 left)
   - Round 3 loss: -3 (14 left)
   - Round 4 loss: -4 (10 left)
   - Round 5 loss: -5 (5 left)
   - Round 6 loss: -6 (triggers defeat at -1)
3. **Expected Result**:
   - Defeat triggers before round 6 completes
   - Run ends properly
   - Returns to main menu

**If defeat timing is wrong**:
- Check reputation calculation
- Verify is_run_over() checks reputation <= 0
- Check that defeat triggers immediately

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
git commit -m "Phase 6: Combat Stub

- Enhanced RunManager with combat option generation
- Created CombatSelect scene with 3 combat options
- Implemented AI enemy options with difficulty scaling
- Implemented Player Ghost options with rank system
- Created CombatStub scene with win/loss buttons
- Victory applies rewards (gold, XP to all characters)
- Defeat applies reputation penalty (scaled by round)
- Win condition (10 wins) triggers run end
- Defeat condition (0 reputation) triggers run end
- Combat rewards persist through save/load
- Full run cycle now complete (draft → encounters → combats → results)
- All tests passing: selection, combat, rewards, win/loss conditions"

# Optional: Tag this milestone
git tag -a v0.6-phase6 -m "Phase 6 Complete: Combat Stub"
```

---

## Success Criteria

Phase 6 is complete when ALL of the following are true:

- ✅ Combat selection shows 3 options
- ✅ Mix of AI enemies and Player Ghosts displayed
- ✅ AI enemies show difficulty (Easy/Medium/Hard) color-coded
- ✅ Player Ghosts show rank (1-10)
- ✅ Rewards scale with difficulty/rank
- ✅ Combat stub loads when FIGHT is clicked
- ✅ Win button applies rewards and increments wins
- ✅ Lose button applies reputation penalty and increments losses
- ✅ Reputation loss scales with current round number
- ✅ XP distributes to all 3 characters
- ✅ Victory condition (10 wins) ends run properly
- ✅ Defeat condition (0 reputation) ends run properly
- ✅ Combat rewards persist through save/load
- ✅ Full run cycle works: draft → encounters → combats → victory/defeat
- ✅ Can complete multiple runs successfully
- ✅ No errors during any combat operation
- ✅ Git commit created with all Phase 6 files

---

## Common Issues & Solutions

### Issue: Combat options don't generate
**Solution**:
- Check RunManager.generate_combat_options() exists
- Verify _generate_ai_combat_option() and _generate_player_ghost_option()
- Add print statements to debug generation

### Issue: Same type appears multiple times
**Solution**:
- This is expected behavior (no duplicate prevention in combat)
- Can be enhanced later if desired

### Issue: Rewards don't apply
**Solution**:
- Check apply_combat_rewards() is called
- Verify won parameter is passed correctly
- Check RunManager.add_gold() works
- Check CharacterInstance.add_experience() is called

### Issue: Reputation doesn't decrease
**Solution**:
- Check apply_combat_rewards(false, ...) calls lose_reputation()
- Verify reputation_loss calculation uses current_round
- Check +1 offset for 1-indexed display

### Issue: Victory doesn't trigger at 10 wins
**Solution**:
- Check is_run_over() logic (wins >= 10)
- Verify _complete_combat() checks is_run_over()
- Check _end_run() is called

### Issue: Defeat doesn't trigger at 0 reputation
**Solution**:
- Check is_run_over() logic (reputation <= 0)
- Verify lose_reputation() can bring reputation to 0
- Check did_player_win() returns false for defeat

### Issue: Run doesn't end properly
**Solution**:
- Check end_run() clears state correctly
- Verify save file is deleted
- Check rewards are distributed
- Verify navigation to main menu works

### Issue: XP doesn't level up characters
**Solution**:
- Check CharacterInstance.add_experience() logic
- Verify level up happens at 100 XP
- Check that levels are saved/loaded correctly

### Issue: Combat results don't persist
**Solution**:
- Check save_run_state() is called after combat
- Verify all state changes are included in save
- Check load_run_state() restores everything

---

## Next Steps

Once Phase 6 is complete and all tests pass:

1. Review `phase_07_run_results.md` for the next phase
2. Consider balancing combat rewards and reputation loss
3. Note that combat_stub.tscn will be replaced with real combat later

**Do not proceed to Phase 7 until all Phase 6 tests pass and the git commit is created.**

---

## Phase 6 Complete! 🎉

You now have:
- ✅ Complete combat selection system
- ✅ AI enemy and Player Ghost options
- ✅ Working combat stub with win/loss outcomes
- ✅ Victory and defeat conditions
- ✅ Full run cycle (draft → encounters → combats → completion)
- ✅ Reward distribution and reputation system
- ✅ Complete game loop structure (ready for real combat implementation)

Total new files created: ~4
Total lines of code: ~500
Estimated time: 3-4 hours

**Ready for Phase 7: Run Results (Victory/defeat screen with rewards)**
