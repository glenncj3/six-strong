class_name WheelOfFortuneEncounterUI
extends RefCounted
## UI creation for Wheel of Fortune encounters.
## Player spins a wheel with 6 segments for varied rewards.
## First spin is free; player may pay gold for one additional spin.
##
## Auto-registration metadata (Phase 4):
const ENCOUNTER_TYPE := "wheel_of_fortune"
##
## Phase 2 Refactor:
## - Items go to player inventory (no character selection)
## - Skills are instant effects (no character selection)


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
	var encounter_data: Dictionary

	# Store callbacks directly instead of whole context dict to avoid stale references
	var _on_complete: Callable = Callable()
	var _context: Dictionary = {}  # Keep context for passing to controller/reward applicator

	# Track active tweens for cleanup on exit
	var _tweens: TweenTracker

	# UI elements
	var spin_button: Button
	var spin_again_button: Button
	var take_prize_button: Button
	var side_button_container: VBoxContainer  # Container for buttons to right of wheel


	func initialize(p_encounter_data: Dictionary, p_context: Dictionary) -> void:
		encounter_data = p_encounter_data
		_context = p_context
		# Extract and store callback directly at initialization time
		_on_complete = p_context.get("on_encounter_complete", Callable())

		# Initialize tween tracker
		_tweens = TweenTracker.new(self)

		set_anchors_preset(Control.PRESET_FULL_RECT)
		add_theme_constant_override("separation", 10)
		alignment = BoxContainer.ALIGNMENT_CENTER

		# Create controller
		controller = WheelController.new()
		controller.setup(encounter_data, _context)

		# Connect controller signals
		controller.state_changed.connect(_on_state_changed)
		controller.spin_started.connect(_on_spin_started)
		controller.spin_ended.connect(_on_spin_ended)
		controller.reward_applied.connect(_on_reward_applied)
		controller.extra_spin_purchased.connect(_on_extra_spin_purchased)

		_build_ui()


	func _build_ui() -> void:
		# Main area: wheel on left, spin/respin buttons on right
		var wheel_row = HBoxContainer.new()
		wheel_row.alignment = BoxContainer.ALIGNMENT_CENTER
		wheel_row.add_theme_constant_override("separation", 16)
		add_child(wheel_row)

		# Create wheel visual
		wheel_visual = WheelVisual.new()
		wheel_visual.custom_minimum_size = Vector2(GameConstants.WHEEL_SIZE + 40, GameConstants.WHEEL_SIZE + 80)
		wheel_visual.setup(controller.get_segments())
		wheel_visual.spin_complete.connect(_on_visual_spin_complete)
		wheel_visual.segment_passed.connect(_on_segment_passed)
		wheel_row.add_child(wheel_visual)

		# Side button container (to the right of wheel, aligned to top)
		side_button_container = VBoxContainer.new()
		side_button_container.alignment = BoxContainer.ALIGNMENT_BEGIN
		side_button_container.add_theme_constant_override("separation", 12)
		side_button_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		wheel_row.add_child(side_button_container)

		# Spin button (in side container)
		spin_button = UIHelpers.create_button(
			"SPIN!",
			_on_spin_pressed,
			GameConstants.BUTTON_WIDTH_SMALL,
			GameConstants.BUTTON_HEIGHT_STANDARD
		)
		UIStyles.setup_success_button(spin_button)
		spin_button.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BUTTON_LARGE)
		side_button_container.add_child(spin_button)

		# Spin again button and take prize button will be instantiated dynamically when needed
		spin_again_button = null
		take_prize_button = null


	func _on_state_changed(new_state: int) -> void:
		"""Handle controller state changes."""
		_update_ui_for_state(new_state)


	func _update_ui_for_state(state: int) -> void:
		match state:
			WheelState.State.IDLE:
				spin_button.visible = true
				spin_button.disabled = false
				_hide_spin_again_button()
				_hide_take_prize_button()

			WheelState.State.SPINNING, WheelState.State.LANDING:
				spin_button.visible = true
				spin_button.disabled = true
				spin_button.text = "Spinning..."
				_hide_spin_again_button()
				_hide_take_prize_button()

			WheelState.State.SHOWING_RESULT:
				spin_button.visible = false
				# Wait for visual animation before showing choices

			WheelState.State.AWAITING_CHOICE:
				spin_button.visible = false
				_show_choice_buttons()

			WheelState.State.SELECTING_TARGET:
				# Phase 2: Items/skills no longer need character selection
				# Apply the reward directly
				_apply_reward_directly()

			WheelState.State.COMPLETE:
				spin_button.visible = false
				_hide_spin_again_button()
				_hide_take_prize_button()


	func _show_choice_buttons() -> void:
		"""Show spin again / take prize options."""
		# Spin again button - create dynamically if needed
		if controller.can_spin_again():
			_create_spin_again_button()
			if controller.can_afford_extra_spin():
				spin_again_button.disabled = false
				spin_again_button.text = "Respin: %dg" % controller.spin_again_cost
				UIStyles.setup_button(spin_again_button)
			else:
				spin_again_button.disabled = true
				spin_again_button.text = "Not enough gold"
				UIStyles.setup_danger_button(spin_again_button)

		# Take prize button - create dynamically
		_create_take_prize_button()
		take_prize_button.disabled = false
		take_prize_button.text = "Take Prize"


	func _create_spin_again_button() -> void:
		"""Create and add the spin again button beneath the spin button."""
		if spin_again_button != null:
			spin_again_button.visible = true
			return

		spin_again_button = UIHelpers.create_button(
			"Respin: %dg" % controller.spin_again_cost,
			_on_spin_again_pressed,
			GameConstants.BUTTON_WIDTH_SMALL,
			GameConstants.BUTTON_HEIGHT_STANDARD
		)
		UIStyles.setup_button(spin_again_button)
		side_button_container.add_child(spin_again_button)


	func _hide_spin_again_button() -> void:
		"""Hide or remove the spin again button."""
		if spin_again_button != null:
			spin_again_button.visible = false


	func _create_take_prize_button() -> void:
		"""Create and add the take prize button beneath the other buttons."""
		if take_prize_button != null:
			take_prize_button.visible = true
			return

		take_prize_button = UIHelpers.create_button(
			"Take Prize",
			_on_take_prize_pressed,
			GameConstants.BUTTON_WIDTH_SMALL,
			GameConstants.BUTTON_HEIGHT_STANDARD
		)
		UIStyles.setup_success_button(take_prize_button)
		side_button_container.add_child(take_prize_button)


	func _hide_take_prize_button() -> void:
		"""Hide the take prize button."""
		if take_prize_button != null:
			take_prize_button.visible = false


	func _apply_reward_directly() -> void:
		"""Apply the reward directly without character selection (Phase 2)."""
		var success = controller.accept_reward()
		if not success:
			# Apply fallback if needed
			var fallback = RewardApplicator.get_fallback_reward(controller.current_reward)
			RewardApplicator.apply_reward(fallback, _context)


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
		# Phase 2: No character selection needed for items/skills
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

		# Complete the encounter using stored callback
		if _on_complete.is_valid():
			_on_complete.call()


	func _on_extra_spin_purchased() -> void:
		"""Called when extra spin is purchased."""
		_update_gold_display()


	func _update_gold_display() -> void:
		"""Gold display is handled by parent encounter UI."""
		pass


	func _exit_tree() -> void:
		"""Clean up signal connections and tweens when removed from tree."""
		# Kill any active tweens to prevent callbacks on freed nodes
		if _tweens:
			_tweens.kill_all()

		# Disconnect controller signals
		if controller:
			if controller.state_changed.is_connected(_on_state_changed):
				controller.state_changed.disconnect(_on_state_changed)
			if controller.spin_started.is_connected(_on_spin_started):
				controller.spin_started.disconnect(_on_spin_started)
			if controller.spin_ended.is_connected(_on_spin_ended):
				controller.spin_ended.disconnect(_on_spin_ended)
			if controller.reward_applied.is_connected(_on_reward_applied):
				controller.reward_applied.disconnect(_on_reward_applied)
			if controller.extra_spin_purchased.is_connected(_on_extra_spin_purchased):
				controller.extra_spin_purchased.disconnect(_on_extra_spin_purchased)

		# Disconnect wheel_visual signals
		if wheel_visual:
			if wheel_visual.spin_complete.is_connected(_on_visual_spin_complete):
				wheel_visual.spin_complete.disconnect(_on_visual_spin_complete)
			if wheel_visual.segment_passed.is_connected(_on_segment_passed):
				wheel_visual.segment_passed.disconnect(_on_segment_passed)
