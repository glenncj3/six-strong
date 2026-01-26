extends SceneTree
# Tests for ModalPopup CanvasLayer usage
# Verifies popups reparent to ModalLayer for correct rendering order
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\auto-battle-journey" --script res://tests/unit/test_modal_popup_layer.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("ModalPopup Layer Tests")
	print("========================================\n")

	_test_modal_layer_exists_in_main()
	_test_modal_popup_finds_layer()
	_test_modal_popup_reparents_to_layer()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


func _test_modal_layer_exists_in_main():
	"""Verify ModalLayer node exists in main.tscn."""
	print("TEST: ModalLayer exists in main.tscn")

	var file = FileAccess.open("res://scenes/main.tscn", FileAccess.READ)
	if file == null:
		_fail("Cannot open main.tscn")
		return

	var content = file.get_as_text()
	file.close()

	var has_modal_layer = content.contains("[node name=\"ModalLayer\" type=\"CanvasLayer\"")
	var has_layer_200 = content.contains("layer = 200")

	if has_modal_layer and has_layer_200:
		_pass("ModalLayer exists at layer 200")
	else:
		_fail("ModalLayer not found or not at layer 200")


func _test_modal_popup_finds_layer():
	"""Verify ModalPopup has _find_modal_layer method."""
	print("TEST: ModalPopup has _find_modal_layer method")

	var file = FileAccess.open("res://scripts/components/modal_popup.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open modal_popup.gd")
		return

	var content = file.get_as_text()
	file.close()

	var has_find_method = content.contains("func _find_modal_layer()")
	var looks_for_main = content.contains("get_node_or_null(\"Main\")")
	var looks_for_modal_layer = content.contains("get_node_or_null(\"ModalLayer\")")

	if has_find_method and looks_for_main and looks_for_modal_layer:
		_pass("Has _find_modal_layer that searches Main/ModalLayer")
	else:
		_fail("Missing or incomplete _find_modal_layer method")


func _test_modal_popup_reparents_to_layer():
	"""Verify ModalPopup reparents to modal layer instead of scene root."""
	print("TEST: ModalPopup reparents to ModalLayer")

	var file = FileAccess.open("res://scripts/components/modal_popup.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open modal_popup.gd")
		return

	var content = file.get_as_text()
	file.close()

	var finds_modal_layer = content.contains("var modal_layer = _find_modal_layer()")
	var reparents_to_modal = content.contains("reparent(modal_layer)")
	var adds_overlay_to_modal = content.contains("modal_layer.add_child(_overlay)")

	if finds_modal_layer and reparents_to_modal and adds_overlay_to_modal:
		_pass("Reparents popup and overlay to ModalLayer")
	else:
		var missing = []
		if not finds_modal_layer:
			missing.append("find modal_layer")
		if not reparents_to_modal:
			missing.append("reparent to modal_layer")
		if not adds_overlay_to_modal:
			missing.append("add overlay to modal_layer")
		_fail("Missing: %s" % ", ".join(missing))


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
