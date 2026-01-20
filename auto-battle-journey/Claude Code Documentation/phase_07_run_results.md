# Phase 7: Run Results & Loop Closure

**Goal**: Complete the run loop with results screen and rewards  
**Duration**: Days 16-17  
**Deliverable**: Full run loop functional, can repeat runs

---

## Overview

Phase 7 implements the run results screen that:
- Displays victory or defeat status
- Shows run statistics (rounds, wins, losses, gold earned)
- Awards gems based on performance
- Awards character rank XP to the 3 characters used
- May trigger character rank ups and unlock new content
- Returns to main menu for another run

This phase closes the game loop, making it fully playable and repeatable.

---

## Prerequisites

- Phase 6 complete and tested
- All Phase 6 tests passing
- Git commit created for Phase 6
- Godot project closed (to avoid file conflicts)

---

## Implementation Tasks

### Task 1: Create Run Results Scene

Create the comprehensive results screen.

#### File: `scenes/ui/run_results.tscn`

Create a scene with this structure:
```
RunResults (Control)
├── Background (ColorRect)
├── MainContainer (VBoxContainer) - Centered
│   ├── ResultTitle (Label) - "VICTORY!" or "DEFEAT"
│   ├── Spacer (Control)
│   ├── StatsPanel (Panel)
│   │   └── MarginContainer
│   │       └── StatsContainer (VBoxContainer)
│   │           ├── StatsTitle (Label) - "RUN STATISTICS"
│   │           ├── RoundsLabel (Label)
│   │           ├── WinsLabel (Label)
│   │           ├── LossesLabel (Label)
│   │           ├── GoldEarnedLabel (Label)
│   │           └── ReputationLabel (Label)
│   ├── Spacer2 (Control)
│   ├── RewardsPanel (Panel)
│   │   └── MarginContainer
│   │       └── RewardsContainer (VBoxContainer)
│   │           ├── RewardsTitle (Label) - "REWARDS"
│   │           ├── GemsLabel (Label) - "+X Gems"
│   │           └── CharacterXPContainer (VBoxContainer)
│   │               └── (Character XP awards listed here)
│   ├── Spacer3 (Control)
│   ├── RankUpsPanel (Panel) - Only visible if rank ups occurred
│   │   └── MarginContainer
│   │       └── RankUpsContainer (VBoxContainer)
│   │           ├── RankUpsTitle (Label) - "RANK UPS!"
│   │           └── RankUpsList (VBoxContainer)
│   │               └── (Rank up notifications listed here)
│   └── ContinueButton (Button) - "CONTINUE"
```

#### File: `scenes/ui/run_results.gd`

