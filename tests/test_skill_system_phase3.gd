extends SceneTree
## Test script for Phase 3: Skill System Rework
## Tests SkillEffectRegistry, LingeringEffects, skill execution, and data loading.
##
## Run with:
##   godot --headless --script res://tests/test_skill_system_phase3.gd

var tests_passed := 0
var tests_failed := 0
var test_name := "Phase 3: Skill System Tests"


func _init():
	call_deferred("_run_all_tests")


func _run_all_tests():
	print("\n========================================")
	print(test_name)
	print("========================================\n")

	# SkillEffectRegistry tests
	print("--- SkillEffectRegistry Tests ---")
	_test_registry_register()
	_test_registry_execute()
	_test_registry_has_effect()
	_test_registry_unregister()

	# LingeringEffects tests
	print("\n--- LingeringEffects Tests ---")
	_test_lingering_add_effect()
	_test_lingering_trigger()
	_test_lingering_trigger_for_character()
	_test_lingering_clear()
	_test_lingering_serialization()

	# Skill data loading tests
	print("\n--- Skill Data Tests ---")
	_test_skill_data_loading()
	_test_skill_data_new_schema()

	# SkillContext tests
	print("\n--- SkillContext Tests ---")
	_test_skill_context_creation()

	# Integration tests
	print("\n--- Integration Tests ---")
	_test_skill_effects_registration()
	_test_instant_effect_execution()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _pass(msg: String):
	tests_passed += 1
	print("  [PASS] %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  [FAIL] %s" % msg)


# =============================================================================
# SKILL EFFECT REGISTRY TESTS
# =============================================================================

func _test_registry_register() -> void:
	"""Test registering effect handlers."""
	var SkillEffectRegistryScript = load("res://scripts/skills/skill_effect_registry.gd")
	var registry = SkillEffectRegistryScript.new()

	# Should start empty
	if registry.get_handler_count() != 0:
		_fail("test_registry_register: Registry should start with 0 handlers")
		return

	# Register a handler
	var handler = func(_effect, _context): pass
	registry.register("test_effect", handler)

	if registry.get_handler_count() != 1:
		_fail("test_registry_register: Registry should have 1 handler after register")
		return

	if not registry.has_effect("test_effect"):
		_fail("test_registry_register: Registry should have 'test_effect' after register")
		return

	_pass("test_registry_register")


func _test_registry_execute() -> void:
	"""Test executing registered handlers."""
	var SkillEffectRegistryScript = load("res://scripts/skills/skill_effect_registry.gd")
	var registry = SkillEffectRegistryScript.new()

	var execution_value = [0]  # Use array to allow modification in closure
	var handler = func(effect_data, _context):
		execution_value[0] = effect_data.get("value", 0)

	registry.register("add_value", handler)

	var skill_data = {
		"effect": {
			"type": "add_value",
			"value": 42
		}
	}

	var success = registry.execute(skill_data, null)

	if not success:
		_fail("test_registry_execute: execute should return true for registered effect")
		return

	if execution_value[0] != 42:
		_fail("test_registry_execute: Handler should have been called with value 42, got %d" % execution_value[0])
		return

	# Test unknown effect
	var unknown_skill = { "effect": { "type": "unknown_effect" } }
	success = registry.execute(unknown_skill, null)

	if success:
		_fail("test_registry_execute: execute should return false for unknown effect")
		return

	_pass("test_registry_execute")


func _test_registry_has_effect() -> void:
	"""Test checking for registered effects."""
	var SkillEffectRegistryScript = load("res://scripts/skills/skill_effect_registry.gd")
	var registry = SkillEffectRegistryScript.new()

	if registry.has_effect("nonexistent"):
		_fail("test_registry_has_effect: has_effect should return false for unregistered effect")
		return

	registry.register("exists", func(_e, _c): pass)

	if not registry.has_effect("exists"):
		_fail("test_registry_has_effect: has_effect should return true for registered effect")
		return

	_pass("test_registry_has_effect")


