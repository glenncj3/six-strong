extends CompactableIconBase
# SkillIcon - Simple display component for skills
# Supports compact mode for space-constrained layouts

@onready var _margin_container: MarginContainer = $MarginContainer
@onready var _vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var icon: TextureRect = $MarginContainer/VBoxContainer/Icon
@onready var skill_name: Label = $MarginContainer/VBoxContainer/SkillName

var skill_id: String = ""


func _on_ready() -> void:
	# Set base class references
	margin_container = _margin_container
	vbox = _vbox
	_icon = icon
	_label = skill_name


func setup(skill_data: Dictionary) -> void:
	"""
	Configure the skill icon with skill data.

	Args:
		skill_data: Skill data dictionary (from GameData or provided directly)
	"""
	if skill_data.is_empty():
		push_error("SkillIcon: Empty skill data provided")
		return

	skill_id = skill_data.get("id", "")

	# Set icon using UIHelpers for safe texture loading
	UIHelpers.set_texture_safe(icon, skill_data.get("image_path", ""))

	# Set name
	skill_name.text = skill_data.get("name", "Unknown")


func set_locked(locked: bool) -> void:
	"""Visual indicator for locked skills"""
	if locked:
		modulate = Color(0.5, 0.5, 0.5)
	else:
		modulate = Color.WHITE


func _get_compact_size() -> Vector2:
	return UIScaler.get_skill_icon_size(true)


func _get_normal_size() -> Vector2:
	return UIScaler.get_skill_icon_size(false)


func _get_compact_icon_size() -> float:
	return UIScaler.get_skill_image_size()


func _get_normal_icon_size() -> float:
	return UIScaler.get_skill_image_size()


func _get_normal_separation() -> int:
	return 2
