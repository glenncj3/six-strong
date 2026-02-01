extends "res://tests/base_test.gd"
# Tests for data-driven status effects: poison, haste, abilities

func _init():
	test_name = "Status Effects Tests"
	super()


func _run_tests():
	TickActionRegistry.register_defaults()

	section("Poison Template")
	test_poison_creation_from_template()
	test_poison_merge_adds_stacks()
	test_poison_merge_from_multiple_sources()
	test_poison_tick_deals_damage()
	test_poison_tick_decrements_stacks()
	test_poison_removed_at_zero_stacks()
	test_poison_multi_tick_decay()

	section("Haste Template")
	test_haste_creation_from_template()
	test_haste_doubles_tick_rate()
	test_haste_expires_restores_tick_rate()
	test_haste_multiple_applications_additive()

	section("Slow Template")
	test_slow_creation_from_template()
	test_slow_halves_tick_rate()
	test_slow_expires_restores_tick_rate()
	test_slow_multiple_applications_additive()

	section("Freeze Template")
	test_freeze_creation_from_template()
	test_freeze_stops_tick_rate()
	test_freeze_expires_restores_tick_rate()
	test_freeze_multiple_applications_additive()
	test_freeze_resumes_cooldown_where_left_off()

	section("Burn Template")
	test_burn_creation_from_template()
	test_burn_deals_damage_on_apply()
	test_burn_stacks_accumulate_and_damage_increases()
	test_burn_stacks_persist()
	test_burn_merge_from_multiple_sources()

	section("Ability Integration")
	test_burn_enemy_ability_integration()
	test_burn_enemy_row_ability_integration()
	test_burn_enemies_ability_integration()
	test_poison_enemy_ability_integration()
	test_haste_self_ability_integration()
	test_haste_ally_ability_integration()
	test_slow_enemy_ability_integration()
	test_slow_enemy_row_ability_integration()
	test_slow_enemies_ability_integration()
	test_freeze_enemy_ability_integration()
	test_freeze_enemy_row_ability_integration()
	test_freeze_enemies_ability_integration()
	test_haste_ally_row_ability_integration()
	test_haste_allies_ability_integration()
	test_heal_self_ability_integration()
	test_poison_enemy_row_ability_integration()
	test_poison_enemies_ability_integration()
	test_shield_ally_row_ability_integration()
	test_shield_allies_ability_integration()
	test_attack_enemy_ability_integration()
	test_attack_enemy_row_ability_integration()
	test_heal_ally_ability_integration()
	test_heal_allies_ability_integration()
	test_multi_ability_character()
	test_solo_ally_single_no_target()

	section("Shield Template")
	test_shield_creation_from_template()
	test_shield_absorbs_attack_damage()
	test_shield_partial_absorb()
	test_shield_removed_at_zero()
	test_shield_does_not_absorb_poison()
	test_shield_stacks_merge()
	test_shield_merge_from_multiple_sources()
	test_shield_self_ability_integration()
	test_shield_ally_ability_integration()

	section("Interactions")
	test_cleanse_removes_poison_not_haste()
	test_on_poisoned_trigger_fires()


# =============================================================================
# HELPERS
# =============================================================================

func _make_source(hp: int, spd: float, dmg: float, def_rate: float = 0.0, crit: float = 0.0, extras: Dictionary = {}) -> CharacterInstance:
	var ch = CharacterInstance.new()
	ch.base_character_id = "test"
	ch.stats = {
		"health": hp,
		"speed": spd,
		"damage": dmg,
		"agility": def_rate,
		"crit_chance": crit,
		"charges": -1,
	}
	for key in extras:
		ch.stats[key] = extras[key]
	ch.current_health = hp
	return ch


func _make_grid_with_one(ch: CharacterInstance) -> CharacterGrid:
	var grid = CharacterGrid.new()
	grid.place_character(ch, 0, 0)
	return grid


func _simulate_time(manager: CombatManager, seconds: float, step: float = 0.1) -> void:
	var remaining = seconds
	while remaining > 0:
		var dt = min(step, remaining)
		manager._update_combat(dt)
		remaining -= dt
		if manager.get_state() and not manager.get_state().combat_active:
			break


func _get_poison_template() -> Dictionary:
	var gd_node = root.get_node_or_null("GameData")
	if gd_node:
		return gd_node.get_status_effect("poison")
	return {}


func _get_haste_template() -> Dictionary:
	var gd_node = root.get_node_or_null("GameData")
	if gd_node:
		return gd_node.get_status_effect("haste")
	return {}


func _get_slow_template() -> Dictionary:
	var gd_node = root.get_node_or_null("GameData")
	if gd_node:
		return gd_node.get_status_effect("slow")
	return {}


func _get_freeze_template() -> Dictionary:
	var gd_node = root.get_node_or_null("GameData")
	if gd_node:
		return gd_node.get_status_effect("freeze")
	return {}


func _get_burn_template() -> Dictionary:
	var gd_node = root.get_node_or_null("GameData")
	if gd_node:
		return gd_node.get_status_effect("burn")
	return {}


# =============================================================================
# POISON TESTS
# =============================================================================