func _test_registry_unregister() -> void:
	"""Test unregistering effect handlers."""
	var SkillEffectRegistryScript = load("res://scripts/skills/skill_effect_registry.gd")
	var registry = SkillEffectRegistryScript.new()

	registry.register("to_remove", func(_e, _c): pass)

	if not registry.has_effect("to_remove"):
		_fail("test_registry_unregister: Effect should exist before unregister")
		return

	var removed = registry.unregister("to_remove")

	if not removed:
		_fail("test_registry_unregister: unregister should return true for existing effect")
		return

	if registry.has_effect("to_remove"):
		_fail("test_registry_unregister: Effect should not exist after unregister")
		return

	# Try to unregister non-existent
	removed = registry.unregister("nonexistent")
	if removed:
		_fail("test_registry_unregister: unregister should return false for non-existent effect")
		return

	_pass("test_registry_unregister")


# =============================================================================
# LINGERING EFFECTS TESTS
# =============================================================================

func _test_lingering_add_effect() -> void:
	"""Test adding lingering effects."""
	var LingeringEffectsScript = load("res://scripts/managers/lingering_effects.gd")
	var effects = LingeringEffectsScript.new()

	# Should start empty
	if effects.get_effect_count() != 0:
		_fail("test_lingering_add_effect: LingeringEffects should start empty")
		return

	# Add a lingering effect
	var skill_data = {
		"id": "test_skill",
		"name": "Test Skill",
		"effect": { "type": "heal_team", "value": 20 },
		"trigger": "next_combat"
	}

	var effect_id = effects.add_effect(skill_data, 1)

	if effect_id <= 0:
		_fail("test_lingering_add_effect: add_effect should return positive ID")
		return

	if effects.get_effect_count() != 1:
		_fail("test_lingering_add_effect: Should have 1 effect after add")
		return

	# Invalid skill (no trigger)
	var invalid_skill = {
		"effect": { "type": "heal_team", "value": 10 }
		# missing "trigger"
	}
	var invalid_id = effects.add_effect(invalid_skill, 1)

	if invalid_id > 0:
		_fail("test_lingering_add_effect: add_effect should return <= 0 for invalid skill")
		return

	_pass("test_lingering_add_effect")


func _test_lingering_trigger() -> void:
	"""Test triggering lingering effects."""
	var LingeringEffectsScript = load("res://scripts/managers/lingering_effects.gd")
	var effects = LingeringEffectsScript.new()

	# Add effects with different triggers
	var combat_skill = {
		"id": "combat_skill",
		"effect": { "type": "heal_team", "value": 20 },
		"trigger": "next_combat"
	}
	var round_skill = {
		"id": "round_skill",
		"effect": { "type": "grant_gold", "value": 10 },
		"trigger": "next_round"
	}

	effects.add_effect(combat_skill, 1)
	effects.add_effect(round_skill, 1)

	if effects.get_effect_count() != 2:
		_fail("test_lingering_trigger: Should have 2 effects")
		return

	# Trigger combat effects (should remove only combat skill)
	var triggered = effects.trigger("next_combat", null, null)

	if triggered.size() != 1:
		_fail("test_lingering_trigger: Should trigger 1 combat effect, got %d" % triggered.size())
		return

	if effects.get_effect_count() != 1:
		_fail("test_lingering_trigger: Should have 1 effect remaining after trigger")
		return

	# Remaining should be the round skill
	if not effects.has_effects_for_trigger("next_round"):
		_fail("test_lingering_trigger: Should still have next_round effect")
		return

	_pass("test_lingering_trigger")


func _test_lingering_trigger_for_character() -> void:
	"""Test triggering character-specific effects."""
	var LingeringEffectsScript = load("res://scripts/managers/lingering_effects.gd")
	var effects = LingeringEffectsScript.new()

	# Add a character stat boost effect
	var boost_skill = {
		"id": "boost_skill",
		"effect": {
			"type": "next_character_stat_boost",
			"stat": "health",
			"value": 25
		},
		"trigger": "next_character_acquired"
	}

	effects.add_effect(boost_skill, 1)

	# Create a mock character
	var mock_character = MockCharacter.new()
	mock_character.max_health = 100
	mock_character.current_health = 100

	# Trigger for the character
	var triggered = effects.trigger_for_character(
		"next_character_acquired",
		mock_character,
		null
	)

	if triggered.size() != 1:
		_fail("test_lingering_trigger_for_character: Should trigger 1 character effect")
		return

	if mock_character.max_health != 125:
		_fail("test_lingering_trigger_for_character: Character max_health should be 125, got %d" % mock_character.max_health)
		return

	if mock_character.current_health != 125:
		_fail("test_lingering_trigger_for_character: Character current_health should be 125, got %d" % mock_character.current_health)
		return

	_pass("test_lingering_trigger_for_character")


