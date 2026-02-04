extends "res://tests/base_test.gd"
## Unit tests for stat buff building blocks.
## Tests StatModifier, SkillTargetResolver, SkillTargetValidator, and StatBuffEffect.
##
## Run with:
##   godot --headless --script res://tests/unit/test_stat_buff_building_blocks.gd


func _init():
	test_name = "Stat Buff Building Blocks Tests"
	super()


func _run_tests():
	# StatModifier tests
	section("StatModifier")
	_test_stat_modifier_from_dict()
	_test_stat_modifier_flat_apply()
	_test_stat_modifier_percent_apply()
	_test_stat_modifier_health_increases_current()
	_test_stat_modifier_description()
	_test_stat_modifier_validation()

	# SkillTargetResolver tests
	section("SkillTargetResolver")
	_test_resolver_dropped_mode()
	_test_resolver_all_mode()
	_test_resolver_all_except_dropped_mode()
	_test_resolver_row_of_dropped_mode()
	_test_resolver_adjacent_to_dropped_mode()
	_test_resolver_requires_drop_target()
	_test_resolver_mode_description()

	# SkillTargetValidator tests
	section("SkillTargetValidator")
	_test_validator_null_target()
	_test_validator_dead_target()
	_test_validator_front_row_requirement()
	_test_validator_back_row_requirement()
	_test_validator_error_messages()

	# StatBuffEffect tests
	section("StatBuffEffect")
	_test_stat_buff_effect_from_dict()
	_test_stat_buff_effect_execute()
	_test_stat_buff_effect_multiple_modifiers()
	_test_stat_buff_effect_all_targets()
	_test_stat_buff_effect_description()
	_test_stat_buff_effect_validation()

	# Integration tests
	section("Integration")
	_test_skill_effects_stat_buff_registered()
	_test_execute_stat_buff_via_registry()
	_test_multi_effect_skill()
	_test_skills_json_stat_buff_skills()


# =============================================================================
# STAT MODIFIER TESTS
# =============================================================================

func _test_stat_modifier_from_dict():
	var data = {"stat": "health", "modifier_type": "flat", "value": 15}
	var modifier = StatModifier.from_dict(data)

	assert_eq(modifier.stat, "health", "stat should be 'health'")
	assert_eq(modifier.modifier_type, "flat", "modifier_type should be 'flat'")
	assert_eq(modifier.value, 15.0, "value should be 15")


func _test_stat_modifier_flat_apply():
	var modifier = StatModifier.from_dict({"stat": "damage", "modifier_type": "flat", "value": 10})
	var character = _make_char({"damage": 50})

	modifier.apply_to(character)

	assert_eq(character.stats["damage"], 60, "damage should be 50 + 10 = 60")


func _test_stat_modifier_percent_apply():
	var modifier = StatModifier.from_dict({"stat": "damage", "modifier_type": "percent", "value": 0.2})
	var character = _make_char({"damage": 50})

	modifier.apply_to(character)

	assert_eq(character.stats["damage"], 60, "damage should be 50 * 1.2 = 60")


func _test_stat_modifier_health_increases_current():
	var modifier = StatModifier.from_dict({"stat": "health", "modifier_type": "flat", "value": 20})
	var character = _make_char({"health": 100}, 80)

	modifier.apply_to(character)

	assert_eq(character.stats["health"], 120, "max health should be 120")
	assert_eq(character.current_health, 100, "current_health should increase by 20 (80 + 20)")


func _test_stat_modifier_description():
	var flat_mod = StatModifier.from_dict({"stat": "health", "modifier_type": "flat", "value": 15})
	var percent_mod = StatModifier.from_dict({"stat": "damage", "modifier_type": "percent", "value": 0.2})
	var negative_mod = StatModifier.from_dict({"stat": "speed", "modifier_type": "flat", "value": -5})

	assert_has(flat_mod.get_description(), "+15", "flat description should contain '+15'")
	assert_has(percent_mod.get_description(), "+20%", "percent description should contain '+20%'")
	assert_has(negative_mod.get_description(), "-5", "negative description should contain '-5'")


func _test_stat_modifier_validation():
	var valid = StatModifier.from_dict({"stat": "health", "modifier_type": "flat", "value": 10})
	var no_stat = StatModifier.from_dict({"stat": "", "modifier_type": "flat", "value": 10})
	var bad_type = StatModifier.from_dict({"stat": "health", "modifier_type": "invalid", "value": 10})

	assert_true(valid.is_valid(), "valid modifier should be valid")
	assert_false(no_stat.is_valid(), "modifier without stat should be invalid")
	assert_false(bad_type.is_valid(), "modifier with invalid type should be invalid")


# =============================================================================
# SKILL TARGET RESOLVER TESTS
# =============================================================================

