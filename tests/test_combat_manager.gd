extends "res://tests/base_test.gd"
# Tests for CombatManager - real-time cooldown-based combat

func _init():
	test_name = "CombatManager Tests"
	super()


func _run_tests():
	section("Initialization")
	test_initialize_creates_state()
	test_characters_cloned_to_board()

	section("Cooldown Mechanics")
	test_cooldown_ticks_down()
	test_character_acts_after_cooldown()

	section("Damage Resolution")
	test_damage_dealt_no_block_no_crit()
	test_block_negates_damage()
	test_crit_doubles_damage()

	section("Death & Cleanup")
	test_character_dies_at_zero_health()

	section("Win Conditions")
	test_player_wins()
	test_opponent_wins()
	test_stalemate_draw()
	test_mutual_kill_draw()

	section("Effect Management")
	test_apply_effect_via_manager()
	test_remove_effect_on_seconds_expiry()
	test_remove_effect_on_cooldown_expiry()
	test_permanent_effect_persists()
	test_combat_effect_persists()
	test_effects_removed_when_source_dies()
	test_effects_cleared_on_dead_character()

	section("Triggered Effects")
	test_on_cooldown_triggered_effect()
	test_on_death_triggered_effect()
	test_on_ally_death_triggered_effect()
	test_on_enemy_death_triggered_effect()
	test_on_damage_taken_triggered_effect()

	section("Healing")
	test_heal_character()
	test_heal_caps_at_max()
	test_heal_dead_character_ignored()

	section("Multi-Character Combat")
	test_multi_character_targeting()
	test_front_back_row_targeting_in_combat()

	section("Stalemate Edge Cases")
	test_stalemate_speed_no_damage()
	test_no_stalemate_with_damage_effect()

	section("Signals")
	test_combat_started_signal()
	test_damage_dealt_signal()
	test_combat_ended_signal()
	test_character_died_signal()
	test_damage_taken_signal()
	test_damage_blocked_signal()
	test_effect_applied_signal()
	test_effect_removed_signal()
	test_character_healed_signal()

	section("Cooldown Reset")
	test_cooldown_resets_to_speed()

	section("Status Effect Merging")
	test_merge_add_stacks()
	test_merge_refresh_duration()
	test_merge_extend_duration()

	section("Tick Events")
	test_tick_event_calls_on_tick()

	section("Cleanse")
	test_cleanse_removes_debuffs_not_buffs()

	section("Status Triggers")
	test_on_status_trigger_fires()


# =============================================================================
# HELPERS
# =============================================================================

func _make_source(hp: int, spd: float, dmg: float, def_rate: float = 0.0, crit: float = 0.0) -> CharacterInstance:
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


# =============================================================================
# TESTS
# =============================================================================

func test_initialize_creates_state():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	assert_not_null(manager.get_state(), "state created")
	assert_true(manager.get_state().combat_active, "combat is active")
	assert_null(manager.get_state().winner, "no winner yet")


func test_characters_cloned_to_board():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(80, 3.0, 15.0))
	manager.initialize_combat(pg, eg)

	var player_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy_ch = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_not_null(player_ch, "player character on board")
	assert_not_null(enemy_ch, "enemy character on board")
	assert_eq(player_ch.max_health, 100.0, "player hp correct")
	assert_eq(enemy_ch.max_health, 80.0, "enemy hp correct")


func test_cooldown_ticks_down():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 5.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 5.0, 1.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var initial_cd = ch.cooldown_remaining
	assert_eq(initial_cd, 5.0, "cooldown starts at speed")

	_simulate_time(manager, 1.0)
	# Cooldown should have decreased by ~1.0
	assert_true(ch.cooldown_remaining < initial_cd, "cooldown decreased after 1s")


func test_character_acts_after_cooldown():
	var manager = CombatManager.new()
	# Player: speed 2.0, damage 10. Enemy: lots of HP, slow
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_eq(enemy.health, 1000.0, "enemy starts full")

	# After 2.1 seconds, player should have acted once
	_simulate_time(manager, 2.1)
	assert_true(enemy.health < 1000.0, "enemy took damage after player cooldown")


func test_damage_dealt_no_block_no_crit():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 25.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	_simulate_time(manager, 1.1)
	assert_eq(enemy.health, 975.0, "exact 25 damage dealt")


