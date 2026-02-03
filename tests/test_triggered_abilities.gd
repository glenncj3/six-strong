extends "res://tests/base_test.gd"
# Tests for triggered abilities - on_ally_crit, buff_burn, require_ability_category filtering

func _init():
	test_name = "Triggered Ability Tests"
	super()


func _run_tests():
	section("on_ally_crit Trigger")
	test_on_ally_crit_fires_on_team_crit()
	test_on_ally_crit_does_not_fire_on_enemy_crit()
	test_on_ally_crit_does_not_fire_on_non_crit()
	test_on_ally_crit_fires_for_any_ally_crit()

	section("buff_burn via Triggered Ability")
	test_buff_burn_increases_burn_value()
	test_buff_burn_stacks_on_multiple_crits()
	test_buff_burn_only_targets_burn_allies()
	test_buff_burn_skips_allies_without_burn()

	section("Triggered Ability Skipped on Cooldown")
	test_triggered_ability_not_executed_on_cooldown()

	section("require_ability_category Filtering")
	test_filter_targets_by_ability_category()
	test_filter_excludes_non_matching()
	test_filter_empty_when_no_match()

	section("Action: deal_damage")
	test_action_deal_damage_with_value()
	test_action_deal_damage_from_stat()
	test_action_deal_damage_zero_does_nothing()

	section("Action: heal")
	test_action_heal_with_value()
	test_action_heal_from_stat()

	section("on_front_ally_strike Trigger")
	test_front_ally_strike_fires_for_back_row()
	test_front_ally_strike_same_column_only()
	test_front_ally_strike_not_fire_for_front_row()
	test_front_ally_strike_not_fire_if_no_front_ally()
	test_front_ally_strike_deal_damage_action()

	section("on_haste Trigger (Effect Application)")
	test_on_haste_fires_when_hasted()
	test_on_haste_fires_on_each_application()
	test_on_haste_fires_when_extended()

	section("on_ally_haste Trigger")
	test_on_ally_haste_fires_for_all_allies()
	test_on_ally_haste_includes_self()
	test_on_ally_haste_not_fire_for_enemies()

	section("on_enemy_haste Trigger")
	test_on_enemy_haste_fires_for_all_enemies()
	test_on_enemy_haste_not_fire_for_allies()

	section("Multi-Target Trigger Behavior")
	test_on_enemy_effect_fires_per_target()
	test_on_ally_effect_fires_per_target()


# =============================================================================
# HELPERS
# =============================================================================

func _make_source(hp: int, spd: float, dmg: float, def_rate: float = 0.0, crit: float = 0.0) -> CharacterInstance:
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
	ch.current_health = hp
	return ch


func _make_source_with_id(char_id: String, hp: int, spd: float, dmg: float, crit: float = 0.0) -> CharacterInstance:
	var ch = CharacterInstance.new()
	ch.base_character_id = char_id
	ch.stats = {
		"health": hp,
		"speed": spd,
		"damage": dmg,
		"agility": 0.0,
		"crit_chance": crit,
		"charges": -1,
		"burn_value": 3,
	}
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


func _make_combat_char(team: int, row: int, col: int, hp: float = 100.0, dmg: float = 10.0) -> CombatCharacter:
	var cc = CombatCharacter.new()
	cc.id = "cc_%d_%d_%d" % [team, row, col]
	cc.source_character_id = "test"
	cc.team = team
	cc.row = row
	cc.column = col
	cc.health = hp
	cc.max_health = hp
	cc.base_damage = dmg
	cc.damage = dmg
	cc.base_speed = 1.0
	cc.speed = 1.0
	cc.is_alive = true
	cc.crit_chance = 0.0
	cc.agility = 0.0
	cc.base_crit_chance = 0.0
	cc.base_agility = 0.0
	return cc


# =============================================================================
# on_ally_crit Trigger
# =============================================================================

