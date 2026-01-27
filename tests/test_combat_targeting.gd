extends "res://tests/base_test.gd"
# Tests for CombatTargeting - all examples from the design document

func _init():
	test_name = "CombatTargeting Tests"
	super()


func _run_tests():
	section("Enemy Targeting - Front Row Priority")
	test_targets_front_row_first()
	test_falls_back_to_back_row()
	test_no_targets_returns_empty()

	section("Enemy Targeting - Column Proximity")
	test_same_column_targeted()
	test_nearest_column_after_death()
	test_equidistant_random_tiebreaker()

	section("Design Doc Examples")
	test_example_1_g_targets_a()
	test_example_2_g_targets_b_after_a_dies()
	test_example_3_h_targets_b()
	test_example_4_h_targets_a_or_c_after_b_dies()
	test_example_5_j_buffs_g()

	section("Ally Targeting")
	test_ally_targeting_excludes_self()
	test_ally_targeting_includes_self()

	section("Utilities")
	test_column_distance()


# =============================================================================
# HELPERS
# =============================================================================

func _make_cc(p_team: int, p_row: int, p_col: int, name_str: String = "") -> CombatCharacter:
	var cc = CombatCharacter.new()
	cc.id = name_str if name_str != "" else "cc_%d_%d_%d" % [p_team, p_row, p_col]
	cc.character_name = cc.id
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


func _setup_design_doc_board() -> Dictionary:
	# Player: A(0,0) B(0,1) C(0,2) / D(1,0) _(1,1) F(1,2)
	# Opponent: G(0,0) H(0,1) _(0,2) / J(1,0) _(1,1) _(1,2)
	var board = CombatBoard.new()
	var A = _make_cc(0, 0, 0, "A")
	var B = _make_cc(0, 0, 1, "B")
	var C = _make_cc(0, 0, 2, "C")
	var D = _make_cc(0, 1, 0, "D")
	var F = _make_cc(0, 1, 2, "F")
	var G = _make_cc(1, 0, 0, "G")
	var H = _make_cc(1, 0, 1, "H")
	var J = _make_cc(1, 1, 0, "J")

	board.set_character_at(0, 0, 0, A)
	board.set_character_at(0, 0, 1, B)
	board.set_character_at(0, 0, 2, C)
	board.set_character_at(0, 1, 0, D)
	board.set_character_at(0, 1, 2, F)
	board.set_character_at(1, 0, 0, G)
	board.set_character_at(1, 0, 1, H)
	board.set_character_at(1, 1, 0, J)

	return {"board": board, "A": A, "B": B, "C": C, "D": D, "F": F, "G": G, "H": H, "J": J}


# =============================================================================
# TESTS
# =============================================================================

func test_targets_front_row_first():
	var board = CombatBoard.new()
	var attacker = _make_cc(0, 0, 0)
	var front = _make_cc(1, 0, 0)
	var back = _make_cc(1, 1, 0)
	board.set_character_at(0, 0, 0, attacker)
	board.set_character_at(1, 0, 0, front)
	board.set_character_at(1, 1, 0, back)

	var targets = CombatTargeting.get_valid_enemy_targets(attacker, board)
	assert_eq(targets.size(), 1, "one front row target")
	assert_eq(targets[0], front, "targets front row")


func test_falls_back_to_back_row():
	var board = CombatBoard.new()
	var attacker = _make_cc(0, 0, 0)
	var back = _make_cc(1, 1, 0)
	board.set_character_at(0, 0, 0, attacker)
	board.set_character_at(1, 1, 0, back)

	var targets = CombatTargeting.get_valid_enemy_targets(attacker, board)
	assert_eq(targets.size(), 1, "falls back to back row")
	assert_eq(targets[0], back, "targets back row when no front")


func test_no_targets_returns_empty():
	var board = CombatBoard.new()
	var attacker = _make_cc(0, 0, 0)
	board.set_character_at(0, 0, 0, attacker)

	var targets = CombatTargeting.get_valid_enemy_targets(attacker, board)
	assert_eq(targets.size(), 0, "no targets returns empty")


func test_same_column_targeted():
	var board = CombatBoard.new()
	var attacker = _make_cc(0, 0, 0)
	var e0 = _make_cc(1, 0, 0)
	var e1 = _make_cc(1, 0, 1)
	var e2 = _make_cc(1, 0, 2)
	board.set_character_at(0, 0, 0, attacker)
	board.set_character_at(1, 0, 0, e0)
	board.set_character_at(1, 0, 1, e1)
	board.set_character_at(1, 0, 2, e2)

	var targets = CombatTargeting.get_valid_enemy_targets(attacker, board)
	assert_eq(targets.size(), 1, "single nearest target")
	assert_eq(targets[0], e0, "same column targeted")