func test_block_negates_damage():
	# 100% defend rate should always block
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 25.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 1.0, 0.0))  # 100% def
	manager.initialize_combat(pg, eg)

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	_simulate_time(manager, 1.1)
	assert_eq(enemy.health, 1000.0, "100% defend blocks all damage")


func test_crit_doubles_damage():
	# 100% crit chance, 0% defend
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 25.0, 0.0, 1.0))  # 100% crit
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	_simulate_time(manager, 1.1)
	assert_eq(enemy.health, 950.0, "crit doubles: 25 * 2 = 50 damage")


func test_character_dies_at_zero_health():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 999.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(10, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 1.1)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_false(enemy.is_alive, "enemy dies from lethal damage")
	assert_eq(enemy.health, 0.0, "health clamped to 0")


func test_player_wins():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	var eg = _make_grid_with_one(_make_source(10, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 2.0)
	assert_false(manager.get_state().combat_active, "combat ended")
	assert_eq(manager.get_state().winner, GameConstants.TEAM_PLAYER, "player wins")


func test_opponent_wins():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(10, 100.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 2.0)
	assert_false(manager.get_state().combat_active, "combat ended")
	assert_eq(manager.get_state().winner, GameConstants.TEAM_OPPONENT, "opponent wins")


func test_stalemate_draw():
	# Both characters have no damage and no speed — stalemate
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(100, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 0.1)
	assert_false(manager.get_state().combat_active, "stalemate detected")
	assert_eq(manager.get_state().winner, GameConstants.WINNER_DRAW, "draw from stalemate")


func test_mutual_kill_draw():
	# Both have speed 1.0 and enough damage to one-shot each other.
	# get_all_living_characters snapshots at start of tick, so both act
	# even if the first kill happens mid-iteration. Both die = draw.
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(10, 1.0, 999.0))
	var eg = _make_grid_with_one(_make_source(10, 1.0, 999.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 1.1, 0.01)
	assert_false(manager.get_state().combat_active, "combat ended")
	assert_eq(manager.get_state().winner, GameConstants.WINNER_DRAW, "mutual kill = draw")


func test_combat_started_signal():
	var manager = CombatManager.new()
	var received = [false]
	manager.combat_started.connect(func(_s): received[0] = true)

	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	assert_true(received[0], "combat_started signal emitted")


func test_damage_dealt_signal():
	var manager = CombatManager.new()
	var dmg_events: Array = []
	manager.damage_dealt.connect(func(src, tgt, amt, crit):
		dmg_events.append({"source": src, "target": tgt, "amount": amt, "is_crit": crit})
	)

	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 1.1)
	assert_true(dmg_events.size() > 0, "damage_dealt signal fired")
	assert_eq(dmg_events[0]["amount"], 10.0, "correct damage amount in signal")
	assert_false(dmg_events[0]["is_crit"], "not a crit")


func test_combat_ended_signal():
	var manager = CombatManager.new()
	var ended = [false]
	var winner_val = [-1]
	manager.combat_ended.connect(func(w, _r):
		ended[0] = true
		winner_val[0] = w
	)

	var pg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	var eg = _make_grid_with_one(_make_source(10, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 2.0)
	assert_true(ended[0], "combat_ended signal fired")
	assert_eq(winner_val[0], GameConstants.TEAM_PLAYER, "player won")


func test_character_died_signal():
	var manager = CombatManager.new()
	var died_chars: Array = []
	manager.character_died.connect(func(ch): died_chars.append(ch))

	var pg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	var eg = _make_grid_with_one(_make_source(10, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 1.1)
	assert_eq(died_chars.size(), 1, "character_died signal fired once")
	assert_eq(died_chars[0].team, GameConstants.TEAM_OPPONENT, "opponent character died")


func test_damage_taken_signal():
	var manager = CombatManager.new()
	var taken_events: Array = []
	manager.damage_taken.connect(func(tgt, amt, src):
		taken_events.append({"target": tgt, "amount": amt, "source": src})
	)

	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 1.1)
	assert_true(taken_events.size() > 0, "damage_taken signal fired")
	assert_eq(taken_events[0]["amount"], 10.0, "correct damage amount")


func test_damage_blocked_signal():
	var manager = CombatManager.new()
	var blocked_events: Array = []
	manager.damage_blocked.connect(func(src, tgt):
		blocked_events.append({"source": src, "target": tgt})
	)

	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 1.0, 0.0))  # 100% defend
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 1.1)
	assert_true(blocked_events.size() > 0, "damage_blocked signal fired")


