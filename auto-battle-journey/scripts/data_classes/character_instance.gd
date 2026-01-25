class_name CharacterInstance
extends RefCounted
# CharacterInstance - Runtime representation of a character during a run
# This is a CLONE of account data - modifications don't affect the account
# Refactored to use StatCalculator for DRY stat calculations

# Persistent identifiers
var base_character_id: String = ""

# Runtime progression
var level: int = 1
var experience: int = 0

# Current state
var current_health: int = 0

# Stats dictionary (data-driven, supports any stat)
var stats: Dictionary = {}

# Equipment and skills during this run
var equipped_items: Array[String] = []
var equipped_item_upgrades: Array[String] = []
var learned_skills: Array[String] = []

# Optional: injected data source for testing (Dependency Inversion)
var _game_data: Node = null


func _init(char_data: Dictionary, game_data: Node = null) -> void:
	"""
	Initialize from player's character data.

	Args:
		char_data: Character data from PlayerAccount
		game_data: Optional injected GameData for testing (defaults to global)
	"""
	_game_data = game_data if game_data != null else GameData

	base_character_id = char_data.get("id", "")

	# Get master data
	var char_master = _get_game_data().get_character_by_id(base_character_id)
	if char_master.is_empty():
		push_error("CharacterInstance: Master data not found for %s" % base_character_id)
		return

	# Copy equipped items from account
	if char_data.has("equipped_items"):
		equipped_items = Array(char_data["equipped_items"].duplicate(), TYPE_STRING, "", null)

	# Calculate initial stats using StatCalculator
	stats = StatCalculator.calculate_runtime_stats(
		char_master,
		char_data,
		equipped_items,
		equipped_item_upgrades,
		learned_skills
	)

	# Set health to max
	current_health = stats.get(GameConstants.STAT_HEALTH, 0)


func _get_game_data() -> Node:
	"""Get game data source (supports dependency injection)."""
	return _game_data if _game_data != null else GameData


# =============================================================================
# STAT ACCESSORS (for backwards compatibility)
# =============================================================================

var max_health: int:
	get: return stats.get(GameConstants.STAT_HEALTH, 0)
	set(value): stats[GameConstants.STAT_HEALTH] = value

var mana: int:
	get: return stats.get(GameConstants.STAT_MANA, 0)
	set(value): stats[GameConstants.STAT_MANA] = value

var income: int:
	get: return stats.get(GameConstants.STAT_INCOME, 0)
	set(value): stats[GameConstants.STAT_INCOME] = value

var defend_rate: int:
	get: return stats.get(GameConstants.STAT_DEFEND_RATE, 0)
	set(value): stats[GameConstants.STAT_DEFEND_RATE] = value

var item_slots: int:
	get: return stats.get(GameConstants.STAT_ITEM_SLOTS, 9)
	set(value): stats[GameConstants.STAT_ITEM_SLOTS] = value

var starting_item_slots: int:
	get: return stats.get(GameConstants.STAT_STARTING_ITEM_SLOTS, 0)
	set(value): stats[GameConstants.STAT_STARTING_ITEM_SLOTS] = value


# =============================================================================
# PROGRESSION
# =============================================================================

func add_experience(xp: int) -> bool:
	"""
	Add experience, returns true if leveled up.
	"""
	experience += xp

	if experience >= GameConstants.XP_PER_LEVEL:
		experience -= GameConstants.XP_PER_LEVEL
		level += 1
		return true

	return false


# =============================================================================
# SKILLS
# =============================================================================

func learn_skill(skill_id: String) -> bool:
	"""Learn a new skill during the run."""
	if learned_skills.size() >= GameConstants.MAX_RUN_SKILLS:
		push_warning("CharacterInstance: Max skills reached (%d)" % GameConstants.MAX_RUN_SKILLS)
		return false

	if skill_id in learned_skills:
		push_warning("CharacterInstance: Skill already learned: %s" % skill_id)
		return false

	var skill_data = _get_game_data().get_skill_by_id(skill_id)
	if skill_data.is_empty():
		return false

	learned_skills.append(skill_id)

	# Apply skill effects using StatCalculator
	var effects = skill_data.get("effects", [])
	for effect in effects:
		var effect_type = effect.get("type", "stat_add")
		var stat_name = effect.get("stat", "")
		var value = effect.get("value", 0)

		StatCalculator.apply_modifier(stats, stat_name, value, effect_type == "stat_multiply")

	return true


# =============================================================================
# ITEM UPGRADES
# =============================================================================

func equip_item_upgrade(item_upgrade_id: String) -> bool:
	"""
	Equip an item upgrade found during the run.
	"""
	var total_items = equipped_items.size() + equipped_item_upgrades.size()
	if total_items >= GameConstants.MAX_RUN_ITEMS:
		push_warning("CharacterInstance: Max items reached (%d)" % GameConstants.MAX_RUN_ITEMS)
		return false

	if item_upgrade_id in equipped_item_upgrades:
		push_warning("CharacterInstance: Item upgrade already equipped: %s" % item_upgrade_id)
		return false

	var upgrade_data = _get_game_data().get_item_upgrade_by_id(item_upgrade_id)
	if upgrade_data.is_empty():
		return false

	equipped_item_upgrades.append(item_upgrade_id)

	# Apply stat modifiers using StatCalculator
	var modifiers = upgrade_data.get("stat_modifiers", {})
	for stat_name in modifiers:
		StatCalculator.apply_modifier(stats, stat_name, modifiers[stat_name], false)

	return true


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


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	"""Serialize to dictionary for saving."""
	return {
		"base_character_id": base_character_id,
		"level": level,
		"experience": experience,
		"current_health": current_health,
		"stats": stats.duplicate(),
		"equipped_items": Array(equipped_items),
		"equipped_item_upgrades": Array(equipped_item_upgrades),
		"learned_skills": Array(learned_skills)
	}


static func from_dict(data: Dictionary, game_data: Node = null) -> CharacterInstance:
	"""Deserialize from dictionary (for loading saves)."""
	# Create instance with minimal data
	var instance = CharacterInstance.new({
		"id": data.get("base_character_id", ""),
		"equipped_items": data.get("equipped_items", []),
		"rank": 1
	}, game_data)

	# Restore runtime state
	instance.level = data.get("level", 1)
	instance.experience = data.get("experience", 0)
	instance.current_health = data.get("current_health", 0)

	# Restore stats if saved (otherwise keep calculated)
	if data.has("stats"):
		instance.stats = data["stats"].duplicate()

	# Restore equipment and skills
	if data.has("equipped_item_upgrades"):
		instance.equipped_item_upgrades = Array(data["equipped_item_upgrades"], TYPE_STRING, "", null)
	if data.has("learned_skills"):
		instance.learned_skills = Array(data["learned_skills"], TYPE_STRING, "", null)

	return instance


# =============================================================================
# UTILITY
# =============================================================================

func get_character_name() -> String:
	"""Get the character's name from master data."""
	var char_master = _get_game_data().get_character_by_id(base_character_id)
	return char_master.get("name", "Unknown")


func get_stat(stat_name: String) -> int:
	"""Get a stat value by name."""
	return stats.get(stat_name, 0)


func recalculate_stats(char_data: Dictionary) -> void:
	"""Recalculate all stats (useful after major changes)."""
	var char_master = _get_game_data().get_character_by_id(base_character_id)
	stats = StatCalculator.calculate_runtime_stats(
		char_master,
		char_data,
		equipped_items,
		equipped_item_upgrades,
		learned_skills
	)