```gdscript
extends Control
# RunResults - Display run completion results and rewards

@onready var result_title = $MainContainer/ResultTitle
@onready var rounds_label = $MainContainer/StatsPanel/MarginContainer/StatsContainer/RoundsLabel
@onready var wins_label = $MainContainer/StatsPanel/MarginContainer/StatsContainer/WinsLabel
@onready var losses_label = $MainContainer/StatsPanel/MarginContainer/StatsContainer/LossesLabel
@onready var gold_earned_label = $MainContainer/StatsPanel/MarginContainer/StatsContainer/GoldEarnedLabel
@onready var reputation_label = $MainContainer/StatsPanel/MarginContainer/StatsContainer/ReputationLabel

@onready var gems_label = $MainContainer/RewardsPanel/MarginContainer/RewardsContainer/GemsLabel
@onready var character_xp_container = $MainContainer/RewardsPanel/MarginContainer/RewardsContainer/CharacterXPContainer

@onready var rank_ups_panel = $MainContainer/RankUpsPanel
@onready var rank_ups_list = $MainContainer/RankUpsPanel/MarginContainer/RankUpsContainer/RankUpsList

@onready var continue_button = $MainContainer/ContinueButton

# Store run data before it's cleared
var run_data: Dictionary = {}
var was_victory: bool = false
var rank_ups: Array = []  # Track which characters ranked up


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)

	# Get run data from SceneManager or RunManager
	run_data = SceneManager.get_scene_data("run_results", {})
	if not run_data.is_empty():
		was_victory = run_data.get("victory", false)
	else:
		# Fallback: capture from RunManager before it clears
		_capture_run_data()

	_display_results()


func _capture_run_data() -> void:
	"""Capture run data from RunManager"""
	run_data = {
		"round": RunManager.get_round(),
		"wins": RunManager.get_wins(),
		"losses": RunManager.get_losses(),
		"gold": RunManager.get_gold(),
		"reputation": RunManager.get_reputation(),
		"starting_gold": RunManager.starting_gold,
		"team": []
	}
	
	# Capture team info
	for char_instance in RunManager.get_team():
		run_data["team"].append({
			"id": char_instance.base_character_id,
			"name": char_instance.get_character_name(),
			"level": char_instance.level
		})
	
	was_victory = RunManager.did_player_win()


func _display_results() -> void:
	"""Display all results information"""
	_display_title()
	_display_stats()
	_display_rewards()
	_display_rank_ups()


func _display_title() -> void:
	"""Display victory or defeat title"""
	if was_victory:
		result_title.text = "VICTORY!"
		result_title.modulate = Color(0.2, 1.0, 0.2)
		result_title.add_theme_font_size_override("font_size", 48)
	else:
		result_title.text = "DEFEAT"
		result_title.modulate = Color(1.0, 0.2, 0.2)
		result_title.add_theme_font_size_override("font_size", 48)


func _display_stats() -> void:
	"""Display run statistics"""
	var rounds = run_data.get("round", 0) + 1  # 1-indexed for display
	var wins = run_data.get("wins", 0)
	var losses = run_data.get("losses", 0)
	var gold = run_data.get("gold", 0)
	var starting_gold = run_data.get("starting_gold", 0)
	var reputation = run_data.get("reputation", 0)

	rounds_label.text = "Rounds Completed: %d" % rounds
	wins_label.text = "Victories: %d" % wins
	losses_label.text = "Defeats: %d" % losses
	gold_earned_label.text = "Gold Earned: %d (Started: %d)" % [gold, starting_gold]
	reputation_label.text = "Final Reputation: %d/%d" % [reputation, GameConstants.STARTING_REPUTATION]


func _display_rewards() -> void:
	"""Display and apply rewards"""
	# Calculate gem reward
	var gem_reward = _calculate_gem_reward()
	gems_label.text = "+%d 💎 Gems" % gem_reward
	gems_label.add_theme_font_size_override("font_size", 24)
	gems_label.modulate = Color(0.3, 1.0, 0.3)
	
	# Apply gem reward
	PlayerAccount.add_gems(gem_reward)
	
	# Calculate and display character XP
	var xp_reward = _calculate_character_xp_reward()
	
	for char_data in run_data.get("team", []):
		var char_id = char_data["id"]
		var char_name = char_data["name"]
		
		# Create XP award label
		var xp_label = Label.new()
		xp_label.text = "%s: +%d Rank XP" % [char_name, xp_reward]
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		character_xp_container.add_child(xp_label)
		
		# Get current rank before adding XP
		var char_account_data = PlayerAccount.get_character_data(char_id)
		var old_rank = char_account_data.get("rank", 1)
		
		# Apply XP to account character
		PlayerAccount.add_character_experience(char_id, xp_reward)
		
		# Check if ranked up
		var new_char_data = PlayerAccount.get_character_data(char_id)
		var new_rank = new_char_data.get("rank", 1)
		
		if new_rank > old_rank:
			rank_ups.append({
				"name": char_name,
				"old_rank": old_rank,
				"new_rank": new_rank,
				"id": char_id
			})


func _calculate_gem_reward() -> int:
	"""Calculate gem reward based on performance"""
	var base_reward = 25
	
	if was_victory:
		base_reward = 100
	
	# Bonus for wins
	var wins = run_data.get("wins", 0)
	var win_bonus = wins * 5
	
	# Bonus for remaining reputation (if victory)
	var reputation_bonus = 0
	if was_victory:
		var reputation = run_data.get("reputation", 0)
		reputation_bonus = reputation * 2
	
	return base_reward + win_bonus + reputation_bonus


func _calculate_character_xp_reward() -> int:
	"""Calculate character rank XP based on performance"""
	var base_xp = 25
	
	if was_victory:
		base_xp = 75
	
	# Bonus for wins
	var wins = run_data.get("wins", 0)
	var win_bonus = wins * 5
	
	return base_xp + win_bonus


func _display_rank_ups() -> void:
	"""Display rank up notifications if any occurred"""
	if rank_ups.is_empty():
		rank_ups_panel.visible = false
		return
	
	rank_ups_panel.visible = true
	
	for rank_up in rank_ups:
		var rank_up_container = VBoxContainer.new()
		rank_ups_list.add_child(rank_up_container)
		
		# Character name and rank change
		var name_label = Label.new()
		name_label.text = "%s RANKED UP!" % rank_up["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.modulate = Color(1.0, 0.84, 0.0)  # Gold color
		rank_up_container.add_child(name_label)
		
		var rank_label = Label.new()
		rank_label.text = "Rank %d → Rank %d" % [rank_up["old_rank"], rank_up["new_rank"]]
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_up_container.add_child(rank_label)
		
		# Show unlocked content
		_display_rank_rewards(rank_up_container, rank_up["id"], rank_up["new_rank"])
		
		# Add separator
		var separator = HSeparator.new()
		rank_ups_list.add_child(separator)


func _display_rank_rewards(container: VBoxContainer, char_id: String, new_rank: int) -> void:
	"""Display what was unlocked at the new rank"""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		return
	
	if not char_master.has("rank_rewards"):
		return
	
	# Find rewards for this rank
	for rank_reward in char_master["rank_rewards"]:
		if rank_reward["rank"] == new_rank:
			# Display unlocked content
			if rank_reward.has("rewards"):
				var unlocks_label = Label.new()
				unlocks_label.text = "Unlocked:"
				unlocks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				unlocks_label.modulate = Color(0.7, 0.7, 0.7)
				container.add_child(unlocks_label)
				
				for reward in rank_reward["rewards"]:
					var reward_label = Label.new()
					var reward_name = _get_reward_name(reward)
					reward_label.text = "• %s" % reward_name
					reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					reward_label.modulate = Color(0.3, 1.0, 0.3)
					container.add_child(reward_label)
			
			# Display stat boosts
			if rank_reward.has("stat_boost"):
				var boost_label = Label.new()
				boost_label.text = "Stat Boost:"
				boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				boost_label.modulate = Color(0.7, 0.7, 0.7)
				container.add_child(boost_label)
				
				for stat_name in rank_reward["stat_boost"]:
					var boost_value = rank_reward["stat_boost"][stat_name]
					var stat_label = Label.new()
					stat_label.text = "• %s +%d" % [stat_name.capitalize(), boost_value]
					stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					stat_label.modulate = Color(0.3, 0.7, 1.0)
					container.add_child(stat_label)
			
			break


func _get_reward_name(reward: Dictionary) -> String:
	"""Get display name for a reward"""
	var reward_type = reward["type"]
	var reward_id = reward["id"]
	
	match reward_type:
		"item":
			var item_data = GameData.get_item_by_id(reward_id)
			return item_data.get("name", reward_id)
		"item_upgrade":
			var upgrade_data = GameData.get_item_upgrade_by_id(reward_id)
			return upgrade_data.get("name", reward_id)
		"skill":
			var skill_data = GameData.get_skill_by_id(reward_id)
			var skill_name = skill_data.get("name", reward_id)
			if reward.has("level_requirement"):
				skill_name += " (Req. Level %d)" % reward["level_requirement"]
			return skill_name
		_:
			return reward_id


func _on_continue_pressed() -> void:
	"""Return to main menu"""
	print("RunResults: Continuing to main menu")

	# End run and clear state (if not already done)
	if RunManager.is_run_active:
		RunManager.end_run(was_victory)

	# Navigate to main menu using SceneManager
	SceneManager.go_to_main_menu()
```