func test_poison_creation_from_template():
	var template = _get_poison_template()
	assert_false(template.is_empty(), "poison template loaded from GameData")

	var effect = StatusEffectFactory.create_from_template(template, "src1", {"stacks": 5})
	assert_eq(effect.effect_id, "poison", "effect_id is poison")
	assert_eq(effect.stacks, 5, "stacks from override")
	assert_eq(effect.max_stacks, 99, "max_stacks from template")
	assert_true(abs(effect.tick_interval - 1.0) < 0.01, "tick_interval 1.0")
	assert_eq(effect.merge_behavior, "add_stacks", "merge_behavior")
	assert_true(effect.tags.has("debuff"), "has debuff tag")
	assert_true(effect.tags.has("dot"), "has dot tag")
	assert_true(effect.on_tick.is_valid(), "on_tick wired from registry")


func test_poison_merge_adds_stacks():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_poison_template()

	var e1 = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 3})
	var e2 = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 4})
	manager.apply_effect(target, e1)
	manager.apply_effect(target, e2)

	assert_eq(target.effects.size(), 1, "merged into 1 effect")
	assert_eq(target.get_stacks("poison"), 7, "stacks merged: 3 + 4 = 7")


func test_poison_merge_from_multiple_sources():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_poison_template()

	# Two different sources apply poison
	var e1 = StatusEffectFactory.create_from_template(template, "source_A", {"stacks": 3})
	var e2 = StatusEffectFactory.create_from_template(template, "source_B", {"stacks": 5})
	manager.apply_effect(target, e1)
	manager.apply_effect(target, e2)

	assert_eq(target.effects.filter(func(e): return e.effect_id == "poison").size(), 1, "merged into single poison effect")
	assert_eq(target.get_stacks("poison"), 8, "stacks additive across sources: 3 + 5 = 8")

	# Verify the merged poison ticks correctly: 8 damage on first tick
	_simulate_time(manager, 1.5)
	assert_true(abs(target.health - 992.0) < 0.01, "8 damage from 8 stacks on first tick")
	assert_eq(target.get_stacks("poison"), 7, "stacks decremented to 7 after tick")


func test_poison_tick_deals_damage():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 0.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_poison_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 5})
	manager.apply_effect(target, effect)

	_simulate_time(manager, 1.5)
	# After 1 tick: 5 damage dealt, stacks reduced to 4
	assert_true(target.health < 1000.0, "poison dealt damage")
	assert_true(abs(target.health - 995.0) < 0.01, "5 damage from 5 stacks")


func test_poison_tick_decrements_stacks():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 0.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_poison_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 3})
	manager.apply_effect(target, effect)

	_simulate_time(manager, 1.5)
	assert_eq(target.get_stacks("poison"), 2, "stacks decremented from 3 to 2 after 1 tick")


func test_poison_removed_at_zero_stacks():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 0.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_poison_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 1})
	manager.apply_effect(target, effect)

	_simulate_time(manager, 1.5)
	assert_false(target.has_effect("poison"), "poison removed at 0 stacks")


func test_poison_multi_tick_decay():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_poison_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 4})
	manager.apply_effect(target, effect)

	# Tick 1 (t=1): 4 damage, stacks -> 3, total damage = 4
	_simulate_time(manager, 1.5)
	assert_true(abs(target.health - 996.0) < 0.01, "after tick 1: 4 damage dealt")
	assert_eq(target.get_stacks("poison"), 3, "after tick 1: 3 stacks remain")

	# Tick 2 (t=2): 3 damage, stacks -> 2, total damage = 7
	_simulate_time(manager, 1.0)
	assert_true(abs(target.health - 993.0) < 0.01, "after tick 2: 7 total damage")
	assert_eq(target.get_stacks("poison"), 2, "after tick 2: 2 stacks remain")

	# Tick 3 (t=3): 2 damage, stacks -> 1, total damage = 9
	_simulate_time(manager, 1.0)
	assert_true(abs(target.health - 991.0) < 0.01, "after tick 3: 9 total damage")
	assert_eq(target.get_stacks("poison"), 1, "after tick 3: 1 stack remains")

	# Tick 4 (t=4): 1 damage, stacks -> 0, total damage = 10, poison removed
	_simulate_time(manager, 1.0)
	assert_true(abs(target.health - 990.0) < 0.01, "after tick 4: 10 total damage (4+3+2+1)")
	assert_false(target.has_effect("poison"), "poison removed after all stacks consumed")


# =============================================================================
# HASTE TESTS
# =============================================================================

func test_haste_creation_from_template():
	var template = _get_haste_template()
	assert_false(template.is_empty(), "haste template loaded from GameData")

	var effect = StatusEffectFactory.create_from_template(template, "src1", {"duration_value": 5.0})
	assert_eq(effect.effect_id, "haste", "effect_id is haste")
	assert_eq(effect.continuous_modifier, "cooldown_tick_rate", "continuous_modifier set")
	assert_true(abs(effect.continuous_value - 2.0) < 0.01, "continuous_value 2.0")
	assert_eq(effect.duration_type, "seconds", "duration_type seconds")
	assert_true(abs(effect.duration_value - 5.0) < 0.01, "duration_value from override")
	assert_eq(effect.merge_behavior, "extend_duration", "merge_behavior")


func test_haste_doubles_tick_rate():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 4.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_haste_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 10.0})
	manager.apply_effect(player, effect)

	assert_true(abs(player.tick_rate_multiplier - 2.0) < 0.01, "tick rate doubled")

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	# With haste (2x), speed 4.0 = effective cooldown 2.0s. After 2.5s should have acted.
	_simulate_time(manager, 2.5)
	assert_true(enemy.health < 1000.0, "player attacked faster with haste")


