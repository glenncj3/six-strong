class_name CharacterInstance
extends RefCounted
# CharacterInstance - Runtime representation of a character during a run
# This is a CLONE of account data - modifications don't affect the account

# Persistent identifiers
var base_character_id: String = ""

# Runtime progression
var level: int = 1
var experience: int = 0

# Current state
var current_health: int = 0
var max_health: int = 0

# Calculated stats (base + rank boosts + items + skills)
var basic_attack_damage: int = 0
var speed: int = 0
var defense: int = 0
var income: int = 0

# Equipment and skills during this run
var equipped_items: Array[String] = []  # Item IDs from account
var equipped_item_upgrades: Array[String] = []  # Item upgrade IDs found during run
var learned_skills: Array[String] = []  # Skill IDs learned during run


func _init(char_data: Dictionary) -> void:
	"""
	Initialize from player's character data

	Args:
		char_data: Character data from PlayerAccount
	"""
	base_character_id = char_data["id"]

	# Get master data
	var char_master = GameData.get_character_by_id(base_character_id)
	if char_master.is_empty():
		push_error("CharacterInstance: Master data not found for %s" % base_character_id)
		return

	# Copy equipped items from account
	if char_data.has("equipped_items"):
		equipped_items = char_data["equipped_items"].duplicate()

	# Calculate initial stats
	_calculate_stats(char_master, char_data)

	# Set health to max
	current_health = max_health

	print("CharacterInstance created: %s (HP: %d, ATK: %d)" % [base_character_id, max_health, basic_attack_damage])


func _calculate_stats(char_master: Dictionary, char_data: Dictionary) -> void:
	"""Calculate all stats from base, rank boosts, and equipped items"""
	# Start with base stats
	var base_stats = char_master["base_stats"]
	max_health = base_stats["health"]
	basic_attack_damage = base_stats["basic_attack_damage"]
	speed = base_stats["speed"]
	defense = base_stats["defense"]
	income = base_stats["income"]

	# Apply rank stat boosts
	if char_master.has("rank_rewards"):
		for rank_reward in char_master["rank_rewards"]:
			if rank_reward["rank"] <= char_data["rank"]:
				if rank_reward.has("stat_boost"):
					for stat_name in rank_reward["stat_boost"]:
						var boost = rank_reward["stat_boost"][stat_name]
						match stat_name:
							"health":
								max_health += boost
							"basic_attack_damage":
								basic_attack_damage += boost
							"speed":
								speed += boost
							"defense":
								defense += boost
							"income":
								income += boost

	# Apply equipped items
	for item_id in equipped_items:
		_apply_item_modifiers(item_id)


func _apply_item_modifiers(item_id: String) -> void:
	"""Apply stat modifiers from an item"""
	var item_data = GameData.get_item_by_id(item_id)
	if item_data.is_empty():
		return

	if item_data.has("stat_modifiers"):
		for stat_name in item_data["stat_modifiers"]:
			var modifier = item_data["stat_modifiers"][stat_name]
			match stat_name:
				"health":
					max_health += modifier
				"basic_attack_damage":
					basic_attack_damage += modifier
				"speed":
					speed += modifier
				"defense":
					defense += modifier
				"income":
					income += modifier


func add_experience(xp: int) -> bool:
	"""
	Add experience, returns true if leveled up
	Level ups happen every 100 XP for now
	"""
	experience += xp
	var xp_per_level = 100

	if experience >= xp_per_level:
		experience -= xp_per_level
		level += 1
		print("CharacterInstance: %s leveled up to %d!" % [base_character_id, level])
		return true

	return false


func learn_skill(skill_id: String) -> bool:
	"""Learn a new skill during the run"""
	if skill_id in learned_skills:
		push_warning("CharacterInstance: Skill already learned: %s" % skill_id)
		return false

	# Check level requirement
	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		return false

	if skill_data.has("level_requirement"):
		if level < skill_data["level_requirement"]:
			push_warning("CharacterInstance: Level too low for skill %s (requires %d)" % [skill_id, skill_data["level_requirement"]])
			return false

	learned_skills.append(skill_id)
	_apply_skill_effects(skill_id)
	print("CharacterInstance: %s learned skill: %s" % [base_character_id, skill_id])
	return true


func _apply_skill_effects(skill_id: String) -> void:
	"""Apply skill effects to stats"""
	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		return

	if skill_data.has("effects"):
		for effect in skill_data["effects"]:
			var effect_type = effect["type"]
			var stat = effect["stat"]
			var value = effect["value"]

			match effect_type:
				"stat_add":
					_modify_stat(stat, value, false)
				"stat_multiply":
					_modify_stat(stat, value, true)