**Claude Code Directive**:
```
Create the RunResults scene with comprehensive results display.
This is the final scene in a run. Make sure:
- Victory/defeat status is prominently displayed
- Run statistics show all relevant info
- Gem rewards are calculated and applied
- Character rank XP is calculated and applied
- Rank ups are detected and displayed with unlocked content
- Continue button properly returns to main menu
- Run state is cleared

This scene needs to work whether data comes from metadata or directly from RunManager.
```

---

### Task 2: Update Combat Stub to Navigate to Run Results

Change combat_stub to pass data to run_results instead of ending run directly.

#### File: `scenes/ui/combat_stub.gd` (UPDATE)

Replace the `_end_run()` method to use SceneManager:

```gdscript
func _end_run() -> void:
	"""Run is over, navigate to results"""
	var victory = RunManager.did_player_win()

	print("CombatStub: Run is over! Victory: %s" % victory)

	# Store run data for results screen via SceneManager
	SceneManager.set_scene_data("run_results", {
		"round": RunManager.get_round(),
		"wins": RunManager.get_wins(),
		"losses": RunManager.get_losses(),
		"gold": RunManager.get_gold(),
		"reputation": RunManager.get_reputation(),
		"starting_gold": RunManager.starting_gold,
		"victory": victory,
		"team": _capture_team_data()
	})

	# Navigate to results screen
	SceneManager.go_to("run_results")


func _capture_team_data() -> Array:
	"""Capture team data before run ends"""
	var team_data = []
	for char_instance in RunManager.get_team():
		team_data.append({
			"id": char_instance.base_character_id,
			"name": char_instance.get_character_name(),
			"level": char_instance.level
		})
	return team_data
```