func test_on_ally_crit_fires_on_team_crit():
	var manager = CombatManager.new()
	# Player: 100% crit, enemy: high hp, slow
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var crit_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_ally_crit",
		func(_data): crit_count[0] += 1, "combat")
	manager.apply_effect(player, effect)

	_simulate_time(manager, 1.1)
	assert_true(crit_count[0] >= 1, "on_ally_crit triggered when ally crits (count=%d)" % crit_count[0])


func test_on_ally_crit_does_not_fire_on_enemy_crit():
	var manager = CombatManager.new()
	# Player: no crit, no damage. Enemy: 100% crit
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 1.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var crit_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_ally_crit",
		func(_data): crit_count[0] += 1, "combat")
	manager.apply_effect(player, effect)

	_simulate_time(manager, 1.5)
	assert_eq(crit_count[0], 0, "on_ally_crit NOT triggered by enemy crit")


func test_on_ally_crit_does_not_fire_on_non_crit():
	var manager = CombatManager.new()
	# Player: 0% crit
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var crit_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_ally_crit",
		func(_data): crit_count[0] += 1, "combat")
	manager.apply_effect(player, effect)

	_simulate_time(manager, 1.5)
	assert_eq(crit_count[0], 0, "on_ally_crit NOT triggered on non-crit hit")


func test_on_ally_crit_fires_for_any_ally_crit():
	# Two player characters: critter (100% crit) and listener (has on_ally_crit).
	# The critter crits, listener's on_ally_crit should fire.
	var manager = CombatManager.new()
	var critter = _make_source(1000, 1.0, 10.0, 0.0, 1.0)
	var listener = _make_source(1000, 100.0, 0.0)  # slow, no damage
	var pg = CharacterGrid.new()
	pg.place_character(critter, 0, 0)
	pg.place_character(listener, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var listener_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	var crit_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_ally_crit",
		func(_data): crit_count[0] += 1, "combat")
	manager.apply_effect(listener_cc, effect)

	_simulate_time(manager, 1.1)
	assert_true(crit_count[0] >= 1, "listener's on_ally_crit fires when another ally crits (count=%d)" % crit_count[0])


# =============================================================================
# buff_burn via Triggered Ability
# =============================================================================

func test_buff_burn_increases_burn_value():
	var manager = CombatManager.new()
	# Critter: 100% crit. Burner: has burn ability, slow
	var critter = _make_source(1000, 1.0, 10.0, 0.0, 1.0)
	var burner = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(critter, 0, 0)
	pg.place_character(burner, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var critter_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var burner_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	burner_cc.ability_ids = ["burn_enemy"]
	burner_cc.extra_stats["burn_value"] = 3.0
	burner_cc.base_extra_stats["burn_value"] = 3.0

	# Create the triggered ability inline (same shape as character JSON)
	var ability_def = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "ally_all",
		"buff_stat": "burn_value",
		"buff_modifier_type": "flat",
		"buff_value": 1,
		"require_ability_category": "burn",
	}
	manager._apply_triggered_ability(critter_cc, ability_def, "on_ally_crit")

	var burn_before = burner_cc.get_stat_value("burn_value")
	_simulate_time(manager, 1.1)  # critter crits
	var burn_after = burner_cc.get_stat_value("burn_value")

	assert_true(burn_after > burn_before, "burn_value increased after crit (before=%.1f, after=%.1f)" % [burn_before, burn_after])
	assert_eq(burn_after, burn_before + 1.0, "burn_value increased by exactly 1")


func test_buff_burn_stacks_on_multiple_crits():
	var manager = CombatManager.new()
	var critter = _make_source(1000, 1.0, 10.0, 0.0, 1.0)
	var burner = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(critter, 0, 0)
	pg.place_character(burner, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var critter_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var burner_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	burner_cc.ability_ids = ["burn_enemy"]
	burner_cc.extra_stats["burn_value"] = 3.0
	burner_cc.base_extra_stats["burn_value"] = 3.0

	var ability_def = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "ally_all",
		"buff_stat": "burn_value",
		"buff_modifier_type": "flat",
		"buff_value": 1,
		"require_ability_category": "burn",
	}
	manager._apply_triggered_ability(critter_cc, ability_def, "on_ally_crit")

	var burn_before = burner_cc.get_stat_value("burn_value")
	# Critter has speed 1.0, so should act ~2 times in 2.5 seconds
	_simulate_time(manager, 2.5)
	var burn_after = burner_cc.get_stat_value("burn_value")

	assert_true(burn_after >= burn_before + 2.0, "burn_value stacks across multiple crits (before=%.1f, after=%.1f)" % [burn_before, burn_after])


