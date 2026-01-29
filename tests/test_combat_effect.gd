extends "res://tests/base_test.gd"
# Tests for CombatEffect creation and backward compatibility

func _init():
	test_name = "CombatEffect Tests"
	super()


func _run_tests():
	section("Status Effect Factory")
	test_create_status_effect_fields()

	section("Backward Compatibility")
	test_backward_compat_stat_modifier()
	test_backward_compat_triggered()


func test_create_status_effect_fields():
	var tick_fn = func(_ctx): pass
	var effect = CombatEffect.create_status_effect({
		"source_type": "ability",
		"source_id": "src1",
		"effect_id": "poison",
		"stacks": 3,
		"max_stacks": 99,
		"tick_interval": 1.0,
		"on_tick": tick_fn,
		"merge_behavior": "add_stacks",
		"tags": ["debuff", "dot"],
		"duration_type": "permanent",
	})

	assert_eq(effect.effect_id, "poison", "effect_id set")
	assert_eq(effect.stacks, 3, "stacks set")
	assert_eq(effect.max_stacks, 99, "max_stacks set")
	assert_true(abs(effect.tick_interval - 1.0) < 0.01, "tick_interval set")
	assert_true(effect.on_tick.is_valid(), "on_tick callable set")
	assert_eq(effect.merge_behavior, "add_stacks", "merge_behavior set")
	assert_eq(effect.tags.size(), 2, "tags set")
	assert_true(effect.tags.has("debuff"), "has debuff tag")
	assert_true(effect.tags.has("dot"), "has dot tag")
	assert_eq(effect.duration_type, "permanent", "duration_type set")
	assert_eq(effect.source_type, "ability", "source_type set")
	assert_eq(effect.source_id, "src1", "source_id set")


func test_backward_compat_stat_modifier():
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "combat")
	# New fields should be at default/inert values
	assert_eq(effect.effect_id, "", "effect_id empty")
	assert_eq(effect.stacks, 0, "stacks 0")
	assert_eq(effect.max_stacks, 0, "max_stacks 0")
	assert_true(abs(effect.tick_interval) < 0.01, "tick_interval 0")
	assert_eq(effect.merge_behavior, "none", "merge_behavior none")
	assert_eq(effect.tags.size(), 0, "no tags")
	assert_eq(effect.continuous_modifier, "", "no continuous_modifier")
	# Original fields still work
	assert_eq(effect.effect_type, "stat_modifier", "effect_type correct")
	assert_eq(effect.stat, "damage", "stat correct")
	assert_eq(effect.value, 5.0, "value correct")


func test_backward_compat_triggered():
	var action_fn = func(_data): pass
	var effect = CombatEffect.create_triggered("test", "t1", "on_cooldown", action_fn, "combat")
	assert_eq(effect.effect_id, "", "effect_id empty")
	assert_eq(effect.stacks, 0, "stacks 0")
	assert_eq(effect.tags.size(), 0, "no tags")
	assert_eq(effect.effect_type, "triggered", "effect_type correct")
	assert_eq(effect.trigger, "on_cooldown", "trigger correct")
	assert_true(effect.action.is_valid(), "action valid")
