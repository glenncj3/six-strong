extends Control
# RunResults - Display run completion results and rewards

@onready var background = $Background
@onready var result_title = $ScrollContainer/MainContainer/ResultTitle

@onready var stats_section = $ScrollContainer/MainContainer/StatsPanelContainer
@onready var stats_panel = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel
@onready var stats_title = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/StatsTitle
@onready var rounds_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/RoundsLabel
@onready var wins_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/WinsLabel
@onready var losses_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/LossesLabel
@onready var gold_earned_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/GoldEarnedLabel
@onready var reputation_label = $ScrollContainer/MainContainer/StatsPanelContainer/StatsPanel/StatsContainer/ReputationLabel

@onready var rewards_section = $ScrollContainer/MainContainer/RewardsPanelContainer
@onready var rewards_panel = $ScrollContainer/MainContainer/RewardsPanelContainer/RewardsPanel
@onready var rewards_title = $ScrollContainer/MainContainer/RewardsPanelContainer/RewardsPanel/RewardsContainer/RewardsTitle
@onready var gems_label = $ScrollContainer/MainContainer/RewardsPanelContainer/RewardsPanel/RewardsContainer/GemsLabel
@onready var legacy_fame_container = $ScrollContainer/MainContainer/RewardsPanelContainer/RewardsPanel/RewardsContainer/CharacterXPContainer

@onready var prestige_ups_panel = $ScrollContainer/MainContainer/RankUpsPanelContainer
@onready var rank_ups_panel = $ScrollContainer/MainContainer/RankUpsPanelContainer/RankUpsPanel
@onready var rank_ups_title = $ScrollContainer/MainContainer/RankUpsPanelContainer/RankUpsPanel/RankUpsContainer/RankUpsTitle
@onready var prestige_ups_list = $ScrollContainer/MainContainer/RankUpsPanelContainer/RankUpsPanel/RankUpsContainer/RankUpsList

@onready var continue_button = $ScrollContainer/MainContainer/ContinueButton
@onready var header_gems_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GemsLabel
@onready var header_reroll_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/RerollTokensLabel

# Store run data before it's cleared
var run_data: Dictionary = {}
var was_victory: bool = false
var prestige_ups: Array = []  # Track which characters increased prestige


func _ready() -> void:
	_apply_visual_styling()
	continue_button.pressed.connect(_on_continue_pressed)

	# Initialize header bar currencies
	_update_header_currencies()
	header_gems_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	header_reroll_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	PlayerAccount.gems_changed.connect(_on_gems_changed)
	PlayerAccount.reroll_tokens_changed.connect(_on_reroll_tokens_changed)

	# Get run data from typed SceneTransitionData
	run_data = SceneTransitionData.get_run_results()
	if not run_data.is_empty():
		was_victory = run_data.get("victory", false)
	else:
		# Fallback: capture from RunManager before it clears
		_capture_run_data()

	_display_results()
	_play_entrance_animations()


func _exit_tree() -> void:
	# Disconnect from autoload signals to prevent memory leaks
	if PlayerAccount.gems_changed.is_connected(_on_gems_changed):
		PlayerAccount.gems_changed.disconnect(_on_gems_changed)
	if PlayerAccount.reroll_tokens_changed.is_connected(_on_reroll_tokens_changed):
		PlayerAccount.reroll_tokens_changed.disconnect(_on_reroll_tokens_changed)


func _apply_visual_styling() -> void:
	"""Apply consistent visual styling."""
	# Result title - larger font size
	result_title.add_theme_font_size_override("font_size", 56)
	result_title.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)

	# Panel styles
	UIStyles.apply_panel_style(stats_panel, UIStyles.create_dark_panel())
	UIStyles.apply_panel_style(rewards_panel, UIStyles.create_dark_panel())
	UIStyles.apply_panel_style(rank_ups_panel, UIStyles.create_dark_panel())

	# Panel titles - larger font size
	stats_title.add_theme_font_size_override("font_size", 28)
	stats_title.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	rewards_title.add_theme_font_size_override("font_size", 28)
	rewards_title.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	rank_ups_title.add_theme_font_size_override("font_size", 28)
	rank_ups_title.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)

	# Stat labels - larger font size
	for label in [rounds_label, wins_label, losses_label, gold_earned_label, reputation_label]:
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Gems reward label - larger font size
	gems_label.add_theme_font_size_override("font_size", 28)

	# Continue button - larger font size
	UIStyles.setup_button(continue_button, 28)
	ButtonEffects.apply_effects(continue_button)