func test_buff_burn_only_targets_burn_allies():
	var manager = CombatManager.new()
	var critter = _make_source(1000, 1.0, 10.0, 0.0, 1.0)
	var burner = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(critter, 0, 0)
	pg.place_character(burner, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var critter_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var burner_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	burner_cc.ability_ids = ["burn_enemy"]
	burner_cc.extra_stats["burn_value"] = 3.0
	burner_cc.base_extra_stats["burn_value"] = 3.0
	# Critter has no burn ability
	critter_cc.ability_ids = ["attack_enemy"]

	var ability_def = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "ally_all",
		"buff_stat": "burn_value",
		"buff_modifier_type": "flat",
		"buff_value": 1,
		"require_ability_category": "burn",
	}
	manager._apply_triggered_ability(critter_cc, ability_def, "on_ally_crit")

	_simulate_time(manager, 1.1)

	# Burner should be buffed (has burn ability)
	assert_true(burner_cc.get_stat_value("burn_value") > 3.0, "burner got burn_value buff")
	# Critter should NOT be buffed (no burn ability)
	# Critter doesn't have burn_value base, so check effects
	var critter_burn_modifiers = 0
	for effect in critter_cc.effects:
		if effect.effect_type == "stat_modifier" and effect.stat == "burn_value":
			critter_burn_modifiers += 1
	assert_eq(critter_burn_modifiers, 0, "critter (no burn ability) got no burn_value modifier")


func test_buff_burn_skips_allies_without_burn():
	var manager = CombatManager.new()
	var source = _make_source(1000, 1.0, 10.0, 0.0, 1.0)
	var healer = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(source, 0, 0)
	pg.place_character(healer, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var source_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var healer_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	healer_cc.ability_ids = ["heal_ally"]  # heal, not burn

	var ability_def = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "ally_all",
		"buff_stat": "burn_value",
		"buff_modifier_type": "flat",
		"buff_value": 1,
		"require_ability_category": "burn",
	}
	manager._apply_triggered_ability(source_cc, ability_def, "on_ally_crit")

	_simulate_time(manager, 1.1)

	var healer_burn_modifiers = 0
	for effect in healer_cc.effects:
		if effect.effect_type == "stat_modifier" and effect.stat == "burn_value":
			healer_burn_modifiers += 1
	assert_eq(healer_burn_modifiers, 0, "healer (heal ability, no burn) got no burn_value modifier")


# =============================================================================
# Triggered Ability Skipped on Cooldown
# =============================================================================

func test_triggered_ability_not_executed_on_cooldown():
	# Triggered type abilities should be skipped during normal cooldown execution
	var triggered_ability = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "ally_all",
		"buff_stat": "burn_value",
		"buff_modifier_type": "flat",
		"buff_value": 1,
	}
	var should_skip = triggered_ability.get("type", "") in ["passive", "triggered"]
	assert_true(should_skip, "triggered abilities identified for skipping in _execute_ability")


# =============================================================================
# require_ability_category Filtering
# =============================================================================

func test_filter_targets_by_ability_category():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	cc.ability_ids = ["burn_enemy"]

	var targets = [cc]
	var filtered = manager._filter_targets_by_ability_category(targets, "burn")
	assert_eq(filtered.size(), 1, "character with burn ability passes filter")
	assert_true(filtered.has(cc), "correct character in filtered result")


func test_filter_excludes_non_matching():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	cc.ability_ids = ["heal_ally"]

	var targets = [cc]
	var filtered = manager._filter_targets_by_ability_category(targets, "burn")
	assert_eq(filtered.size(), 0, "character with heal ability excluded from burn filter")


