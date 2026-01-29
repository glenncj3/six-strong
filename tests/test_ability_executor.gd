extends "res://tests/base_test.gd"
# Tests for AbilityExecutor - target resolution + action inference

func _init():
	test_name = "AbilityExecutor Tests"
	super()


func _run_tests():
	section("Unknown Target Mode")
	test_unknown_target_mode_warns()

	section("Enemy Single Strategy")
	test_enemy_single_deals_damage()

	section("Enemy All Strategy")
	test_enemy_all_hits_all_enemies()

	section("Ally Single Strategy")
	test_ally_single_heals()

	section("Ally All Strategy")
	test_ally_all_heals_all()

	section("Enemy Frontline Strategy")
	test_enemy_frontline_hits_front_row()
	test_enemy_frontline_falls_back_to_back_row()


# =============================================================================
# HELPERS
# =============================================================================

func _make_char(team: int, row: int, col: int, hp: float = 100.0, dmg: float = 10.0, spd: float = 1.0) -> CombatCharacter:
	var cc = CombatCharacter.new()
	cc.id = "test_%d_%d_%d" % [team, row, col]
	cc.team = team
	cc.row = row
	cc.column = col
	cc.health = hp
	cc.max_health = hp
	cc.base_damage = dmg
	cc.damage = dmg
	cc.base_speed = spd
	cc.speed = spd
	cc.is_alive = true
	cc.crit_chance = 0.0
	cc.defend_rate = 0.0
	cc.base_crit_chance = 0.0
	cc.base_defend_rate = 0.0
	return cc


func _make_board_1v1() -> CombatBoard:
	var board = CombatBoard.new()
	var player = _make_char(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy = _make_char(GameConstants.TEAM_OPPONENT, 0, 0)
	board.set_character_at(GameConstants.TEAM_PLAYER, 0, 0, player)
	board.set_character_at(GameConstants.TEAM_OPPONENT, 0, 0, enemy)
	return board


func _make_board_1v3() -> CombatBoard:
	var board = CombatBoard.new()
	var player = _make_char(GameConstants.TEAM_PLAYER, 0, 0)
	board.set_character_at(GameConstants.TEAM_PLAYER, 0, 0, player)
	for i in range(3):
		var enemy = _make_char(GameConstants.TEAM_OPPONENT, 0, i)
		board.set_character_at(GameConstants.TEAM_OPPONENT, 0, i, enemy)
	return board


func _make_board_3v1() -> CombatBoard:
	var board = CombatBoard.new()
	for i in range(3):
		var player = _make_char(GameConstants.TEAM_PLAYER, 0, i)
		board.set_character_at(GameConstants.TEAM_PLAYER, 0, i, player)
	var enemy = _make_char(GameConstants.TEAM_OPPONENT, 0, 0)
	board.set_character_at(GameConstants.TEAM_OPPONENT, 0, 0, enemy)
	return board


var _damage_log: Array = []
var _heal_log: Array = []
var _effect_log: Array = []

func _mock_deal_damage(source: CombatCharacter, target: CombatCharacter, amount: float) -> void:
	target.health -= amount
	_damage_log.append({"source": source, "target": target, "amount": amount})


func _mock_heal(target: CombatCharacter, amount: float, source: CombatCharacter) -> void:
	target.health = min(target.health + amount, target.max_health)
	_heal_log.append({"target": target, "amount": amount, "source": source})


func _mock_apply_effect(target: CombatCharacter, effect: CombatEffect) -> void:
	target.effects.append(effect)
	target.recalculate_stats()
	_effect_log.append({"target": target, "effect": effect})


func _make_context(board: CombatBoard) -> Dictionary:
	return {
		"board": board,
		"deal_damage": _mock_deal_damage,
		"heal": _mock_heal,
		"apply_effect": _mock_apply_effect,
	}


func _clear_logs() -> void:
	_damage_log.clear()
	_heal_log.clear()
	_effect_log.clear()


# =============================================================================
# TESTS
# =============================================================================

func test_unknown_target_mode_warns():
	# Should not crash, just warn
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	AbilityExecutor.execute(source, {"target_mode": "nonexistent", "damage_multiplier": 1.0}, _make_context(board))
	assert_true(true, "no crash on unknown target_mode")


func test_enemy_single_deals_damage():
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var ability = {"target_mode": "enemy_single", "damage_multiplier": 1.5}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_damage_log.size(), 1, "one damage event")
	assert_eq(_damage_log[0]["amount"], 15.0, "damage = 10 * 1.5")


func test_enemy_all_hits_all_enemies():
	_clear_logs()
	var board = _make_board_1v3()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var ability = {"target_mode": "enemy_all", "damage_multiplier": 0.6}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_damage_log.size(), 3, "hit all 3 enemies")
	assert_eq(_damage_log[0]["amount"], 6.0, "damage = 10 * 0.6")


func test_ally_single_heals():
	_clear_logs()
	var board = _make_board_3v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.health = 50.0
	source.extra_stats["heal_value"] = 25.0
	var ability = {"target_mode": "ally_single", "heal_from": "heal_value"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_heal_log.size(), 1, "one heal event")
	assert_eq(_heal_log[0]["amount"], 25.0, "heal amount = character heal_value stat")


func test_ally_all_heals_all():
	_clear_logs()
	var board = _make_board_3v1()
	# Damage all allies
	for i in range(3):
		var ch = board.get_character_at(GameConstants.TEAM_PLAYER, 0, i)
		ch.health = 50.0
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.extra_stats["heal_value"] = 15.0
	var ability = {"target_mode": "ally_all", "heal_from": "heal_value"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_heal_log.size(), 3, "healed all 3 allies")
	assert_eq(_heal_log[0]["amount"], 15.0, "heal amount = character heal_value stat")


func test_enemy_frontline_hits_front_row():
	_clear_logs()
	var board = CombatBoard.new()
	var source = _make_char(GameConstants.TEAM_PLAYER, 0, 0)
	board.set_character_at(GameConstants.TEAM_PLAYER, 0, 0, source)
	# 2 front row enemies, 1 back row enemy
	var e1 = _make_char(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 0)
	var e2 = _make_char(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 1)
	var e3 = _make_char(GameConstants.TEAM_OPPONENT, GameConstants.ROW_BACK, 0)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 0, e1)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 1, e2)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_BACK, 0, e3)
	var ability = {"target_mode": "enemy_frontline", "damage_multiplier": 1.0}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_damage_log.size(), 2, "only front row enemies hit")
	assert_eq(_damage_log[0]["amount"], 10.0, "damage = 10 * 1.0")


func test_enemy_frontline_falls_back_to_back_row():
	_clear_logs()
	var board = CombatBoard.new()
	var source = _make_char(GameConstants.TEAM_PLAYER, 0, 0)
	board.set_character_at(GameConstants.TEAM_PLAYER, 0, 0, source)
	# Only back row enemies
	var e1 = _make_char(GameConstants.TEAM_OPPONENT, GameConstants.ROW_BACK, 0)
	var e2 = _make_char(GameConstants.TEAM_OPPONENT, GameConstants.ROW_BACK, 1)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_BACK, 0, e1)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_BACK, 1, e2)
	var ability = {"target_mode": "enemy_frontline", "damage_multiplier": 1.0}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_damage_log.size(), 2, "falls back to back row when no front row")
	assert_eq(_damage_log[0]["amount"], 10.0, "damage = 10 * 1.0")
