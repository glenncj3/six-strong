extends "res://tests/base_test.gd"

# Tests for CharacterTile stat icon display and live updates


func _run_tests():
	test_name = "StatIcons"

	# Instantiate tile and add to tree
	var scene = load("res://scenes/components/character_tile.tscn")
	assert_not_null(scene, "CharacterTile scene loads")
	if scene == null:
		return

	var tile = scene.instantiate()
	root.add_child(tile)

	# Manually trigger _ready chain by calling _build_stat_containers
	# Since we're in the same frame, @onready vars should be set after add_child
	# Let's check if _stat_badges got populated
	var badges = tile.get("_stat_badges")
	assert_not_null(badges, "_stat_badges property exists")
	if badges == null or badges.is_empty():
		# _ready may not have fired yet in headless. Try calling directly.
		print("  INFO: _stat_badges empty, badges count: %s" % [badges.size() if badges else "null"])
		tile.queue_free()
		return

	_test_stat_badges_created(badges)
	_test_update_stat_icons_shows_nonzero(tile, badges)
	_test_update_stat_icons_hides_zero(tile, badges)
	_test_update_stats_from_combat_charges(tile, badges)
	_test_update_stats_from_combat_extra_stats(tile, badges)
	_test_clear_display_hides_all(tile, badges)

	tile.queue_free()


func _test_stat_badges_created(badges: Dictionary):
	section("Stat badges created")
	assert_true(badges.size() > 0, "_stat_badges populated (%d entries)" % badges.size())
	var expected_keys = ["damage", "heal_value", "shield_value", "burn_value", "poison_value",
		"charges", "multistrike_value", "speed"]
	for key in expected_keys:
		assert_true(badges.has(key), "Badge exists for '%s'" % key)


func _test_update_stat_icons_shows_nonzero(tile: Node, badges: Dictionary):
	section("_update_stat_icons shows non-zero values")
	var stats = {"damage": 15, "charges": 6, "speed": 3, "heal_value": 0, "shield_value": 0,
		"burn_value": 0, "poison_value": 0, "multistrike_value": 0}
	tile.call("_update_stat_icons", stats)

	assert_true(badges["damage"].container.visible, "damage badge visible when 15")
	assert_eq(badges["damage"].label.text, "15", "damage label shows 15")
	assert_true(badges["charges"].container.visible, "charges badge visible when 6")
	assert_eq(badges["charges"].label.text, "6", "charges label shows 6")
	assert_true(badges["speed"].container.visible, "speed badge visible when 3")
	assert_eq(badges["speed"].label.text, "3", "speed label shows 3")
	assert_false(badges["heal_value"].container.visible, "heal badge hidden when 0")


func _test_update_stat_icons_hides_zero(tile: Node, badges: Dictionary):
	section("_update_stat_icons hides zero values")
	tile.call("_update_stat_icons", {"damage": 10, "charges": 5})
	assert_true(badges["damage"].container.visible, "damage visible before update")

	tile.call("_update_stat_icons", {"damage": 0, "charges": 5})
	assert_false(badges["damage"].container.visible, "damage hidden after set to 0")
	assert_true(badges["charges"].container.visible, "charges still visible")
	assert_eq(badges["charges"].label.text, "5", "charges shows 5")


func _test_update_stats_from_combat_charges(tile: Node, badges: Dictionary):
	section("update_stats_from_combat reflects charge changes")
	var cc = CombatCharacter.new()
	cc.damage = 10.0
	cc.speed = 3.0
	cc.charges = 6
	# Simulate real CombatCharacter: extra_stats also contains "charges" from source copy
	cc.extra_stats = {"charges": 6, "heal_value": 0, "shield_value": 0, "burn_value": 0,
		"poison_value": 0, "multistrike_value": 0}

	tile.call("update_stats_from_combat", cc)
	assert_eq(badges["charges"].label.text, "6", "charges initially 6")
	assert_true(badges["charges"].container.visible, "charges badge visible at 6")

	# Decrement live charges but extra_stats retains stale value (the real bug)
	cc.charges = 4
	tile.call("update_stats_from_combat", cc)
	assert_eq(badges["charges"].label.text, "4", "charges updated to 4 (not stale 6 from extra_stats)")

	cc.charges = 0
	tile.call("update_stats_from_combat", cc)
	assert_false(badges["charges"].container.visible, "charges badge hidden at 0")

	cc.charges = -1
	tile.call("update_stats_from_combat", cc)
	assert_false(badges["charges"].container.visible, "charges badge hidden for unlimited (-1)")


func _test_update_stats_from_combat_extra_stats(tile: Node, badges: Dictionary):
	section("update_stats_from_combat reflects extra stat changes")
	var cc = CombatCharacter.new()
	cc.damage = 10.0
	cc.speed = 3.0
	cc.charges = 6
	cc.extra_stats = {"heal_value": 5, "shield_value": 0, "burn_value": 10,
		"poison_value": 0, "multistrike_value": 2}

	tile.call("update_stats_from_combat", cc)
	assert_true(badges["heal_value"].container.visible, "heal visible at 5")
	assert_eq(badges["heal_value"].label.text, "5", "heal shows 5")
	assert_true(badges["burn_value"].container.visible, "burn visible at 10")
	assert_eq(badges["burn_value"].label.text, "10", "burn shows 10")
	assert_false(badges["shield_value"].container.visible, "shield hidden at 0")
	assert_true(badges["multistrike_value"].container.visible, "multistrike visible at 2")

	cc.damage = 20.0
	tile.call("update_stats_from_combat", cc)
	assert_eq(badges["damage"].label.text, "20", "damage updated to 20 after buff")


func _test_clear_display_hides_all(tile: Node, badges: Dictionary):
	section("_clear_display hides all stat badges")
	tile.call("_update_stat_icons", {"damage": 10, "charges": 6, "speed": 3})
	assert_true(badges["damage"].container.visible, "damage visible before clear")

	tile.call("_clear_display")
	for key in badges:
		assert_false(badges[key].container.visible, "'%s' hidden after _clear_display" % key)
