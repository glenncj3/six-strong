extends SceneTree
## Unit tests for ProgressionManager.

const PM = preload("res://scripts/managers/progression_manager.gd")


func _init() -> void:
	var results = run_all_tests()

	print("\n========================================")
	print("ProgressionManager Tests")
	print("========================================\n")

	for test_name in results.test_names:
		var status = "PASS" if test_name in results.passed else "FAIL"
		print("TEST: %s" % test_name)
		print("  %s" % status)
		if test_name in results.errors:
			print("  Error: %s" % results.errors[test_name])

	print("\n========================================")
	print("Results: %d passed, %d failed" % [results.passed.size(), results.failed.size()])
	print("========================================\n")

	quit(results.failed.size())


static func run_all_tests() -> Dictionary:
	var passed: Array = []
	var failed: Array = []
	var errors: Dictionary = {}
	var test_names: Array = []

	var tests: Array[Callable] = [
		_test_initial_state,
		_test_advance_round,
		_test_complete_encounter_switches_phase,
		_test_add_win,
		_test_is_victory,
		_test_add_player_xp_no_level,
		_test_add_player_xp_level_up,
		_test_max_level,
		_test_reset,
		_test_serialization,
		_test_round_signal,
		_test_phase_signal,
		_test_level_signal,
	]
	var names: Array[String] = [
		"initial_state",
		"advance_round",
		"complete_encounter_switches_phase",
		"add_win",
		"is_victory",
		"add_player_xp_no_level",
		"add_player_xp_level_up",
		"max_level",
		"reset",
		"serialization",
		"round_signal",
		"phase_signal",
		"level_signal",
	]

	for i in tests.size():
		test_names.append(names[i])
		if tests[i].call():
			passed.append(names[i])
		else:
			failed.append(names[i])
			errors[names[i]] = "Assertion failed"

	return {"passed": passed, "failed": failed, "errors": errors, "test_names": test_names}


static func _test_initial_state() -> bool:
	var pm = PM.new()
	return pm.current_round == 1 and pm.current_phase == "encounter" and pm.wins == 0 and pm.player_level == 1


static func _test_advance_round() -> bool:
	var pm = PM.new()
	pm.encounters_this_round = 3
	pm.advance_round()
	return pm.current_round == 2 and pm.current_phase == "encounter" and pm.encounters_this_round == 0


static func _test_complete_encounter_switches_phase() -> bool:
	var pm = PM.new()
	# Complete enough encounters to switch to combat
	for i in GameConstants.ENCOUNTERS_PER_ROUND:
		pm.complete_encounter()
	return pm.current_phase == "combat"


static func _test_add_win() -> bool:
	var pm = PM.new()
	pm.add_win()
	pm.add_win()
	return pm.wins == 2


static func _test_is_victory() -> bool:
	var pm = PM.new()
	for i in GameConstants.WINS_FOR_VICTORY:
		pm.add_win()
	return pm.is_victory()


static func _test_add_player_xp_no_level() -> bool:
	var pm = PM.new()
	var leveled = pm.add_player_xp(1)
	return not leveled and pm.player_level == 1 and pm.player_xp == 1


static func _test_add_player_xp_level_up() -> bool:
	var pm = PM.new()
	var leveled = pm.add_player_xp(GameConstants.XP_PER_LEVEL)
	return leveled and pm.player_level == 2


static func _test_max_level() -> bool:
	var pm = PM.new()
	pm.add_player_xp(GameConstants.XP_PER_LEVEL * 10)  # Way more than needed
	return pm.is_max_level() and pm.player_xp == 0


static func _test_reset() -> bool:
	var pm = PM.new()
	pm.add_win()
	pm.advance_round()
	pm.add_player_xp(100)
	pm.reset()
	return pm.current_round == 1 and pm.wins == 0 and pm.player_level == 1


static func _test_serialization() -> bool:
	var pm = PM.new()
	pm.advance_round()
	pm.add_win()
	pm.add_player_xp(5)
	var data = pm.to_dict()
	var pm2 = PM.new()
	pm2.load_from_dict(data)
	return pm2.current_round == 2 and pm2.wins == 1 and pm2.player_xp == 5


static func _test_round_signal() -> bool:
	var pm = PM.new()
	var received = [0]
	pm.round_changed.connect(func(v): received[0] = v)
	pm.advance_round()
	return received[0] == 2


static func _test_phase_signal() -> bool:
	var pm = PM.new()
	var received = [""]
	pm.phase_changed.connect(func(v): received[0] = v)
	pm.set_phase("combat")
	return received[0] == "combat"


static func _test_level_signal() -> bool:
	var pm = PM.new()
	var received = [0]
	pm.player_level_changed.connect(func(v): received[0] = v)
	pm.add_player_xp(GameConstants.XP_PER_LEVEL)
	return received[0] == 2
