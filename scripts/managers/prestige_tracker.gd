class_name PrestigeTracker
extends RefCounted
# PrestigeTracker - Reusable prestige/fame tracking for any entity
# Extracted to follow DRY principle - can be used by Legacy, future systems
# Follows Single Responsibility Principle - only tracks prestige/fame

## Emitted when fame value changes
signal fame_changed(new_fame: int)
## Emitted when prestige increases (may fire multiple times if fame overflow)
signal prestige_up(new_prestige: int)

# Current state
var _prestige: int = 1
var _fame: int = 0

# Configuration (from GameConstants for consistency)
const FAME_PER_PRESTIGE: int = 100


# =============================================================================
# ACCESSORS
# =============================================================================

func get_prestige() -> int:
	"""Get current prestige level."""
	return _prestige


func get_fame() -> int:
	"""Get current fame (progress toward next prestige)."""
	return _fame


func get_fame_progress() -> float:
	"""Get fame progress as percentage (0.0 to 1.0)."""
	return float(_fame) / float(FAME_PER_PRESTIGE)


# =============================================================================
# FAME OPERATIONS
# =============================================================================

func add_fame(amount: int) -> Dictionary:
	"""
	Add fame, potentially increasing prestige.

	Args:
		amount: Fame to add (must be positive)

	Returns:
		Dictionary with:
		- prestige_increased: bool - whether prestige went up
		- new_prestige: int - current prestige after operation
		- overflow_fame: int - remaining fame after prestige increases
		- levels_gained: int - how many prestige levels were gained
	"""
	if amount <= 0:
		return {
			"prestige_increased": false,
			"new_prestige": _prestige,
			"overflow_fame": _fame,
			"levels_gained": 0
		}

	_fame += amount
	var result = {
		"prestige_increased": false,
		"new_prestige": _prestige,
		"levels_gained": 0
	}

	# Process prestige increases
	while _fame >= FAME_PER_PRESTIGE:
		_fame -= FAME_PER_PRESTIGE
		_prestige += 1
		result.prestige_increased = true
		result.new_prestige = _prestige
		result.levels_gained += 1
		prestige_up.emit(_prestige)

	fame_changed.emit(_fame)
	result.overflow_fame = _fame
	return result


func set_fame(amount: int) -> void:
	"""Set fame directly (for loading from save)."""
	_fame = max(0, amount)


func set_prestige(level: int) -> void:
	"""Set prestige directly (for loading from save)."""
	_prestige = max(1, level)


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize tracker state for saving."""
	return {
		"prestige": _prestige,
		"fame": _fame
	}


static func from_dict(data: Dictionary) -> PrestigeTracker:
	"""Create tracker from saved data."""
	var tracker = PrestigeTracker.new()
	tracker._prestige = data.get("prestige", 1)
	tracker._fame = data.get("fame", 0)
	return tracker


# =============================================================================
# UTILITY
# =============================================================================

func reset() -> void:
	"""Reset to initial state (prestige 1, fame 0)."""
	_prestige = 1
	_fame = 0
	fame_changed.emit(_fame)


func duplicate_tracker() -> PrestigeTracker:
	"""Create a copy of this tracker."""
	var copy = PrestigeTracker.new()
	copy._prestige = _prestige
	copy._fame = _fame
	return copy
