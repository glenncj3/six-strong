extends "res://tests/base_test.gd"
# Tests for DamageResolver - static damage resolution utility

func _init():
	test_name = "DamageResolver Tests"
	super()


func _run_tests():
	section("Basic Resolution")
	test_no_block_no_crit()
	test_dodge_with_100_percent_agility()
	test_crit_with_100_percent_crit()
	test_no_block_zero_defend()
	test_no_crit_zero_crit()
	test_crit_prevents_dodge()

	section("Return Structure")
	test_result_has_required_keys()


# =============================================================================
# HELPERS
# =============================================================================

func _make_combat_char(dmg: float, crit: float, defend: float) -> CombatCharacter:
	var cc = CombatCharacter.new()
	cc.id = "test_%d" % randi()
	cc.base_damage = dmg
	cc.damage = dmg
	cc.base_crit_chance = crit
	cc.crit_chance = crit
	cc.base_agility = defend
	cc.agility = defend
	cc.health = 100.0
	cc.max_health = 100.0
	cc.is_alive = true
	return cc


# =============================================================================
# TESTS
# =============================================================================

func test_no_block_no_crit():
	var source = _make_combat_char(10.0, 0.0, 0.0)
	var target = _make_combat_char(0.0, 0.0, 0.0)
	var result = DamageResolver.resolve(source, target, 25.0)
	assert_false(result.blocked, "not blocked with 0 defend")
	assert_eq(result.damage, 25.0, "damage equals base")
	assert_false(result.is_crit, "not a crit with 0 crit chance")


func test_dodge_with_100_percent_agility():
	var source = _make_combat_char(10.0, 0.0, 0.0)
	var target = _make_combat_char(0.0, 0.0, 1.0)
	var result = DamageResolver.resolve(source, target, 25.0)
	assert_true(result.blocked, "dodged with 100% agility")
	var expected = 25.0 * (1.0 - GameConstants.DODGE_DAMAGE_REDUCTION)
	assert_eq(result.damage, expected, "dodge reduces damage by 90%")


func test_crit_with_100_percent_crit():
	var source = _make_combat_char(10.0, 1.0, 0.0)
	var target = _make_combat_char(0.0, 0.0, 0.0)
	var result = DamageResolver.resolve(source, target, 25.0)
	assert_false(result.blocked, "not blocked")
	assert_eq(result.damage, 25.0 * GameConstants.CRIT_MULTIPLIER, "crit multiplier applied")
	assert_true(result.is_crit, "is a crit")


func test_no_block_zero_defend():
	var source = _make_combat_char(10.0, 0.0, 0.0)
	var target = _make_combat_char(0.0, 0.0, 0.0)
	# Run multiple times to confirm no random blocks
	var blocked_count = 0
	for i in range(20):
		var result = DamageResolver.resolve(source, target, 10.0)
		if result.blocked:
			blocked_count += 1
	assert_eq(blocked_count, 0, "never blocks with 0 defend rate")


func test_no_crit_zero_crit():
	var source = _make_combat_char(10.0, 0.0, 0.0)
	var target = _make_combat_char(0.0, 0.0, 0.0)
	var crit_count = 0
	for i in range(20):
		var result = DamageResolver.resolve(source, target, 10.0)
		if result.is_crit:
			crit_count += 1
	assert_eq(crit_count, 0, "never crits with 0 crit chance")


func test_crit_prevents_dodge():
	# Both 100% crit and 100% agility — crit should win, no dodge
	var source = _make_combat_char(10.0, 1.0, 0.0)
	var target = _make_combat_char(0.0, 0.0, 1.0)
	var result = DamageResolver.resolve(source, target, 25.0)
	assert_false(result.blocked, "crit prevents dodge")
	assert_true(result.is_crit, "is a crit")
	assert_eq(result.damage, 25.0 * GameConstants.CRIT_MULTIPLIER, "full crit damage, no dodge reduction")


func test_result_has_required_keys():
	var source = _make_combat_char(10.0, 0.0, 0.0)
	var target = _make_combat_char(0.0, 0.0, 0.0)
	var result = DamageResolver.resolve(source, target, 10.0)
	assert_has(result, "blocked", "result has blocked key")
	assert_has(result, "damage", "result has damage key")
	assert_has(result, "is_crit", "result has is_crit key")
