extends Node
# PlayerAccount Singleton
# Manages player progression, unlocks, currencies, and character collection
# TODO: Replace local save/load with cloud API calls in future

signal gems_changed(new_amount: int)
signal reroll_tokens_changed(new_amount: int)
signal character_unlocked(char_id: String)
signal character_ranked_up(char_id: String, new_rank: int)

# Save file path
# TODO: Replace with cloud service endpoint
const SAVE_PATH = "user://player_account.json"

# Player data structure
var player_data: Dictionary = {
	"player_id": "",
	"currencies": {
		"gems": 0,
		"reroll_tokens": 0
	},
	"characters": [],
	"unlocked_character_ids": []
}


func _ready() -> void:
	load_account()


func create_default_account() -> void:
	"""Create a new player account with starting characters unlocked"""
	print("PlayerAccount: Creating default account...")

	player_data["player_id"] = "player_%d" % Time.get_unix_time_from_system()
	player_data["currencies"]["gems"] = 1000  # Starting gems
	player_data["currencies"]["reroll_tokens"] = 0

	# Unlock 5 starting characters
	var starting_chars = ["char_warrior_001", "char_mage_001", "char_rogue_001", "char_cleric_001", "char_ranger_001"]
	for char_id in starting_chars:
		_create_character_data(char_id)

	save_account()
	print("PlayerAccount: Default account created with %d characters" % starting_chars.size())


func _create_character_data(char_id: String) -> void:
	"""Create character data entry in player account"""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("PlayerAccount: Cannot create character data - master data not found: %s" % char_id)
		return

	# Get rank 1 unlocked items
	var unlocked_items = []
	if char_master.has("rank_rewards") and char_master["rank_rewards"].size() > 0:
		var rank_1_rewards = char_master["rank_rewards"][0]
		if rank_1_rewards.has("rewards"):
			for reward in rank_1_rewards["rewards"]:
				if reward["type"] == "item":
					unlocked_items.append(reward["id"])

	var char_data = {
		"id": char_id,
		"unlocked": true,
		"rank": 1,
		"experience": 0,
		"equipped_items": [],
		"unlocked_items": unlocked_items,
		"unlocked_item_upgrades": [],
		"unlocked_skills": []
	}

	player_data["characters"].append(char_data)
	player_data["unlocked_character_ids"].append(char_id)


func save_account() -> void:
	"""Save player account to local JSON file"""
	# TODO: Replace with cloud API call
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PlayerAccount: Could not open save file for writing")
		return

	var json_string = JSON.stringify(player_data, "\t")
	file.store_string(json_string)
	file.close()

	print("PlayerAccount: Account saved to %s" % SAVE_PATH)


func load_account() -> void:
	"""Load player account from local JSON file"""
	# TODO: Replace with cloud API call
	if not FileAccess.file_exists(SAVE_PATH):
		print("PlayerAccount: No save file found, creating default account")
		create_default_account()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("PlayerAccount: Could not open save file for reading")
		create_default_account()
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("PlayerAccount: Failed to parse save file, creating default account")
		create_default_account()
		return

	player_data = json.data
	print("PlayerAccount: Account loaded successfully")
	print("  - Gems: %d" % player_data["currencies"]["gems"])
	print("  - Reroll Tokens: %d" % player_data["currencies"]["reroll_tokens"])
	print("  - Unlocked Characters: %d" % player_data["unlocked_character_ids"].size())


# Currency management

func get_gems() -> int:
	return player_data["currencies"]["gems"]


func get_reroll_tokens() -> int:
	return player_data["currencies"]["reroll_tokens"]


func add_gems(amount: int) -> void:
	player_data["currencies"]["gems"] += amount
	gems_changed.emit(player_data["currencies"]["gems"])
	save_account()


func spend_gems(amount: int) -> bool:
	if player_data["currencies"]["gems"] >= amount:
		player_data["currencies"]["gems"] -= amount
		gems_changed.emit(player_data["currencies"]["gems"])
		save_account()
		return true
	return false


func add_reroll_token() -> void:
	player_data["currencies"]["reroll_tokens"] += 1
	reroll_tokens_changed.emit(player_data["currencies"]["reroll_tokens"])
	save_account()


func spend_reroll_token() -> bool:
	if player_data["currencies"]["reroll_tokens"] > 0:
		player_data["currencies"]["reroll_tokens"] -= 1
		reroll_tokens_changed.emit(player_data["currencies"]["reroll_tokens"])
		save_account()
		return true
	return false


# Character collection management

func get_unlocked_characters() -> Array:
	"""Get array of all unlocked character data"""
	var unlocked = []
	for char_data in player_data["characters"]:
		if char_data["unlocked"]:
			unlocked.append(char_data)
	return unlocked


