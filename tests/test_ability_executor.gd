extends "res://tests/base_test.gd"
# Tests for AbilityExecutor - strategy registry for ability execution

func _init():
	test_name = "AbilityExecutor Tests"
	super()


func _run_tests():
	section("Registry")
	test_register_defaults()
	test_has_strategy()
	test_unknown_strategy_warns()

	section("Enemy Single Strategy")
	test_enemy_single_deals_damage()

	section("Enemy All Strategy")
	test_enemy_all_hits_all_enemies()

	section("Ally Single Strategy")
	test_ally_single_heals()

	section("Ally All Strategy")
	test_ally_all_heals_all()

	section("Self Buff Strategy")
	test_self_buff_applies_effect()

	section("Enemy Random Multi Strategy")
	test_enemy_random_multi_hits()


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

func test_register_defaults():
	AbilityExecutor.register_defaults()
	assert_true(AbilityExecutor.has_strategy("enemy_single"), "enemy_single registered")
	assert_true(AbilityExecutor.has_strategy("enemy_all"), "enemy_all registered")
	assert_true(AbilityExecutor.has_strategy("ally_single"), "ally_single registered")
	assert_true(AbilityExecutor.has_strategy("ally_all"), "ally_all registered")
	assert_true(AbilityExecutor.has_strategy("self_buff"), "self_buff registered")
	assert_true(AbilityExecutor.has_strategy("enemy_random_multi"), "enemy_random_multi registered")


func test_has_strategy():
	AbilityExecutor.register_defaults()
	assert_false(AbilityExecutor.has_strategy("nonexistent"), "nonexistent strategy not found")


func test_unknown_strategy_warns():
	AbilityExecutor.register_defaults()
	# Should not crash, just warn
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	AbilityExecutor.execute("nonexistent", source, {}, _make_context(board))
	assert_true(true, "no crash on unknown strategy")


func test_enemy_single_deals_damage():
	AbilityExecutor.register_defaults()
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var ability = {"targeting": "enemy_single", "damage_multiplier": 1.5}
	AbilityExecutor.execute("enemy_single", source, ability, _make_context(board))
	assert_eq(_damage_log.size(), 1, "one damage event")
	assert_eq(_damage_log[0]["amount"], 15.0, "damage = 10 * 1.5")


func test_enemy_all_hits_all_enemies():
	AbilityExecutor.register_defaults()
	_clear_logs()
	var board = _make_board_1v3()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var ability = {"targeting": "enemy_all", "damage_multiplier": 0.6}
	AbilityExecutor.execute("enemy_all", source, ability, _make_context(board))
	assert_eq(_damage_log.size(), 3, "hit all 3 enemies")
	assert_eq(_damage_log[0]["amount"], 6.0, "damage = 10 * 0.6")


func test_ally_single_heals():
	AbilityExecutor.register_defaults()
	_clear_logs()
	var board = _make_board_3v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.health = 50.0
	var ability = {"targeting": "ally_single", "heal_value": 20.0}
	AbilityExecutor.execute("ally_single", source, ability, _make_context(board))
	assert_eq(_heal_log.size(), 1, "one heal event")
	assert_eq(_heal_log[0]["amount"], 20.0, "heal amount = heal_value")


func test_ally_all_heals_all():
	AbilityExecutor.register_defaults()
	_clear_logs()
	var board = _make_board_3v1()
	# Damage all allies
	for i in range(3):
		var ch = board.get_character_at(GameConstants.TEAM_PLAYER, 0, i)
		ch.health = 50.0
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var ability = {"targeting": "ally_all", "heal_value": 10.0}
	AbilityExecutor.execute("ally_all", source, ability, _make_context(board))
	assert_eq(_heal_log.size(), 3, "healed all 3 allies")
	assert_eq(_heal_log[0]["amount"], 10.0, "heal amount = heal_value")


func test_self_buff_applies_effect():
	AbilityExecutor.register_defaults()
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var ability = {
		"targeting": "self_buff",
		"buff_stat": "damage",
		"buff_value": 5.0,
		"buff_modifier_type": "flat",
		"buff_duration_type": "cooldowns",
		"buff_duration_value": 3,
	}
	AbilityExecutor.execute("self_buff", source, ability, _make_context(board))
	assert_eq(_effect_log.size(), 1, "one effect applied")
	assert_eq(_effect_log[0]["target"], source, "effect applied to self")
	assert_eq(source.damage, 15.0, "damage buffed: 10 + 5 = 15")


func test_enemy_random_multi_hits():
	AbilityExecutor.register_defaults()
	_clear_logs()
	var board = _make_board_1v3()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var ability = {"targeting": "enemy_random_multi", "damage_multiplier": 0.5, "hit_count": 3}
	AbilityExecutor.execute("enemy_random_multi", source, ability, _make_context(board))
	assert_eq(_damage_log.size(), 3, "3 hits dealt")
	assert_eq(_damage_log[0]["amount"], 5.0, "damage = 10 * 0.5 per hit")
