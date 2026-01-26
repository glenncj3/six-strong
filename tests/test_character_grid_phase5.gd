extends Node
## Phase 5 Tests: CharacterGrid

# =============================================================================
# TEST INFRASTRUCTURE
# =============================================================================

var _passed := 0
var _failed := 0
var _test_results: Array[String] = []

func _ready() -> void:
	run_all_tests()

func run_all_tests() -> void:
	print("\n" + "=".repeat(60))
	print("PHASE 5 TESTS: CharacterGrid")
	print("=".repeat(60))

	# CharacterGrid tests
	_run_test("test_grid_initialization", test_grid_initialization)
	_run_test("test_place_character", test_place_character)
	_run_test("test_place_in_first_empty", test_place_in_first_empty)
	_run_test("test_remove_character", test_remove_character)
	_run_test("test_swap_positions", test_swap_positions)
	_run_test("test_move_character", test_move_character)
	_run_test("test_is_full", test_is_full)
	_run_test("test_get_all_characters", test_get_all_characters)
	_run_test("test_get_front_back_rows", test_get_front_back_rows)
	_run_test("test_serialization", test_serialization)

	print("\n" + "-".repeat(60))
	print("Phase 5 Results: %d passed, %d failed" % [_passed, _failed])
	print("-".repeat(60))

	for result in _test_results:
		print(result)

	if _failed == 0:
		print("\n[SUCCESS] All Phase 5 tests passed!")
	else:
		print("\n[FAILURE] Some tests failed")

func _run_test(test_name: String, test_func: Callable) -> void:
	var result = test_func.call()
	if result:
		_passed += 1
		_test_results.append("[PASS] %s" % test_name)
	else:
		_failed += 1
		_test_results.append("[FAIL] %s" % test_name)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _create_test_character(id: String = "test_char") -> CharacterInstance:
	var char_data = {
		"id": id,
		"name": "Test Character",
		"base_stats": {
			"health": 100,
			"mana": 50,
			"defendRate": 10
		}
	}
	return CharacterInstance.from_master_data(char_data)

func _create_grid() -> CharacterGrid:
	return CharacterGrid.new()

# =============================================================================
# TESTS
# =============================================================================

func test_grid_initialization() -> bool:
	var grid = _create_grid()

	# Grid should be empty on creation
	if grid.get_character_count() != 0:
		push_error("Grid should start empty")
		return false

	if not grid.is_empty():
		push_error("is_empty should return true for new grid")
		return false

	if grid.is_full():
		push_error("is_full should return false for new grid")
		return false

	# Should have 6 empty slots
	var empty_slots = grid.get_empty_slots()
	if empty_slots.size() != 6:
		push_error("Should have 6 empty slots, got %d" % empty_slots.size())
		return false

	return true

func test_place_character() -> bool:
	var grid = _create_grid()
	var char1 = _create_test_character("char1")

	# Place character at specific position
	var success = grid.place_character(char1, 0, 0)
	if not success:
		push_error("place_character should succeed")
		return false

	# Character should be at that position
	var retrieved = grid.get_character_at(0, 0)
	if retrieved != char1:
		push_error("get_character_at should return placed character")
		return false

	# Character's grid_position should be updated
	if char1.grid_position != Vector2i(0, 0):
		push_error("Character grid_position should be updated")
		return false

	# Placing in occupied slot should fail
	var char2 = _create_test_character("char2")
	success = grid.place_character(char2, 0, 0)
	if success:
		push_error("place_character should fail for occupied slot")
		return false

	# Placing at invalid position should fail
	success = grid.place_character(char2, 5, 5)
	if success:
		push_error("place_character should fail for invalid position")
		return false

	return true

func test_place_in_first_empty() -> bool:
	var grid = _create_grid()
	var char1 = _create_test_character("char1")
	var char2 = _create_test_character("char2")

	# First character should go to (0, 0)
	var success = grid.place_character_in_first_empty(char1)
	if not success:
		push_error("place_character_in_first_empty should succeed")
		return false

	if char1.grid_position != Vector2i(0, 0):
		push_error("First character should be at (0, 0), got %s" % str(char1.grid_position))
		return false

	# Second character should go to (0, 1)
	success = grid.place_character_in_first_empty(char2)
	if not success:
		push_error("Second place should succeed")
		return false

	if char2.grid_position != Vector2i(0, 1):
		push_error("Second character should be at (0, 1), got %s" % str(char2.grid_position))
		return false

	return true

func test_remove_character() -> bool:
	var grid = _create_grid()
	var char1 = _create_test_character("char1")

	grid.place_character(char1, 1, 2)

	# Remove character
	var removed = grid.remove_character(1, 2)
	if removed != char1:
		push_error("remove_character should return the character")
		return false

	# Slot should be empty
	if not grid.is_slot_empty(1, 2):
		push_error("Slot should be empty after removal")
		return false

	# Character's grid_position should be cleared
	if char1.is_in_grid():
		push_error("Character should not be in grid after removal")
		return false

	# Removing from empty slot should return null
	removed = grid.remove_character(1, 2)
	if removed != null:
		push_error("remove_character from empty slot should return null")
		return false

	return true

