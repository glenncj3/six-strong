extends "res://tests/base_test.gd"
# Tests for run-time triggered abilities - on_recruit, on_ally_recruit

const RunTriggeredAbilitiesScript = preload("res://scripts/managers/run_triggered_abilities.gd")
const GridBonusCalculatorScript = preload("res://scripts/utils/grid_bonus_calculator.gd")


func _init():
	test_name = "Run Triggered Abilities Tests"
	super()


func _run_tests():
	section("on_recruit Trigger")
	test_on_recruit_buff_stat_self()
	test_on_recruit_heal_self()
	test_on_recruit_buff_stat_ally_all()

	section("on_ally_recruit Trigger")
	test_on_ally_recruit_fires_on_existing_allies()
	test_on_ally_recruit_fires_on_new_recruit()
	test_on_ally_recruit_buff_all_allies()

	section("Target Modes")
	test_target_mode_self()
	test_target_mode_recruited()
	test_target_mode_ally_all()
	test_target_mode_ally_other()

	section("Actions")
	test_action_buff_stat_flat()
	test_action_buff_stat_percent()
	test_action_heal()
	test_action_buff_health_updates_current()


# =============================================================================
# HELPERS
# =============================================================================

func _make_character(char_id: String, health: int = 100, damage: int = 10) -> CharacterInstance:
	var ch = CharacterInstance.new()
	ch.base_character_id = char_id
	ch.stats = {
		"health": health,
		"damage": damage,
		"speed": 1.0,
		"crit_chance": 0.0,
	}
	ch.current_health = health
	return ch


# =============================================================================
# on_recruit Trigger
# =============================================================================

func test_on_recruit_buff_stat_self():
	# on_recruit with buff_stat targeting self should buff the recruited character
	var recruited = _make_character("test_recruit", 100, 10)
	var all_chars = [recruited]

	var ability = {
		"type": "triggered",
		"trigger": "on_recruit",
		"target_mode": "self",
		"action": "buff_stat",
		"buff_stat": "damage",
		"buff_modifier_type": "flat",
		"buff_value": 5,
	}

	# Simulate the ability execution directly
	RunTriggeredAbilitiesScript._execute_triggered_ability(recruited, ability, recruited, all_chars, null)

	assert_eq(recruited.stats["damage"], 15, "on_recruit buff_stat self increased damage to 15")


func test_on_recruit_heal_self():
	var recruited = _make_character("test_recruit", 100, 10)
	recruited.current_health = 50  # Damage the character
	var all_chars = [recruited]

	var ability = {
		"type": "triggered",
		"trigger": "on_recruit",
		"target_mode": "self",
		"action": "heal",
		"heal_value": 30,
	}

	RunTriggeredAbilitiesScript._execute_triggered_ability(recruited, ability, recruited, all_chars, null)

	assert_eq(recruited.current_health, 80, "on_recruit heal self restored 30 hp")


func test_on_recruit_buff_stat_ally_all():
	var recruited = _make_character("test_recruit", 100, 10)
	var ally1 = _make_character("ally1", 100, 20)
	var ally2 = _make_character("ally2", 100, 15)
	var all_chars = [ally1, ally2, recruited]

	var ability = {
		"type": "triggered",
		"trigger": "on_recruit",
		"target_mode": "ally_all",
		"action": "buff_stat",
		"buff_stat": "damage",
		"buff_modifier_type": "flat",
		"buff_value": 3,
	}

	RunTriggeredAbilitiesScript._execute_triggered_ability(recruited, ability, recruited, all_chars, null)

	assert_eq(ally1.stats["damage"], 23, "ally1 gained +3 damage")
	assert_eq(ally2.stats["damage"], 18, "ally2 gained +3 damage")
	assert_eq(recruited.stats["damage"], 13, "recruited gained +3 damage")


# =============================================================================
# on_ally_recruit Trigger
# =============================================================================

func test_on_ally_recruit_fires_on_existing_allies():
	# When a new character is recruited, on_ally_recruit on existing allies should fire
	var existing = _make_character("existing", 100, 10)
	var recruited = _make_character("new_recruit", 100, 10)
	var all_chars = [existing, recruited]

	# Ability on the existing character that triggers on_ally_recruit
	var ability = {
		"type": "triggered",
		"trigger": "on_ally_recruit",
		"target_mode": "self",
		"action": "buff_stat",
		"buff_stat": "damage",
		"buff_modifier_type": "flat",
		"buff_value": 2,
	}

	# This simulates the existing character's on_ally_recruit trigger firing
	RunTriggeredAbilitiesScript._execute_triggered_ability(existing, ability, recruited, all_chars, null)

	assert_eq(existing.stats["damage"], 12, "existing character gained +2 damage from on_ally_recruit")


