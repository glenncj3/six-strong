extends "res://tests/base_test.gd"
# Tests for EffectManager - effect lifecycle management

func _init():
	test_name = "EffectManager Tests"
	super()


func _run_tests():
	section("Apply Effects")
	test_apply_new_effect()
	test_apply_stat_modifier_recalculates()
	test_merge_add_stacks()
	test_merge_refresh_duration()
	test_merge_extend_duration()
	test_merge_max_stacks_cap()

	section("Remove Effects")
	test_remove_effect()
	test_remove_stat_modifier_recalculates()

	section("Source Removal")
	test_remove_effects_from_source()
	test_remove_effects_from_source_multiple_characters()

	section("Cleanse")
	test_cleanse_by_tag()
	test_cleanse_recalculates_for_stat_modifiers()
	test_cleanse_preserves_non_matching()

	section("Triggered Effects")
	test_process_triggered_effects()
	test_process_triggered_effects_ignores_wrong_trigger()


# =============================================================================
# HELPERS
# =============================================================================

func _make_cc() -> CombatCharacter:
	var cc = CombatCharacter.new()
	cc.id = "cc_test"
	cc.health = 100.0
	cc.max_health = 100.0
	cc.base_speed = 2.0
	cc.speed = 2.0
	cc.base_damage = 10.0
	cc.damage = 10.0
	cc.is_alive = true
	return cc


# =============================================================================
# TESTS
# =============================================================================

func test_apply_new_effect():
	var em = EffectManager.new()
	var cc = _make_cc()
	var effect = CombatEffect.create_status_effect({"effect_id": "poison", "stacks": 3})
	var result = em.apply_effect(cc, effect)

	assert_eq(cc.effects.size(), 1, "effect added")
	assert_false(result.merged, "not merged")
	assert_eq(result.trigger_id, "poison", "trigger_id set")


func test_apply_stat_modifier_recalculates():
	var em = EffectManager.new()
	var cc = _make_cc()
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "combat")
	em.apply_effect(cc, effect)

	assert_eq(cc.damage, 15.0, "stat recalculated: 10 + 5 = 15")


func test_merge_add_stacks():
	var em = EffectManager.new()
	var cc = _make_cc()
	var e1 = CombatEffect.create_status_effect({
		"effect_id": "poison", "stacks": 3, "max_stacks": 10,
		"merge_behavior": "add_stacks",
	})
	var e2 = CombatEffect.create_status_effect({
		"effect_id": "poison", "stacks": 4, "max_stacks": 10,
		"merge_behavior": "add_stacks",
	})
	em.apply_effect(cc, e1)
	var result = em.apply_effect(cc, e2)

	assert_eq(cc.effects.size(), 1, "only 1 effect (merged)")
	assert_eq(cc.get_stacks("poison"), 7, "stacks merged: 3 + 4 = 7")
	assert_true(result.merged, "second apply was a merge")


func test_merge_refresh_duration():
	var em = EffectManager.new()
	var cc = _make_cc()
	var e1 = CombatEffect.create_status_effect({
		"effect_id": "haste", "merge_behavior": "refresh_duration",
		"duration_type": "seconds", "duration_value": 5.0,
	})
	em.apply_effect(cc, e1)
	cc.get_effect("haste").duration_value = 2.0  # Simulate time passing

	var e2 = CombatEffect.create_status_effect({
		"effect_id": "haste", "merge_behavior": "refresh_duration",
		"duration_type": "seconds", "duration_value": 5.0,
	})
	em.apply_effect(cc, e2)

	assert_eq(cc.effects.size(), 1, "still 1 effect")
	assert_true(abs(cc.get_effect("haste").duration_value - 5.0) < 0.01, "duration refreshed")


func test_merge_extend_duration():
	var em = EffectManager.new()
	var cc = _make_cc()
	var e1 = CombatEffect.create_status_effect({
		"effect_id": "shield", "merge_behavior": "extend_duration",
		"duration_type": "seconds", "duration_value": 5.0,
	})
	em.apply_effect(cc, e1)
	var e2 = CombatEffect.create_status_effect({
		"effect_id": "shield", "merge_behavior": "extend_duration",
		"duration_type": "seconds", "duration_value": 3.0,
	})
	em.apply_effect(cc, e2)

	assert_eq(cc.effects.size(), 1, "still 1 effect")
	assert_true(abs(cc.get_effect("shield").duration_value - 8.0) < 0.01, "duration extended: 5 + 3 = 8")


func test_merge_max_stacks_cap():
	var em = EffectManager.new()
	var cc = _make_cc()
	var e1 = CombatEffect.create_status_effect({
		"effect_id": "poison", "stacks": 8, "max_stacks": 10,
		"merge_behavior": "add_stacks",
	})
	var e2 = CombatEffect.create_status_effect({
		"effect_id": "poison", "stacks": 5, "max_stacks": 10,
		"merge_behavior": "add_stacks",
	})
	em.apply_effect(cc, e1)
	em.apply_effect(cc, e2)

	assert_eq(cc.get_stacks("poison"), 10, "stacks capped at max_stacks")