func _test_resolver_dropped_mode():
	var chars = [_make_char(), _make_char(), _make_char()]
	var context = _make_context(chars)
	var drop_target = chars[0]

	var targets = SkillTargetResolver.resolve("dropped", drop_target, context)

	assert_eq(targets.size(), 1, "dropped mode should return 1 target")
	assert_eq(targets[0], drop_target, "dropped mode should return the drop target")


func _test_resolver_all_mode():
	var chars = [_make_char(), _make_char(), _make_char()]
	var context = _make_context(chars)

	var targets = SkillTargetResolver.resolve("all", null, context)

	assert_eq(targets.size(), 3, "all mode should return all 3 characters")


func _test_resolver_all_except_dropped_mode():
	var chars = [_make_char(), _make_char(), _make_char()]
	var context = _make_context(chars)
	var drop_target = chars[0]

	var targets = SkillTargetResolver.resolve("all_except_dropped", drop_target, context)

	assert_eq(targets.size(), 2, "all_except_dropped should return 2 characters")
	assert_false(targets.has(drop_target), "all_except_dropped should not include drop target")


func _test_resolver_row_of_dropped_mode():
	var chars = _make_grid_chars()
	var context = _make_context(chars)
	var drop_target = chars[0]  # Front row (0,0)

	var targets = SkillTargetResolver.resolve("row_of_dropped", drop_target, context)

	assert_eq(targets.size(), 2, "row_of_dropped should return 2 front row characters")
	for target in targets:
		assert_true(target.is_front_row(), "all targets should be in front row")


func _test_resolver_adjacent_to_dropped_mode():
	var chars = _make_grid_chars()
	var context = _make_context(chars)
	var drop_target = chars[0]  # Position (0,0)

	var targets = SkillTargetResolver.resolve("adjacent_to_dropped", drop_target, context)

	# Adjacent to (0,0): (0,1) and (1,0) - both occupied
	assert_eq(targets.size(), 2, "adjacent_to_dropped should return 2 adjacent characters")
	assert_false(targets.has(drop_target), "adjacent should not include drop target itself")


func _test_resolver_requires_drop_target():
	assert_true(SkillTargetResolver.requires_drop_target("dropped"), "dropped requires target")
	assert_false(SkillTargetResolver.requires_drop_target("all"), "all does not require target")
	assert_true(SkillTargetResolver.requires_drop_target("row_of_dropped"), "row_of_dropped requires target")
	assert_true(SkillTargetResolver.requires_drop_target("adjacent_to_dropped"), "adjacent_to_dropped requires target")


func _test_resolver_mode_description():
	var dropped_desc = SkillTargetResolver.get_mode_description("dropped")
	var all_desc = SkillTargetResolver.get_mode_description("all")

	assert_has(dropped_desc, "target", "dropped description should mention 'target'")
	assert_has(all_desc, "all", "all description should mention 'all'")


# =============================================================================
# SKILL TARGET VALIDATOR TESTS
# =============================================================================

func _test_validator_null_target():
	var effect_data = {"target_mode": "dropped"}
	var context = _make_context([])

	var is_valid = SkillTargetValidator.is_valid_target(effect_data, null, context)

	assert_false(is_valid, "null target should be invalid for 'dropped' mode")

	# But null should be valid for 'all' mode
	effect_data["target_mode"] = "all"
	is_valid = SkillTargetValidator.is_valid_target(effect_data, null, context)
	assert_true(is_valid, "null target should be valid for 'all' mode")


func _test_validator_dead_target():
	var effect_data = {"target_mode": "dropped", "requires_alive": true}
	var context = _make_context([])
	var dead_char = _make_char({}, 0)  # current_health = 0

	var is_valid = SkillTargetValidator.is_valid_target(effect_data, dead_char, context)

	assert_false(is_valid, "dead target should be invalid when requires_alive is true")


func _test_validator_front_row_requirement():
	var effect_data = {"target_mode": "dropped", "requires_front_row": true}
	var chars = _make_grid_chars()
	var context = _make_context(chars)
	var front_char = chars[0]  # Row 0
	var back_char = chars[2]   # Row 1

	var front_valid = SkillTargetValidator.is_valid_target(effect_data, front_char, context)
	var back_valid = SkillTargetValidator.is_valid_target(effect_data, back_char, context)

	assert_true(front_valid, "front row character should be valid")
	assert_false(back_valid, "back row character should be invalid for front_row requirement")


func _test_validator_back_row_requirement():
	var effect_data = {"target_mode": "dropped", "requires_back_row": true}
	var chars = _make_grid_chars()
	var context = _make_context(chars)
	var front_char = chars[0]  # Row 0
	var back_char = chars[2]   # Row 1

	var front_valid = SkillTargetValidator.is_valid_target(effect_data, front_char, context)
	var back_valid = SkillTargetValidator.is_valid_target(effect_data, back_char, context)

	assert_false(front_valid, "front row character should be invalid for back_row requirement")
	assert_true(back_valid, "back row character should be valid")