func test_on_ally_recruit_fires_on_new_recruit():
	# on_ally_recruit should also fire on the newly recruited character itself
	var recruited = _make_character("new_recruit", 100, 10)
	var all_chars = [recruited]

	var ability = {
		"type": "triggered",
		"trigger": "on_ally_recruit",
		"target_mode": "self",
		"action": "buff_stat",
		"buff_stat": "damage",
		"buff_modifier_type": "flat",
		"buff_value": 5,
	}

	RunTriggeredAbilitiesScript._execute_triggered_ability(recruited, ability, recruited, all_chars, null)

	assert_eq(recruited.stats["damage"], 15, "new recruit gained +5 damage from own on_ally_recruit")


func test_on_ally_recruit_buff_all_allies():
	var existing1 = _make_character("existing1", 100, 10)
	var existing2 = _make_character("existing2", 100, 15)
	var recruited = _make_character("new_recruit", 100, 20)
	var all_chars = [existing1, existing2, recruited]

	# Existing character buffs all allies when someone is recruited
	var ability = {
		"type": "triggered",
		"trigger": "on_ally_recruit",
		"target_mode": "ally_all",
		"action": "buff_stat",
		"buff_stat": "health",
		"buff_modifier_type": "flat",
		"buff_value": 10,
	}

	RunTriggeredAbilitiesScript._execute_triggered_ability(existing1, ability, recruited, all_chars, null)

	assert_eq(existing1.stats["health"], 110, "existing1 gained +10 health")
	assert_eq(existing2.stats["health"], 110, "existing2 gained +10 health")
	assert_eq(recruited.stats["health"], 110, "recruited gained +10 health")


# =============================================================================
# Target Modes
# =============================================================================

func test_target_mode_self():
	var source = _make_character("source", 100, 10)
	var recruited = _make_character("recruited", 100, 20)
	var all_chars = [source, recruited]

	var targets = RunTriggeredAbilitiesScript._resolve_targets(source, "self", recruited, all_chars)

	assert_eq(targets.size(), 1, "self mode returns 1 target")
	assert_true(targets.has(source), "self mode returns the source")


func test_target_mode_recruited():
	var source = _make_character("source", 100, 10)
	var recruited = _make_character("recruited", 100, 20)
	var all_chars = [source, recruited]

	var targets = RunTriggeredAbilitiesScript._resolve_targets(source, "recruited", recruited, all_chars)

	assert_eq(targets.size(), 1, "recruited mode returns 1 target")
	assert_true(targets.has(recruited), "recruited mode returns the recruited character")


func test_target_mode_ally_all():
	var source = _make_character("source", 100, 10)
	var recruited = _make_character("recruited", 100, 20)
	var other = _make_character("other", 100, 15)
	var all_chars = [source, recruited, other]

	var targets = RunTriggeredAbilitiesScript._resolve_targets(source, "ally_all", recruited, all_chars)

	assert_eq(targets.size(), 3, "ally_all mode returns all characters")


func test_target_mode_ally_other():
	var source = _make_character("source", 100, 10)
	var recruited = _make_character("recruited", 100, 20)
	var other = _make_character("other", 100, 15)
	var all_chars = [source, recruited, other]

	var targets = RunTriggeredAbilitiesScript._resolve_targets(source, "ally_other", recruited, all_chars)

	assert_eq(targets.size(), 2, "ally_other mode returns 2 targets")
	assert_false(targets.has(source), "ally_other mode excludes the source")
	assert_true(targets.has(recruited), "ally_other mode includes recruited")
	assert_true(targets.has(other), "ally_other mode includes other")


# =============================================================================
# Actions
# =============================================================================

func test_action_buff_stat_flat():
	var char1 = _make_character("test", 100, 10)
	var targets = [char1]

	var ability = {
		"buff_stat": "damage",
		"buff_modifier_type": "flat",
		"buff_value": 7,
	}

	RunTriggeredAbilitiesScript._action_buff_stat(char1, ability, targets)

	assert_eq(char1.stats["damage"], 17, "flat buff added 7 damage")


func test_action_buff_stat_percent():
	var char1 = _make_character("test", 100, 20)
	var targets = [char1]

	var ability = {
		"buff_stat": "damage",
		"buff_modifier_type": "percent",
		"buff_value": 0.5,  # 50% increase
	}

	RunTriggeredAbilitiesScript._action_buff_stat(char1, ability, targets)

	assert_eq(char1.stats["damage"], 30, "percent buff increased damage by 50%")


func test_action_heal():
	var char1 = _make_character("test", 100, 10)
	char1.current_health = 40
	var targets = [char1]

	var ability = {
		"heal_value": 25,
	}

	RunTriggeredAbilitiesScript._action_heal(char1, ability, targets)

	assert_eq(char1.current_health, 65, "heal restored 25 hp")


func test_action_buff_health_updates_current():
	var char1 = _make_character("test", 100, 10)
	char1.current_health = 80  # Not at full health
	var targets = [char1]

	var ability = {
		"buff_stat": "health",
		"buff_modifier_type": "flat",
		"buff_value": 20,
	}

	RunTriggeredAbilitiesScript._action_buff_stat(char1, ability, targets)

	assert_eq(char1.stats["health"], 120, "max health increased to 120")
	assert_eq(char1.current_health, 100, "current health increased by buff amount (capped at max)")