func test_remove_effect():
	var em = EffectManager.new()
	var cc = _make_cc()
	var effect = CombatEffect.create_status_effect({"effect_id": "poison", "stacks": 3})
	cc.effects.append(effect)

	em.remove_effect(cc, effect)
	assert_eq(cc.effects.size(), 0, "effect removed")


func test_remove_stat_modifier_recalculates():
	var em = EffectManager.new()
	var cc = _make_cc()
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "combat")
	em.apply_effect(cc, effect)
	assert_eq(cc.damage, 15.0, "buff active")

	var recalced = em.remove_effect(cc, effect)
	assert_true(recalced, "recalculation happened")
	assert_eq(cc.damage, 10.0, "stat reverted")


func test_remove_effects_from_source():
	var em = EffectManager.new()
	var cc = _make_cc()
	var e1 = CombatEffect.create_stat_modifier("character", "src1", "damage", 5.0, "flat", "permanent")
	var e2 = CombatEffect.create_stat_modifier("character", "src2", "speed", 1.0, "flat", "permanent")
	em.apply_effect(cc, e1)
	em.apply_effect(cc, e2)
	assert_eq(cc.effects.size(), 2, "2 effects before removal")

	var removed = em.remove_effects_from_source("src1", [cc])
	assert_eq(removed.size(), 1, "1 effect removed")
	assert_eq(cc.effects.size(), 1, "1 effect remaining")
	assert_eq(cc.damage, 10.0, "damage reverted")


func test_remove_effects_from_source_multiple_characters():
	var em = EffectManager.new()
	var cc1 = _make_cc()
	cc1.id = "cc1"
	var cc2 = _make_cc()
	cc2.id = "cc2"

	var e1 = CombatEffect.create_stat_modifier("character", "src1", "damage", 5.0, "flat", "permanent")
	var e2 = CombatEffect.create_stat_modifier("character", "src1", "damage", 3.0, "flat", "permanent")
	em.apply_effect(cc1, e1)
	em.apply_effect(cc2, e2)

	var removed = em.remove_effects_from_source("src1", [cc1, cc2])
	assert_eq(removed.size(), 2, "2 effects removed across 2 characters")
	assert_eq(cc1.effects.size(), 0, "cc1 clean")
	assert_eq(cc2.effects.size(), 0, "cc2 clean")


func test_cleanse_by_tag():
	var em = EffectManager.new()
	var cc = _make_cc()
	var poison = CombatEffect.create_status_effect({"effect_id": "poison", "tags": ["debuff"]})
	var haste = CombatEffect.create_status_effect({"effect_id": "haste", "tags": ["buff"]})
	cc.effects.append(poison)
	cc.effects.append(haste)

	var removed = em.cleanse_effects_by_tag(cc, "debuff")
	assert_eq(removed.size(), 1, "1 debuff removed")
	assert_eq(cc.effects.size(), 1, "1 effect remaining")
	assert_true(cc.has_effect("haste"), "haste preserved")


func test_cleanse_recalculates_for_stat_modifiers():
	var em = EffectManager.new()
	var cc = _make_cc()
	var debuff = CombatEffect.create_stat_modifier("test", "t1", "damage", -5.0, "flat", "combat")
	debuff.tags = ["debuff"]
	em.apply_effect(cc, debuff)
	assert_eq(cc.damage, 5.0, "debuff active")

	em.cleanse_effects_by_tag(cc, "debuff")
	assert_eq(cc.damage, 10.0, "stat recalculated after cleanse")


func test_cleanse_preserves_non_matching():
	var em = EffectManager.new()
	var cc = _make_cc()
	var poison = CombatEffect.create_status_effect({"effect_id": "poison", "tags": ["debuff"]})
	var burn = CombatEffect.create_status_effect({"effect_id": "burn", "tags": ["debuff"]})
	var haste = CombatEffect.create_status_effect({"effect_id": "haste", "tags": ["buff"]})
	cc.effects.append(poison)
	cc.effects.append(burn)
	cc.effects.append(haste)

	em.cleanse_effects_by_tag(cc, "debuff")
	assert_eq(cc.effects.size(), 1, "only buff remains")
	assert_true(cc.has_effect("haste"), "haste preserved")


func test_process_triggered_effects():
	var em = EffectManager.new()
	var cc = _make_cc()
	var count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_cooldown",
		func(_data): count[0] += 1, "combat")
	cc.effects.append(effect)

	em.process_triggered_effects(cc, "on_cooldown", {})
	assert_eq(count[0], 1, "triggered effect fired")


func test_process_triggered_effects_ignores_wrong_trigger():
	var em = EffectManager.new()
	var cc = _make_cc()
	var count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_cooldown",
		func(_data): count[0] += 1, "combat")
	cc.effects.append(effect)

	em.process_triggered_effects(cc, "on_death", {})
	assert_eq(count[0], 0, "wrong trigger ignored")
