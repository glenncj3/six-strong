extends SceneTree
# Tests for Phase 1: Constants Centralization
# Verifies magic numbers have been moved to GameConstants and are used correctly
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_constants_centralization.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Constants Centralization Tests (Phase 1)")
	print("========================================\n")

	_test_overlay_colors_exist()
	_test_float_animation_constants_exist()
	_test_encounter_tile_constants_exist()
	_test_modal_constants_exist()
	_test_modal_popup_uses_constant()
	_test_ui_styles_uses_constant()
	_test_clickable_panel_uses_constant()
	_test_floating_number_uses_constants()
	_test_ui_container_helpers_uses_constant()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


# =============================================================================
# EXISTENCE TESTS - Verify constants are defined
# =============================================================================

func _test_overlay_colors_exist():
	"""Verify overlay/shadow color constants exist in GameConstants."""
	print("TEST: Overlay and shadow color constants exist")

	# Check that constants are defined with expected types
	var has_overlay_dim = typeof(GameConstants.COLOR_OVERLAY_DIM) == TYPE_COLOR
	var has_shadow_light = typeof(GameConstants.COLOR_SHADOW_LIGHT) == TYPE_COLOR
	var has_shadow_dark = typeof(GameConstants.COLOR_SHADOW_DARK) == TYPE_COLOR
	var has_placeholder = typeof(GameConstants.COLOR_PLACEHOLDER_TEXT) == TYPE_COLOR
	var has_highlight = typeof(GameConstants.COLOR_HIGHLIGHT_TINT) == TYPE_COLOR
	var has_critical = typeof(GameConstants.COLOR_CRITICAL_HIT) == TYPE_COLOR

	if has_overlay_dim and has_shadow_light and has_shadow_dark and has_placeholder and has_highlight and has_critical:
		_pass("All overlay/shadow color constants exist")
	else:
		var missing = []
		if not has_overlay_dim: missing.append("COLOR_OVERLAY_DIM")
		if not has_shadow_light: missing.append("COLOR_SHADOW_LIGHT")
		if not has_shadow_dark: missing.append("COLOR_SHADOW_DARK")
		if not has_placeholder: missing.append("COLOR_PLACEHOLDER_TEXT")
		if not has_highlight: missing.append("COLOR_HIGHLIGHT_TINT")
		if not has_critical: missing.append("COLOR_CRITICAL_HIT")
		_fail("Missing constants: %s" % ", ".join(missing))


func _test_float_animation_constants_exist():
	"""Verify floating number animation constants exist."""
	print("TEST: Floating number animation constants exist")

	var has_peak_scale = typeof(GameConstants.FLOAT_CRITICAL_PEAK_SCALE) == TYPE_FLOAT
	var has_rise_distance = typeof(GameConstants.FLOAT_CRITICAL_RISE_DISTANCE) == TYPE_FLOAT
	var has_duration = typeof(GameConstants.FLOAT_CRITICAL_DURATION) == TYPE_FLOAT

	if has_peak_scale and has_rise_distance and has_duration:
		_pass("All floating number constants exist")
	else:
		var missing = []
		if not has_peak_scale: missing.append("FLOAT_CRITICAL_PEAK_SCALE")
		if not has_rise_distance: missing.append("FLOAT_CRITICAL_RISE_DISTANCE")
		if not has_duration: missing.append("FLOAT_CRITICAL_DURATION")
		_fail("Missing constants: %s" % ", ".join(missing))


func _test_encounter_tile_constants_exist():
	"""Verify encounter tile layout constants exist."""
	print("TEST: Encounter tile layout constants exist")

	var has_margin = typeof(GameConstants.ENCOUNTER_TILE_MARGIN) == TYPE_FLOAT
	var has_spacing = typeof(GameConstants.ENCOUNTER_TILE_SPACING) == TYPE_FLOAT
	var has_min_size = typeof(GameConstants.ENCOUNTER_TILE_MIN_SIZE) == TYPE_FLOAT

	if has_margin and has_spacing and has_min_size:
		_pass("All encounter tile constants exist")
	else:
		var missing = []
		if not has_margin: missing.append("ENCOUNTER_TILE_MARGIN")
		if not has_spacing: missing.append("ENCOUNTER_TILE_SPACING")
		if not has_min_size: missing.append("ENCOUNTER_TILE_MIN_SIZE")
		_fail("Missing constants: %s" % ", ".join(missing))


func _test_modal_constants_exist():
	"""Verify modal popup fallback constants exist."""
	print("TEST: Modal popup constants exist")

	var has_fallback = typeof(GameConstants.MODAL_FALLBACK_HALF_SIZE) == TYPE_FLOAT

	if has_fallback:
		_pass("Modal popup constants exist")
	else:
		_fail("Missing MODAL_FALLBACK_HALF_SIZE constant")


# =============================================================================
# USAGE TESTS - Verify files use the constants instead of magic numbers
# =============================================================================

