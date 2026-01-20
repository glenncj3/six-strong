extends PanelContainer
# SkillIcon - Simple display component for skills

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/Icon
@onready var skill_name: Label = $MarginContainer/VBoxContainer/SkillName

var skill_id: String = ""


func setup(skill_data_id: String) -> void:
	"""Configure the skill icon"""
	skill_id = skill_data_id

	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		push_error("SkillIcon: Skill not found: %s" % skill_id)
		return

	# Set icon using UIHelpers for safe texture loading
	UIHelpers.set_texture_safe(icon, skill_data.get("image_path", ""))

	# Set name
	skill_name.text = skill_data["name"]


func set_locked(locked: bool) -> void:
	"""Visual indicator for locked skills"""
	if locked:
		modulate = Color(0.5, 0.5, 0.5)
	else:
		modulate = Color.WHITE