func _test_lingering_clear() -> void:
	"""Test clearing lingering effects."""
	var LingeringEffectsScript = load("res://scripts/managers/lingering_effects.gd")
	var effects = LingeringEffectsScript.new()

	# Add multiple effects
	effects.add_effect_direct({ "type": "heal_team", "value": 10 }, "next_combat", "skill1", 1)
	effects.add_effect_direct({ "type": "grant_gold", "value": 5 }, "next_combat", "skill2", 1)
	effects.add_effect_direct({ "type": "grant_xp", "value": 15 }, "next_round", "skill3", 1)

	if effects.get_effect_count() != 3:
		_fail("test_lingering_clear: Should have 3 effects")
		return

	# Clear by trigger
	var removed = effects.clear_by_trigger("next_combat")

	if removed != 2:
		_fail("test_lingering_clear: Should have removed 2 combat effects, removed %d" % removed)
		return

	if effects.get_effect_count() != 1:
		_fail("test_lingering_clear: Should have 1 effect remaining")
		return

	# Clear all
	effects.clear()

	if effects.get_effect_count() != 0:
		_fail("test_lingering_clear: Should have 0 effects after clear")
		return

	_pass("test_lingering_clear")


func _test_lingering_serialization() -> void:
	"""Test serialization of lingering effects."""
	var LingeringEffectsScript = load("res://scripts/managers/lingering_effects.gd")
	var original = LingeringEffectsScript.new()

	# Add effects
	original.add_effect_direct({ "type": "heal_team", "value": 30 }, "next_combat", "heal_skill", 2)
	original.add_effect_direct({ "type": "grant_gold", "value": 15 }, "next_round", "gold_skill", 3)

	# Serialize
	var data = original.to_dict()

	if not data.has("effects"):
		_fail("test_lingering_serialization: Serialized data should have 'effects' key")
		return

	if data["effects"].size() != 2:
		_fail("test_lingering_serialization: Serialized effects should have 2 entries")
		return

	# Deserialize
	var restored = LingeringEffectsScript.from_dict(data)

	if restored.get_effect_count() != 2:
		_fail("test_lingering_serialization: Restored should have 2 effects, got %d" % restored.get_effect_count())
		return

	if not restored.has_effects_for_trigger("next_combat"):
		_fail("test_lingering_serialization: Restored should have next_combat effects")
		return

	if not restored.has_effects_for_trigger("next_round"):
		_fail("test_lingering_serialization: Restored should have next_round effects")
		return

	_pass("test_lingering_serialization")


# =============================================================================
# SKILL DATA TESTS
# =============================================================================

func _test_skill_data_loading() -> void:
	"""Test that skill data loads correctly."""
	var data = _load_skills_json()

	if data == null or not data.has("skills"):
		_fail("test_skill_data_loading: Failed to load skills.json")
		return

	var skills = data["skills"]
	if skills.size() == 0:
		_fail("test_skill_data_loading: skills.json should have at least one skill")
		return

	_pass("test_skill_data_loading")


func _test_skill_data_new_schema() -> void:
	"""Test that skills use the new Phase 3 schema."""
	var data = _load_skills_json()

	if data == null or not data.has("skills"):
		_fail("test_skill_data_new_schema: Failed to load skills.json for schema test")
		return

	var skills = data["skills"]
	var has_instant = false
	var has_lingering = false

	for skill in skills:
		# Check required new fields
		if not skill.has("effect_type"):
			_fail("test_skill_data_new_schema: Skill '%s' missing effect_type" % skill.get("id", "unknown"))
			return

		if not skill.has("effect"):
			_fail("test_skill_data_new_schema: Skill '%s' missing effect" % skill.get("id", "unknown"))
			return

		var effect = skill.get("effect", {})
		if not effect.has("type"):
			_fail("test_skill_data_new_schema: Skill '%s' effect missing type" % skill.get("id", "unknown"))
			return

		# Track effect types seen
		var effect_type = skill.get("effect_type", "")
		if effect_type == "instant":
			has_instant = true
		elif effect_type == "lingering":
			has_lingering = true
			# Lingering effects should have trigger
			if not skill.has("trigger"):
				_fail("test_skill_data_new_schema: Lingering skill '%s' missing trigger" % skill.get("id", "unknown"))
				return

	if not has_instant:
		_fail("test_skill_data_new_schema: Should have at least one instant skill")
		return

	if not has_lingering:
		_fail("test_skill_data_new_schema: Should have at least one lingering skill")
		return

	_pass("test_skill_data_new_schema")


