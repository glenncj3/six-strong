extends "res://tests/base_test.gd"
# Tests for data-driven status effects: poison, haste, abilities

func _init():
	test_name = "Status Effects Tests"
	super()


func _run_tests():
	TickActionRegistry.register_defaults()
	AbilityExecutor.register_defaults()

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

	section("Ability Integration")
	test_basic_poison_ability_integration()
	test_self_haste_ability_integration()
	test_ally_haste_ability_integration()

	section("Shield Template")
	test_shield_creation_from_template()
	test_shield_absorbs_attack_damage()
	test_shield_partial_absorb()
	test_shield_removed_at_zero()
	test_shield_does_not_absorb_poison()
	test_shield_stacks_merge()
	test_shield_merge_from_multiple_sources()
	test_self_shield_ability_integration()
	test_ally_shield_ability_integration()

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
		GameConstants.STAT_HEALTH: hp,
		GameConstants.STAT_SPEED: spd,
		GameConstants.STAT_DAMAGE: dmg,
		GameConstants.STAT_DEFEND_RATE: def_rate,
		GameConstants.STAT_CRIT_CHANCE: crit,
		GameConstants.STAT_MANA: 0,
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


func test_self_shield_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"shield_value": 15}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["self_shield"]
	player.extra_stats["shield_value"] = 15

	_simulate_time(manager, 1.5)
	assert_true(player.has_effect("shield"), "player has shield effect")
	assert_eq(player.get_stacks("shield"), 15, "15 stacks of shield applied")


func test_ally_shield_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"shield_value": 20})
	var ally = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["ally_shield"]
	caster_ch.extra_stats["shield_value"] = 20

	var ally_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)

	_simulate_time(manager, 1.5)
	assert_false(caster_ch.has_effect("shield"), "caster does not have shield (excludes self)")
	assert_true(ally_ch.has_effect("shield"), "ally has shield effect")
	assert_eq(ally_ch.get_stacks("shield"), 20, "20 stacks of shield on ally")


# =============================================================================
# ABILITY INTEGRATION
# =============================================================================

func test_basic_poison_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0, {"poison_value": 3}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	# Override player's ability to basic_poison
	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["basic_poison"]
	player.extra_stats["poison_value"] = 3

	# Poison no longer deals direct damage; wait long enough for poison to tick
	_simulate_time(manager, 2.5)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_true(enemy.has_effect("poison"), "enemy has poison effect")
	assert_true(enemy.health < 1000.0, "enemy took damage from poison tick")


func test_self_haste_ability_integration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0, 0.0, 0.0, {"haste_value": 5.0}))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	player.ability_ids = ["self_haste"]
	player.extra_stats["haste_value"] = 5.0

	_simulate_time(manager, 1.5)
	assert_true(player.has_effect("haste"), "player has haste effect")
	assert_true(abs(player.tick_rate_multiplier - 2.0) < 0.01, "tick rate doubled")


func test_ally_haste_ability_integration():
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	var caster = _make_source(1000, 1.0, 1.0, 0.0, 0.0, {"haste_value": 5.0})
	var ally = _make_source(1000, 100.0, 1.0)
	pg.place_character(caster, 0, 0)
	pg.place_character(ally, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var caster_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	caster_ch.ability_ids = ["ally_haste"]
	caster_ch.extra_stats["haste_value"] = 5.0

	var ally_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)

	_simulate_time(manager, 1.5)
	assert_false(caster_ch.has_effect("haste"), "caster does not have haste (excludes self)")
	assert_true(ally_ch.has_effect("haste"), "ally has haste effect")
	assert_true(abs(ally_ch.tick_rate_multiplier - 2.0) < 0.01, "ally tick rate doubled")


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