func test_haste_expires_restores_tick_rate():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_haste_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 1.0})
	manager.apply_effect(player, effect)
	assert_true(abs(player.tick_rate_multiplier - 2.0) < 0.01, "tick rate doubled")

	_simulate_time(manager, 2.0)
	assert_false(player.has_effect("haste"), "haste expired")
	assert_true(abs(player.tick_rate_multiplier - 1.0) < 0.01, "tick rate restored to 1.0")


func test_haste_multiple_applications_additive():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_haste_template()

	# Apply haste for 3 seconds, then again for 4 seconds
	var effect1 = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 3.0})
	manager.apply_effect(player, effect1)
	var effect2 = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 4.0})
	manager.apply_effect(player, effect2)

	# Duration should be additive: 3 + 4 = 7 seconds
	var haste_effect = player.get_effect("haste")
	assert_true(abs(haste_effect.duration_value - 7.0) < 0.01, "haste duration is additive: 3 + 4 = 7")
	assert_true(player.has_effect("haste"), "haste still active")

	# Duration drains at real time (not affected by tick rate), so 7s means 7 real seconds
	_simulate_time(manager, 6.5)
	assert_true(player.has_effect("haste"), "haste still active at 6.5s")

	_simulate_time(manager, 1.0)
	assert_false(player.has_effect("haste"), "haste expired after 7s")


# =============================================================================
# SLOW TESTS
# =============================================================================

func test_slow_creation_from_template():
	var template = _get_slow_template()
	assert_false(template.is_empty(), "slow template loaded from GameData")

	var effect = StatusEffectFactory.create_from_template(template, "src1", {"duration_value": 5.0})
	assert_eq(effect.effect_id, "slow", "effect_id is slow")
	assert_eq(effect.continuous_modifier, "cooldown_tick_rate", "continuous_modifier set")
	assert_true(abs(effect.continuous_value - 0.5) < 0.01, "continuous_value 0.5")
	assert_eq(effect.duration_type, "seconds", "duration_type seconds")
	assert_true(abs(effect.duration_value - 5.0) < 0.01, "duration_value from override")
	assert_eq(effect.merge_behavior, "extend_duration", "merge_behavior")


func test_slow_halves_tick_rate():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_slow_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 10.0})
	manager.apply_effect(player, effect)

	assert_true(abs(player.tick_rate_multiplier - 0.5) < 0.01, "tick rate halved")

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	# With slow (0.5x), speed 2.0 = effective cooldown 4.0s. After 3.5s should NOT have acted.
	_simulate_time(manager, 3.5)
	assert_true(abs(enemy.health - 1000.0) < 0.01, "player has not attacked yet due to slow")

	# After 4.5s total, should have acted once
	_simulate_time(manager, 1.0)
	assert_true(enemy.health < 1000.0, "player attacked after slow cooldown elapsed")


func test_slow_expires_restores_tick_rate():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_slow_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 1.0})
	manager.apply_effect(player, effect)
	assert_true(abs(player.tick_rate_multiplier - 0.5) < 0.01, "tick rate halved")

	_simulate_time(manager, 2.0)
	assert_false(player.has_effect("slow"), "slow expired")
	assert_true(abs(player.tick_rate_multiplier - 1.0) < 0.01, "tick rate restored to 1.0")


func test_slow_multiple_applications_additive():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_slow_template()

	var effect1 = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 3.0})
	manager.apply_effect(player, effect1)
	var effect2 = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 4.0})
	manager.apply_effect(player, effect2)

	var slow_effect = player.get_effect("slow")
	assert_true(abs(slow_effect.duration_value - 7.0) < 0.01, "slow duration is additive: 3 + 4 = 7")
	assert_true(player.has_effect("slow"), "slow still active")

	_simulate_time(manager, 6.5)
	assert_true(player.has_effect("slow"), "slow still active at 6.5s")

	_simulate_time(manager, 1.0)
	assert_false(player.has_effect("slow"), "slow expired after 7s")


# =============================================================================
# FREEZE TESTS
# =============================================================================

func test_freeze_creation_from_template():
	var template = _get_freeze_template()
	assert_false(template.is_empty(), "freeze template loaded from GameData")

	var effect = StatusEffectFactory.create_from_template(template, "src1", {"duration_value": 5.0})
	assert_eq(effect.effect_id, "freeze", "effect_id is freeze")
	assert_eq(effect.continuous_modifier, "cooldown_tick_rate", "continuous_modifier set")
	assert_true(abs(effect.continuous_value - 0.0) < 0.01, "continuous_value 0.0")
	assert_eq(effect.duration_type, "seconds", "duration_type seconds")
	assert_true(abs(effect.duration_value - 5.0) < 0.01, "duration_value from override")
	assert_eq(effect.merge_behavior, "extend_duration", "merge_behavior")


func test_freeze_stops_tick_rate():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_freeze_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 10.0})
	manager.apply_effect(player, effect)

	assert_true(abs(player.tick_rate_multiplier - 0.0) < 0.01, "tick rate is zero")

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	# Frozen character should never act, even after a long time
	_simulate_time(manager, 8.0)
	assert_true(abs(enemy.health - 1000.0) < 0.01, "frozen player never attacked")


