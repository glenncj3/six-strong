class_name WheelController
extends RefCounted
## Business logic controller for Wheel of Fortune encounter.
## Manages state, segments, spins, and reward application.
## Separated from visuals for clean architecture.


## Emitted when state changes
signal state_changed(new_state: int)

## Emitted when spin starts
signal spin_started()

## Emitted when spin ends with winning segment
signal spin_ended(winning_index: int, reward: RewardDefinition)

## Emitted when reward is successfully applied
signal reward_applied(reward: RewardDefinition, character: Variant)

## Emitted when extra spin is purchased
signal extra_spin_purchased()


## Wheel segments (6 total)
var segments: Array = []  # Array[RewardDefinition]

## Current state machine state
var current_state: int = WheelState.State.IDLE

## Number of spins remaining (starts at 1)
var spins_remaining: int = 1

## Gold cost to spin again (only one extra allowed)
var spin_again_cost: int = 30

## Whether extra spin has been purchased
var extra_spin_used: bool = false

## Current winning reward (set after spin)
var current_reward: RewardDefinition = null

## Index of winning segment
var winning_index: int = -1

## Context callbacks for reward application
var context: Dictionary = {}


func _init(p_segments: Array = [], p_spin_again_cost: int = 30) -> void:
	segments = p_segments
	spin_again_cost = p_spin_again_cost


## Initialize with encounter data and context
func setup(encounter_data: Dictionary, p_context: Dictionary) -> void:
	context = p_context

	var data = encounter_data.get("data", {})
	spin_again_cost = data.get("spin_again_cost", 30)

	# Generate segments if not provided in data
	if data.has("segments") and data["segments"] is Array:
		segments = []
		for seg_dict in data["segments"]:
			segments.append(RewardDefinition.from_dict(seg_dict))
	else:
		# Generate based on current round
		var round_num = RunManager.current_round
		segments = RewardGenerator.generate_wheel_segments(round_num)

	# Ensure exactly 6 segments
	while segments.size() < 6:
		segments.append(RewardDefinition.create_gold(randi_range(10, 30)))
	if segments.size() > 6:
		segments = segments.slice(0, 6)

	spins_remaining = 1
	extra_spin_used = false
	current_reward = null
	winning_index = -1
	_set_state(WheelState.State.IDLE)


## Start a spin if allowed
func start_spin() -> bool:
	if current_state != WheelState.State.IDLE and current_state != WheelState.State.AWAITING_CHOICE:
		return false
	if spins_remaining <= 0:
		return false

	spins_remaining -= 1
	current_reward = null
	winning_index = -1

	_set_state(WheelState.State.SPINNING)
	spin_started.emit()

	return true


## Called by visual component when spin enters landing phase
func begin_landing() -> void:
	if current_state != WheelState.State.SPINNING:
		return
	_set_state(WheelState.State.LANDING)


## Select the winning segment (called when spin starts)
## Returns the winning index (0-5)
func select_winning_segment() -> int:
	# Use segment weights for biased selection
	var weights = RewardGenerator.generate_segment_weights(segments)
	winning_index = _weighted_random_select(weights)
	return winning_index


## Called by visual component when spin finishes
func finish_spin(p_winning_index: int) -> void:
	winning_index = p_winning_index
	if winning_index >= 0 and winning_index < segments.size():
		current_reward = segments[winning_index]
	else:
		current_reward = null

	_set_state(WheelState.State.SHOWING_RESULT)
	spin_ended.emit(winning_index, current_reward)

	# Auto-transition based on reward type
	_auto_transition_after_result()


## Attempt to buy an extra spin
## Returns true if successful
func buy_extra_spin() -> bool:
	if extra_spin_used:
		return false
	if current_state != WheelState.State.AWAITING_CHOICE:
		return false

	# Try to spend gold
	var success = EncounterUIHelpers.try_spend_gold(spin_again_cost, context.get("on_gold_spend", Callable()))
	if not success:
		return false

	extra_spin_used = true
	spins_remaining += 1
	extra_spin_purchased.emit()

	return true


## Accept the current reward
## For rewards requiring target selection, pass the character
func accept_reward(target_char: Variant = null) -> bool:
	if current_reward == null:
		return false

	var result = RewardApplicator.apply_reward(current_reward, context, target_char)

	if result.success:
		reward_applied.emit(current_reward, target_char)
		_set_state(WheelState.State.COMPLETE)
		return true

	return false


## Check if player can spin again
func can_spin_again() -> bool:
	if extra_spin_used:
		return false
	if current_state != WheelState.State.AWAITING_CHOICE:
		return false
	return true


## Check if player can afford another spin
func can_afford_extra_spin() -> bool:
	return RunManager.get_gold() >= spin_again_cost


## Get the current player gold
func get_player_gold() -> int:
	return RunManager.get_gold()


## Skip to complete (forfeit reward)
func skip_reward() -> void:
	_set_state(WheelState.State.COMPLETE)


## Get segment at index
func get_segment(index: int) -> RewardDefinition:
	if index >= 0 and index < segments.size():
		return segments[index]
	return null


## Get all segments
func get_segments() -> Array:
	return segments


## Check if reward requires character selection
func reward_requires_selection() -> bool:
	if current_reward == null:
		return false
	return current_reward.requires_target_selection()


## Get eligible characters for current reward
func get_eligible_characters() -> Dictionary:
	if current_reward == null:
		return {"indices": [], "characters": []}
	return RewardApplicator.get_eligible_characters(current_reward)


## Transition to character selection state
func begin_target_selection() -> void:
	if current_state == WheelState.State.SHOWING_RESULT or current_state == WheelState.State.AWAITING_CHOICE:
		_set_state(WheelState.State.SELECTING_TARGET)


## Cancel target selection (go back to choice)
func cancel_target_selection() -> void:
	if current_state == WheelState.State.SELECTING_TARGET:
		_set_state(WheelState.State.AWAITING_CHOICE)


# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _set_state(new_state: int) -> void:
	if not WheelState.can_transition(current_state, new_state):
		# Allow same-state (no-op) or force for initial setup
		if current_state != new_state and current_state != WheelState.State.IDLE:
			push_warning("WheelController: Invalid state transition from %s to %s" %
				[WheelState.get_state_name(current_state), WheelState.get_state_name(new_state)])
			return

	current_state = new_state
	state_changed.emit(new_state)


func _auto_transition_after_result() -> void:
	# Brief delay handled by visual, then transition
	# For now, go directly to appropriate state

	if current_reward == null:
		_set_state(WheelState.State.AWAITING_CHOICE)
		return

	# Check if reward requires target selection
	if current_reward.requires_target_selection():
		var eligible = get_eligible_characters()
		if eligible["characters"].is_empty():
			# No eligible targets, offer fallback
			current_reward = RewardApplicator.get_fallback_reward(current_reward)
			_set_state(WheelState.State.AWAITING_CHOICE)
		else:
			# Has eligible targets, will need selection
			_set_state(WheelState.State.AWAITING_CHOICE)
	else:
		# Reward doesn't need selection
		_set_state(WheelState.State.AWAITING_CHOICE)


func _weighted_random_select(weights: Array) -> int:
	var total_weight = 0.0
	for w in weights:
		total_weight += w

	var random_value = randf() * total_weight
	var cumulative = 0.0

	for i in range(weights.size()):
		cumulative += weights[i]
		if random_value <= cumulative:
			return i

	return 0
