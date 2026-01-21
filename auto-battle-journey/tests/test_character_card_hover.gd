extends SceneTree
# Standalone test for CharacterCard hover functionality
# Run with: godot --headless --script res://tests/test_character_card_hover.gd

var card_scene = preload("res://scenes/components/character_card.tscn")
var tests_passed := 0
var tests_failed := 0


func _init():
	# Need to wait for tree to be ready
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("CharacterCard Hover Investigation Tests")
	print("========================================\n")

	_test_child_nodes_have_blocking_mouse_filter()
	_test_hover_state_not_triggered_initially()
	_test_manual_hover_call_works()
	_test_styles_are_initialized()
	_test_hover_style_differs_from_normal()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _create_card() -> Node:
	var card = card_scene.instantiate()
	root.add_child(card)
	# Use a character that exists in game data
	card.setup({"id": "char_warrior_001", "prestige": 1, "experience": 0, "equipped_items": []}, false)
	card.set_card_size(UIScaler.CardSize.SMALL)
	card.set_clickable(true)
	return card


func _test_child_nodes_have_blocking_mouse_filter():
	print("TEST 1: All child nodes have IGNORE mouse_filter (fix is applied)")
	var card = _create_card()

	var margin = card.get_node("MarginContainer")
	var vbox = card.get_node("MarginContainer/VBoxContainer")
	var portrait = card.get_node("MarginContainer/VBoxContainer/Portrait")
	var name_label = card.get_node("MarginContainer/VBoxContainer/NameLabel")
	var stats = card.get_node("MarginContainer/VBoxContainer/StatsContainer")

	# MOUSE_FILTER_STOP = 0, MOUSE_FILTER_PASS = 1, MOUSE_FILTER_IGNORE = 2
	var all_correct = true

	for node_info in [
		["MarginContainer", margin],
		["VBoxContainer", vbox],
		["Portrait", portrait],
		["NameLabel", name_label],
		["StatsContainer", stats]
	]:
		var node_name = node_info[0]
		var node = node_info[1]
		if node.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			_pass("%s has MOUSE_FILTER_IGNORE" % node_name)
		else:
			_fail("%s has filter=%d (expected IGNORE=2)" % [node_name, node.mouse_filter])
			all_correct = false

	card.queue_free()


func _test_hover_state_not_triggered_initially():
	print("\nTEST 2: Hover state is false initially")
	var card = _create_card()

	if card._is_hovered == false:
		_pass("_is_hovered is false initially")
	else:
		_fail("_is_hovered should be false initially")

	card.queue_free()


func _test_manual_hover_call_works():
	print("\nTEST 3: Manual _on_mouse_entered() call works")
	var card = _create_card()

	card._on_mouse_entered()

	if card._is_hovered == true:
		_pass("_on_mouse_entered() sets _is_hovered to true")
	else:
		_fail("_on_mouse_entered() did not set _is_hovered")

	card.queue_free()


func _test_styles_are_initialized():
	print("\nTEST 4: Styles dictionary is initialized")
	var card = _create_card()

	var has_styles = not card._styles.is_empty()
	var has_normal = card._styles.has("normal")
	var has_hover = card._styles.has("hover")
	var has_pressed = card._styles.has("pressed")

	if has_styles and has_normal and has_hover and has_pressed:
		_pass("All styles (normal, hover, pressed) are initialized")
	else:
		_fail("Missing styles - empty:%s normal:%s hover:%s pressed:%s" % [
			not has_styles, not has_normal, not has_hover, not has_pressed
		])

	card.queue_free()


func _test_hover_style_differs_from_normal():
	print("\nTEST 5: Hover style differs from normal style")
	var card = _create_card()

	var normal_style: StyleBoxFlat = card._styles.get("normal")
	var hover_style: StyleBoxFlat = card._styles.get("hover")

	var bg_differs = normal_style.bg_color != hover_style.bg_color
	var border_differs = normal_style.border_color != hover_style.border_color

	print("  Normal bg: %s, Hover bg: %s" % [normal_style.bg_color, hover_style.bg_color])
	print("  Normal border: %s, Hover border: %s" % [normal_style.border_color, hover_style.border_color])

	if bg_differs and border_differs:
		_pass("Hover style has different colors than normal")
	else:
		_fail("Hover style colors should differ - bg:%s border:%s" % [bg_differs, border_differs])

	card.queue_free()


func _pass(msg: String):
	tests_passed += 1
	print("  ✓ PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  ✗ FAIL: %s" % msg)