**Claude Code Directive**:
```
Update combat_stub.gd to navigate to run_results instead of ending run directly.
Pass all necessary data via metadata so results screen can display everything.
Add the _capture_team_data() helper method.
```

---

### Task 3: Update Run Results to Handle Victory Flag

The run_results.gd needs to get victory status from SceneManager.

#### File: `scenes/ui/run_results.gd` (UPDATE)

Update the `_ready()` method to use SceneManager for data retrieval:

```gdscript
func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)

	# Get run data from SceneManager
	run_data = SceneManager.get_scene_data("run_results", {})
	if not run_data.is_empty():
		was_victory = run_data.get("victory", false)
	else:
		# Fallback: capture from RunManager before it clears
		_capture_run_data()

	_display_results()
```

**Claude Code Directive**:
```
Update run_results.gd to use SceneManager.get_scene_data() for data retrieval.
This ensures the victory/defeat status is correctly displayed.
```

---

### Task 4: Enhance RunManager End Run Method

Make sure end_run properly clears state but doesn't double-award rewards.

#### File: `autoloads/run_manager.gd` (UPDATE)

Update the `end_run()` method:

```gdscript
func end_run(victory: bool) -> void:
	"""
	End the current run and clear state
	Note: Rewards should be applied BEFORE calling this (in run_results)
	
	Args:
		victory: True if player won (10 combats), false if defeated (0 reputation)
	"""
	print("RunManager: Ending run - %s" % ("VICTORY" if victory else "DEFEAT"))
	
	# Clear run state
	_clear_run_state()
	
	print("RunManager: Run ended, state cleared")
```

Remove the reward distribution from end_run() since it's now handled in run_results:

