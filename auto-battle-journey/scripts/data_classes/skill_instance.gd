class_name SkillInstance
extends RefCounted
# SkillInstance - Runtime representation of a skill
# Uses StatCalculator for stat modifications (data-driven approach)

var skill_id: String = ""
var name: String = ""
var description: String = ""
var image_path: String = ""
var effects: Array = []


func _init(skill_data_id: String) -> void:
	"""Initialize from skill data."""
	skill_id = skill_data_id

	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		push_error("SkillInstance: Skill data not found: %s" % skill_id)
		return

	name = skill_data.get("name", "Unknown Skill")
	description = skill_data.get("description", "")
	image_path = skill_data.get("image_path", "")

	if skill_data.has("effects"):
		effects = skill_data["effects"].duplicate(true)


func apply_to_character(char_instance: CharacterInstance) -> void:
	"""Apply this skill's effects to a character using StatCalculator."""
	for effect in effects:
		var effect_type = effect.get("type", "stat_add")
		var stat = effect.get("stat", "")
		var value = effect.get("value", 0)

		match effect_type:
			"stat_add":
				# Use StatCalculator for data-driven stat modification
				StatCalculator.apply_modifier(char_instance.stats, stat, value, false)
			"stat_multiply":
				StatCalculator.apply_modifier(char_instance.stats, stat, value, true)

	# Sync max_health if health was modified
	if char_instance.stats.has(GameConstants.STAT_HEALTH):
		char_instance.current_health = mini(char_instance.current_health, char_instance.max_health)


func to_dict() -> Dictionary:
	"""Serialize for saving."""
	return {
		"skill_id": skill_id,
		"name": name,
		"description": description,
		"image_path": image_path,
		"effects": effects
	}


static func from_dict(data: Dictionary) -> SkillInstance:
	"""Deserialize from save data."""
	var instance = SkillInstance.new(data.get("skill_id", ""))
	return instance