func test_freeze_expires_restores_tick_rate():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_freeze_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 1.0})
	manager.apply_effect(player, effect)
	assert_true(abs(player.tick_rate_multiplier - 0.0) < 0.01, "tick rate is zero")

	_simulate_time(manager, 2.0)
	assert_false(player.has_effect("freeze"), "freeze expired")
	assert_true(abs(player.tick_rate_multiplier - 1.0) < 0.01, "tick rate restored to 1.0")


func test_freeze_multiple_applications_additive():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_freeze_template()

	var effect1 = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 3.0})
	manager.apply_effect(player, effect1)
	var effect2 = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 4.0})
	manager.apply_effect(player, effect2)

	var freeze_effect = player.get_effect("freeze")
	assert_true(abs(freeze_effect.duration_value - 7.0) < 0.01, "freeze duration is additive: 3 + 4 = 7")

	_simulate_time(manager, 6.5)
	assert_true(player.has_effect("freeze"), "freeze still active at 6.5s")

	_simulate_time(manager, 1.0)
	assert_false(player.has_effect("freeze"), "freeze expired after 7s")


func test_freeze_resumes_cooldown_where_left_off():
	var manager = CombatManager.new()
	# Player with speed 4.0 (acts every 4s normally)
	var pg = _make_grid_with_one(_make_source(1000, 4.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)

	# Let 2s pass: cooldown_remaining should be ~2.0 (started at 4.0, ticked 2.0)
	_simulate_time(manager, 2.0)
	assert_true(abs(enemy.health - 1000.0) < 0.01, "no attack yet at 2s")

	# Freeze for 3 seconds
	var template = _get_freeze_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"duration_value": 3.0})
	manager.apply_effect(player, effect)

	# 3 seconds pass while frozen - no progress on cooldown
	_simulate_time(manager, 3.0)
	assert_true(abs(enemy.health - 1000.0) < 0.01, "no attack during freeze")

	# Freeze expired at t=5s. Player resumes with ~2.0s remaining on cooldown.
	# After 2.5 more seconds (t=7.5s total), player should have attacked.
	_simulate_time(manager, 2.5)
	assert_true(enemy.health < 1000.0, "player attacked after freeze expired and remaining cooldown elapsed")


# =============================================================================
# BURN TESTS
# =============================================================================

func test_burn_creation_from_template():
	var template = _get_burn_template()
	assert_false(template.is_empty(), "burn template loaded from GameData")

	var effect = StatusEffectFactory.create_from_template(template, "src1", {"stacks": 10})
	assert_eq(effect.effect_id, "burn", "effect_id is burn")
	assert_eq(effect.stacks, 10, "stacks from override")
	assert_eq(effect.max_stacks, 99, "max_stacks from template")
	assert_eq(effect.merge_behavior, "add_stacks", "merge_behavior")
	assert_true(effect.tags.has("debuff"), "has debuff tag")
	assert_true(effect.tags.has("dot"), "has dot tag")
	assert_true(effect.on_apply.is_valid(), "on_apply wired from registry")


func test_burn_deals_damage_on_apply():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_burn_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 10})
	manager.apply_effect(target, effect)

	# Burn for 10 should deal 10 damage immediately
	assert_true(abs(target.health - 990.0) < 0.01, "10 damage dealt immediately on burn apply")
	assert_eq(target.get_stacks("burn"), 10, "burn stacks remain at 10")


func test_burn_stacks_accumulate_and_damage_increases():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_burn_template()

	# First burn: 10 stacks, deals 10 damage
	var e1 = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 10})
	manager.apply_effect(target, e1)
	assert_true(abs(target.health - 990.0) < 0.01, "first burn: 10 damage, hp=990")

	# Second burn: 11 stacks added, total 21, deals 21 damage
	var e2 = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 11})
	manager.apply_effect(target, e2)
	assert_eq(target.get_stacks("burn"), 21, "stacks accumulated: 10 + 11 = 21")
	assert_true(abs(target.health - 969.0) < 0.01, "second burn: 21 damage, hp=969")

	# Third burn: 1 stack added, total 22, deals 22 damage
	var e3 = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 1})
	manager.apply_effect(target, e3)
	assert_eq(target.get_stacks("burn"), 22, "stacks accumulated: 21 + 1 = 22")
	assert_true(abs(target.health - 947.0) < 0.01, "third burn: 22 damage, hp=947")


func test_burn_stacks_persist():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_burn_template()
	var effect = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 5})
	manager.apply_effect(target, effect)

	# Wait a while - stacks should not decay (no tick action)
	_simulate_time(manager, 5.0)
	assert_true(target.has_effect("burn"), "burn persists after time passes")
	assert_eq(target.get_stacks("burn"), 5, "burn stacks unchanged after time passes")


func test_burn_merge_from_multiple_sources():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var target = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_burn_template()

	var e1 = StatusEffectFactory.create_from_template(template, "source_A", {"stacks": 5})
	var e2 = StatusEffectFactory.create_from_template(template, "source_B", {"stacks": 7})
	manager.apply_effect(target, e1)
	manager.apply_effect(target, e2)

	assert_eq(target.effects.filter(func(e): return e.effect_id == "burn").size(), 1, "merged into single burn effect")
	assert_eq(target.get_stacks("burn"), 12, "stacks additive across sources: 5 + 7 = 12")
	# First apply: 5 damage. Second apply: 12 damage. Total: 17 damage.
	assert_true(abs(target.health - 983.0) < 0.01, "total damage: 5 + 12 = 17")


