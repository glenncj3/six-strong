extends "res://tests/base_test.gd"
# Tests for ability crit support on burn, poison, shield, and heal

func _init():
	test_name = "Ability Crit Tests"
	super()


func _run_tests():
	section("Crittable Effects (100% crit chance)")
	test_poison_effect_crits_double_stacks()
	test_burn_effect_crits_double_stacks()
	test_shield_effect_crits_double_stacks()
	test_heal_crits_double_value()

	section("Non-Crittable Effects (100% crit chance, should NOT crit)")
	test_slow_does_not_crit()
	test_haste_does_not_crit()
	test_freeze_does_not_crit()

	section("Edge Cases")
	test_zero_crit_chance_no_crit()
	test_crit_applies_to_all_targets()


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
	cc.agility = 0.0
	cc.base_crit_chance = 0.0
	cc.base_agility = 0.0
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


func _mock_heal(target: CombatCharacter, amount: float, source: CombatCharacter, is_crit: bool = false) -> void:
	target.health = min(target.health + amount, target.max_health)
	_heal_log.append({"target": target, "amount": amount, "source": source, "is_crit": is_crit})


func _mock_apply_effect(target: CombatCharacter, effect: CombatEffect) -> void:
	target.effects.append(effect)
	target.recalculate_stats()
	_effect_log.append({"target": target, "effect": effect})


func _mock_get_status_effect(effect_id: String) -> Dictionary:
	# Return minimal templates for testing
	match effect_id:
		"poison":
			return {"id": "poison", "merge_behavior": "add_stacks", "stacks": 3, "duration_type": "timed", "duration_value": 5.0, "tick_interval": 1.0}
		"burn":
			return {"id": "burn", "merge_behavior": "add_stacks", "stacks": 3, "duration_type": "timed", "duration_value": 5.0, "tick_interval": 1.0}
		"shield":
			return {"id": "shield", "merge_behavior": "add_stacks", "stacks": 5, "duration_type": "timed", "duration_value": 5.0}
		"slow":
			return {"id": "slow", "merge_behavior": "refresh", "duration_type": "timed", "duration_value": 3.0, "continuous_modifier": "speed", "continuous_value": -0.5}
		"haste":
			return {"id": "haste", "merge_behavior": "refresh", "duration_type": "timed", "duration_value": 3.0, "continuous_modifier": "speed", "continuous_value": 0.5}
		"freeze":
			return {"id": "freeze", "merge_behavior": "refresh", "duration_type": "timed", "duration_value": 2.0}
	return {}


func _make_context(board: CombatBoard) -> Dictionary:
	return {
		"board": board,
		"deal_damage": _mock_deal_damage,
		"heal": _mock_heal,
		"apply_effect": _mock_apply_effect,
		"get_status_effect": _mock_get_status_effect,
	}


func _clear_logs() -> void:
	_damage_log.clear()
	_heal_log.clear()
	_effect_log.clear()


# =============================================================================
# CRITTABLE EFFECTS (crit_chance = 1.0)
# =============================================================================

func test_poison_effect_crits_double_stacks():
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.crit_chance = 1.0
	source.extra_stats["poison_stacks"] = 4.0
	var ability = {"target_mode": "enemy_single", "applies_effect": "poison", "category": "poison", "stacks_from": "poison_stacks"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_effect_log.size(), 1, "one effect applied")
	assert_eq(_effect_log[0]["effect"].stacks, 8, "poison stacks doubled on crit (4 * 2 = 8)")


func test_burn_effect_crits_double_stacks():
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.crit_chance = 1.0
	source.extra_stats["burn_stacks"] = 5.0
	var ability = {"target_mode": "enemy_single", "applies_effect": "burn", "category": "burn", "stacks_from": "burn_stacks"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_effect_log.size(), 1, "one effect applied")
	assert_eq(_effect_log[0]["effect"].stacks, 10, "burn stacks doubled on crit (5 * 2 = 10)")


