extends Node
# RunFlowController Singleton
# Orchestrates run flow and scene transitions
# RunManager handles state; this class handles "what happens next"

signal combat_completed(winner: int, is_run_over: bool)


func complete_combat(winner: int, combat_data: Dictionary) -> void:
	"""
	Complete a combat and handle all post-combat logic.
	Emits combat_completed signal for the scene to handle navigation.

	Args:
		winner: 0 = player won, 1 = opponent won, 2 = draw
		combat_data: The combat option dictionary
	"""
	if winner == GameConstants.TEAM_PLAYER:
		RunManager.apply_combat_rewards(true, combat_data)
		RunManager.add_win()
	elif winner == GameConstants.TEAM_OPPONENT:
		RunManager.apply_combat_rewards(false, combat_data)
		RunManager.add_loss()
	# winner == WINNER_DRAW: no win, no loss, no reputation change

	RunManager.save_run_state()

	var run_over = RunManager.is_run_over()
	if run_over:
		var victory = RunManager.did_player_win()
		var reward_data = RunManager.end_run(victory)
		SceneTransitionData.set_run_results(reward_data)
	else:
		RunManager.advance_round()

	combat_completed.emit(winner, run_over)
