class_name WheelState
extends RefCounted
## State machine enum and logic for the Wheel of Fortune encounter.
## Defines all valid states and transitions.


## Possible states for the wheel encounter
enum State {
	IDLE,             ## Ready to spin
	SPINNING,         ## Wheel is in motion
	LANDING,          ## Decelerating to target segment
	SHOWING_RESULT,   ## Displaying winning reward
	AWAITING_CHOICE,  ## Player choosing: spin again or take reward
	SELECTING_TARGET, ## Character selection (for items/skills)
	COMPLETE          ## Encounter finished
}


## String representations for debugging
const STATE_NAMES := {
	State.IDLE: "IDLE",
	State.SPINNING: "SPINNING",
	State.LANDING: "LANDING",
	State.SHOWING_RESULT: "SHOWING_RESULT",
	State.AWAITING_CHOICE: "AWAITING_CHOICE",
	State.SELECTING_TARGET: "SELECTING_TARGET",
	State.COMPLETE: "COMPLETE"
}


## Valid state transitions
const VALID_TRANSITIONS := {
	State.IDLE: [State.SPINNING],
	State.SPINNING: [State.LANDING, State.SHOWING_RESULT],  # Can skip LANDING
	State.LANDING: [State.SHOWING_RESULT],
	State.SHOWING_RESULT: [State.AWAITING_CHOICE, State.SELECTING_TARGET, State.COMPLETE],
	State.AWAITING_CHOICE: [State.SPINNING, State.SELECTING_TARGET, State.COMPLETE],
	State.SELECTING_TARGET: [State.COMPLETE, State.AWAITING_CHOICE],
	State.COMPLETE: []
}


## Check if a transition is valid
static func can_transition(from: int, to: int) -> bool:
	var valid_targets = VALID_TRANSITIONS.get(from, [])
	return to in valid_targets


## Get state name for debugging/display
static func get_state_name(state: int) -> String:
	return STATE_NAMES.get(state, "UNKNOWN")
