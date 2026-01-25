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
	_load_characters()
	_load_items()
	_load_item_upgrades()
	_load_skills()
	_load_encounter_types()


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
# GENERIC ACCESSOR
# =============================================================================

func _get_from(collection: Dictionary, id: String, type_name: String) -> Dictionary:
	"""Generic accessor with warning on miss."""
	if collection.has(id):
		return collection[id]
	push_warning("GameData: %s not found: %s" % [type_name, id])
	return {}


# =============================================================================
# PUBLIC API
# =============================================================================

func get_character_by_id(id: String) -> Dictionary:
	return _get_from(characters, id, "Character")

func get_all_characters() -> Array:
	return characters.values()

func has_character(id: String) -> bool:
	return characters.has(id)

func get_item_by_id(id: String) -> Dictionary:
	return _get_from(items, id, "Item")

func get_all_items() -> Array:
	return items.values()

func has_item(id: String) -> bool:
	return items.has(id)

func get_item_upgrade_by_id(id: String) -> Dictionary:
	return _get_from(item_upgrades, id, "Item upgrade")

func get_all_item_upgrades() -> Array:
	return item_upgrades.values()

func has_item_upgrade(id: String) -> bool:
	return item_upgrades.has(id)

func get_skill_by_id(id: String) -> Dictionary:
	return _get_from(skills, id, "Skill")

func get_all_skills() -> Array:
	return skills.values()

func has_skill(id: String) -> bool:
	return skills.has(id)

func get_encounter_types() -> Array:
	return encounter_types