```gdscript
# REMOVE these lines from end_run():
# # Award character rank XP (placeholder: 50 XP per character)
# for char_instance in team:
# 	PlayerAccount.add_character_experience(char_instance.base_character_id, 50)
# 
# # Award gems (placeholder)
# if victory:
# 	PlayerAccount.add_gems(100)
# else:
# 	PlayerAccount.add_gems(25)
```

**Claude Code Directive**:
```
Update RunManager.end_run() to only clear state, not distribute rewards.
Rewards are now handled by run_results.gd to ensure they're displayed properly.
```

---

### Task 5: Add Starting Gold Tracking to RunManager

Make sure starting_gold is accessible for the results screen.

#### File: `autoloads/run_manager.gd` (UPDATE)

The `starting_gold` variable should already exist. Make sure it's included in save/load:

```gdscript
# In save_run_state():
var save_data = {
	"run_id": run_id,
	"round": current_round,
	"reputation": reputation,
	"wins": wins,
	"losses": losses,
	"starting_gold": starting_gold,  # Make sure this line exists
	"current_gold": current_gold,
	"team": [],
	"encounter_history": encounter_history
}

# In load_run_state():
starting_gold = save_data["starting_gold"]  # Make sure this line exists
```

**Claude Code Directive**:
```
Verify that starting_gold is properly saved and loaded in RunManager.
This is needed for the results screen to show how much gold was earned vs started with.
```

---

## Testing Instructions

### Test 1: Victory Results Screen

1. Start a run and win 10 combats
2. **Expected Result**:
   - Results screen loads (not main menu directly)
   - Title shows "VICTORY!" in green
   - Statistics show: rounds, wins, losses, gold, reputation

**If results screen doesn't load**:
- Check _end_run() in combat_stub.gd navigates to run_results
- Verify scene path is correct
- Check metadata passing

### Test 2: Defeat Results Screen

1. Start a run and lose until reputation is 0
2. **Expected Result**:
   - Results screen loads
   - Title shows "DEFEAT" in red
   - Statistics show final state

**If defeat doesn't show results**:
- Check combat_stub handles defeat same as victory
- Verify was_victory is set correctly

### Test 3: Statistics Display

1. Complete a run (any outcome)
2. Check statistics panel
3. **Expected Result**:
   - Rounds matches how many you completed
   - Wins matches your victory count
   - Losses matches your defeat count
   - Gold shows final amount and starting amount
   - Reputation shows final value

**If stats are wrong**:
- Check run_data is captured correctly
- Verify metadata contains all fields
- Check _display_stats() reads correct values

### Test 4: Gem Rewards - Victory

1. Win a run with high performance (10 wins, high reputation)
2. Note gems before run
3. Check gem reward on results screen
4. Click Continue, check gems in main menu
5. **Expected Result**:
   - Victory base reward: 100 gems
   - + Win bonus: 5 per win (50 for 10 wins)
   - + Reputation bonus: 2 per remaining reputation
   - Gems increase by calculated amount
   - Example: 10 wins, 15 reputation = 100 + 50 + 30 = 180 gems

**If gems are wrong**:
- Check _calculate_gem_reward() logic
- Verify PlayerAccount.add_gems() is called
- Check that rewards aren't being applied twice

### Test 5: Gem Rewards - Defeat

1. Lose a run (reputation to 0)
2. Note gems before and after
3. **Expected Result**:
   - Defeat base reward: 25 gems
   - + Win bonus: 5 per win
   - No reputation bonus
   - Example: 3 wins before defeat = 25 + 15 = 40 gems

**If defeat gems are wrong**:
- Check defeat branch in _calculate_gem_reward()
- Verify was_victory is false

### Test 6: Character Rank XP - Victory

1. Complete a victorious run
2. Check XP awards on results screen
3. **Expected Result**:
   - Each character receives rank XP
   - Victory base XP: 75
   - + Win bonus: 5 per win
   - Example: 10 wins = 75 + 50 = 125 XP per character

