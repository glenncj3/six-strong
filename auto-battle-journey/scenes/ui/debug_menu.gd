extends Control
# DebugMenu - Developer tools for testing

@onready var gems_label = $Panel/MarginContainer/VBoxContainer/GemsSection/GemsLabel
@onready var tokens_label = $Panel/MarginContainer/VBoxContainer/TokensSection/TokensLabel
@onready var add_gems_button = $Panel/MarginContainer/VBoxContainer/GemsSection/GemsButtons/AddGemsButton
@onready var remove_gems_button = $Panel/MarginContainer/VBoxContainer/GemsSection/GemsButtons/RemoveGemsButton
@onready var add_token_button = $Panel/MarginContainer/VBoxContainer/TokensSection/AddTokenButton
@onready var unlock_all_button = $Panel/MarginContainer/VBoxContainer/CharacterSection/UnlockAllButton
@onready var rank_up_all_button = $Panel/MarginContainer/VBoxContainer/CharacterSection/RankUpAllButton
@onready var clear_run_button = $Panel/MarginContainer/VBoxContainer/RunSection/ClearRunButton
@onready var close_button = $Panel/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	add_gems_button.pressed.connect(_on_add_gems)
	remove_gems_button.pressed.connect(_on_remove_gems)
	add_token_button.pressed.connect(_on_add_token)
	unlock_all_button.pressed.connect(_on_unlock_all)
	rank_up_all_button.pressed.connect(_on_rank_up_all)
	clear_run_button.pressed.connect(_on_clear_run)
	close_button.pressed.connect(_on_close)

	_update_labels()


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
	else:
		print("DebugMenu: No active run to clear")


func _on_close() -> void:
	"""Close the debug menu."""
	queue_free()