# =============================================================================
# SHIELD TESTS
# =============================================================================

func _get_shield_template() -> Dictionary:
	var gd_node = root.get_node_or_null("GameData")
	if gd_node:
		return gd_node.get_status_effect("shield")
	return {}


func test_shield_creation_from_template():
	var template = _get_shield_template()
	assert_false(template.is_empty(), "shield template loaded from GameData")

	var effect = StatusEffectFactory.create_from_template(template, "src1", {"stacks": 20})
	assert_eq(effect.effect_id, "shield", "effect_id is shield")
	assert_eq(effect.stacks, 20, "stacks from override")
	assert_eq(effect.max_stacks, 999, "max_stacks from template")
	assert_eq(effect.merge_behavior, "add_stacks", "merge_behavior")
	assert_eq(effect.duration_type, "permanent", "duration_type permanent")
	assert_true(effect.tags.has("buff"), "has buff tag")
	assert_true(effect.tags.has("shield"), "has shield tag")


func test_shield_absorbs_attack_damage():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_shield_template()
	var shield = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 20})
	manager.apply_effect(enemy, shield)

	_simulate_time(manager, 1.5)
	# Player attacks for 10 damage, shield absorbs all
	assert_true(abs(enemy.health - 1000.0) < 0.01, "no HP lost, shield absorbed")
	assert_eq(enemy.get_stacks("shield"), 10, "shield reduced from 20 to 10")


func test_shield_partial_absorb():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 30.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_shield_template()
	var shield = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 10})
	manager.apply_effect(enemy, shield)

	_simulate_time(manager, 1.5)
	# 30 damage - 10 shield = 20 damage taken
	assert_true(abs(enemy.health - 980.0) < 0.01, "20 damage after shield absorb")
	assert_false(enemy.has_effect("shield"), "shield fully consumed")


func test_shield_removed_at_zero():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var template = _get_shield_template()
	var shield = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 10})
	manager.apply_effect(enemy, shield)

	_simulate_time(manager, 1.5)
	# 10 damage = 10 shield, exact match
	assert_true(abs(enemy.health - 1000.0) < 0.01, "no HP lost")
	assert_false(enemy.has_effect("shield"), "shield removed at zero stacks")


func test_shield_does_not_absorb_poison():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var shield_template = _get_shield_template()
	var shield = StatusEffectFactory.create_from_template(shield_template, "s1", {"stacks": 50})
	manager.apply_effect(enemy, shield)

	var poison_template = _get_poison_template()
	var poison = StatusEffectFactory.create_from_template(poison_template, "s1", {"stacks": 5})
	manager.apply_effect(enemy, poison)

	_simulate_time(manager, 1.5)
	# Poison tick deals 5 damage, bypasses shield
	assert_true(enemy.health < 1000.0, "poison bypassed shield")
	assert_eq(enemy.get_stacks("shield"), 50, "shield stacks unchanged by poison")


func test_shield_stacks_merge():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_shield_template()

	var s1 = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 10})
	var s2 = StatusEffectFactory.create_from_template(template, "s1", {"stacks": 15})
	manager.apply_effect(ch, s1)
	manager.apply_effect(ch, s2)

	assert_eq(ch.effects.size(), 1, "merged into 1 effect")
	assert_eq(ch.get_stacks("shield"), 25, "stacks merged: 10 + 15 = 25")


func test_shield_merge_from_multiple_sources():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 1.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var template = _get_shield_template()

	# Two different sources apply shield
	var s1 = StatusEffectFactory.create_from_template(template, "source_A", {"stacks": 8})
	var s2 = StatusEffectFactory.create_from_template(template, "source_B", {"stacks": 12})
	manager.apply_effect(ch, s1)
	manager.apply_effect(ch, s2)

	assert_eq(ch.effects.filter(func(e): return e.effect_id == "shield").size(), 1, "merged into single shield effect")
	assert_eq(ch.get_stacks("shield"), 20, "stacks additive across sources: 8 + 12 = 20")

	# Verify shield absorbs correctly after merging from multiple sources
	_simulate_time(manager, 1.5)
	# Enemy has 10 damage, attacks once. Shield absorbs 10, leaving 10 stacks.
	assert_eq(ch.get_stacks("shield"), 10, "shield absorbed 10 damage, 10 stacks remain")
	assert_true(abs(ch.health - 1000.0) < 0.01, "no health lost while shield holds")


func test_shield_self_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"shield_value": 15}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["shield_self"]
	player.extra_stats["shield_value"] = 15

	_simulate_time(manager, 1.5)
	assert_true(player.has_effect("shield"), "player has shield effect")
	assert_eq(player.get_stacks("shield"), 15, "15 stacks of shield applied")


func test_shield_ally_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"shield_value": 20})
	var ally = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["shield_ally"]
	caster_ch.extra_stats["shield_value"] = 20

	var ally_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)

	_simulate_time(manager, 1.5)
	assert_false(caster_ch.has_effect("shield"), "caster does not have shield (excludes self)")
	assert_true(ally_ch.has_effect("shield"), "ally has shield effect")
	assert_eq(ally_ch.get_stacks("shield"), 20, "20 stacks of shield on ally")


