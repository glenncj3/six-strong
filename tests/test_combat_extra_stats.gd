extends "res://tests/base_test.gd"

# Tests that extra_stats (burn_value, heal_value, etc.) are recalculated by effects


func _run_tests():
	test_name = "CombatExtraStats"

	_test_stat_modifier_changes_extra_stat()
	_test_removing_effect_reverts_extra_stat()
	_test_charges_not_affected_by_recalculate()


func _make_effect(stat_name: String, flat_val: float) -> CombatEffect:
	var e = CombatEffect.new()
	e.effect_type = "stat_modifier"
	e.stat = stat_name
	e.value = flat_val
	e.modifier_type = "flat"
	e.duration_type = "permanent"
	return e


func _test_stat_modifier_changes_extra_stat():
	section("stat_modifier effect targeting burn_value changes extra_stats")
	var cc = CombatCharacter.new()
	cc.base_extra_stats = {"burn_value": 5.0, "heal_value": 3.0}
	cc.extra_stats = {"burn_value": 5, "heal_value": 3, "charges": 2}
	cc.base_speed = 3.0
	cc.speed = 3.0
	cc.base_damage = 10.0
	cc.damage = 10.0
	cc.base_max_health = 100.0
	cc.max_health = 100.0
	cc.health = 100.0
	cc.charges = 2

	cc.effects.append(_make_effect("burn_value", 7.0))
	cc.recalculate_stats()

	assert_eq(cc.extra_stats["burn_value"], 12.0, "burn_value = base 5 + flat 7 = 12")
	assert_eq(cc.extra_stats["heal_value"], 3.0, "heal_value unchanged at 3")


func _test_removing_effect_reverts_extra_stat():
	section("Removing effect reverts extra_stat to base")
	var cc = CombatCharacter.new()
	cc.base_extra_stats = {"burn_value": 5.0}
	cc.extra_stats = {"burn_value": 5}
	cc.base_speed = 3.0
	cc.speed = 3.0
	cc.base_damage = 10.0
	cc.damage = 10.0
	cc.base_max_health = 100.0
	cc.max_health = 100.0
	cc.health = 100.0

	var eff = _make_effect("burn_value", 7.0)
	cc.effects.append(eff)
	cc.recalculate_stats()
	assert_eq(cc.extra_stats["burn_value"], 12.0, "burn_value buffed to 12")

	cc.effects.erase(eff)
	cc.recalculate_stats()
	assert_eq(cc.extra_stats["burn_value"], 5.0, "burn_value reverted to base 5")


func _test_charges_not_affected_by_recalculate():
	section("charges is NOT recalculated by recalculate_stats")
	var cc = CombatCharacter.new()
	cc.base_extra_stats = {"burn_value": 5.0}
	cc.extra_stats = {"burn_value": 5, "charges": 6}
	cc.base_speed = 3.0
	cc.speed = 3.0
	cc.base_damage = 10.0
	cc.damage = 10.0
	cc.base_max_health = 100.0
	cc.max_health = 100.0
	cc.health = 100.0
	cc.charges = 4  # Decremented imperatively from 6 to 4

	cc.recalculate_stats()

	assert_eq(cc.charges, 4, "charges stays at 4 (imperative, not recalculated)")
	assert_eq(cc.extra_stats["charges"], 6, "extra_stats charges untouched by recalc loop")