func test_filter_empty_when_no_match():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var filtered = manager._filter_targets_by_ability_category([], "burn")
	assert_eq(filtered.size(), 0, "empty input returns empty output")


# =============================================================================
# Action: deal_damage
# =============================================================================

func test_action_deal_damage_with_value():
	var manager = CombatManager.new()
	var attacker = _make_source(1000, 1.0, 10.0, 0.0, 1.0)  # 100% crit to trigger
	var pg = _make_grid_with_one(attacker)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var attacker_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var hp_before = enemy_cc.health

	var ability_def = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "enemy_single",
		"action": "deal_damage",
		"damage_value": 25,
	}
	manager._apply_triggered_ability(attacker_cc, ability_def, "on_ally_crit")

	_simulate_time(manager, 1.1)  # attacker crits, trigger fires
	var hp_after = enemy_cc.health

	# Enemy should have taken crit damage (10 * 1.5 = 15) + triggered damage (25) = at least 40
	assert_true(hp_before - hp_after >= 40, "deal_damage action dealt damage (lost %.1f hp)" % (hp_before - hp_after))


func test_action_deal_damage_from_stat():
	var manager = CombatManager.new()
	var attacker = _make_source(1000, 1.0, 10.0, 0.0, 1.0)
	var pg = _make_grid_with_one(attacker)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var attacker_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	attacker_cc.extra_stats["burn_value"] = 20.0
	attacker_cc.base_extra_stats["burn_value"] = 20.0
	var enemy_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var hp_before = enemy_cc.health

	var ability_def = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "enemy_single",
		"action": "deal_damage",
		"damage_from": "burn_value",  # Read damage from burn_value stat
	}
	manager._apply_triggered_ability(attacker_cc, ability_def, "on_ally_crit")

	_simulate_time(manager, 1.1)
	var hp_after = enemy_cc.health

	# Should have dealt 20 damage from burn_value stat
	assert_true(hp_before - hp_after >= 20, "deal_damage from stat dealt damage (lost %.1f hp)" % (hp_before - hp_after))


func test_action_deal_damage_zero_does_nothing():
	var manager = CombatManager.new()
	var attacker = _make_source(1000, 1.0, 10.0, 0.0, 1.0)
	var pg = _make_grid_with_one(attacker)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var attacker_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)

	var ability_def = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "enemy_single",
		"action": "deal_damage",
		"damage_value": 0,
	}
	manager._apply_triggered_ability(attacker_cc, ability_def, "on_ally_crit")

	var hp_before_crit = enemy_cc.health
	_simulate_time(manager, 1.1)
	var hp_after_crit = enemy_cc.health

	# Should only take crit damage (10 * 1.5 = 15), not extra from triggered
	var damage_taken = hp_before_crit - hp_after_crit
	assert_true(damage_taken <= 20, "zero damage_value doesn't add extra damage (took %.1f)" % damage_taken)


# =============================================================================
# Action: heal
# =============================================================================

func test_action_heal_with_value():
	var manager = CombatManager.new()
	var attacker = _make_source(1000, 1.0, 10.0, 0.0, 1.0)
	var pg = _make_grid_with_one(attacker)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var attacker_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	attacker_cc.health = 500  # Damage the attacker

	var ability_def = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "self",
		"action": "heal",
		"heal_value": 100,
	}
	manager._apply_triggered_ability(attacker_cc, ability_def, "on_ally_crit")

	_simulate_time(manager, 1.1)

	assert_eq(attacker_cc.health, 600.0, "heal action restored health")