**If XP is wrong**:
- Check _calculate_character_xp_reward() logic
- Verify add_character_experience() is called for each character

### Test 7: Character Rank XP - Defeat

1. Lose a run
2. Check XP awards
3. **Expected Result**:
   - Defeat base XP: 25
   - + Win bonus: 5 per win
   - Less than victory rewards

**If defeat XP is wrong**:
- Check defeat branch in _calculate_character_xp_reward()

### Test 8: Rank Up Detection

1. Use a character close to ranking up (check experience in player_account.json)
2. Or start fresh and play multiple runs
3. Complete a run where a character should rank up
4. **Expected Result**:
   - Rank Ups panel appears (was hidden before)
   - Shows character name with "RANKED UP!"
   - Shows rank change (Rank 1 → Rank 2)
   - Shows unlocked content (items, skills, stat boosts)

**If rank up doesn't show**:
- Check rank_ups array is populated
- Verify rank comparison logic (old_rank vs new_rank)
- Check _display_rank_ups() is called

### Test 9: Rank Up Rewards Display

1. Trigger a rank up (may need to edit player_account.json to set experience near threshold)
2. Check rank up panel
3. **Expected Result**:
   - Lists unlocked items/skills by name
   - Shows stat boosts (e.g., "Basic_attack_damage +2")
   - Skills show level requirements if applicable

**If rewards don't display**:
- Check _display_rank_rewards() logic
- Verify GameData has rank_rewards in character master data
- Check _get_reward_name() returns correct names

### Test 10: Continue Button

1. On results screen, click **CONTINUE**
2. **Expected Result**:
   - Returns to main menu
   - Run state is cleared
   - No active run (PLAY button, not RESUME)
   - Gems reflect rewards
   - Character ranks/XP reflect rewards
   - Can start a new run immediately

**If continue doesn't work**:
- Check _on_continue_pressed() logic
- Verify RunManager.end_run() clears state
- Check navigation to main menu

### Test 11: No Double Rewards

1. Complete a run, note gem count
2. Check that rewards are applied exactly once
3. **Expected Result**:
   - Gems increase by calculated amount only
   - Character XP increases by calculated amount only
   - No duplicate additions

**If rewards are doubled**:
- Check that RunManager.end_run() doesn't award gems anymore
- Verify run_results.gd applies rewards only once
- Check that run_results isn't loaded twice

### Test 12: Multiple Runs Persistence

1. Complete run 1, note final gems and character XP
2. Return to main menu
3. Start run 2, complete it
4. **Expected Result**:
   - Gems accumulate across runs
   - Character rank XP accumulates
   - Characters can rank up over multiple runs
   - All progress persists

**If persistence fails**:
- Check PlayerAccount.save_account() is called
- Verify gems and character data are saved
- Check load_account() on game start

### Test 13: Rank Up Content Unlocking

1. Rank up a character
2. Go to Collection screen
3. Select the ranked up character
4. **Expected Result**:
   - New items appear in unlocked items
   - New skills appear in unlocked skills
   - Character stats may have increased
   - Can equip newly unlocked items

**If content isn't unlocked**:
- Check _apply_rank_rewards() in PlayerAccount
- Verify rank_rewards structure in JSON
- Check that unlocked arrays are updated

### Test 14: Full Loop Test

1. Start from fresh (or delete save file)
2. Complete 3 full runs (mix of wins and losses)
3. **Expected Result**:
   - Each run ends with proper results screen
   - Gems accumulate correctly
   - Characters progress toward rank ups
   - At least one rank up should occur
   - All progress persists
   - Can always start new runs

**If loop has issues**:
- Identify where it breaks
- Check all state transitions
- Verify no data corruption

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
git commit -m "Phase 7: Run Results & Loop Closure

