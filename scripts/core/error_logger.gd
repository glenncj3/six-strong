class_name ErrorLogger
## Centralized error logging with history for debugging.
## Stores recent errors with timestamps and categories.
## Usage:
##   ErrorLogger.log_error("GOLD", "INSUFFICIENT_GOLD", "Cannot afford 50g")
##   ErrorLogger.log_warning("INVENTORY", "Item already owned: sword_01")
##   var recent = ErrorLogger.get_recent_errors(10)

const MAX_HISTORY := 100

static var _history: Array[Dictionary] = []


static func log_error(category: String, code: String, message: String = "") -> void:
	"""Log an error with category and code."""
	_add_entry("error", category, code, message)
	push_error("[%s] %s: %s" % [category, code, message])


static func log_warning(category: String, message: String) -> void:
	"""Log a warning with category."""
	_add_entry("warning", category, "", message)
	push_warning("[%s] %s" % [category, message])


static func log_info(category: String, message: String) -> void:
	"""Log an info message with category."""
	_add_entry("info", category, "", message)


static func _add_entry(level: String, category: String, code: String, message: String) -> void:
	"""Add an entry to the history."""
	_history.append({
		"level": level,
		"category": category,
		"code": code,
		"message": message,
		"timestamp": Time.get_ticks_msec()
	})
	if _history.size() > MAX_HISTORY:
		_history.pop_front()


static func get_recent_errors(count: int = 10) -> Array[Dictionary]:
	"""Get the most recent error entries."""
	var result: Array[Dictionary] = []
	var start = maxi(0, _history.size() - count)
	for i in range(start, _history.size()):
		if _history[i].level == "error":
			result.append(_history[i])
	return result


static func get_recent(count: int = 10) -> Array[Dictionary]:
	"""Get the most recent log entries of any level."""
	var start = maxi(0, _history.size() - count)
	var result: Array[Dictionary] = []
	for i in range(start, _history.size()):
		result.append(_history[i])
	return result


static func get_by_category(category: String, count: int = 10) -> Array[Dictionary]:
	"""Get recent entries for a specific category."""
	var result: Array[Dictionary] = []
	for i in range(_history.size() - 1, -1, -1):
		if _history[i].category == category:
			result.append(_history[i])
			if result.size() >= count:
				break
	result.reverse()
	return result


static func clear() -> void:
	"""Clear all log history."""
	_history.clear()


static func get_history_size() -> int:
	"""Get the number of entries in the history."""
	return _history.size()
