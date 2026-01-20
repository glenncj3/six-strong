class_name JsonPersistence
extends RefCounted
# JsonPersistence - Unified JSON file loading and saving
# Eliminates duplicate file I/O code across the codebase

# =============================================================================
# LOADING
# =============================================================================

static func load_json(path: String) -> Variant:
	"""
	Load and parse a JSON file.

	Args:
		path: File path (res:// or user://)

	Returns:
		Parsed JSON data, or null on failure
	"""
	if not FileAccess.file_exists(path):
		push_error("JsonPersistence: File not found: %s" % path)
		return null

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("JsonPersistence: Could not open file: %s (error: %s)" % [path, FileAccess.get_open_error()])
		return null

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("JsonPersistence: JSON parse error in %s at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()
		])
		return null

	return json.data


static func load_json_or_default(path: String, default_value: Variant) -> Variant:
	"""
	Load JSON file, returning default value if file doesn't exist or fails to parse.

	Args:
		path: File path
		default_value: Value to return on failure

	Returns:
		Parsed JSON data or default_value
	"""
	var data = load_json(path)
	if data == null:
		return default_value
	return data


static func file_exists(path: String) -> bool:
	"""Check if a file exists."""
	return FileAccess.file_exists(path)


# =============================================================================
# SAVING
# =============================================================================

static func save_json(path: String, data: Variant, pretty_print: bool = true) -> bool:
	"""
	Save data to a JSON file.

	Args:
		path: File path (typically user://)
		data: Data to serialize (Dictionary or Array)
		pretty_print: If true, format with indentation

	Returns:
		true on success, false on failure
	"""
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("JsonPersistence: Could not open file for writing: %s (error: %s)" % [
			path, FileAccess.get_open_error()
		])
		return false

	var json_string: String
	if pretty_print:
		json_string = JSON.stringify(data, "\t")
	else:
		json_string = JSON.stringify(data)

	file.store_string(json_string)
	file.close()

	return true


# =============================================================================
# FILE MANAGEMENT
# =============================================================================

static func delete_file(path: String) -> bool:
	"""
	Delete a file if it exists.

	Args:
		path: File path

	Returns:
		true if deleted or didn't exist, false on error
	"""
	if not FileAccess.file_exists(path):
		return true

	var error = DirAccess.remove_absolute(path)
	if error != OK:
		push_error("JsonPersistence: Could not delete file: %s (error: %d)" % [path, error])
		return false

	return true


static func ensure_directory_exists(dir_path: String) -> bool:
	"""
	Ensure a directory exists, creating it if necessary.

	Args:
		dir_path: Directory path

	Returns:
		true if directory exists or was created
	"""
	if DirAccess.dir_exists_absolute(dir_path):
		return true

	var error = DirAccess.make_dir_recursive_absolute(dir_path)
	if error != OK:
		push_error("JsonPersistence: Could not create directory: %s (error: %d)" % [dir_path, error])
		return false

	return true