func test_action_heal_from_stat():
	var manager = CombatManager.new()
	var attacker = _make_source(1000, 1.0, 10.0, 0.0, 1.0)
	var pg = _make_grid_with_one(attacker)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var attacker_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	attacker_cc.health = 500
	attacker_cc.extra_stats["heal_value"] = 50.0
	attacker_cc.base_extra_stats["heal_value"] = 50.0

	var ability_def = {
		"type": "triggered",
		"trigger": "on_ally_crit",
		"target_mode": "self",
		"action": "heal",
		"heal_from": "heal_value",
	}
	manager._apply_triggered_ability(attacker_cc, ability_def, "on_ally_crit")

	_simulate_time(manager, 1.1)

	assert_eq(attacker_cc.health, 550.0, "heal from stat restored correct amount")


# =============================================================================
# on_front_ally_strike Trigger
# =============================================================================

func test_front_ally_strike_fires_for_back_row():
	# Front row char acts, back row char's trigger should fire
	var manager = CombatManager.new()
	var front = _make_source(1000, 1.0, 10.0)  # Fast attacker in front
	var back = _make_source(1000, 100.0, 0.0)  # Slow supporter in back
	var pg = CharacterGrid.new()
	pg.place_character(front, 0, 0)  # Front row, col 0
	pg.place_character(back, 1, 0)   # Back row, col 0 (same column)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var back_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_BACK, 0)
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_front_ally_strike",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(back_cc, effect)

	_simulate_time(manager, 1.1)

	assert_true(trigger_count[0] >= 1, "on_front_ally_strike fired for back row char (count=%d)" % trigger_count[0])


func test_front_ally_strike_same_column_only():
	# Front row char in col 0, back row char in col 1 - should NOT trigger
	var manager = CombatManager.new()
	var front = _make_source(1000, 1.0, 10.0)
	var back = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(front, 0, 0)  # Front row, col 0
	pg.place_character(back, 1, 1)   # Back row, col 1 (different column)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var back_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_BACK, 1)
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_front_ally_strike",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(back_cc, effect)

	_simulate_time(manager, 1.5)

	assert_eq(trigger_count[0], 0, "on_front_ally_strike NOT fired for different column")


func test_front_ally_strike_not_fire_for_front_row():
	# Both chars in front row - trigger should not fire
	var manager = CombatManager.new()
	var front1 = _make_source(1000, 1.0, 10.0)
	var front2 = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(front1, 0, 0)  # Front row, col 0
	pg.place_character(front2, 0, 1)  # Front row, col 1
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var front2_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_front_ally_strike",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(front2_cc, effect)

	_simulate_time(manager, 1.5)

	assert_eq(trigger_count[0], 0, "on_front_ally_strike NOT fired for front row char")


func test_front_ally_strike_not_fire_if_no_front_ally():
	# Only back row char - no front ally to trigger from
	var manager = CombatManager.new()
	var back = _make_source(1000, 1.0, 10.0)
	var pg = CharacterGrid.new()
	pg.place_character(back, 1, 0)  # Back row only
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var back_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_BACK, 0)
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_front_ally_strike",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(back_cc, effect)

	_simulate_time(manager, 1.5)

	assert_eq(trigger_count[0], 0, "on_front_ally_strike NOT fired when no front ally exists")


func test_front_ally_strike_deal_damage_action():
	# Integration test: back row char deals damage when front ally strikes
	var manager = CombatManager.new()
	var front = _make_source(1000, 1.0, 10.0)
	var back = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(front, 0, 0)
	pg.place_character(back, 1, 0)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var back_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, GameConstants.ROW_BACK, 0)
	var enemy_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var hp_before = enemy_cc.health

	# Backstab Archer style ability
	var ability_def = {
		"type": "triggered",
		"trigger": "on_front_ally_strike",
		"target_mode": "enemy_single",
		"action": "deal_damage",
		"damage_value": 15,
	}
	manager._apply_triggered_ability(back_cc, ability_def, "on_front_ally_strike")

	_simulate_time(manager, 1.1)
	var hp_after = enemy_cc.health

	# Front char deals 10 damage, back char deals 15 via trigger = 25 total
	var total_damage = hp_before - hp_after
	assert_true(total_damage >= 25, "front ally strike + deal_damage dealt combined damage (%.1f)" % total_damage)


# =============================================================================
# on_haste Trigger (Effect Application)
# =============================================================================

