class_name CharacterInstance
extends RefCounted
# CharacterInstance - Runtime representation of a character during a run
# Characters are run-time acquisitions like items/skills.
# They have level_requirement in master data that gates when they appear.
# Stats = base_stats only (no leveling, no items/skills/prestige modifiers)

# Persistent identifiers
var base_character_id: String = ""

# Current state
var current_health: int = 0

# Stats dictionary (data-driven, supports any stat)
var stats: Dictionary = {}

# Grid position for 2x3 character grid
# Vector2i(row, column) where row 0 = front, row 1 = back
# Value of Vector2i(-1, -1) indicates not placed in grid
var grid_position: Vector2i = Vector2i(-1, -1)

# Optional: injected data source for testing (Dependency Inversion)
var _game_data: Node = null


func _init(char_data: Dictionary = {}, game_data = null) -> void:
	"""
	Initialize from character master data or save data.

	Args:
		char_data: Either master character data or saved character instance data
		game_data: Optional injected GameData for testing (defaults to global autoload)
	"""
	_game_data = game_data

	# Handle empty initialization (for factory methods)
	if char_data.is_empty():
		return

	base_character_id = char_data.get("id", "")

	# Get master data (only if game_data is available)
	var gd = _get_game_data()
	if gd == null:
		# No game data - stats must be set manually
		return

	var char_master = gd.get_character_by_id(base_character_id)
	if char_master.is_empty():
		push_error("CharacterInstance: Master data not found for %s" % base_character_id)
		return

	# Calculate initial stats using StatCalculator
	stats = StatCalculator.calculate_character_base_stats(char_master)

	# Set health to max
	current_health = stats.get(GameConstants.STAT_HEALTH, 0)


func _get_game_data():
	"""Get game data source (supports dependency injection)."""
	if _game_data != null:
		return _game_data
	# Try to get the autoload - may be null in test mode
	if Engine.has_singleton("GameData"):
		return Engine.get_singleton("GameData")
	# Check if it's available as an autoload node
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("/root/GameData"):
		return tree.root.get_node("/root/GameData")
	return null


# =============================================================================
# STAT ACCESSORS (for backwards compatibility)
# =============================================================================

var max_health: int:
	get: return stats.get(GameConstants.STAT_HEALTH, 0)
	set(value): stats[GameConstants.STAT_HEALTH] = value

var charges: int:
	get: return stats.get(GameConstants.STAT_CHARGES, 0)
	set(value): stats[GameConstants.STAT_CHARGES] = value

var agility: int:
	get: return stats.get(GameConstants.STAT_agility, 0)
	set(value): stats[GameConstants.STAT_agility] = value

var speed: int:
	get: return stats.get(GameConstants.STAT_SPEED, 0)
	set(value): stats[GameConstants.STAT_SPEED] = value

var damage: int:
	get: return stats.get(GameConstants.STAT_DAMAGE, 0)
	set(value): stats[GameConstants.STAT_DAMAGE] = value

var crit_chance: int:
	get: return stats.get(GameConstants.STAT_CRIT_CHANCE, 0)
	set(value): stats[GameConstants.STAT_CRIT_CHANCE] = value


# =============================================================================
# GRID PLACEMENT
# =============================================================================

func set_grid_position(row: int, col: int) -> void:
	"""Set the character's position in the 2x3 grid."""
	grid_position = Vector2i(row, col)


func clear_grid_position() -> void:
	"""Remove character from grid (set to invalid position)."""
	grid_position = Vector2i(-1, -1)


func is_in_grid() -> bool:
	"""Check if character is currently placed in the grid."""
	return grid_position.x >= 0 and grid_position.y >= 0


func is_front_row() -> bool:
	"""Check if character is in the front row (row 0)."""
	return grid_position.x == 0


func is_back_row() -> bool:
	"""Check if character is in the back row (row 1)."""
	return grid_position.x == 1


# =============================================================================
# COMBAT
# =============================================================================

func take_damage(amount: int) -> void:
	"""Take damage, clamped to 0."""
	current_health = max(0, current_health - amount)


func heal(amount: int) -> void:
	"""Heal, clamped to max health."""
	current_health = min(max_health, current_health + amount)


func is_alive() -> bool:
	"""Check if character is still alive."""
	return current_health > 0


func restore_full_health() -> void:
	"""Restore character to full health."""
	current_health = max_health


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize to dictionary for saving."""
	return {
		"base_character_id": base_character_id,
		"current_health": current_health,
		"stats": stats.duplicate(),
		"grid_position": {"x": grid_position.x, "y": grid_position.y}
	}


static func from_dict(data: Dictionary, game_data = null) -> CharacterInstance:
	"""Deserialize from dictionary (for loading saves)."""
	var instance = CharacterInstance.new({}, game_data)

	instance.base_character_id = data.get("base_character_id", "")
	instance.current_health = data.get("current_health", 0)

	# Restore stats if saved (otherwise recalculate)
	if data.has("stats"):
		instance.stats = data["stats"].duplicate()
	else:
		# Recalculate from master data if game_data available
		var gd = instance._get_game_data()
		if gd != null:
			var char_master = gd.get_character_by_id(instance.base_character_id)
			if not char_master.is_empty():
				instance.stats = StatCalculator.calculate_character_base_stats(char_master)

	# Restore grid position
	if data.has("grid_position"):
		var pos = data["grid_position"]
		instance.grid_position = Vector2i(pos.get("x", -1), pos.get("y", -1))

	return instance


static func from_master_data(char_id: String, game_data = null) -> CharacterInstance:
	"""Create a new character instance directly from master data (character ID)."""
	# Create instance first to use its _get_game_data method
	var instance = CharacterInstance.new({}, game_data)
	var gd = instance._get_game_data()
	if gd == null:
		push_error("CharacterInstance: GameData not available")
		return null

	var char_master = gd.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("CharacterInstance: Master data not found for %s" % char_id)
		return null

	return CharacterInstance.new({"id": char_id}, game_data)


# =============================================================================
# UTILITY
# =============================================================================

func get_character_name() -> String:
	"""Get the character's name from master data."""
	var gd = _get_game_data()
	if gd == null:
		return "Unknown"
	var char_master = gd.get_character_by_id(base_character_id)
	return char_master.get("name", "Unknown")


func get_character_description() -> String:
	"""Get the character's description from master data."""
	var gd = _get_game_data()
	if gd == null:
		return ""
	var char_master = gd.get_character_by_id(base_character_id)
	return char_master.get("description", "")


func get_stat(stat_name: String) -> int:
	"""Get a stat value by name."""
	return stats.get(stat_name, 0)


func recalculate_stats() -> void:
	"""Recalculate all stats from master data (useful after major changes)."""
	var gd = _get_game_data()
	if gd == null:
		return
	var char_master = gd.get_character_by_id(base_character_id)
	if char_master.is_empty():
		return
	stats = StatCalculator.calculate_character_base_stats(char_master)
