class_name UIFormattingHelpers
extends RefCounted
## Text and number formatting utilities for UI display.


static func format_currency(amount: int, symbol: String = "") -> String:
	"""
	Format a currency amount for display.

	Args:
		amount: The amount to format
		symbol: Optional symbol prefix (e.g., "G" for gold)

	Returns:
		Formatted string
	"""
	if symbol.is_empty():
		return str(amount)
	return "%s %d" % [symbol, amount]


static func format_stat(stat_name: String, value: int) -> String:
	"""
	Format a stat for compact display.

	Args:
		stat_name: Full stat name
		value: Stat value

	Returns:
		Formatted string (e.g., "HP 100")
	"""
	var short = GameConstants.STAT_DISPLAY_NAMES.get(stat_name, stat_name.to_upper().left(3))
	return "%s %d" % [short, value]


static func get_difficulty_color(difficulty: String) -> Color:
	"""
	Get the color for a combat difficulty level.

	Args:
		difficulty: Difficulty string ("Easy", "Medium", "Hard")

	Returns:
		Appropriate color from GameConstants
	"""
	match difficulty:
		"Easy":
			return GameConstants.COLOR_DIFFICULTY_EASY
		"Medium":
			return GameConstants.COLOR_DIFFICULTY_MEDIUM
		"Hard":
			return GameConstants.COLOR_DIFFICULTY_HARD
		_:
			return GameConstants.COLOR_DISABLED
