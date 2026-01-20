extends Control
# DebugMenu - Developer tools for testing
# Centralized debug controls (Issue 6 - moved from run_view.gd)
#
# Keyboard shortcuts (when debug menu is open):
#   G: Add 50 gold (during run)
#   X: Add 50 XP to first character (during run)
#   L: Lose 5 reputation (during run)
#   W: Add 1 win (during run)

@onready var gems_label = $Panel/MarginContainer/VBoxContainer/GemsSection/GemsLabel
@onready var tokens_label = $Panel/MarginContainer/VBoxContainer/TokensSection/TokensLabel
@onready var add_gems_button = $Panel/MarginContainer/VBoxContainer/GemsSection/GemsButtons/AddGemsButton
@onready var remove_gems_button = $Panel/MarginContainer/VBoxContainer/GemsSection/GemsButtons/RemoveGemsButton
@onready var add_token_button = $Panel/MarginContainer/VBoxContainer/TokensSection/AddTokenButton
@onready var unlock_all_button = $Panel/MarginContainer/VBoxContainer/CharacterSection/UnlockAllButton
@onready var rank_up_all_button = $Panel/MarginContainer/VBoxContainer/CharacterSection/RankUpAllButton

# Run controls (Issue 6)
@onready var run_status_label = $Panel/MarginContainer/VBoxContainer/RunSection/RunStatusLabel
@onready var add_gold_button = $Panel/MarginContainer/VBoxContainer/RunSection/GoldButtons/AddGoldButton
@onready var remove_gold_button = $Panel/MarginContainer/VBoxContainer/RunSection/GoldButtons/RemoveGoldButton
@onready var add_xp_button = $Panel/MarginContainer/VBoxContainer/RunSection/XpRepButtons/AddXpButton
@onready var lose_rep_button = $Panel/MarginContainer/VBoxContainer/RunSection/XpRepButtons/LoseRepButton
@onready var add_win_button = $Panel/MarginContainer/VBoxContainer/RunSection/WinLossButtons/AddWinButton
@onready var add_loss_button = $Panel/MarginContainer/VBoxContainer/RunSection/WinLossButtons/AddLossButton
@onready var clear_run_button = $Panel/MarginContainer/VBoxContainer/RunSection/ClearRunButton
@onready var close_button = $Panel/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	# Account controls
	add_gems_button.pressed.connect(_on_add_gems)
	remove_gems_button.pressed.connect(_on_remove_gems)
	add_token_button.pressed.connect(_on_add_token)
	unlock_all_button.pressed.connect(_on_unlock_all)
	rank_up_all_button.pressed.connect(_on_rank_up_all)

	# Run controls (Issue 6)
	add_gold_button.pressed.connect(_on_add_gold)
	remove_gold_button.pressed.connect(_on_remove_gold)
	add_xp_button.pressed.connect(_on_add_xp)
	lose_rep_button.pressed.connect(_on_lose_rep)
	add_win_button.pressed.connect(_on_add_win)
	add_loss_button.pressed.connect(_on_add_loss)
	clear_run_button.pressed.connect(_on_clear_run)

	close_button.pressed.connect(_on_close)

	_update_labels()
	_update_run_controls()


func _update_labels() -> void:
	"""Update currency display labels."""
	gems_label.text = "Gems: %d" % PlayerAccount.get_gems()
	tokens_label.text = "Tokens: %d" % PlayerAccount.get_reroll_tokens()


func _on_add_gems() -> void:
	"""Add 100 gems."""
	PlayerAccount.add_gems(100)
	_update_labels()
	print("DebugMenu: Added 100 gems")


func _on_remove_gems() -> void:
	"""Remove 100 gems."""
	PlayerAccount.spend_gems(100)
	_update_labels()
	print("DebugMenu: Removed 100 gems")


func _on_add_token() -> void:
	"""Add a reroll token."""
	PlayerAccount.add_reroll_token()
	_update_labels()
	print("DebugMenu: Added reroll token")