func test_nearest_column_after_death():
	var board = CombatBoard.new()
	var attacker = _make_cc(0, 0, 0)
	var e0 = _make_cc(1, 0, 0)
	e0.is_alive = false
	e0.health = 0
	var e1 = _make_cc(1, 0, 1)
	var e2 = _make_cc(1, 0, 2)
	board.set_character_at(0, 0, 0, attacker)
	board.set_character_at(1, 0, 0, e0)
	board.set_character_at(1, 0, 1, e1)
	board.set_character_at(1, 0, 2, e2)

	var targets = CombatTargeting.get_valid_enemy_targets(attacker, board)
	assert_eq(targets.size(), 1, "nearest after death")
	assert_eq(targets[0], e1, "col 1 is nearest to col 0 after col 0 dies")


func test_equidistant_random_tiebreaker():
	var board = CombatBoard.new()
	var attacker = _make_cc(0, 0, 1)  # col 1
	var e0 = _make_cc(1, 0, 0)  # dist 1
	var e2 = _make_cc(1, 0, 2)  # dist 1
	board.set_character_at(0, 0, 1, attacker)
	board.set_character_at(1, 0, 0, e0)
	board.set_character_at(1, 0, 2, e2)

	var targets = CombatTargeting.get_valid_enemy_targets(attacker, board)
	assert_eq(targets.size(), 2, "both equidistant targets returned")
	assert_true(targets.has(e0), "e0 in pool")
	assert_true(targets.has(e2), "e2 in pool")


# Design doc examples
func test_example_1_g_targets_a():
	var d = _setup_design_doc_board()
	var targets = CombatTargeting.get_valid_enemy_targets(d["G"], d["board"])
	assert_eq(targets.size(), 1, "G: one target")
	assert_eq(targets[0], d["A"], "G targets A (col 0, distance 0)")


func test_example_2_g_targets_b_after_a_dies():
	var d = _setup_design_doc_board()
	d["A"].is_alive = false
	d["A"].health = 0
	var targets = CombatTargeting.get_valid_enemy_targets(d["G"], d["board"])
	assert_eq(targets.size(), 1, "G after A dies: one target")
	assert_eq(targets[0], d["B"], "G targets B (nearest to col 0)")


func test_example_3_h_targets_b():
	var d = _setup_design_doc_board()
	var targets = CombatTargeting.get_valid_enemy_targets(d["H"], d["board"])
	assert_eq(targets.size(), 1, "H: one target")
	assert_eq(targets[0], d["B"], "H targets B (col 1, distance 0)")


func test_example_4_h_targets_a_or_c_after_b_dies():
	var d = _setup_design_doc_board()
	d["B"].is_alive = false
	d["B"].health = 0
	var targets = CombatTargeting.get_valid_enemy_targets(d["H"], d["board"])
	assert_eq(targets.size(), 2, "H after B dies: two equidistant targets")
	assert_true(targets.has(d["A"]), "A in pool")
	assert_true(targets.has(d["C"]), "C in pool")


func test_example_5_j_buffs_g():
	var d = _setup_design_doc_board()
	var targets = CombatTargeting.get_valid_ally_targets(d["J"], d["board"], false)
	assert_eq(targets.size(), 1, "J ally targeting: one target")
	assert_eq(targets[0], d["G"], "J buffs G (front row, col 0, distance 0)")


func test_ally_targeting_excludes_self():
	var board = CombatBoard.new()
	var actor = _make_cc(0, 0, 0)
	board.set_character_at(0, 0, 0, actor)

	var targets = CombatTargeting.get_valid_ally_targets(actor, board, false)
	assert_eq(targets.size(), 0, "no allies when only self and exclude_self")


func test_ally_targeting_includes_self():
	var board = CombatBoard.new()
	var actor = _make_cc(0, 0, 0)
	board.set_character_at(0, 0, 0, actor)

	var targets = CombatTargeting.get_valid_ally_targets(actor, board, true)
	assert_eq(targets.size(), 1, "self included")
	assert_eq(targets[0], actor, "target is self")


func test_column_distance():
	assert_eq(CombatTargeting.get_column_distance(0, 0), 0, "same col = 0")
	assert_eq(CombatTargeting.get_column_distance(0, 2), 2, "col 0 to 2 = 2")
	assert_eq(CombatTargeting.get_column_distance(2, 0), 2, "col 2 to 0 = 2")
	assert_eq(CombatTargeting.get_column_distance(1, 2), 1, "col 1 to 2 = 1")