func _test_modal_popup_uses_constant():
	"""Verify modal_popup.gd uses COLOR_OVERLAY_DIM constant."""
	print("TEST: modal_popup.gd uses COLOR_OVERLAY_DIM")

	var file = FileAccess.open("res://scripts/components/modal_popup.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open modal_popup.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_constant = content.contains("GameConstants.COLOR_OVERLAY_DIM")
	var has_hardcoded = content.contains("Color(0, 0, 0, 0.5)")

	if uses_constant and not has_hardcoded:
		_pass("Uses COLOR_OVERLAY_DIM constant")
	elif uses_constant and has_hardcoded:
		_fail("Uses constant but still has hardcoded value")
	else:
		_fail("Still using hardcoded Color(0, 0, 0, 0.5)")


func _test_ui_styles_uses_constant():
	"""Verify ui_styles.gd uses shadow color constants."""
	print("TEST: ui_styles.gd uses shadow color constants")

	var file = FileAccess.open("res://scripts/ui_utils/ui_styles.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open ui_styles.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_shadow_light = content.contains("GameConstants.COLOR_SHADOW_LIGHT")
	var uses_shadow_dark = content.contains("GameConstants.COLOR_SHADOW_DARK")
	var has_hardcoded_03 = content.contains("Color(0, 0, 0, 0.3)")
	var has_hardcoded_07 = content.contains("Color(0, 0, 0, 0.7)")

	if uses_shadow_light and uses_shadow_dark and not has_hardcoded_03 and not has_hardcoded_07:
		_pass("Uses shadow color constants")
	else:
		var issues = []
		if not uses_shadow_light: issues.append("missing COLOR_SHADOW_LIGHT")
		if not uses_shadow_dark: issues.append("missing COLOR_SHADOW_DARK")
		if has_hardcoded_03: issues.append("has hardcoded 0.3 alpha")
		if has_hardcoded_07: issues.append("has hardcoded 0.7 alpha")
		_fail("Issues: %s" % ", ".join(issues))


func _test_clickable_panel_uses_constant():
	"""Verify clickable_panel_base.gd uses COLOR_HIGHLIGHT_TINT constant."""
	print("TEST: clickable_panel_base.gd uses COLOR_HIGHLIGHT_TINT")

	var file = FileAccess.open("res://scripts/components/clickable_panel_base.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open clickable_panel_base.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_constant = content.contains("GameConstants.COLOR_HIGHLIGHT_TINT")
	var has_hardcoded = content.contains("Color(1.2, 1.2, 1.2)")

	if uses_constant and not has_hardcoded:
		_pass("Uses COLOR_HIGHLIGHT_TINT constant")
	elif uses_constant and has_hardcoded:
		_fail("Uses constant but still has hardcoded value")
	else:
		_fail("Still using hardcoded Color(1.2, 1.2, 1.2)")


func _test_floating_number_uses_constants():
	"""Verify floating_number.gd uses critical hit constants."""
	print("TEST: floating_number.gd uses critical hit constants")

	var file = FileAccess.open("res://scripts/effects/floating_number.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open floating_number.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_peak_scale = content.contains("GameConstants.FLOAT_CRITICAL_PEAK_SCALE")
	var uses_rise_distance = content.contains("GameConstants.FLOAT_CRITICAL_RISE_DISTANCE")
	var uses_duration = content.contains("GameConstants.FLOAT_CRITICAL_DURATION")
	var uses_critical_color = content.contains("GameConstants.COLOR_CRITICAL_HIT")

	var has_hardcoded_scale = content.contains("_peak_scale = 1.5")
	var has_hardcoded_rise = content.contains("_rise_distance = 70.0")
	var has_hardcoded_duration = content.contains("_duration = 1.2")
	var has_hardcoded_color = content.contains("Color(1.0, 0.3, 0.3)")

	if uses_peak_scale and uses_rise_distance and uses_duration and uses_critical_color:
		if not has_hardcoded_scale and not has_hardcoded_rise and not has_hardcoded_duration and not has_hardcoded_color:
			_pass("Uses all critical hit constants")
		else:
			_fail("Uses constants but still has some hardcoded values")
	else:
		var missing = []
		if not uses_peak_scale: missing.append("FLOAT_CRITICAL_PEAK_SCALE")
		if not uses_rise_distance: missing.append("FLOAT_CRITICAL_RISE_DISTANCE")
		if not uses_duration: missing.append("FLOAT_CRITICAL_DURATION")
		if not uses_critical_color: missing.append("COLOR_CRITICAL_HIT")
		_fail("Missing constant usage: %s" % ", ".join(missing))


func _test_ui_container_helpers_uses_constant():
	"""Verify ui_container_helpers.gd uses COLOR_PLACEHOLDER_TEXT constant."""
	print("TEST: ui_container_helpers.gd uses COLOR_PLACEHOLDER_TEXT")

	var file = FileAccess.open("res://scripts/ui_utils/ui_container_helpers.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open ui_container_helpers.gd")
		return

	var content = file.get_as_text()
	file.close()

	var uses_constant = content.contains("GameConstants.COLOR_PLACEHOLDER_TEXT")
	var has_hardcoded = content.contains("Color(0.7, 0.7, 0.7)")

	if uses_constant and not has_hardcoded:
		_pass("Uses COLOR_PLACEHOLDER_TEXT constant")
	elif uses_constant and has_hardcoded:
		_fail("Uses constant but still has hardcoded value")
	else:
		_fail("Still using hardcoded Color(0.7, 0.7, 0.7)")


# =============================================================================
# HELPERS
# =============================================================================

func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