# =============================================================================
# ABILITY INTEGRATION
# =============================================================================

func test_poison_enemy_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0, {"poison_value": 3}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	# Override player's ability to basic_poison
	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["poison_enemy"]
	player.extra_stats["poison_value"] = 3

	# Poison no longer deals direct damage; wait long enough for poison to tick
	_simulate_time(manager, 2.5)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_true(enemy.has_effect("poison"), "enemy has poison effect")
	assert_true(enemy.health < 1000.0, "enemy took damage from poison tick")


func test_haste_self_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"haste_value": 5.0}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["haste_self"]
	player.extra_stats["haste_value"] = 5.0

	_simulate_time(manager, 1.5)
	assert_true(player.has_effect("haste"), "player has haste effect")
	assert_true(abs(player.tick_rate_multiplier - 2.0) < 0.01, "tick rate doubled")


func test_haste_ally_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"haste_value": 5.0})
	var ally = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["haste_ally"]
	caster_ch.extra_stats["haste_value"] = 5.0

	var ally_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)

	_simulate_time(manager, 1.5)
	assert_false(caster_ch.has_effect("haste"), "caster does not have haste (excludes self)")
	assert_true(ally_ch.has_effect("haste"), "ally has haste effect")
	assert_true(abs(ally_ch.tick_rate_multiplier - 2.0) < 0.01, "ally tick rate doubled")


func test_slow_enemy_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"slow_value": 5.0}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["slow_enemy"]
	player.extra_stats["slow_value"] = 5.0

	_simulate_time(manager, 1.5)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_true(enemy.has_effect("slow"), "enemy has slow effect")
	assert_true(abs(enemy.tick_rate_multiplier - 0.5) < 0.01, "enemy tick rate halved")


func test_slow_enemy_row_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"slow_value": 5.0}))
	var eg = CharacterGrid.new()
	var e_front1 = _make_source(1000, 100.0, 1.0)
	var e_front2 = _make_source(1000, 100.0, 1.0)
	var e_back = _make_source(1000, 100.0, 1.0)
	eg.place_character(e_front1, 0, 0)
	eg.place_character(e_front2, 0, 1)
	eg.place_character(e_back, 1, 0)
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["slow_enemy_row"]
	player.extra_stats["slow_value"] = 5.0

	_simulate_time(manager, 1.5)
	var ef1 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var ef2 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 1)
	var eb = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(ef1.has_effect("slow"), "front row enemy 1 has slow")
	assert_true(ef2.has_effect("slow"), "front row enemy 2 has slow")
	assert_false(eb.has_effect("slow"), "back row enemy does not have slow")


func test_slow_enemies_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"slow_value": 5.0}))
	var eg = CharacterGrid.new()
	var e_front = _make_source(1000, 100.0, 1.0)
	var e_back = _make_source(1000, 100.0, 1.0)
	eg.place_character(e_front, 0, 0)
	eg.place_character(e_back, 1, 0)
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["slow_enemies"]
	player.extra_stats["slow_value"] = 5.0

	_simulate_time(manager, 1.5)
	var ef = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var eb = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(ef.has_effect("slow"), "front row enemy has slow")
	assert_true(eb.has_effect("slow"), "back row enemy has slow")


func test_freeze_enemy_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"freeze_value": 5.0}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["freeze_enemy"]
	player.extra_stats["freeze_value"] = 5.0

	_simulate_time(manager, 1.5)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_true(enemy.has_effect("freeze"), "enemy has freeze effect")
	assert_true(abs(enemy.tick_rate_multiplier - 0.0) < 0.01, "enemy tick rate is zero")


func test_freeze_enemy_row_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"freeze_value": 5.0}))
	var eg = CharacterGrid.new()
	var e_front1 = _make_source(1000, 100.0, 1.0)
	var e_front2 = _make_source(1000, 100.0, 1.0)
	var e_back = _make_source(1000, 100.0, 1.0)
	eg.place_character(e_front1, 0, 0)
	eg.place_character(e_front2, 0, 1)
	eg.place_character(e_back, 1, 0)
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["freeze_enemy_row"]
	player.extra_stats["freeze_value"] = 5.0

	_simulate_time(manager, 1.5)
	var ef1 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var ef2 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 1)
	var eb = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(ef1.has_effect("freeze"), "front row enemy 1 has freeze")
	assert_true(ef2.has_effect("freeze"), "front row enemy 2 has freeze")
	assert_false(eb.has_effect("freeze"), "back row enemy does not have freeze")


func test_freeze_enemies_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"freeze_value": 5.0}))
	var eg = CharacterGrid.new()
	var e_front = _make_source(1000, 100.0, 1.0)
	var e_back = _make_source(1000, 100.0, 1.0)
	eg.place_character(e_front, 0, 0)
	eg.place_character(e_back, 1, 0)
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["freeze_enemies"]
	player.extra_stats["freeze_value"] = 5.0

	_simulate_time(manager, 1.5)
	var ef = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var eb = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(ef.has_effect("freeze"), "front row enemy has freeze")
	assert_true(eb.has_effect("freeze"), "back row enemy has freeze")