- Created RunResults scene with comprehensive results display
- Victory/defeat title with appropriate styling
- Run statistics: rounds, wins, losses, gold, reputation
- Gem rewards calculated based on performance
- Character rank XP awarded to all team members
- Rank up detection with unlocked content display
- Shows items, skills, and stat boosts from rank ups
- Updated combat_stub to navigate to results instead of main menu
- Moved reward distribution from RunManager to run_results
- Full game loop now complete and repeatable
- Multiple runs accumulate progress correctly
- All tests passing: results display, rewards, rank ups, persistence"

# Optional: Tag this milestone
git tag -a v0.7-phase7 -m "Phase 7 Complete: Run Results & Loop Closure"
```

---

## Success Criteria

Phase 7 is complete when ALL of the following are true:

- ✅ Run results screen loads after run completion
- ✅ Victory shows "VICTORY!" in green
- ✅ Defeat shows "DEFEAT" in red
- ✅ Statistics display correct values (rounds, wins, losses, gold, reputation)
- ✅ Gem rewards calculated correctly (base + win bonus + reputation bonus)
- ✅ Gem rewards applied to account
- ✅ Character rank XP calculated correctly
- ✅ Character rank XP applied to all 3 characters
- ✅ Rank ups detected and displayed
- ✅ Rank up rewards (items, skills, stat boosts) shown
- ✅ Continue button returns to main menu
- ✅ Run state cleared after continue
- ✅ No double rewards
- ✅ Progress persists across multiple runs
- ✅ Ranked up content accessible in Collection
- ✅ Full game loop repeatable indefinitely
- ✅ Git commit created with all Phase 7 files

---

## Common Issues & Solutions

### Issue: Results screen shows wrong victory/defeat
**Solution**:
- Check was_victory is set from metadata correctly
- Verify combat_stub passes "victory" in metadata
- Check _ready() reads victory flag properly

### Issue: Statistics show zeros
**Solution**:
- Check run_data is populated
- Verify metadata is passed correctly
- Check _capture_run_data() fallback works

### Issue: Gem rewards not applied
**Solution**:
- Check PlayerAccount.add_gems() is called
- Verify _display_rewards() runs
- Check for errors in console

### Issue: Rank ups not detected
**Solution**:
- Check old_rank vs new_rank comparison
- Verify add_character_experience() can trigger rank up
- Check XP threshold (100 per rank)
- Make sure character data is re-fetched after adding XP

### Issue: Rank up rewards not displayed
**Solution**:
- Check GameData has rank_rewards for character
- Verify _display_rank_rewards() is called
- Check reward structure matches expected format

### Issue: Double rewards
**Solution**:
- Check RunManager.end_run() doesn't award gems
- Verify run_results only applies rewards once
- Make sure results screen isn't loaded multiple times

### Issue: Continue doesn't clear state
**Solution**:
- Check RunManager.end_run() is called
- Verify _clear_run_state() deletes save file
- Check is_run_active is set to false

### Issue: Rank up content not in Collection
**Solution**:
- Check _apply_rank_rewards() in PlayerAccount
- Verify save_account() is called after adding rewards
- Check Collection screen reads from current PlayerAccount data

---

## Next Steps

Once Phase 7 is complete and all tests pass:

1. Review `phase_08_polish.md` for the final phase
2. Play through several complete runs to verify stability
3. Consider balance adjustments (gem rewards, XP thresholds)

**Do not proceed to Phase 8 until all Phase 7 tests pass and the git commit is created.**

---

## Phase 7 Complete! 🎉

You now have:
- ✅ Complete run results screen
- ✅ Performance-based reward system
- ✅ Character rank progression with unlocks
- ✅ Full game loop (draft → encounters → combats → results → repeat)
- ✅ Persistent meta-progression across runs
- ✅ Fully playable prototype!

Total new files created: ~2
Total lines of code: ~400
Estimated time: 2-4 hours

**Ready for Phase 8: Polish & Extensibility (Final touches and documentation)**