func test_effect_applied_signal():
	var manager = CombatManager.new()
	var applied_events: Array = []
	manager.effect_applied.connect(func(tgt, eff):
		applied_events.append({"target": tgt, "effect": eff})
	)

	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "combat")
	manager.apply_effect(ch, effect)

	assert_eq(applied_events.size(), 1, "effect_applied signal fired")
	assert_eq(applied_events[0]["effect"], effect, "correct effect in signal")


func test_effect_removed_signal():
	var manager = CombatManager.new()
	var removed_events: Array = []
	manager.effect_removed.connect(func(tgt, eff):
		removed_events.append({"target": tgt, "effect": eff})
	)

	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "seconds", 0.5)
	manager.apply_effect(ch, effect)

	_simulate_time(manager, 1.0)
	assert_true(removed_events.size() > 0, "effect_removed signal fired after expiry")


func test_character_healed_signal():
	var manager = CombatManager.new()
	var heal_events: Array = []
	manager.character_healed.connect(func(tgt, amt, src):
		heal_events.append({"target": tgt, "amount": amt, "source": src})
	)

	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	player.health = 50.0
	manager.heal_character(player, 20.0, enemy)

	assert_eq(heal_events.size(), 1, "character_healed signal fired")
	assert_eq(heal_events[0]["amount"], 20.0, "healed for 20")


# =============================================================================
# EFFECT MANAGEMENT
# =============================================================================

func test_apply_effect_via_manager():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "combat")
	manager.apply_effect(ch, effect)

	assert_eq(ch.effects.size(), 1, "effect added to character")
	assert_eq(ch.damage, 15.0, "stat recalculated: 10 + 5 = 15")


func test_remove_effect_on_seconds_expiry():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 10.0, "flat", "seconds", 1.0)
	manager.apply_effect(ch, effect)
	assert_eq(ch.damage, 11.0, "effect active: 1 + 10 = 11")

	_simulate_time(manager, 1.5)
	assert_eq(ch.effects.size(), 0, "effect removed after expiry")
	assert_eq(ch.damage, 1.0, "stat reverted to base")


func test_remove_effect_on_cooldown_expiry():
	var manager = CombatManager.new()
	# Speed 1.0 so cooldown triggers every second
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 10.0, "flat", "cooldowns", 2.0)
	manager.apply_effect(ch, effect)
	assert_eq(ch.damage, 11.0, "effect active")

	# After 2 cooldown triggers, effect should expire
	_simulate_time(manager, 2.5)  # 2 cooldowns at speed 1.0
	assert_eq(ch.effects.size(), 0, "effect removed after 2 cooldowns")
	assert_eq(ch.damage, 1.0, "stat reverted")


func test_permanent_effect_persists():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 10.0, "flat", "permanent")
	manager.apply_effect(ch, effect)

	_simulate_time(manager, 5.0)
	assert_eq(ch.effects.size(), 1, "permanent effect still present")
	assert_eq(ch.damage, 11.0, "permanent effect still active")


func test_combat_effect_persists():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 10.0, "flat", "combat")
	manager.apply_effect(ch, effect)

	_simulate_time(manager, 5.0)
	assert_eq(ch.effects.size(), 1, "combat-duration effect still present")
	assert_eq(ch.damage, 11.0, "combat-duration effect still active")


func test_effects_removed_when_source_dies():
	var manager = CombatManager.new()
	# Two player characters: a buffer and a fighter
	var buffer_src = _make_source(10, 100.0, 0.0)  # Will die fast
	var fighter_src = _make_source(1000, 1.0, 10.0)
	var pg = CharacterGrid.new()
	pg.place_character(fighter_src, 0, 0)
	pg.place_character(buffer_src, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 1.0, 50.0))
	manager.initialize_combat(pg, eg)

	var fighter = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var buffer = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)

	# Buffer gives fighter a damage buff
	var effect = CombatEffect.create_stat_modifier("character", buffer.id, "damage", 100.0, "flat", "permanent")
	manager.apply_effect(fighter, effect)
	assert_eq(fighter.damage, 110.0, "buff applied: 10 + 100 = 110")

	# Kill the buffer directly
	manager._apply_damage(buffer, 999.0, null)
	assert_false(buffer.is_alive, "buffer died")
	assert_eq(fighter.effects.size(), 0, "effect removed when source died")
	assert_eq(fighter.damage, 10.0, "stat reverted after source death")


