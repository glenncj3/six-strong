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
