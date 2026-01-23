extends Control
# RunResults - Display run completion results and rewards

@onready var result_title = $ScrollContainer/MainContainer/ResultTitle
@onready var rounds_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/RoundsLabel
@onready var wins_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/WinsLabel
@onready var losses_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/LossesLabel
@onready var gold_earned_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/GoldEarnedLabel
@onready var reputation_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/ReputationLabel

@onready var gems_label = $ScrollContainer/MainContainer/RewardsPanelContainer/RewardsPanel/RewardsContainer/GemsLabel
@onready var character_fame_container = $ScrollContainer/MainContainer/RewardsPanelContainer/RewardsPanel/RewardsContainer/CharacterXPContainer

@onready var prestige_ups_panel = $ScrollContainer/MainContainer/RankUpsPanelContainer
@onready var prestige_ups_list = $ScrollContainer/MainContainer/RankUpsPanelContainer/RankUpsPanel/RankUpsContainer/RankUpsList

@onready var continue_button = $ScrollContainer/MainContainer/ContinueButton
@onready var header_gems_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GemsLabel
@onready var header_reroll_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/RerollTokensLabel

# Store run data before it's cleared
var run_data: Dictionary = {}
var was_victory: bool = false
var prestige_ups: Array = []  # Track which characters increased prestige


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)

	# Initialize header bar currencies
	_update_header_currencies()
	header_gems_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	header_reroll_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	PlayerAccount.gems_changed.connect(_on_gems_changed)
	PlayerAccount.reroll_tokens_changed.connect(_on_reroll_tokens_changed)

	# Get run data from SceneManager
	run_data = SceneManager.get_scene_data("run_results", {})
	if not run_data.is_empty():
		was_victory = run_data.get("victory", false)
	else:
		# Fallback: capture from RunManager before it clears
		_capture_run_data()

	_display_results()
	_play_entrance_animations()


func _play_entrance_animations() -> void:
	"""Play entrance animations with dramatic reveal."""
	AnimationManager.fade_in($HeaderBar, GameConstants.ANIM_DURATION_NORMAL, 0.0)
	AnimationManager.fade_in(result_title, GameConstants.ANIM_DURATION_SLOW, 0.0)
	AnimationManager.fade_in(rounds_label.get_parent().get_parent().get_parent(), GameConstants.ANIM_DURATION_NORMAL, 0.2)
	AnimationManager.fade_in(gems_label.get_parent().get_parent().get_parent(), GameConstants.ANIM_DURATION_NORMAL, 0.35)
	AnimationManager.fade_in(continue_button, GameConstants.ANIM_DURATION_NORMAL, 0.5)


func _capture_run_data() -> void:
	"""Capture run data from RunManager."""
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
	"""Display all results information."""
	_display_title()
	_display_stats()
	_display_rewards()
	_display_prestige_ups()


func _display_title() -> void:
	"""Display victory or defeat title."""
	if was_victory:
		result_title.text = "VICTORY!"
		result_title.modulate = Color(0.2, 1.0, 0.2)
	else:
		result_title.text = "DEFEAT"
		result_title.modulate = Color(1.0, 0.2, 0.2)


func _display_stats() -> void:
	"""Display run statistics."""
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
	"""Display and apply rewards."""
	var wins = run_data.get("wins", 0)
	var reputation = run_data.get("reputation", 0)

	# Calculate gem reward using RewardCalculator (DRY)
	var gem_reward = RewardCalculator.calculate_gem_reward(was_victory, wins, reputation)
	gems_label.text = "+%d %s Gems" % [gem_reward, GameConstants.EMOJI_GEM]
	gems_label.modulate = GameConstants.COLOR_SUCCESS

	# Apply gem reward
	PlayerAccount.add_gems(gem_reward)

	# Calculate character fame using RewardCalculator (DRY)
	var fame_reward = RewardCalculator.calculate_character_fame_reward(was_victory, wins)

	for char_data in run_data.get("team", []):
		var char_id = char_data["id"]
		var char_name = char_data["name"]

		# Create fame award label
		var fame_label = Label.new()
		fame_label.text = "%s: +%d Fame" % [char_name, fame_reward]
		fame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		character_fame_container.add_child(fame_label)

		# Get current prestige before adding fame
		var char_account_data = PlayerAccount.get_character_data(char_id)
		var old_prestige = char_account_data.get("prestige", 1)

		# Apply fame to account character
		PlayerAccount.add_character_fame(char_id, fame_reward)

		# Check if prestige increased
		var new_char_data = PlayerAccount.get_character_data(char_id)
		var new_prestige = new_char_data.get("prestige", 1)

		if new_prestige > old_prestige:
			prestige_ups.append({
				"name": char_name,
				"old_prestige": old_prestige,
				"new_prestige": new_prestige,
				"id": char_id
			})


