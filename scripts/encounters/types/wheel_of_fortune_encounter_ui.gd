class_name WheelOfFortuneEncounterUI
extends RefCounted
## UI creation for Wheel of Fortune encounters.
## Player spins a wheel with 6 segments for varied rewards.
## First spin is free; player may pay gold for one additional spin.


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
	var char_selector_container: CenterContainer
	var action_container: HBoxContainer

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

		# Character selector (hidden until needed) - positioned where wheel is
		char_selector_container = CenterContainer.new()
		char_selector_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		char_selector_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		char_selector_container.custom_minimum_size = Vector2(GameConstants.WHEEL_SIZE + 40, GameConstants.WHEEL_SIZE + 80)
		char_selector_container.visible = false
		add_child(char_selector_container)

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
				char_selector_container.visible = false

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
				_transition_to_character_selector()

			WheelState.State.COMPLETE:
				spin_button.visible = false
				spin_again_button.visible = false
				take_prize_button.visible = false
				char_selector_container.visible = false


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


	func _transition_to_character_selector() -> void:
		"""Animate wheel off screen and show character selector."""
		# Build the selector UI first (hidden)
		_build_character_selector_ui()

		if eligible_char_indices.is_empty():
			# No eligible characters, apply fallback (already handled in _build)
			return

		# Hide action buttons
		action_container.visible = false

		# Position selector off-screen to the right
		char_selector_container.visible = true
		char_selector_container.modulate.a = 0

		# Animate wheel rolling off to the left, then hide it to release layout space
		var wheel_tween = create_tween()
		wheel_tween.set_parallel(true)
		wheel_tween.tween_property(wheel_visual, "position:x", -400, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		wheel_tween.tween_property(wheel_visual, "modulate:a", 0.0, 0.3).set_delay(0.1)
		wheel_tween.chain().tween_callback(func(): wheel_visual.visible = false)

		# Animate selector sliding in from the right
		var selector_tween = create_tween()
		selector_tween.tween_property(char_selector_container, "modulate:a", 1.0, 0.3).set_delay(0.2)


	func _transition_back_to_wheel() -> void:
		"""Animate selector off screen and bring wheel back."""
		# Animate selector fading out
		var selector_tween = create_tween()
		selector_tween.tween_property(char_selector_container, "modulate:a", 0.0, 0.2)
		selector_tween.tween_callback(func(): char_selector_container.visible = false)

		# Show action buttons again
		action_container.visible = true

		# Make wheel visible again (was hidden to release layout space)
		wheel_visual.visible = true

		# Animate wheel rolling back in
		var wheel_tween = create_tween()
		wheel_tween.set_parallel(true)
		wheel_tween.tween_property(wheel_visual, "position:x", 0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_delay(0.1)
		wheel_tween.tween_property(wheel_visual, "modulate:a", 1.0, 0.3).set_delay(0.1)


	func _build_character_selector_ui() -> void:
		"""Build character selection UI for items/skills."""
		UIHelpers.clear_children(char_selector_container)

		var eligible = controller.get_eligible_characters()
		eligible_char_indices = eligible["indices"]
		var eligible_chars: Array = eligible["characters"]

		if eligible_chars.is_empty():
			# No eligible characters, apply fallback
			var fallback = RewardApplicator.get_fallback_reward(controller.current_reward)
			controller.current_reward = fallback
			_on_take_prize_pressed()
			return

		# Content VBox - CenterContainer parent will center this
		var content = VBoxContainer.new()
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 12)
		char_selector_container.add_child(content)

		var label = UIHelpers.create_label(
			"Select character for: %s" % controller.current_reward.get_label(),
			GameConstants.FONT_SIZE_BODY,
			GameConstants.COLOR_TEXT_LIGHT,
			true
		)
		content.add_child(label)

		var selector = UIPanelFactory.create_team_selector(eligible_chars)
		selector.custom_minimum_size.x = 300
		content.add_child(selector)

		var confirm_btn = UIHelpers.create_button(
			"Confirm",
			_on_confirm_selection.bind(selector),
			GameConstants.BUTTON_WIDTH_SMALL,
			GameConstants.BUTTON_HEIGHT_STANDARD
		)
		UIStyles.setup_success_button(confirm_btn)
		content.add_child(confirm_btn)

		var cancel_btn = UIHelpers.create_button(
			"Back",
			_on_cancel_selection,
			GameConstants.BUTTON_WIDTH_SMALL,
			GameConstants.BUTTON_HEIGHT_STANDARD
		)
		UIStyles.setup_button(cancel_btn)
		content.add_child(cancel_btn)


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


	func _on_confirm_selection(selector: OptionButton) -> void:
		"""Handle character selection confirmation."""
		var selector_index = selector.selected - 1  # First option is "Select..."
		if selector_index < 0 or selector_index >= eligible_char_indices.size():
			return

		var team = RunManager.get_team()
		var char_index = eligible_char_indices[selector_index]
		var target_char = team[char_index]

		var success = controller.accept_reward(target_char)
		if not success:
			# Show error? For now just stay in selection
			pass


	func _on_cancel_selection() -> void:
		"""Cancel character selection and go back to choice."""
		_transition_back_to_wheel()
		controller.cancel_target_selection()


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
