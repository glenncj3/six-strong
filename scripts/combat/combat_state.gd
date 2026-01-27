class_name CombatState
extends RefCounted
## Holds all state for an active combat instance.

var board: CombatBoard = null
var elapsed_time: float = 0.0
var combat_active: bool = false
var winner = null  # null during combat, TEAM_PLAYER, TEAM_OPPONENT, or WINNER_DRAW
