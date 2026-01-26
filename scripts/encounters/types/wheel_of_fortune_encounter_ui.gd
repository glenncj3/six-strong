class_name WheelOfFortuneEncounterUI
extends RefCounted
## UI creation for Wheel of Fortune encounters.
## Player spins a wheel with 6 segments for varied rewards.
## First spin is free; player may pay gold for one additional spin.

const RewardClaimPopupScene = preload("res://scenes/components/reward_claim_popup.tscn")


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create wheel of fortune encounter UI."""
	var container = WheelEncounterContainer.new()
	container.initialize(encounter_data, context)
	return container


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for wheel of fortune encounter."""
	var data = encounter_data.get("data", {})
	var spin_cost = data.get("spin_again_cost", GameConstants.WHEEL_SPIN_AGAIN_COST)
	return "Spin for rewards! (+%dg for extra)" % spin_cost


## Inner class that handles all game state and logic
class WheelEncounterContainer extends VBoxContainer:
	var controller: WheelController
	var wheel_visual: WheelVisual
	var context: Dictionary
	var encounter_data: Dictionary

	# UI elements
	var spin_button: Button
	var spin_again_button: Button
	var take_prize_button: Button
	var action_container: HBoxContainer
	var reward_popup: RewardClaimPopup = null

	# State tracking
	var eligible_char_indices: Array = []


	func initialize(p_encounter_data: Dictionary, p_context: Dictionary) -> void:
		encounter_data = p_encounter_data
		context = p_context

		set_anchors_preset(Control.PRESET_FULL_RECT)
		add_theme_constant_override("separation", 10)
		alignment = BoxContainer.ALIGNMENT_CENTER

		# Create controller
		controller = WheelController.new()
		controller.setup(encounter_data, context)

		# Connect controller signals
		controller.state_changed.connect(_on_state_changed)
		controller.spin_started.connect(_on_spin_started)
		controller.spin_ended.connect(_on_spin_ended)
		controller.reward_applied.connect(_on_reward_applied)
		controller.extra_spin_purchased.connect(_on_extra_spin_purchased)

		_build_ui()


	func _build_ui() -> void:
		# Create wheel visual
		wheel_visual = WheelVisual.new()
		wheel_visual.custom_minimum_size = Vector2(GameConstants.WHEEL_SIZE + 40, GameConstants.WHEEL_SIZE + 80)
		wheel_visual.setup(controller.get_segments())
		wheel_visual.spin_complete.connect(_on_visual_spin_complete)
		wheel_visual.segment_passed.connect(_on_segment_passed)
		add_child(wheel_visual)

		# Spacer before buttons (at least 20px above skip/finish)
		add_child(UIHelpers.create_spacer(24))

		# Action buttons container
		action_container = HBoxContainer.new()
		action_container.alignment = BoxContainer.ALIGNMENT_CENTER
		action_container.add_theme_constant_override("separation", 16)
		add_child(action_container)

		# Spin button
		spin_button = UIHelpers.create_button(
			"SPIN!",
			_on_spin_pressed,
			GameConstants.BUTTON_WIDTH_SMALL,
			GameConstants.BUTTON_HEIGHT_STANDARD
		)
		UIStyles.setup_success_button(spin_button)
		spin_button.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BUTTON_LARGE)
		action_container.add_child(spin_button)

		# Spin again button (initially hidden)
		spin_again_button = UIHelpers.create_button(
			"Respin: %dg" % controller.spin_again_cost,
			_on_spin_again_pressed,
			GameConstants.BUTTON_WIDTH_SMALL,
			GameConstants.BUTTON_HEIGHT_STANDARD
		)
		UIStyles.setup_button(spin_again_button)
		spin_again_button.visible = false
		action_container.add_child(spin_again_button)

		# Take prize button (initially hidden)
		take_prize_button = UIHelpers.create_button(
			"Take Prize",
			_on_take_prize_pressed,
			GameConstants.BUTTON_WIDTH_SMALL,
			GameConstants.BUTTON_HEIGHT_STANDARD
		)
		UIStyles.setup_success_button(take_prize_button)
		take_prize_button.visible = false
		action_container.add_child(take_prize_button)


	func _on_state_changed(new_state: int) -> void:
		"""Handle controller state changes."""
		_update_ui_for_state(new_state)


	func _update_ui_for_state(state: int) -> void:
		match state:
			WheelState.State.IDLE:
				spin_button.visible = true
				spin_button.disabled = false
				spin_again_button.visible = false
				take_prize_button.visible = false

			WheelState.State.SPINNING, WheelState.State.LANDING:
				spin_button.visible = true
				spin_button.disabled = true
				spin_button.text = "Spinning..."
				spin_again_button.visible = false
				take_prize_button.visible = false

			WheelState.State.SHOWING_RESULT:
				spin_button.visible = false
				# Wait for visual animation before showing choices

			WheelState.State.AWAITING_CHOICE:
				spin_button.visible = false
				_show_choice_buttons()

			WheelState.State.SELECTING_TARGET:
				spin_button.visible = false
				spin_again_button.visible = false
				take_prize_button.visible = false
				_show_reward_claim_popup()

			WheelState.State.COMPLETE:
				spin_button.visible = false
				spin_again_button.visible = false
				take_prize_button.visible = false
				_cleanup_popup()


	func _show_choice_buttons() -> void:
		"""Show spin again / take prize options."""
		# Spin again button
		spin_again_button.visible = controller.can_spin_again()
		if controller.can_spin_again():
			if controller.can_afford_extra_spin():
				spin_again_button.disabled = false
				spin_again_button.text = "Respin: %dg" % controller.spin_again_cost
				UIStyles.setup_button(spin_again_button)
			else:
				spin_again_button.disabled = true
				spin_again_button.text = "Not enough gold"
				UIStyles.setup_danger_button(spin_again_button)

		# Take prize button
		take_prize_button.visible = true
		take_prize_button.disabled = false

		# Check if reward needs character selection
		if controller.reward_requires_selection():
			take_prize_button.text = "Choose Character"
		else:
			take_prize_button.text = "Take Prize"


	func _show_reward_claim_popup() -> void:
		"""Show popup for item/skill reward claiming."""
		_cleanup_popup()

		var eligible = controller.get_eligible_characters()
		eligible_char_indices = eligible["indices"]
		var eligible_chars: Array = eligible["characters"]

		if eligible_chars.is_empty():
			# No eligible characters, apply fallback
			var fallback = RewardApplicator.get_fallback_reward(controller.current_reward)
			controller.current_reward = fallback
			_on_take_prize_pressed()
			return

		# Create and show the popup
		reward_popup = WheelOfFortuneEncounterUI.RewardClaimPopupScene.instantiate()
		var scene_root = get_tree().current_scene
		scene_root.add_child(reward_popup)

		# Connect signals
		reward_popup.claimed.connect(_on_popup_claimed)

		# Determine reward type and show appropriate popup
		var reward = controller.current_reward
		if reward.type == RewardTypes.RewardType.ITEM or reward.type == RewardTypes.RewardType.ITEM_RANDOM:
			var item_id = reward.params.get("item_id", "")
			if item_id.is_empty():
				# Random item - pick one now
				item_id = _pick_random_item_for_reward()
				reward.params["item_id"] = item_id

			reward_popup.show_item(
				item_id,
				eligible_chars,
				eligible_char_indices,
				"",  # No header
				"",  # No bonus
				"Claim",
				0  # Free (already won)
			)
		elif reward.type == RewardTypes.RewardType.SKILL or reward.type == RewardTypes.RewardType.SKILL_RANDOM:
			var skill_id = reward.params.get("skill_id", "")
			if skill_id.is_empty():
				# Random skill - pick one now
				skill_id = _pick_random_skill_for_reward()
				reward.params["skill_id"] = skill_id

			reward_popup.show_skill(
				skill_id,
				eligible_chars,
				eligible_char_indices,
				"",  # No header
				"",  # No bonus
				"Learn",
				0  # Free (already won)
			)


	func _pick_random_item_for_reward() -> String:
		"""Pick a random item for the reward."""
		var team = RunManager.get_team()
		var max_level = 1
		for char_instance in team:
			max_level = maxi(max_level, char_instance.level)

		var all_items = GameData.get_all_item_upgrades()
		var valid_items: Array = []

		for item in all_items:
			var item_id = item["id"]
			var level_req = item.get("level_requirement", 1)
			if level_req > max_level:
				continue

			# Check if at least one character can equip
			for char_instance in team:
				if item_id in char_instance.equipped_item_upgrades:
					continue
				var total = char_instance.equipped_items.size() + char_instance.equipped_item_upgrades.size()
				if total >= GameConstants.MAX_RUN_ITEMS:
					continue
				valid_items.append(item_id)
				break

		if valid_items.is_empty():
			return ""

		valid_items.shuffle()
		return valid_items[0]


	func _pick_random_skill_for_reward() -> String:
		"""Pick a random skill for the reward."""
		var team = RunManager.get_team()
		var max_level = 1
		for char_instance in team:
			max_level = maxi(max_level, char_instance.level)

		var all_skills = GameData.get_all_skills()
		var valid_skills: Array = []

		for skill in all_skills:
			var skill_id = skill["id"]
			var level_req = skill.get("level_requirement", 1)
			if level_req > max_level:
				continue

			# Check if at least one character can learn
			for char_instance in team:
				if skill_id in char_instance.learned_skills:
					continue
				if char_instance.learned_skills.size() >= GameConstants.MAX_RUN_SKILLS:
					continue
				valid_skills.append(skill_id)
				break

		if valid_skills.is_empty():
			return ""

		valid_skills.shuffle()
		return valid_skills[0]


	func _on_popup_claimed(_reward_id: String, char_index: int) -> void:
		"""Handle claim from popup."""
		var team = RunManager.get_team()
		var target_char = team[char_index]

		var success = controller.accept_reward(target_char)
		if success:
			_cleanup_popup()


	func _cleanup_popup() -> void:
		"""Clean up the reward popup if it exists."""
		if reward_popup and is_instance_valid(reward_popup):
			reward_popup.hide_popup()
			reward_popup.queue_free()
			reward_popup = null


	func _on_spin_pressed() -> void:
		"""Handle spin button press."""
		if controller.current_state != WheelState.State.IDLE:
			return

		# Select winning segment
		var winning_index = controller.select_winning_segment()

		# Start controller and visual
		controller.start_spin()
		wheel_visual.start_spin(winning_index)


	func _on_spin_again_pressed() -> void:
		"""Handle spin again button press."""
		if not controller.buy_extra_spin():
			return

		# Update gold display
		_update_gold_display()

		# Select winning segment
		var winning_index = controller.select_winning_segment()

		# Reset visual and start new spin
		wheel_visual.reset()
		controller.start_spin()
		wheel_visual.start_spin(winning_index)


	func _on_take_prize_pressed() -> void:
		"""Handle take prize button press."""
		if controller.reward_requires_selection():
			controller.begin_target_selection()
		else:
			# Apply reward directly
			var success = controller.accept_reward()
			if success:
				_update_gold_display()




	func _on_spin_started() -> void:
		"""Called when spin begins."""
		spin_button.disabled = true
		spin_button.text = "Spinning..."


	func _on_spin_ended(winning_index: int, reward: RewardDefinition) -> void:
		"""Called when controller spin ends."""
		# Show result in visual
		if reward:
			wheel_visual.show_result(reward)
			wheel_visual.flash_winning_segment(winning_index)


	func _on_visual_spin_complete(winning_index: int) -> void:
		"""Called when visual animation completes."""
		# Tell controller to finish the spin
		controller.finish_spin(winning_index)


	func _on_segment_passed(_index: int) -> void:
		"""Called when wheel passes a segment (for tick sound)."""
		# Sound hook - could emit signal or call audio manager
		pass


	func _on_reward_applied(_reward: RewardDefinition, _character: Variant) -> void:
		"""Called when reward is successfully applied."""
		_update_gold_display()

		# Complete the encounter
		var on_complete = context.get("on_encounter_complete", Callable())
		if on_complete.is_valid():
			on_complete.call()


	func _on_extra_spin_purchased() -> void:
		"""Called when extra spin is purchased."""
		_update_gold_display()


	func _update_gold_display() -> void:
		"""Gold display is handled by parent encounter UI."""
		pass
