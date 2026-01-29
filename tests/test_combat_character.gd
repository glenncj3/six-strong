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

	section("Update Timing")
	test_update_decrements_cooldown()
	test_update_returns_action_ready()
	test_update_expires_seconds_effect()
	test_update_expires_cooldown_effect()
	test_update_tick_rate_multiplier()
	test_update_dead_character_noop()

	section("Effect Queries")
	test_has_effect_by_id()
	test_get_effects_by_tag()
	test_get_stacks()
	test_cleanse_by_tag()
	test_tick_rate_from_continuous_modifier()
	test_update_tick_events()


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
		GameConstants.STAT_agility: def_rate,
		GameConstants.STAT_CRIT_CHANCE: crit,
		GameConstants.STAT_CHARGES: -1,
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
	assert_eq(cc.base_agility, 0.1, "base_agility from source")
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
	assert_eq(cc.agility, 0.15, "no effects: agility unchanged")
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


# =============================================================================
# UPDATE TIMING TESTS
# =============================================================================

func test_update_decrements_cooldown():
	var source = _make_source(100, 3.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)
	assert_eq(cc.cooldown_remaining, 3.0, "starts at speed")

	cc.update(1.0)
	assert_true(abs(cc.cooldown_remaining - 2.0) < 0.01, "cooldown decremented by delta")


func test_update_returns_action_ready():
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var result = cc.update(1.0)
	assert_false(result["action_ready"], "not ready after 1s with 2s cooldown")

	result = cc.update(1.5)
	assert_true(result["action_ready"], "ready after cooldown expires")


func test_update_expires_seconds_effect():
	var source = _make_source(100, 5.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "seconds", 1.0)
	cc.effects.append(effect)

	var result = cc.update(1.5)
	assert_true(result["expired_effects"].has(effect), "seconds effect expired")


func test_update_expires_cooldown_effect():
	var source = _make_source(100, 1.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "cooldowns", 1.0)
	cc.effects.append(effect)

	var result = cc.update(1.5)  # Triggers cooldown
	assert_true(result["action_ready"], "action triggered")
	assert_true(result["expired_effects"].has(effect), "cooldown effect expired after 1 cooldown")


func test_update_tick_rate_multiplier():
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)
	cc.tick_rate_multiplier = 2.0

	# With 2x tick rate, 1s of real time = 2s of effective time
	var result = cc.update(1.0)
	assert_true(result["action_ready"], "action ready with 2x tick rate after 1s (effective 2s)")


func test_update_dead_character_noop():
	# Dead characters still update (manager checks is_alive before executing actions)
	# but a character with no speed returns immediately
	var source = _make_source(100, 0.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)
	cc.is_alive = false

	var result = cc.update(5.0)
	assert_false(result["action_ready"], "no-speed character never ready")
	assert_eq(result["expired_effects"].size(), 0, "no expired effects on no-speed character")


# =============================================================================
# EFFECT QUERY TESTS
# =============================================================================

func test_has_effect_by_id():
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	assert_false(cc.has_effect("poison"), "no poison initially")

	var effect = CombatEffect.create_status_effect({"effect_id": "poison", "stacks": 3})
	cc.effects.append(effect)
	assert_true(cc.has_effect("poison"), "has poison after adding")
	assert_false(cc.has_effect("haste"), "does not have haste")


func test_get_effects_by_tag():
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var poison = CombatEffect.create_status_effect({"effect_id": "poison", "tags": ["debuff", "dot"]})
	var haste = CombatEffect.create_status_effect({"effect_id": "haste", "tags": ["buff", "speed"]})
	cc.effects.append(poison)
	cc.effects.append(haste)

	var debuffs = cc.get_effects_by_tag("debuff")
	assert_eq(debuffs.size(), 1, "one debuff")
	assert_eq(debuffs[0].effect_id, "poison", "poison is the debuff")

	var buffs = cc.get_effects_by_tag("buff")
	assert_eq(buffs.size(), 1, "one buff")
	assert_eq(buffs[0].effect_id, "haste", "haste is the buff")


func test_get_stacks():
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	assert_eq(cc.get_stacks("poison"), 0, "no stacks when no effect")

	var effect = CombatEffect.create_status_effect({"effect_id": "poison", "stacks": 5})
	cc.effects.append(effect)
	assert_eq(cc.get_stacks("poison"), 5, "5 stacks of poison")


func test_cleanse_by_tag():
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var poison = CombatEffect.create_status_effect({"effect_id": "poison", "tags": ["debuff", "dot"]})
	var haste = CombatEffect.create_status_effect({"effect_id": "haste", "tags": ["buff", "speed"]})
	cc.effects.append(poison)
	cc.effects.append(haste)

	var removed = cc.cleanse_by_tag("debuff")
	assert_eq(removed.size(), 1, "removed 1 debuff")
	assert_eq(cc.effects.size(), 1, "1 effect remaining")
	assert_true(cc.has_effect("haste"), "haste still present")
	assert_false(cc.has_effect("poison"), "poison removed")


func test_tick_rate_from_continuous_modifier():
	var source = _make_source(100, 2.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var haste = CombatEffect.create_status_effect({
		"effect_id": "haste",
		"continuous_modifier": "cooldown_tick_rate",
		"continuous_value": 2.0,
	})
	cc.effects.append(haste)
	cc.recalculate_stats()

	assert_true(abs(cc.tick_rate_multiplier - 2.0) < 0.01, "tick_rate_multiplier is 2.0 with haste")


func test_update_tick_events():
	var source = _make_source(100, 5.0, 10.0, 0.0, 0.0)
	var cc = CombatCharacter.create_from_character(source, 0, 0, 0)

	var tick_fn = func(_ctx): pass
	var effect = CombatEffect.create_status_effect({
		"effect_id": "poison",
		"tick_interval": 1.0,
		"on_tick": tick_fn,
	})
	cc.effects.append(effect)

	var result = cc.update(0.5)
	assert_eq(result["tick_events"].size(), 0, "no tick at 0.5s")

	result = cc.update(0.6)
	assert_eq(result["tick_events"].size(), 1, "tick fires at 1.1s total")
	assert_eq(result["tick_events"][0], effect, "correct effect ticked")