func _display_prestige_ups() -> void:
	"""Display prestige increase notifications if any occurred."""
	if prestige_ups.is_empty():
		prestige_ups_panel.visible = false
		return

	prestige_ups_panel.visible = true

	for prestige_up in prestige_ups:
		var prestige_up_container = VBoxContainer.new()
		prestige_ups_list.add_child(prestige_up_container)

		# Create clickable header button
		var header_button = Button.new()
		header_button.text = "%s PRESTIGE UP!  [+]" % prestige_up["name"]
		header_button.add_theme_font_size_override("font_size", 18)
		header_button.add_theme_color_override("font_color", GameConstants.COLOR_GOLD)
		header_button.flat = true
		header_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		prestige_up_container.add_child(header_button)

		# Prestige change label (always visible)
		var prestige_label = Label.new()
		prestige_label.text = "Prestige %d -> Prestige %d" % [prestige_up["old_prestige"], prestige_up["new_prestige"]]
		prestige_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prestige_up_container.add_child(prestige_label)

		# Collapsible details container (hidden by default)
		var details_container = VBoxContainer.new()
		details_container.visible = false
		prestige_up_container.add_child(details_container)

		# Connect header button to toggle details
		header_button.pressed.connect(_toggle_prestige_details.bind(header_button, details_container, prestige_up["name"]))

		# Populate details with unlocked content
		_display_prestige_rewards(details_container, prestige_up["id"], prestige_up["new_prestige"])

		# Add separator
		var separator = HSeparator.new()
		prestige_ups_list.add_child(separator)


func _toggle_prestige_details(header_button: Button, details_container: VBoxContainer, char_name: String) -> void:
	"""Toggle visibility of prestige-up details."""
	details_container.visible = not details_container.visible
	if details_container.visible:
		header_button.text = "%s PRESTIGE UP!  [-]" % char_name
	else:
		header_button.text = "%s PRESTIGE UP!  [+]" % char_name


func _display_prestige_rewards(container: VBoxContainer, char_id: String, new_prestige: int) -> void:
	"""Display what was unlocked at the new prestige level."""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		return

	if not char_master.has("prestige_rewards"):
		return

	# Find rewards for this prestige level
	for prestige_reward in char_master["prestige_rewards"]:
		if prestige_reward["prestige"] == new_prestige:
			# Display unlocked content
			if prestige_reward.has("rewards") and not prestige_reward["rewards"].is_empty():
				var unlocks_label = Label.new()
				unlocks_label.text = "Unlocked:"
				unlocks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				unlocks_label.modulate = GameConstants.COLOR_MUTED
				container.add_child(unlocks_label)

				for reward in prestige_reward["rewards"]:
					var reward_label = Label.new()
					var reward_name = _get_reward_name(reward)
					reward_label.text = "  %s" % reward_name
					reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					reward_label.modulate = GameConstants.COLOR_SUCCESS
					container.add_child(reward_label)

			# Display stat boosts
			if prestige_reward.has("stat_boost") and not prestige_reward["stat_boost"].is_empty():
				var boost_label = Label.new()
				boost_label.text = "Stat Boost:"
				boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				boost_label.modulate = GameConstants.COLOR_MUTED
				container.add_child(boost_label)

				for stat_name in prestige_reward["stat_boost"]:
					var boost_value = prestige_reward["stat_boost"][stat_name]
					var stat_label = Label.new()
					stat_label.text = "  %s +%d" % [stat_name.replace("_", " ").capitalize(), boost_value]
					stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					stat_label.modulate = Color(0.3, 0.7, 1.0)
					container.add_child(stat_label)

			break


func _get_reward_name(reward: Dictionary) -> String:
	"""Get display name for a reward."""
	var reward_type = reward.get("type", "")
	var reward_id = reward.get("id", "")

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


func _update_header_currencies() -> void:
	header_gems_label.text = UIHelpers.format_currency(PlayerAccount.get_gems(), GameConstants.EMOJI_GEM)
	header_reroll_label.text = UIHelpers.format_currency(PlayerAccount.get_reroll_tokens(), GameConstants.EMOJI_REROLL)


func _on_gems_changed(new_amount: int) -> void:
	header_gems_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_GEM)


func _on_reroll_tokens_changed(new_amount: int) -> void:
	header_reroll_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_REROLL)


func _on_continue_pressed() -> void:
	"""Return to main menu."""
	print("RunResults: Continuing to main menu")

	# End run and clear state (if not already done)
	if RunManager.is_run_active:
		RunManager.end_run(was_victory)

	# Navigate to main menu using SceneManager
	SceneManager.go_to_main_menu()
