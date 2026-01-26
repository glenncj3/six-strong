extends SceneTree
# Tests for Phase 4 components:
# - RunState: Composite object owning all run subsystems
# - RunPool: Content pool composer with level gating
# - LegacyDraftManager: Legacy draft logic
#
# Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_phase4_components.gd

var tests_passed := 0
var tests_failed := 0


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n========================================")
	print("Phase 4 Component Tests")
	print("========================================\n")

	_test_run_state_creation()
	_test_run_state_gold_operations()
	_test_run_state_reputation_operations()
	_test_run_state_win_loss_tracking()
	_test_run_state_serialization()
	_test_run_pool_creation()
	_test_run_pool_content_picking()
	_test_run_pool_serialization()
	_test_legacy_draft_manager_signals()
	_test_legacy_draft_manager_starting_gold()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")

	quit(tests_failed)


# =============================================================================
# RUNSTATE TESTS
# =============================================================================

func _test_run_state_creation():
	"""Test RunState basic creation and initialization."""
	print("TEST: RunState creation and initialization")

	var RunStateScript = load("res://scripts/managers/run_state.gd")
	var state = RunStateScript.new()

	if state.current_round != 0:
		_fail("current_round should start at 0")
		return

	if state.current_phase != "encounter":
		_fail("current_phase should start as 'encounter'")
		return

	if state.reputation != GameConstants.STARTING_REPUTATION:
		_fail("reputation should start at STARTING_REPUTATION")
		return

	if state.wins != 0 or state.losses != 0:
		_fail("wins and losses should start at 0")
		return

	_pass("RunState initializes correctly")


func _test_run_state_gold_operations():
	"""Test RunState gold operations."""
	print("TEST: RunState gold operations")

	var RunStateScript = load("res://scripts/managers/run_state.gd")
	var state = RunStateScript.new()
	state.current_gold = 100

	state.add_gold(50)
	if state.current_gold != 150:
		_fail("add_gold(50) failed, expected 150, got %d" % state.current_gold)
		return

	var success = state.spend_gold(30)
	if not success or state.current_gold != 120:
		_fail("spend_gold(30) failed, expected 120, got %d" % state.current_gold)
		return

	success = state.spend_gold(200)
	if success or state.current_gold != 120:
		_fail("spend_gold(200) should fail when insufficient")
		return

	_pass("RunState gold operations work correctly")


func _test_run_state_reputation_operations():
	"""Test RunState reputation operations."""
	print("TEST: RunState reputation operations")

	var RunStateScript = load("res://scripts/managers/run_state.gd")
	var state = RunStateScript.new()

	var initial_rep = state.reputation
	state.lose_reputation(5)

	if state.reputation != initial_rep - 5:
		_fail("lose_reputation(5) failed")
		return

	# Lose all reputation
	state.lose_reputation(100)
	if state.reputation != 0:
		_fail("reputation should clamp at 0")
		return

	if not state.is_defeated():
		_fail("is_defeated() should return true when reputation is 0")
		return

	_pass("RunState reputation operations work correctly")


func _test_run_state_win_loss_tracking():
	"""Test RunState win/loss tracking."""
	print("TEST: RunState win/loss tracking")

	var RunStateScript = load("res://scripts/managers/run_state.gd")
	var state = RunStateScript.new()

	# Track wins
	for i in range(GameConstants.WINS_FOR_VICTORY - 1):
		state.add_win()

	if state.is_victory():
		_fail("is_victory() should be false before reaching WINS_FOR_VICTORY")
		return

	state.add_win()

	if not state.is_victory():
		_fail("is_victory() should be true after reaching WINS_FOR_VICTORY")
		return

	if not state.is_run_over():
		_fail("is_run_over() should be true after victory")
		return

	_pass("RunState win/loss tracking works correctly")


func _test_run_state_serialization():
	"""Test RunState serialization."""
	print("TEST: RunState serialization")

	var RunStateScript = load("res://scripts/managers/run_state.gd")
	var state = RunStateScript.new()
	state.run_id = "test_run_123"
	state.current_round = 5
	state.current_gold = 200
	state.wins = 3
	state.drafted_legacy_ids.append("legacy_knight_order")

	var dict = state.to_dict()

	if dict.get("run_id") != "test_run_123":
		_fail("Serialized run_id incorrect")
		return

	if dict.get("current_round") != 5:
		_fail("Serialized current_round incorrect")
		return

	if dict.get("current_gold") != 200:
		_fail("Serialized current_gold incorrect")
		return

	# Test from_dict
	var restored = RunStateScript.from_dict(dict)

	if restored.run_id != state.run_id:
		_fail("Deserialized run_id incorrect")
		return

	if restored.current_round != state.current_round:
		_fail("Deserialized current_round incorrect")
		return

	_pass("RunState serialization works correctly")