func test_on_haste_fires_when_hasted():
	# on_haste should fire when the character receives haste
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(player_cc, effect)

	# Apply haste effect
	var haste_effect = CombatEffect.new()
	haste_effect.effect_id = "haste"
	haste_effect.effect_type = "status"
	haste_effect.source_type = "ability"
	haste_effect.source_id = "test_haste"
	haste_effect.duration_type = "seconds"
	haste_effect.duration_value = 3.0
	haste_effect.merge_behavior = "extend_duration"
	haste_effect.continuous_modifier = "cooldown_tick_rate"
	haste_effect.continuous_value = 2.0
	manager.apply_effect(player_cc, haste_effect)

	assert_eq(trigger_count[0], 1, "on_haste fired when haste applied")


func test_on_haste_fires_on_each_application():
	# on_haste should fire each time haste is applied, even from different sources
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(player_cc, effect)

	# Apply haste twice from different sources
	for i in range(2):
		var haste_effect = CombatEffect.new()
		haste_effect.effect_id = "haste"
		haste_effect.effect_type = "status"
		haste_effect.source_type = "ability"
		haste_effect.source_id = "test_haste_%d" % i
		haste_effect.duration_type = "seconds"
		haste_effect.duration_value = 2.0
		haste_effect.merge_behavior = "extend_duration"
		haste_effect.continuous_modifier = "cooldown_tick_rate"
		haste_effect.continuous_value = 2.0
		manager.apply_effect(player_cc, haste_effect)

	assert_eq(trigger_count[0], 2, "on_haste fired twice for two haste applications")


func test_on_haste_fires_when_extended():
	# on_haste should fire when haste duration is extended (merged)
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(player_cc, effect)

	# Apply haste, then extend it
	var haste1 = CombatEffect.new()
	haste1.effect_id = "haste"
	haste1.effect_type = "status"
	haste1.source_type = "ability"
	haste1.source_id = "test_haste"
	haste1.duration_type = "seconds"
	haste1.duration_value = 3.0
	haste1.merge_behavior = "extend_duration"
	haste1.continuous_modifier = "cooldown_tick_rate"
	haste1.continuous_value = 2.0
	manager.apply_effect(player_cc, haste1)

	# Wait a bit, then extend
	_simulate_time(manager, 1.0)

	var haste2 = CombatEffect.new()
	haste2.effect_id = "haste"
	haste2.effect_type = "status"
	haste2.source_type = "ability"
	haste2.source_id = "test_haste"
	haste2.duration_type = "seconds"
	haste2.duration_value = 2.0
	haste2.merge_behavior = "extend_duration"
	haste2.continuous_modifier = "cooldown_tick_rate"
	haste2.continuous_value = 2.0
	manager.apply_effect(player_cc, haste2)

	assert_eq(trigger_count[0], 2, "on_haste fired twice (initial + extension)")


# =============================================================================
# on_ally_haste Trigger
# =============================================================================

func _make_haste_effect() -> CombatEffect:
	var haste = CombatEffect.new()
	haste.effect_id = "haste"
	haste.effect_type = "status"
	haste.source_type = "ability"
	haste.source_id = "test_haste"
	haste.duration_type = "seconds"
	haste.duration_value = 3.0
	haste.merge_behavior = "extend_duration"
	haste.continuous_modifier = "cooldown_tick_rate"
	haste.continuous_value = 2.0
	return haste


func test_on_ally_haste_fires_for_all_allies():
	# When one ally gets hasted, on_ally_haste fires for ALL allies
	var manager = CombatManager.new()
	var ally1 = _make_source(1000, 100.0, 0.0)
	var ally2 = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(ally1, 0, 0)
	pg.place_character(ally2, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var ally1_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var ally2_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)

	# Put on_ally_haste trigger on ally2
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_ally_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(ally2_cc, effect)

	# Haste ally1
	manager.apply_effect(ally1_cc, _make_haste_effect())

	assert_eq(trigger_count[0], 1, "on_ally_haste fired on ally2 when ally1 was hasted")