func get_character_data(char_id: String) -> Dictionary:
	"""Get player's data for a specific character"""
	for char_data in player_data["characters"]:
		if char_data["id"] == char_id:
			return char_data
	return {}


func is_character_unlocked(char_id: String) -> bool:
	return char_id in player_data["unlocked_character_ids"]


func unlock_character(char_id: String, cost: int) -> bool:
	"""Unlock a character by spending gems"""
	if is_character_unlocked(char_id):
		push_warning("PlayerAccount: Character already unlocked: %s" % char_id)
		return false

	if not spend_gems(cost):
		push_warning("PlayerAccount: Not enough gems to unlock character")
		return false

	_create_character_data(char_id)
	character_unlocked.emit(char_id)
	save_account()
	return true


# Item/Skill management

func equip_item(char_id: String, item_id: String) -> bool:
	"""Equip an item to a character"""
	var char_data = get_character_data(char_id)
	if char_data.is_empty():
		return false

	# Check if item is unlocked for this character
	if item_id not in char_data["unlocked_items"]:
		push_warning("PlayerAccount: Item not unlocked for character: %s" % item_id)
		return false

	# Get item slot
	var item_master = GameData.get_item_by_id(item_id)
	if item_master.is_empty():
		return false

	var slot = item_master["slot"]

	# Unequip any item in the same slot
	for equipped_id in char_data["equipped_items"]:
		var equipped_item = GameData.get_item_by_id(equipped_id)
		if equipped_item["slot"] == slot:
			char_data["equipped_items"].erase(equipped_id)
			break

	# Equip new item
	char_data["equipped_items"].append(item_id)
	save_account()
	return true


func unequip_item(char_id: String, item_id: String) -> bool:
	"""Unequip an item from a character"""
	var char_data = get_character_data(char_id)
	if char_data.is_empty():
		return false

	if item_id in char_data["equipped_items"]:
		char_data["equipped_items"].erase(item_id)
		save_account()
		return true

	return false


func add_character_experience(char_id: String, xp: int) -> void:
	"""Add experience to a character, may cause rank up"""
	var char_data = get_character_data(char_id)
	if char_data.is_empty():
		return

	char_data["experience"] += xp

	# Check for rank up (100 XP per rank for now)
	var xp_per_rank = 100
	while char_data["experience"] >= xp_per_rank:
		char_data["experience"] -= xp_per_rank
		char_data["rank"] += 1
		print("PlayerAccount: Character ranked up! %s is now rank %d" % [char_id, char_data["rank"]])
		_apply_rank_rewards(char_id, char_data["rank"])
		character_ranked_up.emit(char_id, char_data["rank"])

	save_account()


func _apply_rank_rewards(char_id: String, new_rank: int) -> void:
	"""Apply rewards for reaching a new rank"""
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		return

	var char_data = get_character_data(char_id)

	# Find rewards for this rank
	if not char_master.has("rank_rewards"):
		return

	for rank_reward in char_master["rank_rewards"]:
		if rank_reward["rank"] == new_rank:
			print("PlayerAccount: Applying rank %d rewards for %s" % [new_rank, char_id])

			# Unlock items, skills, etc.
			if rank_reward.has("rewards"):
				for reward in rank_reward["rewards"]:
					match reward["type"]:
						"item":
							if reward["id"] not in char_data["unlocked_items"]:
								char_data["unlocked_items"].append(reward["id"])
								print("  - Unlocked item: %s" % reward["id"])
						"item_upgrade":
							if reward["id"] not in char_data["unlocked_item_upgrades"]:
								char_data["unlocked_item_upgrades"].append(reward["id"])
								print("  - Unlocked item upgrade: %s" % reward["id"])
						"skill":
							if reward["id"] not in char_data["unlocked_skills"]:
								char_data["unlocked_skills"].append(reward["id"])
								print("  - Unlocked skill: %s" % reward["id"])

			break


func unlock_content_for_character(char_id: String, content_type: String, content_id: String, cost: int) -> bool:
	"""Unlock an item, skill, or upgrade for a character by spending gems"""
	if not spend_gems(cost):
		return false

	var char_data = get_character_data(char_id)
	if char_data.is_empty():
		return false

	match content_type:
		"item":
			if content_id not in char_data["unlocked_items"]:
				char_data["unlocked_items"].append(content_id)
		"item_upgrade":
			if content_id not in char_data["unlocked_item_upgrades"]:
				char_data["unlocked_item_upgrades"].append(content_id)
		"skill":
			if content_id not in char_data["unlocked_skills"]:
				char_data["unlocked_skills"].append(content_id)
		_:
			push_error("PlayerAccount: Unknown content type: %s" % content_type)
			return false

	save_account()
	return true