func test_effects_cleared_on_dead_character():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(10, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect = CombatEffect.create_stat_modifier("test", "t1", "damage", 5.0, "flat", "combat")
	manager.apply_effect(player, effect)
	assert_eq(player.effects.size(), 1, "effect on character before death")

	_simulate_time(manager, 1.1)
	assert_false(player.is_alive, "player died")
	assert_eq(player.effects.size(), 0, "effects cleared on dead character")


# =============================================================================
# TRIGGERED EFFECTS
# =============================================================================

func test_on_cooldown_triggered_effect():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 0.0))  # No damage, just has speed
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var triggered_count = [0]
	var effect = CombatEffect.create_triggered("test", "t1", "on_cooldown",
		func(_data): triggered_count[0] += 1, "combat")
	manager.apply_effect(ch, effect)

	_simulate_time(manager, 2.5)
	assert_true(triggered_count[0] >= 2, "on_cooldown triggered at least twice")


func test_on_death_triggered_effect():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(10, 100.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var death_triggered = [false]
	var effect = CombatEffect.create_triggered("test", "t1", "on_death",
		func(_data): death_triggered[0] = true, "combat")
	manager.apply_effect(player, effect)

	_simulate_time(manager, 1.1)
	assert_false(player.is_alive, "player died")
	assert_true(death_triggered[0], "on_death effect triggered")


func test_on_ally_death_triggered_effect():
	var manager = CombatManager.new()
	var weak_src = _make_source(10, 100.0, 0.0)
	var strong_src = _make_source(1000, 100.0, 0.0)
	var pg = CharacterGrid.new()
	pg.place_character(weak_src, 0, 0)
	pg.place_character(strong_src, 0, 1)
	var eg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	manager.initialize_combat(pg, eg)

	var strong = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 1)
	var ally_died_data = [null]
	var effect = CombatEffect.create_triggered("test", "t1", "on_ally_death",
		func(data): ally_died_data[0] = data, "combat")
	manager.apply_effect(strong, effect)

	_simulate_time(manager, 1.1)
	assert_not_null(ally_died_data[0], "on_ally_death triggered")
	assert_true(ally_died_data[0].has("dead_character"), "data has dead_character")


