extends Node
# GameData Singleton
# Loads and caches all master data (characters, items, skills, encounters)
# This is the single source of truth for all game content definitions

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
	"""Load all master data from JSON files"""
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


func _load_characters() -> void:
	var data = _load_json_file(CHARACTERS_PATH)
	if data and data.has("characters"):
		for char_data in data["characters"]:
			characters[char_data["id"]] = char_data


func _load_items() -> void:
	var data = _load_json_file(ITEMS_PATH)
	if data and data.has("items"):
		for item_data in data["items"]:
			items[item_data["id"]] = item_data


func _load_item_upgrades() -> void:
	var data = _load_json_file(ITEM_UPGRADES_PATH)
	if data and data.has("item_upgrades"):
		for item_data in data["item_upgrades"]:
			item_upgrades[item_data["id"]] = item_data


func _load_skills() -> void:
	var data = _load_json_file(SKILLS_PATH)
	if data and data.has("skills"):
		for skill_data in data["skills"]:
			skills[skill_data["id"]] = skill_data


func _load_encounter_types() -> void:
	var data = _load_json_file(ENCOUNTERS_PATH)
	if data and data.has("encounter_types"):
		encounter_types = data["encounter_types"]


func _load_json_file(path: String) -> Variant:
	"""Generic JSON file loader with error handling"""
	if not FileAccess.file_exists(path):
		push_error("GameData: File not found: %s" % path)
		return null

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameData: Could not open file: %s" % path)
		return null

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("GameData: JSON parse error in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null

	return json.data


# Public API for accessing game data

func get_character_by_id(id: String) -> Dictionary:
	"""Get character data by ID"""
	if characters.has(id):
		return characters[id]
	push_warning("GameData: Character not found: %s" % id)
	return {}


func get_item_by_id(id: String) -> Dictionary:
	"""Get item data by ID"""
	if items.has(id):
		return items[id]
	push_warning("GameData: Item not found: %s" % id)
	return {}


func get_item_upgrade_by_id(id: String) -> Dictionary:
	"""Get item upgrade data by ID"""
	if item_upgrades.has(id):
		return item_upgrades[id]
	push_warning("GameData: Item upgrade not found: %s" % id)
	return {}


func get_skill_by_id(id: String) -> Dictionary:
	"""Get skill data by ID"""
	if skills.has(id):
		return skills[id]
	push_warning("GameData: Skill not found: %s" % id)
	return {}


func get_all_characters() -> Array:
	"""Get array of all character data"""
	return characters.values()


func get_all_items() -> Array:
	"""Get array of all item data"""
	return items.values()


func get_all_item_upgrades() -> Array:
	"""Get array of all item upgrade data"""
	return item_upgrades.values()


func get_all_skills() -> Array:
	"""Get array of all skill data"""
	return skills.values()


func get_encounter_types() -> Array:
	"""Get array of all encounter type definitions"""
	return encounter_types
