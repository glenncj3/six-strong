extends Node
# GameData Singleton
# Loads and caches all master data (characters, items, skills, encounters)
# This is the single source of truth for all game content definitions
# Refactored to use JsonPersistence utility

# Cached data dictionaries
var characters: Dictionary = {}  # id -> character_data
var items: Dictionary = {}  # id -> item_data
var item_upgrades: Dictionary = {}  # id -> item_upgrade_data
var skills: Dictionary = {}  # id -> skill_data
var encounter_types: Array = []  # Array of encounter type definitions

# Data file paths
const CHARACTERS_PATH = "res://data/characters/characters.json"
const ITEMS_PATH = "res://data/items/items.json"
const ITEM_UPGRADES_PATH = "res://data/items/item_upgrades.json"
const SKILLS_PATH = "res://data/skills/skills.json"
const ENCOUNTERS_PATH = "res://data/encounters/encounter_types.json"


func _ready() -> void:
	load_all_data()


func load_all_data() -> void:
	"""Load all master data from JSON files."""
	print("GameData: Loading all master data...")

	_load_characters()
	_load_items()
	_load_item_upgrades()
	_load_skills()
	_load_encounter_types()

	print("GameData: All data loaded successfully")
	print("  - Characters: %d" % characters.size())
	print("  - Items: %d" % items.size())
	print("  - Item Upgrades: %d" % item_upgrades.size())
	print("  - Skills: %d" % skills.size())
	print("  - Encounter Types: %d" % encounter_types.size())


func _load_data_collection(path: String, container_key: String, target_dict: Dictionary) -> void:
	"""
	Generic helper to load a JSON array into a dictionary keyed by id.

	Args:
		path: Path to JSON file
		container_key: Key in JSON that contains the array (e.g., "characters")
		target_dict: Dictionary to populate with id -> data mappings
	"""
	var data = JsonPersistence.load_json(path)
	if data and data.has(container_key):
		for item_data in data[container_key]:
			if item_data.has("id"):
				target_dict[item_data["id"]] = item_data


func _load_characters() -> void:
	_load_data_collection(CHARACTERS_PATH, "characters", characters)


func _load_items() -> void:
	_load_data_collection(ITEMS_PATH, "items", items)


func _load_item_upgrades() -> void:
	_load_data_collection(ITEM_UPGRADES_PATH, "item_upgrades", item_upgrades)


func _load_skills() -> void:
	_load_data_collection(SKILLS_PATH, "skills", skills)


func _load_encounter_types() -> void:
	var data = JsonPersistence.load_json(ENCOUNTERS_PATH)
	if data and data.has("encounter_types"):
		encounter_types = data["encounter_types"]


# =============================================================================
# PUBLIC API - Character Data
# =============================================================================

func get_character_by_id(id: String) -> Dictionary:
	"""Get character data by ID."""
	if characters.has(id):
		return characters[id]
	push_warning("GameData: Character not found: %s" % id)
	return {}


func get_all_characters() -> Array:
	"""Get array of all character data."""
	return characters.values()


func has_character(id: String) -> bool:
	"""Check if character exists."""
	return characters.has(id)


# =============================================================================
# PUBLIC API - Item Data
# =============================================================================

func get_item_by_id(id: String) -> Dictionary:
	"""Get item data by ID."""
	if items.has(id):
		return items[id]
	push_warning("GameData: Item not found: %s" % id)
	return {}


func get_all_items() -> Array:
	"""Get array of all item data."""
	return items.values()


func has_item(id: String) -> bool:
	"""Check if item exists."""
	return items.has(id)


# =============================================================================
# PUBLIC API - Item Upgrade Data
# =============================================================================

func get_item_upgrade_by_id(id: String) -> Dictionary:
	"""Get item upgrade data by ID."""
	if item_upgrades.has(id):
		return item_upgrades[id]
	push_warning("GameData: Item upgrade not found: %s" % id)
	return {}


func get_all_item_upgrades() -> Array:
	"""Get array of all item upgrade data."""
	return item_upgrades.values()


func has_item_upgrade(id: String) -> bool:
	"""Check if item upgrade exists."""
	return item_upgrades.has(id)


# =============================================================================
# PUBLIC API - Skill Data
# =============================================================================

func get_skill_by_id(id: String) -> Dictionary:
	"""Get skill data by ID."""
	if skills.has(id):
		return skills[id]
	push_warning("GameData: Skill not found: %s" % id)
	return {}


func get_all_skills() -> Array:
	"""Get array of all skill data."""
	return skills.values()


func has_skill(id: String) -> bool:
	"""Check if skill exists."""
	return skills.has(id)


# =============================================================================
# PUBLIC API - Encounter Data
# =============================================================================

func get_encounter_types() -> Array:
	"""Get array of all encounter type definitions."""
	return encounter_types