func test_on_enemy_death_triggered_effect():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 999.0))
	var eg = _make_grid_with_one(_make_source(10, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy_died_data = [null]
	var effect = CombatEffect.create_triggered("test", "t1", "on_enemy_death",
		func(data): enemy_died_data[0] = data, "combat")
	manager.apply_effect(player, effect)

	_simulate_time(manager, 1.1)
	assert_not_null(enemy_died_data[0], "on_enemy_death triggered")
	assert_true(enemy_died_data[0].has("dead_character"), "data has dead_character")


func test_on_damage_taken_triggered_effect():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 100.0, 0.0, 0.0, 0.0))
	var eg = _make_grid_with_one(_make_source(1000, 1.0, 10.0, 0.0, 0.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var taken_data = [null]
	var effect = CombatEffect.create_triggered("test", "t1", "on_damage_taken",
		func(data): taken_data[0] = data, "combat")
	manager.apply_effect(player, effect)

	_simulate_time(manager, 1.1)
	assert_not_null(taken_data[0], "on_damage_taken triggered")
	assert_true(taken_data[0].has("amount"), "data has amount")
	assert_eq(taken_data[0]["amount"], 10.0, "correct damage amount in trigger data")


# =============================================================================
# HEALING
# =============================================================================

func test_heal_character():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	player.health = 50.0
	manager.heal_character(player, 30.0, enemy)
	assert_eq(player.health, 80.0, "healed from 50 to 80")


func test_heal_caps_at_max():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	player.health = 90.0
	manager.heal_character(player, 50.0, enemy)
	assert_eq(player.health, 100.0, "heal capped at max_health")


func test_heal_dead_character_ignored():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var player = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	player.health = 0.0
	player.is_alive = false
	manager.heal_character(player, 50.0, enemy)
	assert_eq(player.health, 0.0, "dead character not healed")


# =============================================================================
# MULTI-CHARACTER COMBAT
# =============================================================================

func test_multi_character_targeting():
	# 3 player characters vs 1 enemy, enemy should die fast
	var manager = CombatManager.new()
	var pg = CharacterGrid.new()
	pg.place_character(_make_source(1000, 1.0, 10.0), 0, 0)
	pg.place_character(_make_source(1000, 1.0, 10.0), 0, 1)
	pg.place_character(_make_source(1000, 1.0, 10.0), 0, 2)
	var eg = _make_grid_with_one(_make_source(25, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 1.1)
	var enemy = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	assert_false(enemy.is_alive, "enemy killed by 3 attackers (30 damage vs 25 hp)")
	assert_eq(manager.get_state().winner, GameConstants.TEAM_PLAYER, "player wins")


func test_front_back_row_targeting_in_combat():
	# Enemy in front row should be targeted before back row
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 1.0, 10.0))
	var eg = CharacterGrid.new()
	eg.place_character(_make_source(100, 100.0, 0.0), 0, 0)  # front
	eg.place_character(_make_source(100, 100.0, 0.0), 1, 0)  # back
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 1.1)
	var front = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 0, 0)
	var back = manager.get_state().board.get_character_at(GameConstants.TEAM_OPPONENT, 1, 0)
	assert_true(front.health < 100.0, "front row took damage")
	assert_eq(back.health, 100.0, "back row untouched while front alive")


# =============================================================================
# STALEMATE EDGE CASES
# =============================================================================

func test_stalemate_speed_no_damage():
	# Characters have speed but no damage = stalemate
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 2.0, 0.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 0.0))
	manager.initialize_combat(pg, eg)

	_simulate_time(manager, 0.1)
	assert_false(manager.get_state().combat_active, "stalemate detected")
	assert_eq(manager.get_state().winner, GameConstants.WINNER_DRAW, "draw from stalemate")