# =============================================================================
# RUNPOOL TESTS
# =============================================================================

func _test_run_pool_creation():
	"""Test RunPool basic creation."""
	print("TEST: RunPool creation")

	var RunPoolScript = load("res://scripts/managers/run_pool.gd")
	var pool = RunPoolScript.new()

	pool.add_character("char_warrior_001", 1)
	pool.add_item("item_rusty_sword", 1)
	pool.add_skill("skill_power_strike", 2)
	pool.add_encounter("enc_knight_tournament", 110, 2)

	if pool.get_pool_size(RunPoolScript.ContentType.CHARACTER) != 1:
		_fail("Character pool size should be 1")
		return

	if not pool.has_content(RunPoolScript.ContentType.CHARACTER, "char_warrior_001"):
		_fail("Should have char_warrior_001 in pool")
		return

	if not pool.has_content(RunPoolScript.ContentType.ITEM, "item_rusty_sword"):
		_fail("Should have item_rusty_sword in pool")
		return

	_pass("RunPool creation works correctly")


func _test_run_pool_content_picking():
	"""Test RunPool content picking with level filtering."""
	print("TEST: RunPool content picking with level filtering")

	var RunPoolScript = load("res://scripts/managers/run_pool.gd")
	var pool = RunPoolScript.new()

	# Add content with different level requirements
	pool.add_item("item_level_1", 1)
	pool.add_item("item_level_2", 2)
	pool.add_item("item_level_3", 3)

	# Pick at level 1
	var items = pool.get_all(RunPoolScript.ContentType.ITEM, 1)
	if items.size() != 1:
		_fail("Should only get 1 item at level 1, got %d" % items.size())
		return

	# Pick at level 2
	items = pool.get_all(RunPoolScript.ContentType.ITEM, 2)
	if items.size() != 2:
		_fail("Should get 2 items at level 2, got %d" % items.size())
		return

	# Pick all
	items = pool.get_all(RunPoolScript.ContentType.ITEM)
	if items.size() != 3:
		_fail("Should get all 3 items without level filter")
		return

	_pass("RunPool content picking with level filtering works correctly")


func _test_run_pool_serialization():
	"""Test RunPool serialization."""
	print("TEST: RunPool serialization")

	var RunPoolScript = load("res://scripts/managers/run_pool.gd")
	var pool = RunPoolScript.new()

	pool.add_character("char_warrior_001", 1)
	pool.add_item("item_rusty_sword", 1)
	pool.add_encounter("enc_knight_tournament", 110, 2)

	var dict = pool.to_dict()

	if not dict.has("character_pool"):
		_fail("Serialized data missing character_pool")
		return

	if not dict.has("item_pool"):
		_fail("Serialized data missing item_pool")
		return

	# Test from_dict
	var restored = RunPoolScript.from_dict(dict)

	if not restored.has_content(RunPoolScript.ContentType.CHARACTER, "char_warrior_001"):
		_fail("Deserialized pool missing character")
		return

	if not restored.has_content(RunPoolScript.ContentType.ITEM, "item_rusty_sword"):
		_fail("Deserialized pool missing item")
		return

	_pass("RunPool serialization works correctly")


# =============================================================================
# LEGACYDRAFTMANAGER TESTS
# =============================================================================

func _test_legacy_draft_manager_signals():
	"""Test LegacyDraftManager signal definitions."""
	print("TEST: LegacyDraftManager signal definitions")

	var file = FileAccess.open("res://scripts/managers/legacy_draft_manager.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open legacy_draft_manager.gd")
		return

	var content = file.get_as_text()
	file.close()

	var required_signals = [
		"signal draft_options_generated",
		"signal legacy_drafted",
		"signal draft_completed",
		"signal generation_failed"
	]

	for sig in required_signals:
		if not content.contains(sig):
			_fail("Missing signal: %s" % sig)
			return

	_pass("LegacyDraftManager has all required signals")


func _test_legacy_draft_manager_starting_gold():
	"""Test LegacyDraftManager starting gold calculation."""
	print("TEST: LegacyDraftManager starting gold calculation")

	var file = FileAccess.open("res://scripts/managers/legacy_draft_manager.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open legacy_draft_manager.gd")
		return

	var content = file.get_as_text()
	file.close()

	if not content.contains("func calculate_starting_gold()"):
		_fail("Missing calculate_starting_gold() method")
		return

	if not content.contains("legacy.income"):
		_fail("calculate_starting_gold() should use legacy.income")
		return

	_pass("LegacyDraftManager has starting gold calculation")


# =============================================================================
# HELPERS
# =============================================================================

func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