func test_burn_enemy_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"burn_value": 10}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["burn_enemy"]
	player.extra_stats["burn_value"] = 10

	_simulate_time(manager, 1.5)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_true(enemy.has_effect("burn"), "enemy has burn effect")
	assert_eq(enemy.get_stacks("burn"), 10, "burn stacks match burn_value")
	assert_true(abs(enemy.health - 990.0) < 0.01, "enemy took 10 burn damage")


func test_burn_enemy_row_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"burn_value": 8}))
	var eg = CharacterGrid.new()
	var e_front1 = _make_source(1000, 100.0, 0.0)
	var e_front2 = _make_source(1000, 100.0, 0.0)
	var e_back = _make_source(1000, 100.0, 0.0)
	eg.place_character(e_front1, 0, 0)
	eg.place_character(e_front2, 0, 1)
	eg.place_character(e_back, 1, 0)
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["burn_enemy_row"]
	player.extra_stats["burn_value"] = 8

	_simulate_time(manager, 1.5)
	var ef1 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var ef2 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 1)
	var eb = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(ef1.has_effect("burn"), "front row enemy 1 has burn")
	assert_true(ef2.has_effect("burn"), "front row enemy 2 has burn")
	assert_false(eb.has_effect("burn"), "back row enemy does not have burn")
	assert_true(abs(ef1.health - 992.0) < 0.01, "front enemy 1 took 8 burn damage")
	assert_true(abs(ef2.health - 992.0) < 0.01, "front enemy 2 took 8 burn damage")
	assert_true(abs(eb.health - 1000.0) < 0.01, "back row enemy took no damage")


func test_burn_enemies_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"burn_value": 6}))
	var eg = CharacterGrid.new()
	var e_front = _make_source(1000, 100.0, 0.0)
	var e_back = _make_source(1000, 100.0, 0.0)
	eg.place_character(e_front, 0, 0)
	eg.place_character(e_back, 1, 0)
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["burn_enemies"]
	player.extra_stats["burn_value"] = 6

	_simulate_time(manager, 1.5)
	var ef = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var eb = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(ef.has_effect("burn"), "front row enemy has burn")
	assert_true(eb.has_effect("burn"), "back row enemy has burn")
	assert_true(abs(ef.health - 994.0) < 0.01, "front enemy took 6 burn damage")
	assert_true(abs(eb.health - 994.0) < 0.01, "back enemy took 6 burn damage")


func test_haste_ally_row_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"haste_value": 5.0})
	var ally_front = _make_source(1000, 100.0, 1.0)
	var ally_back = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally_front, 0, 1)
	pg.place_character(ally_back, 1, 0)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["haste_ally_row"]
	caster_ch.extra_stats["haste_value"] = 5.0

	_simulate_time(manager, 1.5)
	var af = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	var ab = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 1, 0)
	assert_true(caster_ch.has_effect("haste"), "caster in front row gets haste")
	assert_true(af.has_effect("haste"), "front row ally has haste")
	assert_false(ab.has_effect("haste"), "back row ally does not have haste")


func test_haste_allies_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"haste_value": 5.0})
	var ally = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally, 1, 0)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["haste_allies"]
	caster_ch.extra_stats["haste_value"] = 5.0

	_simulate_time(manager, 1.5)
	var ally_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 1, 0)
	assert_true(caster_ch.has_effect("haste"), "caster has haste")
	assert_true(ally_ch.has_effect("haste"), "back row ally has haste")


func test_heal_self_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"heal_value": 50.0}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["heal_self"]
	player.extra_stats["heal_value"] = 50.0
	player.health = 500.0

	_simulate_time(manager, 1.5)
	assert_true(player.health > 500.0, "player healed self")
	assert_true(abs(player.health - 550.0) < 0.01, "healed for 50")


func test_poison_enemy_row_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"poison_value": 3}))
	var eg = CharacterGrid.new()
	var e_front1 = _make_source(1000, 100.0, 1.0)
	var e_front2 = _make_source(1000, 100.0, 1.0)
	var e_back = _make_source(1000, 100.0, 1.0)
	eg.place_character(e_front1, 0, 0)
	eg.place_character(e_front2, 0, 1)
	eg.place_character(e_back, 1, 0)
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["poison_enemy_row"]
	player.extra_stats["poison_value"] = 3

	_simulate_time(manager, 1.5)
	var ef1 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var ef2 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 1)
	var eb = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(ef1.has_effect("poison"), "front row enemy 1 has poison")
	assert_true(ef2.has_effect("poison"), "front row enemy 2 has poison")
	assert_false(eb.has_effect("poison"), "back row enemy does not have poison")


func test_poison_enemies_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"poison_value": 3}))
	var eg = CharacterGrid.new()
	var e_front = _make_source(1000, 100.0, 1.0)
	var e_back = _make_source(1000, 100.0, 1.0)
	eg.place_character(e_front, 0, 0)
	eg.place_character(e_back, 1, 0)
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["poison_enemies"]
	player.extra_stats["poison_value"] = 3

	_simulate_time(manager, 1.5)
	var ef = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var eb = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(ef.has_effect("poison"), "front row enemy has poison")
	assert_true(eb.has_effect("poison"), "back row enemy has poison")


