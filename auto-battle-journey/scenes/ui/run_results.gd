extends Control
# RunResults - Display run completion results and rewards

@onready var result_title = $ScrollContainer/MainContainer/ResultTitle
@onready var rounds_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/RoundsLabel
@onready var wins_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/WinsLabel
@onready var losses_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/LossesLabel
@onready var gold_earned_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/GoldEarnedLabel
@onready var reputation_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/ReputationLabel

@onready var gems_label = $ScrollContainer/MainContainer/RewardsPanelContainer/RewardsPanel/RewardsContainer/GemsLabel
@onready var character_xp_container = $ScrollContainer/MainContainer/RewardsPanelContainer/RewardsPanel/RewardsContainer/CharacterXPContainer

@onready var rank_ups_panel = $ScrollContainer/MainContainer/RankUpsPanelContainer
@onready var rank_ups_list = $ScrollContainer/MainContainer/RankUpsPanelContainer/RankUpsPanel/RankUpsContainer/RankUpsList

@onready var continue_button = $ScrollContainer/MainContainer/ContinueButton

# Store run data before it's cleared
var run_data: Dictionary = {}
var was_victory: bool = false
var rank_ups: Array = []  # Track which characters ranked up


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
	_display_rank_ups()


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

	# Calculate character XP using RewardCalculator (DRY)
	var xp_reward = RewardCalculator.calculate_character_xp_reward(was_victory, wins)

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


func _display_rank_ups() -> void:
	"""Display rank up notifications if any occurred."""
	if rank_ups.is_empty():
		rank_ups_panel.visible = false
		return

	rank_ups_panel.visible = true

	for rank_up in rank_ups:
		var rank_up_container = VBoxContainer.new()
		rank_ups_list.add_child(rank_up_container)

		# Create clickable header button
		var header_button = Button.new()
		header_button.text = "%s RANKED UP!  [+]" % rank_up["name"]
		header_button.add_theme_font_size_override("font_size", 18)
		header_button.add_theme_color_override("font_color", GameConstants.COLOR_GOLD)
		header_button.flat = true
		header_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		rank_up_container.add_child(header_button)

		# Rank change label (always visible)
		var rank_label = Label.new()
		rank_label.text = "Rank %d -> Rank %d" % [rank_up["old_rank"], rank_up["new_rank"]]
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_up_container.add_child(rank_label)

		# Collapsible details container (hidden by default)
		var details_container = VBoxContainer.new()
		details_container.visible = false
		rank_up_container.add_child(details_container)

		# Connect header button to toggle details
		header_button.pressed.connect(_toggle_rank_details.bind(header_button, details_container, rank_up["name"]))

		# Populate details with unlocked content
		_display_rank_rewards(details_container, rank_up["id"], rank_up["new_rank"])

		# Add separator
		var separator = HSeparator.new()
		rank_ups_list.add_child(separator)


func _toggle_rank_details(header_button: Button, details_container: VBoxContainer, char_name: String) -> void:
	"""Toggle visibility of rank-up details."""
	details_container.visible = not details_container.visible
	if details_container.visible:
		header_button.text = "%s RANKED UP!  [-]" % char_name
	else:
		header_button.text = "%s RANKED UP!  [+]" % char_name


func _display_rank_rewards(container: VBoxContainer, char_id: String, new_rank: int) -> void:
	"""Display what was unlocked at the new rank."""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		return

	if not char_master.has("rank_rewards"):
		return

	# Find rewards for this rank
	for rank_reward in char_master["rank_rewards"]:
		if rank_reward["rank"] == new_rank:
			# Display unlocked content
			if rank_reward.has("rewards") and not rank_reward["rewards"].is_empty():
				var unlocks_label = Label.new()
				unlocks_label.text = "Unlocked:"
				unlocks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				unlocks_label.modulate = GameConstants.COLOR_MUTED
				container.add_child(unlocks_label)

				for reward in rank_reward["rewards"]:
					var reward_label = Label.new()
					var reward_name = _get_reward_name(reward)
					reward_label.text = "  %s" % reward_name
					reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					reward_label.modulate = GameConstants.COLOR_SUCCESS
					container.add_child(reward_label)

			# Display stat boosts
			if rank_reward.has("stat_boost") and not rank_reward["stat_boost"].is_empty():
				var boost_label = Label.new()
				boost_label.text = "Stat Boost:"
				boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				boost_label.modulate = GameConstants.COLOR_MUTED
				container.add_child(boost_label)

				for stat_name in rank_reward["stat_boost"]:
					var boost_value = rank_reward["stat_boost"][stat_name]
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


func _on_continue_pressed() -> void:
	"""Return to main menu."""
	print("RunResults: Continuing to main menu")

	# End run and clear state (if not already done)
	if RunManager.is_run_active:
		RunManager.end_run(was_victory)

	# Navigate to main menu using SceneManager
	SceneManager.go_to_main_menu()