func test_swap_positions() -> bool:
	var grid = _create_grid()
	var char1 = _create_test_character("char1")
	var char2 = _create_test_character("char2")

	grid.place_character(char1, 0, 0)
	grid.place_character(char2, 1, 1)

	# Swap characters
	var success = grid.swap_positions(0, 0, 1, 1)
	if not success:
		push_error("swap_positions should succeed")
		return false

	# Characters should have swapped positions
	if grid.get_character_at(0, 0) != char2:
		push_error("char2 should be at (0, 0) after swap")
		return false

	if grid.get_character_at(1, 1) != char1:
		push_error("char1 should be at (1, 1) after swap")
		return false

	# Grid positions should be updated
	if char1.grid_position != Vector2i(1, 1):
		push_error("char1 grid_position should be (1, 1)")
		return false

	if char2.grid_position != Vector2i(0, 0):
		push_error("char2 grid_position should be (0, 0)")
		return false

	return true

func test_move_character() -> bool:
	var grid = _create_grid()
	var char1 = _create_test_character("char1")

	grid.place_character(char1, 0, 0)

	# Move to empty slot
	var success = grid.move_character(0, 0, 1, 2)
	if not success:
		push_error("move_character should succeed")
		return false

	# Old slot should be empty
	if not grid.is_slot_empty(0, 0):
		push_error("Old slot should be empty")
		return false

	# New slot should have character
	if grid.get_character_at(1, 2) != char1:
		push_error("Character should be at new position")
		return false

	# Move to occupied slot should fail
	var char2 = _create_test_character("char2")
	grid.place_character(char2, 0, 0)

	success = grid.move_character(0, 0, 1, 2)
	if success:
		push_error("move_character to occupied slot should fail")
		return false

	return true

func test_is_full() -> bool:
	var grid = _create_grid()

	# Fill the grid
	for i in range(6):
		var char_instance = _create_test_character("char%d" % i)
		grid.place_character_in_first_empty(char_instance)

	if not grid.is_full():
		push_error("Grid should be full with 6 characters")
		return false

	if grid.get_character_count() != 6:
		push_error("Character count should be 6")
		return false

	# Placing another should fail
	var extra = _create_test_character("extra")
	var success = grid.place_character_in_first_empty(extra)
	if success:
		push_error("place_character_in_first_empty should fail when full")
		return false

	return true

func test_get_all_characters() -> bool:
	var grid = _create_grid()
	var char1 = _create_test_character("char1")
	var char2 = _create_test_character("char2")
	var char3 = _create_test_character("char3")

	grid.place_character(char1, 0, 0)
	grid.place_character(char2, 0, 2)
	grid.place_character(char3, 1, 1)

	var all_chars = grid.get_all_characters()
	if all_chars.size() != 3:
		push_error("Should have 3 characters, got %d" % all_chars.size())
		return false

	# Check all characters are present
	if not all_chars.has(char1) or not all_chars.has(char2) or not all_chars.has(char3):
		push_error("get_all_characters should return all placed characters")
		return false

	return true

func test_get_front_back_rows() -> bool:
	var grid = _create_grid()
	var front1 = _create_test_character("front1")
	var front2 = _create_test_character("front2")
	var back1 = _create_test_character("back1")

	grid.place_character(front1, 0, 0)
	grid.place_character(front2, 0, 2)
	grid.place_character(back1, 1, 1)

	var front_row = grid.get_front_row()
	if front_row.size() != 2:
		push_error("Front row should have 2 characters, got %d" % front_row.size())
		return false

	var back_row = grid.get_back_row()
	if back_row.size() != 1:
		push_error("Back row should have 1 character, got %d" % back_row.size())
		return false

	if not front_row.has(front1) or not front_row.has(front2):
		push_error("Front row should contain front characters")
		return false

	if not back_row.has(back1):
		push_error("Back row should contain back character")
		return false

	return true

func test_serialization() -> bool:
	var grid = _create_grid()
	var char1 = _create_test_character("char1")
	var char2 = _create_test_character("char2")

	grid.place_character(char1, 0, 1)
	grid.place_character(char2, 1, 2)

	# Serialize
	var data = grid.to_dict()
	if not data.has("grid"):
		push_error("Serialized data should have 'grid' key")
		return false

	# Deserialize
	var restored = CharacterGrid.from_dict(data)
	if restored.get_character_count() != 2:
		push_error("Restored grid should have 2 characters, got %d" % restored.get_character_count())
		return false

	# Check positions are preserved
	var restored_at_01 = restored.get_character_at(0, 1)
	var restored_at_12 = restored.get_character_at(1, 2)

	if restored_at_01 == null or restored_at_12 == null:
		push_error("Characters should be restored at correct positions")
		return false

	# Check empty slots are preserved
	if not restored.is_slot_empty(0, 0):
		push_error("Empty slots should remain empty after restore")
		return false

	return true
