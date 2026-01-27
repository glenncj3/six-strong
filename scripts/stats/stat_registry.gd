class_name StatRegistry
extends RefCounted
## Data-driven stat definitions registry.
## Loads stat definitions from JSON and provides lookup methods.
## Replaces hardcoded stat constants in GameConstants.
##
## Usage:
##   StatRegistry.get_all_stat_ids()  # Returns ["health", "mana", ...]
##   StatRegistry.get_display_name("health")  # Returns "HP"
##   StatRegistry.get_default_value("health")  # Returns 100

# Static registry state (shared across all instances)
static var _stats: Dictionary = {}
static var _initialized: bool = false
static var _stat_ids: Array[String] = []

const STATS_PATH := "res://data/stats/stat_definitions.json"


# =============================================================================
# INITIALIZATION
# =============================================================================

static func initialize() -> void:
	"""
	Load stat definitions from JSON. Called automatically on first access.
	Safe to call multiple times (no-op after first initialization).
	"""
	if _initialized:
		return

	var data = JsonPersistence.load_json(STATS_PATH)
	if data == null:
		push_error("StatRegistry: Failed to load stat definitions from %s" % STATS_PATH)
		_initialized = true  # Prevent repeated load attempts
		return

	if not data is Array:
		push_error("StatRegistry: Invalid stat definitions format (expected Array)")
		_initialized = true
		return

	_stats.clear()
	_stat_ids.clear()

	for stat in data:
		if not stat is Dictionary or not stat.has("id"):
			push_warning("StatRegistry: Skipping invalid stat entry: %s" % stat)
			continue
		var id = stat["id"]
		_stats[id] = stat
		_stat_ids.append(id)

	_initialized = true


static func reset() -> void:
	"""Reset the registry (for testing purposes)."""
	_stats.clear()
	_stat_ids.clear()
	_initialized = false


# =============================================================================
# LOOKUP METHODS
# =============================================================================

static func get_all_stat_ids() -> Array[String]:
	"""
	Get all registered stat IDs.

	Returns:
		Array of stat ID strings
	"""
	initialize()
	return _stat_ids.duplicate()


static func get_display_name(id: String) -> String:
	"""
	Get the display name for a stat.

	Args:
		id: Stat identifier

	Returns:
		Display name or the id itself if not found
	"""
	initialize()
	return _stats.get(id, {}).get("display_name", id)


static func get_default_value(id: String) -> Variant:
	"""
	Get the default value for a stat.

	Args:
		id: Stat identifier

	Returns:
		Default value or 0 if not found
	"""
	initialize()
	return _stats.get(id, {}).get("default", 0)


static func get_description(id: String) -> String:
	"""
	Get the description for a stat.

	Args:
		id: Stat identifier

	Returns:
		Description or empty string if not found
	"""
	initialize()
	return _stats.get(id, {}).get("description", "")


static func is_valid_stat(id: String) -> bool:
	"""
	Check if a stat ID is valid (registered).

	Args:
		id: Stat identifier to check

	Returns:
		True if the stat is registered
	"""
	initialize()
	return _stats.has(id)


static func get_stat_data(id: String) -> Dictionary:
	"""
	Get the full data dictionary for a stat.

	Args:
		id: Stat identifier

	Returns:
		Full stat data dictionary or empty dict if not found
	"""
	initialize()
	return _stats.get(id, {}).duplicate()


static func get_all_stats() -> Array[Dictionary]:
	"""
	Get all stat definitions.

	Returns:
		Array of stat data dictionaries
	"""
	initialize()
	var result: Array[Dictionary] = []
	for id in _stat_ids:
		result.append(_stats[id].duplicate())
	return result


static func get_default_stats() -> Dictionary:
	"""
	Get a dictionary with all stats set to their default values.

	Returns:
		Dictionary mapping stat IDs to their default values
	"""
	initialize()
	var result: Dictionary = {}
	for id in _stat_ids:
		result[id] = _stats[id].get("default", 0)
	return result