func _modify_stat(stat_name: String, value: float, multiply: bool) -> void:
	"""Modify a stat (used by skills)"""
	match stat_name:
		"health":
			if multiply:
				max_health = int(max_health * value)
			else:
				max_health += int(value)
		"basic_attack_damage":
			if multiply:
				basic_attack_damage = int(basic_attack_damage * value)
			else:
				basic_attack_damage += int(value)
		"speed":
			if multiply:
				speed = int(speed * value)
			else:
				speed += int(value)
		"defense":
			if multiply:
				defense = int(defense * value)
			else:
				defense += int(value)


func equip_item_upgrade(item_upgrade_id: String) -> bool:
	"""
	Equip an item upgrade found during the run.
	Item upgrades are added alongside existing items (no replacement).
	"""
	if item_upgrade_id in equipped_item_upgrades:
		push_warning("CharacterInstance: Item upgrade already equipped: %s" % item_upgrade_id)
		return false

	var upgrade_data = GameData.get_item_upgrade_by_id(item_upgrade_id)
	if upgrade_data.is_empty():
		return false

	# Check level requirement
	if upgrade_data.has("level_requirement"):
		if level < upgrade_data["level_requirement"]:
			push_warning("CharacterInstance: Level too low for upgrade (requires %d)" % upgrade_data["level_requirement"])
			return false

	# Equip the upgrade
	equipped_item_upgrades.append(item_upgrade_id)
	_apply_item_upgrade_modifiers(item_upgrade_id)
	print("CharacterInstance: %s equipped item upgrade: %s" % [base_character_id, item_upgrade_id])

	return true


func _apply_item_upgrade_modifiers(upgrade_id: String) -> void:
	"""Apply stat modifiers from an item upgrade"""
	var upgrade_data = GameData.get_item_upgrade_by_id(upgrade_id)
	if upgrade_data.is_empty():
		return

	if upgrade_data.has("stat_modifiers"):
		for stat_name in upgrade_data["stat_modifiers"]:
			var modifier = upgrade_data["stat_modifiers"][stat_name]
			match stat_name:
				"health":
					max_health += modifier
				"basic_attack_damage":
					basic_attack_damage += modifier
				"speed":
					speed += modifier
				"defense":
					defense += modifier


func take_damage(amount: int) -> void:
	"""Take damage, clamped to 0"""
	current_health = max(0, current_health - amount)
	if current_health == 0:
		print("CharacterInstance: %s has fallen!" % base_character_id)


func heal(amount: int) -> void:
	"""Heal, clamped to max health"""
	current_health = min(max_health, current_health + amount)


func is_alive() -> bool:
	"""Check if character is still alive"""
	return current_health > 0


func to_dict() -> Dictionary:
	"""Serialize to dictionary for saving"""
	return {
		"base_character_id": base_character_id,
		"level": level,
		"experience": experience,
		"current_health": current_health,
		"max_health": max_health,
		"basic_attack_damage": basic_attack_damage,
		"speed": speed,
		"defense": defense,
		"income": income,
		"equipped_items": equipped_items,
		"equipped_item_upgrades": equipped_item_upgrades,
		"learned_skills": learned_skills
	}


static func from_dict(data: Dictionary) -> CharacterInstance:
	"""Deserialize from dictionary (for loading saves)"""
	# Create instance with minimal data
	var instance = CharacterInstance.new({
		"id": data["base_character_id"],
		"equipped_items": data["equipped_items"],
		"rank": 1  # Rank is only used for initial calculation, we restore stats directly
	})

	# Restore runtime state (overwriting calculated values with saved values)
	instance.level = data["level"]
	instance.experience = data["experience"]
	instance.current_health = data["current_health"]
	instance.max_health = data["max_health"]
	instance.basic_attack_damage = data["basic_attack_damage"]
	instance.speed = data["speed"]
	instance.defense = data["defense"]
	instance.income = data["income"]
	instance.equipped_item_upgrades = Array(data["equipped_item_upgrades"], TYPE_STRING, "", null)
	instance.learned_skills = Array(data["learned_skills"], TYPE_STRING, "", null)

	return instance


func get_character_name() -> String:
	"""Get the character's name from master data"""
	var char_master = GameData.get_character_by_id(base_character_id)
	if char_master.has("name"):
		return char_master["name"]
	return "Unknown"