func _play_entrance_animations() -> void:
	"""Play entrance animations with dramatic reveal."""
	AnimationManager.fade_in($HeaderBar, GameConstants.ANIM_DURATION_NORMAL, 0.0)
	AnimationManager.fade_in(result_title, GameConstants.ANIM_DURATION_SLOW, 0.0)
	AnimationManager.fade_in(stats_section, GameConstants.ANIM_DURATION_NORMAL, 0.2)
	AnimationManager.fade_in(rewards_section, GameConstants.ANIM_DURATION_NORMAL, 0.35)
	AnimationManager.fade_in(continue_button, GameConstants.ANIM_DURATION_NORMAL, 0.5)


func _capture_run_data() -> void:
	"""Fallback: Capture run data from RunManager if scene_data not provided."""
	run_data = {
		"round": RunManager.get_round(),
		"wins": RunManager.get_wins(),
		"losses": RunManager.get_losses(),
		"gold": RunManager.get_gold(),
		"reputation": RunManager.get_reputation(),
		"starting_gold": RunManager.starting_gold,
		"team": RunManager.capture_team_data()
	}
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
	else:
		result_title.text = "DEFEAT"
	# Title color is already set to gold in _apply_visual_styling


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
	"""Display pre-calculated rewards (applied by RunManager.end_run())."""
	var gem_reward = run_data.get("gem_reward", 0)
	var fame_reward = run_data.get("fame_reward", 0)
	prestige_ups = run_data.get("prestige_ups", [])
	var drafted_legacy_ids = run_data.get("drafted_legacy_ids", [])

	gems_label.text = "+%d %s Gems" % [gem_reward, GameConstants.EMOJI_GEM]
	gems_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Display legacy fame (Phase 7: Fame goes to legacies)
	if drafted_legacy_ids.size() > 0:
		for legacy_id in drafted_legacy_ids:
			var legacy = PlayerAccount.get_legacy_data(legacy_id)
			var legacy_name = legacy.legacy_name if legacy else legacy_id
			var fame_label = Label.new()
			fame_label.text = "%s: +%d Fame" % [legacy_name, fame_reward]
			fame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fame_label.add_theme_font_size_override("font_size", 22)
			fame_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
			legacy_fame_container.add_child(fame_label)
	else:
		# Fallback: Display character fame for backwards compatibility
		for char_data in run_data.get("team", []):
			var fame_label = Label.new()
			fame_label.text = "%s: +%d Fame" % [char_data["name"], fame_reward]
			fame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fame_label.add_theme_font_size_override("font_size", 22)
			fame_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
			legacy_fame_container.add_child(fame_label)


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
		header_button.add_theme_font_size_override("font_size", 24)
		header_button.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
		header_button.flat = true
		header_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		prestige_up_container.add_child(header_button)

		# Prestige change label (always visible)
		var prestige_label = Label.new()
		prestige_label.text = "Prestige %d -> Prestige %d" % [prestige_up["old_prestige"], prestige_up["new_prestige"]]
		prestige_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prestige_label.add_theme_font_size_override("font_size", 22)
		prestige_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
		prestige_up_container.add_child(prestige_label)

		# Collapsible details container (hidden by default)
		var details_container = VBoxContainer.new()
		details_container.visible = false
		prestige_up_container.add_child(details_container)

		# Connect header button to toggle details
		header_button.pressed.connect(_toggle_prestige_details.bind(header_button, details_container, prestige_up["name"]))

		# Populate details with unlocked content based on type
		var entity_type = prestige_up.get("type", "character")
		if entity_type == "legacy":
			_display_legacy_prestige_rewards(details_container, prestige_up["id"], prestige_up["new_prestige"])
		else:
			_display_prestige_rewards(details_container, prestige_up["id"], prestige_up["new_prestige"])



func _toggle_prestige_details(header_button: Button, details_container: VBoxContainer, char_name: String) -> void:
	"""Toggle visibility of prestige-up details."""
	details_container.visible = not details_container.visible
	if details_container.visible:
		header_button.text = "%s PRESTIGE UP!  [-]" % char_name
	else:
		header_button.text = "%s PRESTIGE UP!  [+]" % char_name


