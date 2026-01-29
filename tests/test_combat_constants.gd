extends "res://tests/base_test.gd"
# Tests that combat code uses GameConstants instead of magic numbers.
# Verifies constant values are correct and that combat classes reference them properly.

func _init():
	test_name = "CombatConstants Tests"
	super()


func _run_tests():
	section("Constant Values")
	test_team_constants()
	test_row_constants()
	test_grid_constants()
	test_crit_multiplier()

	section("CombatBoard Uses Constants")
	test_board_size_matches_constant()
	test_board_team_player()
	test_board_team_opponent()
	test_board_row_front_back()

	section("CombatCharacter Uses Constants")
	test_character_defaults()
	test_character_board_index()

	section("CombatManager Uses Constants")
	test_manager_player_win()
	test_manager_opponent_win()
	test_manager_draw()
	test_manager_clones_both_teams()

	section("Utility Functions")
	test_get_enemy_team()

	section("CombatTargeting Uses Constants")
	test_targeting_enemy_team_flip()
	test_targeting_front_row_priority()
	test_targeting_ally_uses_own_team()


# =============================================================================
# HELPERS
# =============================================================================

func _make_source(hp: int, spd: float, dmg: float, def_rate: float = 0.0, crit: float = 0.0) -> CharacterInstance:
	var ch = CharacterInstance.new()
	ch.base_character_id = "test"
	ch.stats = {
		GameConstants.STAT_HEALTH: hp,
		GameConstants.STAT_SPEED: spd,
		GameConstants.STAT_DAMAGE: dmg,
		GameConstants.STAT_agility: def_rate,
		GameConstants.STAT_CRIT_CHANCE: crit,
		GameConstants.STAT_CHARGES: -1,
	}
	ch.current_health = hp
	return ch


func _make_grid_with_one(ch: CharacterInstance) -> CharacterGrid:
	var grid = CharacterGrid.new()
	grid.place_character(ch, 0, 0)
	return grid


func _make_cc(p_team: int, p_row: int, p_col: int) -> CombatCharacter:
	var cc = CombatCharacter.new()
	cc.id = "cc_%d_%d_%d" % [p_team, p_row, p_col]
	cc.health = 100.0
	cc.max_health = 100.0
	cc.team = p_team
	cc.row = p_row
	cc.column = p_col
	cc.is_alive = true
	cc.base_speed = 2.0
	cc.speed = 2.0
	cc.base_damage = 10.0
	cc.damage = 10.0
	return cc


func _simulate_time(manager: CombatManager, seconds: float, step: float = 0.1) -> void:
	var remaining = seconds
	while remaining > 0:
		var dt = min(step, remaining)
		manager._update_combat(dt)
		remaining -= dt
		if manager.get_state() and not manager.get_state().combat_active:
			break


# =============================================================================
# TESTS: Constant Values
# =============================================================================

func test_team_constants():
	assert_eq(GameConstants.TEAM_PLAYER, 0, "TEAM_PLAYER is 0")
	assert_eq(GameConstants.TEAM_OPPONENT, 1, "TEAM_OPPONENT is 1")
	assert_ne(GameConstants.TEAM_PLAYER, GameConstants.TEAM_OPPONENT, "TEAM_PLAYER != TEAM_OPPONENT")


func test_row_constants():
	assert_eq(GameConstants.ROW_FRONT, 0, "ROW_FRONT is 0")
	assert_eq(GameConstants.ROW_BACK, 1, "ROW_BACK is 1")
	assert_ne(GameConstants.ROW_FRONT, GameConstants.ROW_BACK, "ROW_FRONT != ROW_BACK")


func test_grid_constants():
	assert_eq(GameConstants.GRID_ROWS, 2, "GRID_ROWS is 2")
	assert_eq(GameConstants.GRID_COLS, 3, "GRID_COLS is 3")
	assert_eq(GameConstants.MAX_GRID_CHARACTERS, 6, "MAX_GRID_CHARACTERS is 6")
	assert_eq(GameConstants.MAX_GRID_CHARACTERS, GameConstants.GRID_ROWS * GameConstants.GRID_COLS, "MAX = ROWS * COLS")


func test_crit_multiplier():
	assert_eq(GameConstants.CRIT_MULTIPLIER, 2.0, "CRIT_MULTIPLIER is 2.0")
	assert_eq(GameConstants.WINNER_DRAW, 2, "WINNER_DRAW is 2")


# =============================================================================
# TESTS: CombatBoard
# =============================================================================

func test_board_size_matches_constant():
	var board = CombatBoard.new()
	assert_eq(board.player_characters.size(), GameConstants.MAX_GRID_CHARACTERS, "player array size matches constant")
	assert_eq(board.opponent_characters.size(), GameConstants.MAX_GRID_CHARACTERS, "opponent array size matches constant")


func test_board_team_player():
	var board = CombatBoard.new()
	var cc = _make_cc(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0)
	board.set_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0, cc)
	var retrieved = board.get_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0)
	assert_eq(retrieved, cc, "get/set with TEAM_PLAYER works")


func test_board_team_opponent():
	var board = CombatBoard.new()
	var cc = _make_cc(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 1)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 1, cc)
	var retrieved = board.get_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 1)
	assert_eq(retrieved, cc, "get/set with TEAM_OPPONENT works")


