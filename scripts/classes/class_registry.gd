class_name ClassRegistry
extends RefCounted
## Data-driven class definitions registry.
## Loads class definitions from JSON and provides lookup methods.
## Replaces hardcoded class type constants in GameConstants.
##
## Usage:
##   ClassRegistry.get_all_class_ids()  # Returns ["warrior", "mage", ...]
##   ClassRegistry.get_display_name("warrior")  # Returns "Warrior"
##   ClassRegistry.is_valid_class("warrior")  # Returns true

# Static registry state (shared across all instances)
static var _classes: Dictionary = {}
static var _initialized: bool = false
static var _class_ids: Array[String] = []

const CLASSES_PATH := "res://data/classes/class_definitions.json"


# =============================================================================
# INITIALIZATION
# =============================================================================

static func initialize() -> void:
	"""
	Load class definitions from JSON. Called automatically on first access.
	Safe to call multiple times (no-op after first initialization).
	"""
	if _initialized:
		return

	var data = JsonPersistence.load_json(CLASSES_PATH)
	if data == null:
		push_error("ClassRegistry: Failed to load class definitions from %s" % CLASSES_PATH)
		_initialized = true  # Prevent repeated load attempts
		return

	if not data is Array:
		push_error("ClassRegistry: Invalid class definitions format (expected Array)")
		_initialized = true
		return

	_classes.clear()
	_class_ids.clear()

	for class_def in data:
		if not class_def is Dictionary or not class_def.has("id"):
			push_warning("ClassRegistry: Skipping invalid class entry: %s" % class_def)
			continue
		var id = class_def["id"]
		_classes[id] = class_def
		_class_ids.append(id)

	_initialized = true


static func reset() -> void:
	"""Reset the registry (for testing purposes)."""
	_classes.clear()
	_class_ids.clear()
	_initialized = false


# =============================================================================
# LOOKUP METHODS
# =============================================================================

static func get_all_class_ids() -> Array[String]:
	"""
	Get all registered class IDs.

	Returns:
		Array of class ID strings
	"""
	initialize()
	return _class_ids.duplicate()


static func get_display_name(id: String) -> String:
	"""
	Get the display name for a class.

	Args:
		id: Class identifier

	Returns:
		Display name or the id capitalized if not found
	"""
	initialize()
	return _classes.get(id, {}).get("display_name", id.capitalize())


static func get_description(id: String) -> String:
	"""
	Get the description for a class.

	Args:
		id: Class identifier

	Returns:
		Description or empty string if not found
	"""
	initialize()
	return _classes.get(id, {}).get("description", "")


static func is_valid_class(id: String) -> bool:
	"""
	Check if a class ID is valid (registered).

	Args:
		id: Class identifier to check

	Returns:
		True if the class is registered
	"""
	initialize()
	return _classes.has(id)


static func get_class_data(id: String) -> Dictionary:
	"""
	Get the full data dictionary for a class.

	Args:
		id: Class identifier

	Returns:
		Full class data dictionary or empty dict if not found
	"""
	initialize()
	return _classes.get(id, {}).duplicate()


static func get_all_classes() -> Array[Dictionary]:
	"""
	Get all class definitions.

	Returns:
		Array of class data dictionaries
	"""
	initialize()
	var result: Array[Dictionary] = []
	for id in _class_ids:
		result.append(_classes[id].duplicate())
	return result


static func get_display_names_map() -> Dictionary:
	"""
	Get a dictionary mapping class IDs to their display names.

	Returns:
		Dictionary mapping class ID strings to display name strings
	"""
	initialize()
	var result: Dictionary = {}
	for id in _class_ids:
		result[id] = _classes[id].get("display_name", id.capitalize())
	return result