func _on_unlock_all() -> void:
	"""Unlock all characters without spending gems."""
	var all_chars = GameData.get_all_characters()
	var unlocked_count = 0

	for char_data in all_chars:
		var char_id = char_data["id"]
		if not PlayerAccount.is_character_unlocked(char_id):
			# Use internal unlock that doesn't cost gems
			if not PlayerAccount.player_data["unlocked_character_ids"].has(char_id):
				PlayerAccount.player_data["unlocked_character_ids"].append(char_id)
				PlayerAccount._create_character_data(char_id)
				unlocked_count += 1

	PlayerAccount.save_account()
	print("DebugMenu: Unlocked %d characters" % unlocked_count)


func _on_rank_up_all() -> void:
	"""Add 100 XP to all owned characters."""
	var ranked_count = 0

	for char_data in PlayerAccount.player_data["characters"]:
		PlayerAccount.add_character_experience(char_data["id"], 100)
		ranked_count += 1

	print("DebugMenu: Added 100 XP to %d characters" % ranked_count)


func _on_clear_run() -> void:
	"""Clear any active run state."""
	if RunManager.is_run_active:
		RunManager._clear_run_state()
		print("DebugMenu: Cleared active run")
		_update_run_controls()
	else:
		print("DebugMenu: No active run to clear")


func _on_close() -> void:
	"""Close the debug menu."""
	queue_free()


# =============================================================================
# RUN CONTROLS (Issue 6 - moved from run_view.gd)
# =============================================================================

func _update_run_controls() -> void:
	"""Update run control states based on active run."""
	var has_run = RunManager.is_run_active

	# Enable/disable run-specific buttons
	add_gold_button.disabled = not has_run
	remove_gold_button.disabled = not has_run
	add_xp_button.disabled = not has_run
	lose_rep_button.disabled = not has_run
	add_win_button.disabled = not has_run
	add_loss_button.disabled = not has_run
	clear_run_button.disabled = not has_run

	# Update status label
	if has_run:
		run_status_label.text = "Round %d | Gold: %d | Rep: %d | Wins: %d" % [
			RunManager.get_round() + 1,
			RunManager.get_gold(),
			RunManager.get_reputation(),
			RunManager.get_wins()
		]
		run_status_label.modulate = Color.WHITE
	else:
		run_status_label.text = "No active run"
		run_status_label.modulate = GameConstants.COLOR_MUTED


func _on_add_gold() -> void:
	"""Add 50 gold to current run."""
	if not RunManager.is_run_active:
		return
	RunManager.add_gold(50)
	_update_run_controls()
	print("DebugMenu: Added 50 gold")


func _on_remove_gold() -> void:
	"""Remove 50 gold from current run."""
	if not RunManager.is_run_active:
		return
	RunManager.spend_gold(50)
	_update_run_controls()
	print("DebugMenu: Removed 50 gold")


func _on_add_xp() -> void:
	"""Add 50 XP to first character in team."""
	if not RunManager.is_run_active:
		return
	var team = RunManager.get_team()
	if team.size() > 0:
		var leveled_up = team[0].add_experience(50)
		var msg = "Added 50 XP to %s" % team[0].get_character_name()
		if leveled_up:
			msg += " (LEVEL UP!)"
		print("DebugMenu: %s" % msg)
	_update_run_controls()


func _on_lose_rep() -> void:
	"""Lose 5 reputation."""
	if not RunManager.is_run_active:
		return
	RunManager.lose_reputation(5)
	_update_run_controls()
	print("DebugMenu: Lost 5 reputation")


func _on_add_win() -> void:
	"""Add 1 win to current run."""
	if not RunManager.is_run_active:
		return
	RunManager.add_win()
	_update_run_controls()
	print("DebugMenu: Added 1 win")


func _on_add_loss() -> void:
	"""Add 1 loss to current run."""
	if not RunManager.is_run_active:
		return
	RunManager.add_loss()
	_update_run_controls()
	print("DebugMenu: Added 1 loss")


# =============================================================================
# KEYBOARD SHORTCUTS
# =============================================================================

func _input(event: InputEvent) -> void:
	"""Handle keyboard shortcuts for debug controls."""
	if not event is InputEventKey or not event.pressed:
		return

	# Only process if we have an active run for run-specific shortcuts
	if RunManager.is_run_active:
		match event.keycode:
			KEY_G:
				_on_add_gold()
			KEY_X:
				_on_add_xp()
			KEY_L:
				_on_lose_rep()
			KEY_W:
				_on_add_win()

	# ESC to close debug menu
	if event.keycode == KEY_ESCAPE:
		_on_close()
