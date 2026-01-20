class_name CurrencyManager
extends RefCounted
# CurrencyManager - Handles all currency operations
# Split from PlayerAccount for Single Responsibility Principle

signal gems_changed(new_amount: int)
signal reroll_tokens_changed(new_amount: int)

var _gems: int = 0
var _reroll_tokens: int = 0

# Callback for persistence (injected by PlayerAccount)
var _on_change_callback: Callable = Callable()


func _init(gems: int = 0, reroll_tokens: int = 0) -> void:
	_gems = gems
	_reroll_tokens = reroll_tokens


# =============================================================================
# PERSISTENCE INTEGRATION
# =============================================================================

func set_change_callback(callback: Callable) -> void:
	"""Set callback to be called when currencies change (for persistence)."""
	_on_change_callback = callback


func _notify_change() -> void:
	"""Notify that data changed (triggers save)."""
	if _on_change_callback.is_valid():
		_on_change_callback.call()


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize currency data for saving."""
	return {
		"gems": _gems,
		"reroll_tokens": _reroll_tokens
	}


static func from_dict(data: Dictionary) -> CurrencyManager:
	"""Create CurrencyManager from saved data."""
	return CurrencyManager.new(
		data.get("gems", GameConstants.STARTING_GEMS),
		data.get("reroll_tokens", GameConstants.STARTING_REROLL_TOKENS)
	)


# =============================================================================
# GEMS
# =============================================================================

func get_gems() -> int:
	return _gems


func add_gems(amount: int) -> void:
	"""Add gems (from rewards, etc.)."""
	if amount <= 0:
		return
	_gems += amount
	gems_changed.emit(_gems)
	_notify_change()


func spend_gems(amount: int) -> bool:
	"""
	Spend gems if sufficient balance.

	Returns:
		true if spent successfully, false if insufficient
	"""
	if amount <= 0:
		return true
	if _gems < amount:
		return false

	_gems -= amount
	gems_changed.emit(_gems)
	_notify_change()
	return true


func can_afford_gems(amount: int) -> bool:
	"""Check if player can afford a gem cost."""
	return _gems >= amount


# =============================================================================
# REROLL TOKENS
# =============================================================================

func get_reroll_tokens() -> int:
	return _reroll_tokens


func add_reroll_token(amount: int = 1) -> void:
	"""Add reroll tokens."""
	if amount <= 0:
		return
	_reroll_tokens += amount
	reroll_tokens_changed.emit(_reroll_tokens)
	_notify_change()


func spend_reroll_token() -> bool:
	"""
	Spend a reroll token if available.

	Returns:
		true if spent successfully, false if none available
	"""
	if _reroll_tokens <= 0:
		return false

	_reroll_tokens -= 1
	reroll_tokens_changed.emit(_reroll_tokens)
	_notify_change()
	return true


func has_reroll_tokens() -> bool:
	"""Check if player has any reroll tokens."""
	return _reroll_tokens > 0