func _test_validator_error_messages():
	var context = _make_context([])

	var null_error = SkillTargetValidator.get_validation_error({"target_mode": "dropped"}, null, context)
	assert_has(null_error, "target", "null target error should mention target")

	var dead_char = _make_char({}, 0)
	var dead_error = SkillTargetValidator.get_validation_error({"requires_alive": true}, dead_char, context)
	assert_has(dead_error, "alive", "dead target error should mention alive")


# =============================================================================
# STAT BUFF EFFECT TESTS
# =============================================================================

func _test_stat_buff_effect_from_dict():
	var data = {
		"target_mode": "dropped",
		"modifiers": [
			{"stat": "health", "modifier_type": "flat", "value": 15}
		]
	}
	var effect = StatBuffEffect.from_dict(data)

	assert_eq(effect.target_mode, "dropped", "target_mode should be 'dropped'")
	assert_eq(effect.modifiers.size(), 1, "should have 1 modifier")
	assert_true(effect.is_valid(), "effect should be valid")


func _test_stat_buff_effect_execute():
	var data = {
		"target_mode": "dropped",
		"modifiers": [
			{"stat": "damage", "modifier_type": "flat", "value": 10}
		]
	}
	var effect = StatBuffEffect.from_dict(data)
	var chars = [_make_char({"damage": 50})]
	var context = _make_context(chars)
	var drop_target = chars[0]

	var success = effect.execute(drop_target, context)

	assert_true(success, "execute should return true")
	assert_eq(drop_target.stats["damage"], 60, "damage should be 60 after buff")


func _test_stat_buff_effect_multiple_modifiers():
	var data = {
		"target_mode": "dropped",
		"modifiers": [
			{"stat": "health", "modifier_type": "flat", "value": 20},
			{"stat": "damage", "modifier_type": "flat", "value": 5},
			{"stat": "speed", "modifier_type": "percent", "value": 0.1}
		]
	}
	var effect = StatBuffEffect.from_dict(data)
	var chars = [_make_char({"health": 100, "damage": 50, "speed": 100}, 100)]
	var context = _make_context(chars)
	var drop_target = chars[0]

	effect.execute(drop_target, context)

	assert_eq(drop_target.stats["health"], 120, "health should be 120")
	assert_eq(drop_target.stats["damage"], 55, "damage should be 55")
	assert_eq(drop_target.stats["speed"], 110, "speed should be 110")


func _test_stat_buff_effect_all_targets():
	var data = {
		"target_mode": "all",
		"modifiers": [
			{"stat": "agility", "modifier_type": "flat", "value": 5}
		]
	}
	var effect = StatBuffEffect.from_dict(data)
	var chars = [
		_make_char({"agility": 10}),
		_make_char({"agility": 10}),
		_make_char({"agility": 10})
	]
	var context = _make_context(chars)

	effect.execute(null, context)

	for char in chars:
		assert_eq(char.stats["agility"], 15, "each character's agility should be 15")


func _test_stat_buff_effect_description():
	var single_data = {
		"target_mode": "dropped",
		"modifiers": [{"stat": "health", "modifier_type": "flat", "value": 15}]
	}
	var multi_data = {
		"target_mode": "all",
		"modifiers": [
			{"stat": "damage", "modifier_type": "flat", "value": 10},
			{"stat": "speed", "modifier_type": "percent", "value": 0.1}
		]
	}

	var single_effect = StatBuffEffect.from_dict(single_data)
	var multi_effect = StatBuffEffect.from_dict(multi_data)

	var single_desc = single_effect.get_description()
	var multi_desc = multi_effect.get_description()

	assert_has(single_desc, "+15", "single description should contain '+15'")
	assert_has(multi_desc, "+10", "multi description should contain '+10'")
	assert_has(multi_desc, "+10%", "multi description should contain '+10%'")


func _test_stat_buff_effect_validation():
	var valid_data = {
		"target_mode": "dropped",
		"modifiers": [{"stat": "health", "modifier_type": "flat", "value": 10}]
	}
	var no_modifiers = {"target_mode": "dropped", "modifiers": []}

	assert_true(StatBuffEffect.validate_effect_data(valid_data), "valid data should pass")
	assert_false(StatBuffEffect.validate_effect_data(no_modifiers), "empty modifiers should fail")


# =============================================================================
# INTEGRATION TESTS
# =============================================================================