func test_shield_ally_row_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"shield_value": 15})
	var ally_front = _make_source(1000, 100.0, 1.0)
	var ally_back = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally_front, 0, 1)
	pg.place_character(ally_back, 1, 0)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["shield_ally_row"]
	caster_ch.extra_stats["shield_value"] = 15

	_simulate_time(manager, 1.5)
	var af = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	var ab = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 1, 0)
	assert_true(caster_ch.has_effect("shield"), "caster in front row gets shield")
	assert_true(af.has_effect("shield"), "front row ally has shield")
	assert_false(ab.has_effect("shield"), "back row ally does not have shield")


func test_shield_allies_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"shield_value": 15})
	var ally = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally, 1, 0)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["shield_allies"]
	caster_ch.extra_stats["shield_value"] = 15

	_simulate_time(manager, 1.5)
	var ally_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 1, 0)
	assert_true(caster_ch.has_effect("shield"), "caster has shield")
	assert_true(ally_ch.has_effect("shield"), "back row ally has shield")
	assert_eq(caster_ch.get_stacks("shield"), 15, "caster has 15 shield stacks")
	assert_eq(ally_ch.get_stacks("shield"), 15, "ally has 15 shield stacks")


func test_attack_enemy_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 25.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["attack_enemy"]

	_simulate_time(manager, 1.5)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_true(abs(enemy.health - 975.0) < 0.01, "enemy took 25 damage from basic attack")


func test_attack_enemy_row_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 20.0, 0.0, 0.0))
	var eg = CharacterGrid.new()
	var e_front1 = _make_source(1000, 100.0, 0.0)
	var e_front2 = _make_source(1000, 100.0, 0.0)
	var e_back = _make_source(1000, 100.0, 0.0)
	eg.place_character(e_front1, 0, 0)
	eg.place_character(e_front2, 0, 1)
	eg.place_character(e_back, 1, 0)
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["attack_enemy_row"]

	_simulate_time(manager, 1.5)
	var ef1 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var ef2 = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 1)
	var eb = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(abs(ef1.health - 980.0) < 0.01, "front row enemy 1 took 20 damage")
	assert_true(abs(ef2.health - 980.0) < 0.01, "front row enemy 2 took 20 damage")
	assert_true(abs(eb.health - 1000.0) < 0.01, "back row enemy took no damage")


func test_heal_ally_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"heal_value": 30.0})
	var ally = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["heal_ally"]
	caster_ch.extra_stats["heal_value"] = 30.0

	var ally_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	ally_ch.health = 500.0

	_simulate_time(manager, 1.5)
	assert_true(abs(ally_ch.health - 530.0) < 0.01, "ally healed for 30")
	# Caster should not have healed self (ally_single excludes self)
	assert_true(abs(caster_ch.health - 1000.0) < 0.01, "caster health unchanged")


func test_heal_allies_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"heal_value": 20.0})
	var ally = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally, 1, 0)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["heal_allies"]
	caster_ch.extra_stats["heal_value"] = 20.0
	caster_ch.health = 800.0

	var ally_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 1, 0)
	ally_ch.health = 700.0

	_simulate_time(manager, 1.5)
	assert_true(abs(caster_ch.health - 820.0) < 0.01, "caster healed for 20 (ally_all includes self)")
	assert_true(abs(ally_ch.health - 720.0) < 0.01, "ally healed for 20")


func test_multi_ability_character():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0, {"poison_value": 5}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["attack_enemy", "poison_enemy"]
	player.extra_stats["poison_value"] = 5

	_simulate_time(manager, 1.5)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	# Should have both attacked (10 damage) and applied poison
	assert_true(enemy.health < 1000.0, "enemy took damage from attack")
	assert_true(enemy.has_effect("poison"), "enemy also has poison from second ability")
	assert_eq(enemy.get_stacks("poison"), 5, "poison stacks match poison_value")


func test_solo_ally_single_no_target():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"heal_value": 50.0}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["heal_ally"]
	player.extra_stats["heal_value"] = 50.0
	player.health = 500.0

	_simulate_time(manager, 1.5)
	# ally_single excludes self, so solo character should find no target
	assert_true(abs(player.health - 500.0) < 0.01, "solo character cannot heal_ally (excludes self)")


# =============================================================================
# INTERACTIONS
# =============================================================================

func test_cleanse_removes_poison_not_haste():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var poison_template = _get_poison_template()
	var haste_template = _get_haste_template()

	var poison = StatusEffectFactory.create_from_template(poison_template, "s1", {"stacks": 3})
	var haste = StatusEffectFactory.create_from_template(haste_template, "s1", {"duration_value": 10.0})
	manager.apply_effect(ch, poison)
	manager.apply_effect(ch, haste)

	var removed = manager.cleanse_effects_by_tag(ch, "debuff")
	assert_eq(removed.size(), 1, "removed 1 debuff")
	assert_false(ch.has_effect("poison"), "poison cleansed")
	assert_true(ch.has_effect("haste"), "haste still present")


func test_on_poisoned_trigger_fires():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var triggered = [false]
	var trigger_effect = CombatEffect.create_triggered("test", "t1", "on_poison",
		func(_data): triggered[0] = true, "combat")
	manager.apply_effect(ch, trigger_effect)

	var poison_template = _get_poison_template()
	var poison = StatusEffectFactory.create_from_template(poison_template, "s1", {"stacks": 3})
	manager.apply_effect(ch, poison)
	assert_true(triggered[0], "on_poison trigger fired when poison applied")