func test_shield_effect_crits_double_stacks():
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.crit_chance = 1.0
	source.extra_stats["shield_stacks"] = 6.0
	var ability = {"target_mode": "self", "applies_effect": "shield", "category": "shield", "stacks_from": "shield_stacks"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_effect_log.size(), 1, "one effect applied")
	assert_eq(_effect_log[0]["effect"].stacks, 12, "shield stacks doubled on crit (6 * 2 = 12)")


func test_heal_crits_double_value():
	_clear_logs()
	var board = _make_board_3v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.crit_chance = 1.0
	source.health = 50.0
	source.extra_stats["heal_value"] = 10.0
	var ability = {"target_mode": "self", "heal_from": "heal_value"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_heal_log.size(), 1, "one heal event")
	assert_eq(_heal_log[0]["amount"], 20.0, "heal value doubled on crit (10 * 2 = 20)")
	assert_eq(_heal_log[0]["is_crit"], true, "is_crit flag set")


# =============================================================================
# NON-CRITTABLE EFFECTS (crit_chance = 1.0, should NOT crit)
# =============================================================================

func test_slow_does_not_crit():
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.crit_chance = 1.0
	source.extra_stats["slow_duration"] = 3.0
	var ability = {"target_mode": "enemy_single", "applies_effect": "slow", "category": "slow", "duration_from": "slow_duration"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_effect_log.size(), 1, "one effect applied")
	assert_eq(_effect_log[0]["effect"].duration_value, 3.0, "slow duration unchanged (not crittable)")


func test_haste_does_not_crit():
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.crit_chance = 1.0
	source.extra_stats["haste_duration"] = 4.0
	var ability = {"target_mode": "self", "applies_effect": "haste", "category": "haste", "duration_from": "haste_duration"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_effect_log.size(), 1, "one effect applied")
	assert_eq(_effect_log[0]["effect"].duration_value, 4.0, "haste duration unchanged (not crittable)")


func test_freeze_does_not_crit():
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.crit_chance = 1.0
	var ability = {"target_mode": "enemy_single", "applies_effect": "freeze", "category": "freeze"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_effect_log.size(), 1, "one effect applied")
	assert_eq(_effect_log[0]["effect"].duration_value, 2.0, "freeze duration unchanged (not crittable)")


# =============================================================================
# EDGE CASES
# =============================================================================

func test_zero_crit_chance_no_crit():
	_clear_logs()
	var board = _make_board_1v1()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.crit_chance = 0.0
	source.extra_stats["poison_stacks"] = 4.0
	var ability = {"target_mode": "enemy_single", "applies_effect": "poison", "category": "poison", "stacks_from": "poison_stacks"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_effect_log.size(), 1, "one effect applied")
	assert_eq(_effect_log[0]["effect"].stacks, 4, "poison stacks normal with 0% crit")

	# Also test heal
	_clear_logs()
	source.health = 50.0
	source.extra_stats["heal_value"] = 10.0
	var heal_ability = {"target_mode": "self", "heal_from": "heal_value"}
	AbilityExecutor.execute(source, heal_ability, _make_context(board))
	assert_eq(_heal_log[0]["amount"], 10.0, "heal normal with 0% crit")
	assert_eq(_heal_log[0]["is_crit"], false, "is_crit false with 0% crit")


func test_crit_applies_to_all_targets():
	_clear_logs()
	var board = _make_board_1v3()
	var source = board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	source.crit_chance = 1.0
	source.extra_stats["poison_stacks"] = 3.0
	var ability = {"target_mode": "enemy_all", "applies_effect": "poison", "category": "poison", "stacks_from": "poison_stacks"}
	AbilityExecutor.execute(source, ability, _make_context(board))
	assert_eq(_effect_log.size(), 3, "effect applied to all 3 enemies")
	for i in range(3):
		assert_eq(_effect_log[i]["effect"].stacks, 6, "enemy %d got doubled stacks (3 * 2 = 6)" % i)