func test_board_row_front_back():
	var board = CombatBoard.new()
	var front_cc = _make_cc(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0)
	var back_cc = _make_cc(GameConstants.TEAM_PLAYER, GameConstants.ROW_BACK, 0)
	board.set_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0, front_cc)
	board.set_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_BACK, 0, back_cc)

	var front_chars = board.get_living_characters(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT)
	var back_chars = board.get_living_characters(GameConstants.TEAM_PLAYER, GameConstants.ROW_BACK)
	assert_eq(front_chars.size(), 1, "one front row character")
	assert_eq(back_chars.size(), 1, "one back row character")
	assert_eq(front_chars[0], front_cc, "front row returns front character")
	assert_eq(back_chars[0], back_cc, "back row returns back character")


# =============================================================================
# TESTS: CombatCharacter
# =============================================================================

func test_character_defaults():
	var cc = CombatCharacter.new()
	assert_eq(cc.team, GameConstants.TEAM_PLAYER, "default team is TEAM_PLAYER")
	assert_eq(cc.row, GameConstants.ROW_FRONT, "default row is ROW_FRONT")


func test_character_board_index():
	var cc = CombatCharacter.new()
	cc.row = GameConstants.ROW_BACK
	cc.column = 2
	assert_eq(cc.get_board_index(), GameConstants.ROW_BACK * GameConstants.GRID_COLS + 2, "board index uses GRID_COLS")
	assert_eq(cc.get_board_index(), 5, "back row col 2 = index 5")


# =============================================================================
# TESTS: Utility Functions
# =============================================================================

func test_get_enemy_team():
	assert_eq(GameConstants.get_enemy_team(GameConstants.TEAM_PLAYER), GameConstants.TEAM_OPPONENT, "player's enemy is opponent")
	assert_eq(GameConstants.get_enemy_team(GameConstants.TEAM_OPPONENT), GameConstants.TEAM_PLAYER, "opponent's enemy is player")


# =============================================================================
# TESTS: CombatManager
# =============================================================================

func test_manager_player_win():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	var eg = _make_grid_with_one(_make_source(10, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 2.0)
	assert_eq(manager.get_state().winner, GameConstants.TEAM_PLAYER, "winner is TEAM_PLAYER constant")


func test_manager_opponent_win():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(10, 100.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 2.0)
	assert_eq(manager.get_state().winner, GameConstants.TEAM_OPPONENT, "winner is TEAM_OPPONENT constant")


func test_manager_draw():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(100, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 0.1)
	assert_eq(manager.get_state().winner, GameConstants.WINNER_DRAW, "winner is WINNER_DRAW constant")


func test_manager_clones_both_teams():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(80, 3.0, 15.0))
	manager.initialize_combat(pg, eg)

	var p = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0)
	var e = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 0)
	assert_not_null(p, "player character placed at TEAM_PLAYER")
	assert_not_null(e, "enemy character placed at TEAM_OPPONENT")
	assert_eq(p.team, GameConstants.TEAM_PLAYER, "player char has TEAM_PLAYER")
	assert_eq(e.team, GameConstants.TEAM_OPPONENT, "enemy char has TEAM_OPPONENT")


# =============================================================================
# TESTS: CombatTargeting
# =============================================================================

func test_targeting_enemy_team_flip():
	var board = CombatBoard.new()
	var player = _make_cc(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0)
	var enemy = _make_cc(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 0)
	board.set_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0, player)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 0, enemy)

	var targets = CombatTargeting.get_valid_enemy_targets(player, board)
	assert_eq(targets.size(), 1, "player targets opponent")
	assert_eq(targets[0].team, GameConstants.TEAM_OPPONENT, "target is on TEAM_OPPONENT")

	targets = CombatTargeting.get_valid_enemy_targets(enemy, board)
	assert_eq(targets.size(), 1, "opponent targets player")
	assert_eq(targets[0].team, GameConstants.TEAM_PLAYER, "target is on TEAM_PLAYER")


func test_targeting_front_row_priority():
	var board = CombatBoard.new()
	var attacker = _make_cc(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0)
	var front_enemy = _make_cc(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 0)
	var back_enemy = _make_cc(GameConstants.TEAM_OPPONENT, GameConstants.ROW_BACK, 0)
	board.set_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0, attacker)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 0, front_enemy)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_BACK, 0, back_enemy)

	var targets = CombatTargeting.get_valid_enemy_targets(attacker, board)
	assert_eq(targets.size(), 1, "only front row targeted")
	assert_eq(targets[0].row, GameConstants.ROW_FRONT, "target is ROW_FRONT")


func test_targeting_ally_uses_own_team():
	var board = CombatBoard.new()
	var actor = _make_cc(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0)
	var ally = _make_cc(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 1)
	var enemy = _make_cc(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 0)
	board.set_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 0, actor)
	board.set_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_FRONT, 1, ally)
	board.set_character_at(GameConstants.TEAM_OPPONENT, GameConstants.ROW_FRONT, 0, enemy)

	var targets = CombatTargeting.get_valid_ally_targets(actor, board, false)
	assert_eq(targets.size(), 1, "one ally target")
	assert_eq(targets[0].team, GameConstants.TEAM_PLAYER, "ally is on same team")
	assert_eq(targets[0], ally, "ally is the correct character")
