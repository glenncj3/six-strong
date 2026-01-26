extends SceneTree
# Test runner that executes all test files in the tests directory
# Run with: godot --headless --script res://tests/run_all_tests.gd
#
# Tests are discovered by looking for files matching test_*.gd
# Each test file should extend SceneTree and call quit() when done

var test_files: Array[String] = []
var current_test_index := 0
var total_passed := 0
var total_failed := 0


func _init():
	call_deferred("_discover_and_run_tests")


func _discover_and_run_tests():
	print("\n================================================")
	print("AUTO-BATTLE JOURNEY TEST SUITE")
	print("================================================\n")

	_discover_tests()

	if test_files.is_empty():
		print("No test files found!")
		quit(1)
		return

	print("Found %d test file(s):" % test_files.size())
	for file in test_files:
		print("  - %s" % file)
	print("")

	# Note: In Godot, we can't easily run multiple SceneTree scripts sequentially
	# Each test file needs to be run as a separate process
	# This script outputs the commands to run each test

	print("To run all tests, execute these commands:\n")
	for file in test_files:
		var godot_path = "\"C:\\Program Files\\Godot\\Godot_v4.5.1-stable_win64.exe\""
		var project_path = "\"C:\\Users\\glenn\\Dev\\auto-battle-journey\""
		print("%s --headless --path %s --script res://%s" % [godot_path, project_path, file])

	print("\n================================================")
	print("Or run tests individually for detailed output")
	print("================================================\n")

	quit(0)


func _discover_tests():
	# Discover test files in tests/ directory
	var dir = DirAccess.open("res://tests")
	if dir == null:
		push_error("Cannot open tests directory")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd"):
			test_files.append("tests/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Also check subdirectories
	_discover_tests_in_dir("res://tests/unit")
	_discover_tests_in_dir("res://tests/integration")

	test_files.sort()


func _discover_tests_in_dir(dir_path: String):
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return  # Directory doesn't exist yet, that's OK

	var relative_path = dir_path.replace("res://", "")

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd"):
			test_files.append(relative_path + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
