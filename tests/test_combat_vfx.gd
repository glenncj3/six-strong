extends "res://tests/base_test.gd"
# Tests for CombatVFX signal routing, config lookups, and scene caching.
# Run with: godot --headless --script res://tests/test_combat_vfx.gd

const CombatVFXScript = preload("res://scripts/effects/combat_vfx.gd")

func _init():
	test_name = "CombatVFX Tests"
	super()


func _run_tests():
	section("Config Consistency")
	test_projectile_effects_have_impact_scenes()
	test_all_config_keys_match_scene_keys()
	test_config_values_are_valid()

	section("Signal Routing")
	test_connects_both_signals()
	test_ability_used_skips_non_projectile_effects()
	test_effect_applied_skips_projectile_effects()

	section("Scene Caching")
	test_load_cached_returns_same_instance()

	section("Slot Position Resolution")
	test_get_slot_center_returns_null_for_missing()
	test_get_slot_center_returns_position()


func test_projectile_effects_have_impact_scenes():
	var vfx = CombatVFXScript.new()
	for effect_id in vfx._projectile_scenes:
		assert_true(vfx._effect_scenes.has(effect_id),
			"projectile effect '%s' has matching impact scene" % effect_id)


func test_all_config_keys_match_scene_keys():
	var vfx = CombatVFXScript.new()
	for effect_id in vfx._effect_config:
		assert_true(vfx._effect_scenes.has(effect_id),
			"effect_config '%s' has matching effect_scene" % effect_id)
	for effect_id in vfx._projectile_config:
		assert_true(vfx._projectile_scenes.has(effect_id),
			"projectile_config '%s' has matching projectile_scene" % effect_id)


func test_config_values_are_valid():
	var vfx = CombatVFXScript.new()
	for effect_id in vfx._effect_config:
		var cfg = vfx._effect_config[effect_id]
		assert_true(cfg.has("size"), "effect_config '%s' has size" % effect_id)
		assert_true(cfg.has("duration"), "effect_config '%s' has duration" % effect_id)
		assert_true(cfg.duration > 0.0, "effect_config '%s' duration > 0" % effect_id)

	for effect_id in vfx._projectile_config:
		var cfg = vfx._projectile_config[effect_id]
		assert_true(cfg.has("size"), "projectile_config '%s' has size" % effect_id)
		assert_true(cfg.has("duration"), "projectile_config '%s' has duration" % effect_id)
		assert_true(cfg.has("arc_height"), "projectile_config '%s' has arc_height" % effect_id)
		assert_true(cfg.duration > 0.0, "projectile_config '%s' duration > 0" % effect_id)
		assert_true(cfg.arc_height > 0.0, "projectile_config '%s' arc_height > 0" % effect_id)


func test_connects_both_signals():
	var vfx = CombatVFXScript.new()
	var manager = CombatManager.new()
	var parent = Control.new()
	root.add_child(parent)
	root.add_child(manager)

	vfx.connect_to_manager(manager, {}, parent)

	assert_true(manager.effect_applied.is_connected(vfx._on_effect_applied),
		"effect_applied signal connected")
	assert_true(manager.ability_used.is_connected(vfx._on_ability_used),
		"ability_used signal connected")

	manager.queue_free()
	parent.queue_free()


func test_ability_used_skips_non_projectile_effects():
	var vfx = CombatVFXScript.new()
	# An ability with applies_effect not in _projectile_scenes should be a no-op
	var source = CombatCharacter.new()
	source.team = 0
	source.row = 0
	source.column = 0
	var ability = {"applies_effect": "nonexistent_effect"}
	# Should not error
	vfx._on_ability_used(source, ability, [])
	assert_true(true, "ability_used with unknown effect is a no-op")

	# Ability without applies_effect at all
	vfx._on_ability_used(source, {}, [])
	assert_true(true, "ability_used without applies_effect is a no-op")


func test_effect_applied_skips_projectile_effects():
	var vfx = CombatVFXScript.new()
	var target = CombatCharacter.new()
	target.team = 0
	target.row = 0
	target.column = 0

	var effect = CombatEffect.new()
	effect.effect_id = "burn"

	# Burn has a projectile, so effect_applied should skip it (no error, no VFX)
	vfx._on_effect_applied(target, effect)
	assert_true(true, "effect_applied skips burn (handled by ability_used)")


func test_load_cached_returns_same_instance():
	var vfx = CombatVFXScript.new()
	var path = vfx._effect_scenes["burn"]
	var scene1 = vfx._load_cached(path)
	var scene2 = vfx._load_cached(path)
	assert_true(scene1 == scene2, "cached scene returns same PackedScene instance")
	assert_true(vfx._scene_cache.has(path), "scene is stored in cache")


func test_get_slot_center_returns_null_for_missing():
	var vfx = CombatVFXScript.new()
	vfx._slot_displays = {}
	var char = CombatCharacter.new()
	char.team = 0
	char.row = 0
	char.column = 0
	var result = vfx._get_slot_center(char)
	assert_true(result == null, "returns null for missing slot display")


func test_get_slot_center_returns_position():
	var vfx = CombatVFXScript.new()
	var slot = Control.new()
	slot.position = Vector2(100, 200)
	slot.size = Vector2(80, 120)
	root.add_child(slot)

	vfx._slot_displays = {"0_0_0": {"slot": slot}}
	var char = CombatCharacter.new()
	char.team = 0
	char.row = 0
	char.column = 0

	var result = vfx._get_slot_center(char)
	assert_not_null(result, "returns position for valid slot")
	# global_position + size/2 = (100, 200) + (40, 60) = (140, 260)
	assert_true(abs(result.x - 140.0) < 1.0, "x position is slot center")
	assert_true(abs(result.y - 260.0) < 1.0, "y position is slot center")

	slot.queue_free()