func test_no_stalemate_with_damage_effect():
	# Character has no damage stat but has on_cooldown triggered effect = not stalemate
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(100, 2.0, 0.0))
	var eg = _make_grid_with_one(_make_source(100, 2.0, 0.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect = CombatEffect.create_triggered("test", "t1", "on_cooldown",
		func(_data): pass, "combat")
	manager.apply_effect(ch, effect)

	# Need to manually re-check since stalemate may have already fired
	# Re-initialize to test properly
	var manager2 = CombatManager.new()
	var pg2 = _make_grid_with_one(_make_source(100, 2.0, 0.0))
	var eg2 = _make_grid_with_one(_make_source(100, 2.0, 0.0))
	manager2.initialize_combat(pg2, eg2)

	# Apply effect before first update
	var ch2 = manager2.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var effect2 = CombatEffect.create_triggered("test", "t1", "on_cooldown",
		func(_data): pass, "combat")
	ch2.effects.append(effect2)

	_simulate_time(manager2, 0.1)
	assert_true(manager2.get_state().combat_active, "combat still active with damage-dealing effect")


# =============================================================================
# COOLDOWN RESET
# =============================================================================

func test_cooldown_resets_to_speed():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 3.0, 1.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 1.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	assert_eq(ch.cooldown_remaining, 3.0, "starts at speed")

	# After one cooldown trigger, should reset to speed value
	_simulate_time(manager, 3.1, 0.05)
	# With discrete steps, cooldown won't be exactly 3.0 but should be close
	# (it resets to speed, then decrements by remaining delta in that tick)
	assert_true(ch.cooldown_remaining > 2.5 and ch.cooldown_remaining <= 3.0, "cooldown resets near speed value")


# =============================================================================
# STATUS EFFECT MERGING
# =============================================================================

func test_merge_add_stacks():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var e1 = CombatEffect.create_status_effect({
		"effect_id": "poison", "stacks": 3, "max_stacks": 10,
		"merge_behavior": "add_stacks", "tags": ["debuff"],
	})
	var e2 = CombatEffect.create_status_effect({
		"effect_id": "poison", "stacks": 4, "max_stacks": 10,
		"merge_behavior": "add_stacks", "tags": ["debuff"],
	})
	manager.apply_effect(ch, e1)
	manager.apply_effect(ch, e2)

	assert_eq(ch.effects.size(), 1, "only 1 effect (merged)")
	assert_eq(ch.get_stacks("poison"), 7, "stacks merged: 3 + 4 = 7")


func test_merge_refresh_duration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var e1 = CombatEffect.create_status_effect({
		"effect_id": "haste", "merge_behavior": "refresh_duration",
		"duration_type": "seconds", "duration_value": 5.0,
	})
	manager.apply_effect(ch, e1)

	# Simulate some time passing
	_simulate_time(manager, 2.0)

	var e2 = CombatEffect.create_status_effect({
		"effect_id": "haste", "merge_behavior": "refresh_duration",
		"duration_type": "seconds", "duration_value": 5.0,
	})
	manager.apply_effect(ch, e2)

	assert_eq(ch.effects.size(), 1, "still 1 effect")
	assert_true(ch.get_effect("haste").duration_value > 4.5, "duration refreshed to 5.0")


func test_merge_extend_duration():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var e1 = CombatEffect.create_status_effect({
		"effect_id": "shield", "merge_behavior": "extend_duration",
		"duration_type": "seconds", "duration_value": 5.0,
	})
	manager.apply_effect(ch, e1)

	var e2 = CombatEffect.create_status_effect({
		"effect_id": "shield", "merge_behavior": "extend_duration",
		"duration_type": "seconds", "duration_value": 3.0,
	})
	manager.apply_effect(ch, e2)

	assert_eq(ch.effects.size(), 1, "still 1 effect")
	assert_true(abs(ch.get_effect("shield").duration_value - 8.0) < 0.01, "duration extended: 5 + 3 = 8")


# =============================================================================
# TICK EVENTS
# =============================================================================

func test_tick_event_calls_on_tick():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 100.0, 0.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var tick_count = [0]
	var tick_fn = func(_ctx): tick_count[0] += 1
	var effect = CombatEffect.create_status_effect({
		"effect_id": "dot", "tick_interval": 1.0, "on_tick": tick_fn,
		"tags": ["debuff", "dot"],
	})
	manager.apply_effect(ch, effect)

	_simulate_time(manager, 2.5)
	assert_true(tick_count[0] >= 2, "on_tick called at least twice in 2.5s")


# =============================================================================
# CLEANSE
# =============================================================================

func test_cleanse_removes_debuffs_not_buffs():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var poison = CombatEffect.create_status_effect({
		"effect_id": "poison", "tags": ["debuff", "dot"], "stacks": 3,
	})
	var haste = CombatEffect.create_status_effect({
		"effect_id": "haste", "tags": ["buff", "speed"],
		"continuous_modifier": "cooldown_tick_rate", "continuous_value": 2.0,
	})
	manager.apply_effect(ch, poison)
	manager.apply_effect(ch, haste)
	assert_eq(ch.effects.size(), 2, "2 effects before cleanse")

	var removed = manager.cleanse_effects_by_tag(ch, "debuff")
	assert_eq(removed.size(), 1, "removed 1 debuff")
	assert_eq(ch.effects.size(), 1, "1 effect remaining")
	assert_true(ch.has_effect("haste"), "haste still present")
	assert_false(ch.has_effect("poison"), "poison removed")


# =============================================================================
# STATUS TRIGGERS
# =============================================================================

func test_on_status_trigger_fires():
	var manager = CombatManager.new()
	var pg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	var eg = _make_grid_with_one(_make_source(1000, 2.0, 10.0))
	manager.initialize_combat(pg, eg)

	var ch = manager.get_state().board.get_character_at(GameConstants.TEAM_PLAYER, 0, 0)
	var triggered = [false]
	var trigger_effect = CombatEffect.create_triggered("test", "t1", "on_poison",
		func(_data): triggered[0] = true, "combat")
	manager.apply_effect(ch, trigger_effect)

	var poison = CombatEffect.create_status_effect({
		"effect_id": "poison", "tags": ["debuff"], "stacks": 3,
	})
	manager.apply_effect(ch, poison)
	assert_true(triggered[0], "on_poison trigger fired when poison applied")