# =============================================================================
# SKILL CONTEXT TESTS
# =============================================================================

func _test_skill_context_creation() -> void:
	"""Test creating a SkillContext."""
	var SkillContextScript = load("res://scripts/skills/skill_context.gd")
	var context = SkillContextScript.new()

	# Default context should not be fully valid
	if context.is_valid():
		_fail("test_skill_context_creation: Empty context should not be valid")
		return

	# Test with get_team Callable
	var mock_team = MockTeamManager.new()
	context.get_team = mock_team.get_team

	if not context.is_valid():
		_fail("test_skill_context_creation: Context with get_team should be valid")
		return

	# Test convenience methods
	var chars = context.get_all_characters()
	if chars.size() != 2:
		_fail("test_skill_context_creation: get_all_characters should return 2 from mock, got %d" % chars.size())
		return

	_pass("test_skill_context_creation")


# =============================================================================
# INTEGRATION TESTS
# =============================================================================

func _test_skill_effects_registration() -> void:
	"""Test that built-in effects register correctly."""
	var SkillEffectRegistryScript = load("res://scripts/skills/skill_effect_registry.gd")
	var SkillEffectsScript = load("res://scripts/skills/skill_effects.gd")
	var registry = SkillEffectRegistryScript.new()

	SkillEffectsScript.register_all(registry)

	# Check required effects
	var required_effects = ["heal_team", "grant_gold", "grant_xp", "next_character_stat_boost"]

	for effect_type in required_effects:
		if not registry.has_effect(effect_type):
			_fail("test_skill_effects_registration: Missing required effect: %s" % effect_type)
			return

	if registry.get_handler_count() < 4:
		_fail("test_skill_effects_registration: Should have at least 4 registered effects, got %d" % registry.get_handler_count())
		return

	_pass("test_skill_effects_registration")


func _test_instant_effect_execution() -> void:
	"""Test executing instant effects via the system."""
	var SkillEffectRegistryScript = load("res://scripts/skills/skill_effect_registry.gd")
	var SkillEffectsScript = load("res://scripts/skills/skill_effects.gd")
	var SkillContextScript = load("res://scripts/skills/skill_context.gd")

	var registry = SkillEffectRegistryScript.new()
	SkillEffectsScript.register_all(registry)

	# Create context with mock team using get_team Callable
	var context = SkillContextScript.new()
	var mock_team = MockTeamManager.new()
	context.get_team = mock_team.get_team

	# Test heal_team effect
	var heal_skill = {
		"effect": {
			"type": "heal_team",
			"value": 25
		}
	}

	# Get initial health
	var chars = mock_team.get_team()
	var initial_health = chars[0].current_health

	var success = registry.execute(heal_skill, context)

	if not success:
		_fail("test_instant_effect_execution: heal_team execution should succeed")
		return

	# Health should have increased
	if chars[0].current_health <= initial_health:
		_fail("test_instant_effect_execution: Character health should have increased after heal")
		return

	_pass("test_instant_effect_execution")


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _load_skills_json() -> Dictionary:
	"""Load skills.json directly for testing."""
	var file = FileAccess.open("res://data/skills/skills.json", FileAccess.READ)
	if file == null:
		return {}
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		return {}
	return json.data


# =============================================================================
# MOCK CLASSES FOR TESTING
# =============================================================================

class MockCharacter:
	var max_health: int = 100
	var current_health: int = 100
	var mana: int = 50
	var defend_rate: int = 10

	func heal(amount: int) -> void:
		current_health = min(current_health + amount, max_health)


class MockTeamManager:
	var _team: Array = []

	func _init():
		# Create mock characters
		var char1 = MockCharacter.new()
		char1.current_health = 80
		char1.max_health = 100
		var char2 = MockCharacter.new()
		char2.current_health = 60
		char2.max_health = 100
		_team = [char1, char2]

	func get_team() -> Array:
		return _team

	func distribute_experience(_xp: int) -> void:
		pass  # Mock implementation