func _display_prestige_rewards(container: VBoxContainer, char_id: String, new_prestige: int) -> void:
	"""Display what was unlocked at the new prestige level (character-based, deprecated)."""
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
				unlocks_label.add_theme_font_size_override("font_size", 20)
				unlocks_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
				container.add_child(unlocks_label)

				for reward in prestige_reward["rewards"]:
					var reward_label = Label.new()
					var reward_name = _get_reward_name(reward)
					reward_label.text = "  %s" % reward_name
					reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					reward_label.add_theme_font_size_override("font_size", 20)
					reward_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
					container.add_child(reward_label)

			# Display stat boosts
			if prestige_reward.has("stat_boost") and not prestige_reward["stat_boost"].is_empty():
				var boost_label = Label.new()
				boost_label.text = "Stat Boost:"
				boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				boost_label.add_theme_font_size_override("font_size", 20)
				boost_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
				container.add_child(boost_label)

				for stat_name in prestige_reward["stat_boost"]:
					var boost_value = prestige_reward["stat_boost"][stat_name]
					var stat_label = Label.new()
					stat_label.text = "  %s +%d" % [stat_name.replace("_", " ").capitalize(), boost_value]
					stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					stat_label.add_theme_font_size_override("font_size", 20)
					stat_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
					container.add_child(stat_label)

			break


func _display_legacy_prestige_rewards(container: VBoxContainer, legacy_id: String, new_prestige: int) -> void:
	"""Display what was unlocked at the new prestige level for a legacy."""
	var legacy_master = GameData.get_legacy(legacy_id)
	if legacy_master.is_empty():
		return

	if not legacy_master.has("prestige_rewards"):
		return

	# Find rewards for this prestige level
	for prestige_reward in legacy_master["prestige_rewards"]:
		if prestige_reward.get("prestige", 0) == new_prestige:
			var unlocks = prestige_reward.get("unlocks", {})
			var has_unlocks = false

			# Collect all unlock categories
			var unlock_categories = [
				{"key": "starting_characters", "label": "Starting Characters"},
				{"key": "starting_items", "label": "Starting Items"},
				{"key": "characters", "label": "Characters"},
				{"key": "items", "label": "Items"},
				{"key": "skills", "label": "Skills"},
				{"key": "encounters", "label": "Encounters"}
			]

			for category in unlock_categories:
				var ids = unlocks.get(category.key, [])
				if ids.size() > 0:
					if not has_unlocks:
						# Add header on first unlock found
						var unlocks_label = Label.new()
						unlocks_label.text = "Unlocked:"
						unlocks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						unlocks_label.add_theme_font_size_override("font_size", 20)
						unlocks_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
						container.add_child(unlocks_label)
						has_unlocks = true

					for item_id in ids:
						var display_name = _get_legacy_unlock_name(category.key, item_id)
						var reward_label = Label.new()
						reward_label.text = "  %s: %s" % [category.label.trim_suffix("s"), display_name]
						reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						reward_label.add_theme_font_size_override("font_size", 20)
						reward_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
						container.add_child(reward_label)

			# Display encounter weight bonus if present
			var weight_bonus = unlocks.get("encounter_weight_bonus", 0)
			if weight_bonus > 0:
				var bonus_label = Label.new()
				bonus_label.text = "  Encounter Weight: +%d" % weight_bonus
				bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				bonus_label.add_theme_font_size_override("font_size", 20)
				bonus_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
				container.add_child(bonus_label)

			break


func _get_legacy_unlock_name(category: String, item_id: String) -> String:
	"""Get display name for a legacy unlock."""
	match category:
		"starting_characters", "characters":
			var char_data = GameData.get_character_by_id(item_id)
			return char_data.get("name", item_id)
		"starting_items", "items":
			var item_data = GameData.get_item_by_id(item_id)
			return item_data.get("name", item_id)
		"skills":
			var skill_data = GameData.get_skill_by_id(item_id)
			return skill_data.get("name", item_id)
		"encounters":
			var enc_data = GameData.get_encounter_type(item_id)
			return enc_data.get("name", item_id)
		_:
			return item_id


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
	"""Return to main menu. Run was already ended by RunManager."""
	SceneManager.go_to("main_menu")