func _test_skill_effects_stat_buff_registered():
	var registry = SkillEffectRegistry.new()
	SkillEffects.register_all(registry)

	assert_true(registry.has_effect("stat_buff"), "stat_buff should be registered")


func _test_execute_stat_buff_via_registry():
	var registry = SkillEffectRegistry.new()
	SkillEffects.register_all(registry)

	var chars = [_make_char({"damage": 50})]
	var context = _make_context(chars)
	var drop_target = chars[0]
	context.drop_target = drop_target

	var skill_data = {
		"effect": {
			"type": "stat_buff",
			"target_mode": "dropped",
			"modifiers": [
				{"stat": "damage", "modifier_type": "flat", "value": 15}
			]
		}
	}

	var success = registry.execute(skill_data, context)

	assert_true(success, "registry execute should succeed")
	assert_eq(drop_target.stats["damage"], 65, "damage should be 65 after registry execution")


func _test_multi_effect_skill():
	var chars = [_make_char({"damage": 50, "health": 100}, 80)]
	var context = _make_context(chars)
	var drop_target = chars[0]
	context.drop_target = drop_target

	# Test the multi-effect execution helper
	var skill_data = {
		"name": "Warrior's Blessing",
		"effects": [
			{
				"type": "stat_buff",
				"target_mode": "dropped",
				"modifiers": [{"stat": "damage", "modifier_type": "flat", "value": 10}]
			},
			{
				"type": "heal_team",
				"value": 20
			}
		]
	}

	# Execute each effect manually to test the flow
	var registry = SkillEffectRegistry.new()
	SkillEffects.register_all(registry)

	for effect_data in skill_data.get("effects", []):
		var temp_skill = {"effect": effect_data}
		registry.execute(temp_skill, context)

	assert_eq(drop_target.stats["damage"], 60, "damage should be 60 after stat_buff")
	assert_eq(drop_target.current_health, 100, "health should be healed to 100")


func _test_skills_json_stat_buff_skills():
	# Load skills.json and verify stat_buff skills are valid
	var file = FileAccess.open("res://data/skills/skills.json", FileAccess.READ)
	if file == null:
		_fail("Could not open skills.json")
		return

	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		_fail("Failed to parse skills.json")
		return

	var data = json.data
	var skills = data.get("skills", [])
	var stat_buff_count = 0

	for skill in skills:
		var effect = skill.get("effect", {})
		var effects = skill.get("effects", [])

		# Check single effect
		if effect.get("type") == "stat_buff":
			stat_buff_count += 1
			if not StatBuffEffect.validate_effect_data(effect):
				_fail("Invalid stat_buff effect in skill: %s" % skill.get("id", "unknown"))
				return

		# Check multi-effects
		for e in effects:
			if e.get("type") == "stat_buff":
				stat_buff_count += 1
				if not StatBuffEffect.validate_effect_data(e):
					_fail("Invalid stat_buff effect in multi-effect skill: %s" % skill.get("id", "unknown"))
					return

	assert_true(stat_buff_count >= 7, "Should have at least 7 stat_buff effects in skills.json, found %d" % stat_buff_count)


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _make_char(stats: Dictionary = {}, current_hp: int = 100) -> MockChar:
	"""Create a mock character with given stats."""
	var char = MockChar.new()
	char.stats = {"health": 100, "damage": 50, "speed": 100, "agility": 10}
	char.stats.merge(stats, true)
	char.current_health = current_hp
	return char


func _make_grid_chars() -> Array:
	"""Create 3 characters with grid positions."""
	var chars = [_make_char(), _make_char(), _make_char()]
	# Grid: [0,0] [0,1] [empty]
	#       [1,0] [empty] [empty]
	chars[0].grid_position = Vector2i(0, 0)  # Front row, col 0
	chars[1].grid_position = Vector2i(0, 1)  # Front row, col 1
	chars[2].grid_position = Vector2i(1, 0)  # Back row, col 0
	return chars


func _make_context(chars: Array) -> SkillContext:
	"""Create a SkillContext with given characters."""
	var context = SkillContext.new()
	# Use lambda capture - need to wrap in dict to capture by reference
	var holder = {"chars": chars}
	context.get_team = func(): return holder.chars
	return context


# =============================================================================
# MOCK CHARACTER CLASS
# =============================================================================

class MockChar extends RefCounted:
	var stats: Dictionary = {}
	var current_health: int = 100
	var grid_position: Vector2i = Vector2i(-1, -1)

	func is_alive() -> bool:
		return current_health > 0

	func is_in_grid() -> bool:
		return grid_position.x >= 0 and grid_position.y >= 0

	func is_front_row() -> bool:
		return grid_position.x == 0

	func is_back_row() -> bool:
		return grid_position.x == 1

	func heal(amount: int) -> void:
		current_health = mini(current_health + amount, stats.get("health", 100))
