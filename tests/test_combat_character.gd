extends "res://tests/base_test.gd"
# Tests for CombatCharacter creation and stat recalculation

func _init():
	test_name = "CombatCharacter Tests"
	super()


func _run_tests():
	section("Creation")
	test_create_from_character_instance()
	test_has_speed_and_damage()

	section("Stat Recalculation")
	test_flat_modifier()
	test_percent_modifier()
	test_additive_percent_stacking()
	test_flat_then_percent()
	test_no_effects_keeps_base()

	section("Max Health Changes")
	test_max_health_buff_increases_current()
	test_max_health_debuff_caps_current()
	test_max_health_debuff_no_cap_when_below()


# =============================================================================
# HELPERS
# =============================================================================

func _make_source(hp: int, spd: float, dmg: float, def_rate: float, crit: float) -> CharacterInstance:
	var ch = CharacterInstance.new()
	ch.base_character_id = "test_char"
	ch.stats = {
		GameConstants.STAT_HEALTH: hp,
		GameConstants.STAT_SPEED: spd,
		GameConstants.STAT_DAMAGE: dmg,
		GameConstants.STAT_DEFEND_RATE: def_rate,
		GameConstants.STAT_CRIT_CHANCE: crit,
		GameConstants.STAT_MANA: 0,
	}
	ch.current_health = hp
	return ch


# =============================================================================
# TESTS
# =============================================================================

func test_create_from_character_instance():
	var source = _make_source(100, 2.5, 15.0, 0.1, 0.05)
	var cc = CombatCharacter.create_from_character(source, 0, 1, 2)

	assert_eq(cc.max_health, 100.0, "max_health from source")
	assert_eq(cc.health, 100.0, "health from source current_health")
	assert_eq(cc.base_speed, 2.5, "base_speed from source")
	assert_eq(cc.base_damage, 15.0, "base_damage from source")
	assert_eq(cc.base_crit_chance, 0.05, "base_crit_chance from source")
	assert_eq(cc.base_defend_rate, 0.1, "base_defend_rate from source")
	assert_eq(cc.team, 0, "team set")
	assert_eq(cc.row, 1, "row set")
	assert_eq(cc.column, 2, "column set")
	assert_true(cc.is_alive, "starts alive")
	assert_eq(cc.cooldown_remaining, 2.5, "cooldown starts at speed")


func test_has_speed_and_damage():
	var source = _make_source(100, 0.0, 0.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)
	assert_false(cc.has_speed(), "no speed when 0")
	assert_false(cc.has_damage(), "no damage when 0")

	var source2 = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc2 = CombatCharacter.create_from_character(source2, 0, 0, 0)
	assert_true(cc2.has_speed(), "has speed when > 0")
	assert_true(cc2.has_damage(), "has damage when > 0")


func test_flat_modifier():
	var source = _make_source(100, 2.0, 10.0, 0.1, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "combat")
	cc.effects.append(effect)
	cc.recalculate_stats()

	assert_eq(cc.damage, 15.0, "flat +5 damage: 10 + 5 = 15")


func test_percent_modifier():
	var source = _make_source(100, 2.0, 10.0, 0.1, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 0.5, "percent", "combat")
	cc.effects.append(effect)
	cc.recalculate_stats()

	assert_eq(cc.damage, 15.0, "50% damage: 10 * 1.5 = 15")


func test_additive_percent_stacking():
	# Per design doc: two +10% = +20%, not multiplicative
	var source = _make_source(100, 2.0, 100.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var e1 = CombatEffect.create_stat_modifier("test", "t1", "damage", 0.1, "percent", "combat")
	var e2 = CombatEffect.create_stat_modifier("test", "t2", "damage", 0.1, "percent", "combat")
	cc.effects.append(e1)
	cc.effects.append(e2)
	cc.recalculate_stats()

	assert_eq(cc.damage, 120.0, "additive stacking: 100 * (1 + 0.1 + 0.1) = 120")


func test_flat_then_percent():
	# Per design doc: base 100 + 100 flat + 10% = (100+100) * 1.1 = 220
	var source = _make_source(100, 2.0, 100.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var e_flat = CombatEffect.create_stat_modifier("test", "t1", "damage", 100.0, "flat", "combat")
	var e_pct = CombatEffect.create_stat_modifier("test", "t2", "damage", 0.1, "percent", "combat")
	cc.effects.append(e_flat)
	cc.effects.append(e_pct)
	cc.recalculate_stats()

	assert_true(abs(cc.damage - 220.0) < 0.01, "flat+percent: (100+100) * 1.1 = 220")


func test_no_effects_keeps_base():
	var source = _make_source(100, 3.0, 20.0, 0.15, 0.1)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)
	cc.recalculate_stats()

	assert_eq(cc.damage, 20.0, "no effects: damage unchanged")
	assert_eq(cc.speed, 3.0, "no effects: speed unchanged")
	assert_eq(cc.defend_rate, 0.15, "no effects: defend_rate unchanged")
	assert_eq(cc.crit_chance, 0.1, "no effects: crit_chance unchanged")


func test_max_health_buff_increases_current():
	# Buff: +50 max health should also increase current health by 50
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)
	assert_eq(cc.health, 100.0, "starts at 100 hp")

	var effect = CombatEffect.create_stat_modifier("test", "t1", "health", 50.0, "flat", "combat")
	cc.effects.append(effect)
	cc.recalculate_stats()

	assert_eq(cc.max_health, 150.0, "max_health increased to 150")
	assert_eq(cc.health, 150.0, "current health increased by same amount")


func test_max_health_debuff_caps_current():
	# Debuff: -50 max health should cap current at new max
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)
	assert_eq(cc.health, 100.0, "starts at 100 hp")

	var effect = CombatEffect.create_stat_modifier("test", "t1", "health", -50.0, "flat", "combat")
	cc.effects.append(effect)
	cc.recalculate_stats()

	assert_eq(cc.max_health, 50.0, "max_health reduced to 50")
	assert_eq(cc.health, 50.0, "current health capped at new max")


func test_max_health_debuff_no_cap_when_below():
	# Debuff when current health already below new max: no change to current
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)
	cc.health = 30.0  # Damaged to 30

	var effect = CombatEffect.create_stat_modifier("test", "t1", "health", -50.0, "flat", "combat")
	cc.effects.append(effect)
	cc.recalculate_stats()

	assert_eq(cc.max_health, 50.0, "max_health reduced to 50")
	assert_eq(cc.health, 30.0, "current health unchanged (already below new max)")