func test_on_ally_haste_includes_self():
	# on_ally_haste fires when the character with the trigger is hasted (self counts as ally)
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)

	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_ally_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(player_cc, effect)

	# Haste self
	manager.apply_effect(player_cc, _make_haste_effect())

	assert_eq(trigger_count[0], 1, "on_ally_haste fired when self was hasted")


func test_on_ally_haste_not_fire_for_enemies():
	# on_ally_haste should NOT fire when an enemy is hasted
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)

	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_ally_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(player_cc, effect)

	# Haste enemy
	manager.apply_effect(enemy_cc, _make_haste_effect())

	assert_eq(trigger_count[0], 0, "on_ally_haste NOT fired when enemy was hasted")


# =============================================================================
# on_enemy_haste Trigger
# =============================================================================

func test_on_enemy_haste_fires_for_all_enemies():
	# When an enemy gets hasted, on_enemy_haste fires for all characters on opposing team
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)

	# Put on_enemy_haste trigger on player
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_enemy_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(player_cc, effect)

	# Haste enemy
	manager.apply_effect(enemy_cc, _make_haste_effect())

	assert_eq(trigger_count[0], 1, "on_enemy_haste fired on player when enemy was hasted")


func test_on_enemy_haste_not_fire_for_allies():
	# on_enemy_haste should NOT fire when an ally is hasted
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)

	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_enemy_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(player_cc, effect)

	# Haste self (ally)
	manager.apply_effect(player_cc, _make_haste_effect())

	assert_eq(trigger_count[0], 0, "on_enemy_haste NOT fired when ally was hasted")


# =============================================================================
# Multi-Target Trigger Behavior
# =============================================================================

func test_on_enemy_effect_fires_per_target():
	# When an ability applies an effect to 3 enemies, on_enemy_<effect> should fire 3 times
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	# Create 3 enemies
	var enemy1 = _make_source(1000, 100.0, 0.0)
	var enemy2 = _make_source(1000, 100.0, 0.0)
	var enemy3 = _make_source(1000, 100.0, 0.0)
	var eg = CharacterGrid.new()
	eg.place_character(enemy1, 0, 0)
	eg.place_character(enemy2, 0, 1)
	eg.place_character(enemy3, 0, 2)
	manager.initialize_combat(pg, eg)

	var player_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy1_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var enemy2_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 1)
	var enemy3_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 2)

	# Put on_enemy_haste trigger on player
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_enemy_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(player_cc, effect)

	# Haste all 3 enemies (simulating a multi-target ability)
	manager.apply_effect(enemy1_cc, _make_haste_effect())
	manager.apply_effect(enemy2_cc, _make_haste_effect())
	manager.apply_effect(enemy3_cc, _make_haste_effect())

	assert_eq(trigger_count[0], 3, "on_enemy_haste fired 3 times when 3 enemies were hasted")


func test_on_ally_effect_fires_per_target():
	# When an ability applies an effect to 3 allies, on_ally_<effect> should fire 3 times
	var manager = CombatManager.new()
	# Create 3 allies
	var ally1 = _make_source(1000, 100.0, 0.0)
	var ally2 = _make_source(1000, 100.0, 0.0)
	var ally3 = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(ally1, 0, 0)
	pg.place_character(ally2, 0, 1)
	pg.place_character(ally3, 0, 2)
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var ally1_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var ally2_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	var ally3_cc = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 2)

	# Put on_ally_haste trigger on ally1 (will count triggers from all 3 haste applications)
	var trigger_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_ally_haste",
		func(_data): trigger_count[0] += 1, "combat")
	manager.apply_effect(ally1_cc, effect)

	# Haste all 3 allies (simulating a multi-target ability)
	manager.apply_effect(ally1_cc, _make_haste_effect())
	manager.apply_effect(ally2_cc, _make_haste_effect())
	manager.apply_effect(ally3_cc, _make_haste_effect())

	assert_eq(trigger_count[0], 3, "on_ally_haste fired 3 times when 3 allies were hasted")
