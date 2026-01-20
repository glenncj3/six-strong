extends PanelContainer
# SkillIcon - Simple display component for skills
# Supports compact mode for space-constrained layouts

@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var icon: TextureRect = $MarginContainer/VBoxContainer/Icon
@onready var skill_name: Label = $MarginContainer/VBoxContainer/SkillName

var skill_id: String = ""
var is_compact: bool = false


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


func set_compact(enabled: bool) -> void:
	"""
	Enable or disable compact mode.
	Compact mode hides the skill name label.

	Args:
		enabled: Whether to enable compact mode
	"""
	is_compact = enabled

	if enabled:
		# Compact: hide label, reduce margins
		var compact_size = UIScaler.get_skill_icon_size(true)
		custom_minimum_size = compact_size

		margin_container.add_theme_constant_override("margin_left", 2)
		margin_container.add_theme_constant_override("margin_top", 2)
		margin_container.add_theme_constant_override("margin_right", 2)
		margin_container.add_theme_constant_override("margin_bottom", 2)

		icon.custom_minimum_size = Vector2(UIScaler.get_skill_image_size(true), UIScaler.get_skill_image_size(true))
		skill_name.visible = false
		vbox.add_theme_constant_override("separation", 0)
	else:
		# Normal: show label, normal margins
		var normal_size = UIScaler.get_skill_icon_size(false)
		custom_minimum_size = normal_size

		margin_container.add_theme_constant_override("margin_left", 4)
		margin_container.add_theme_constant_override("margin_top", 4)
		margin_container.add_theme_constant_override("margin_right", 4)
		margin_container.add_theme_constant_override("margin_bottom", 4)

		icon.custom_minimum_size = Vector2(UIScaler.get_skill_image_size(false), UIScaler.get_skill_image_size(false))
		skill_name.visible = true
		vbox.add_theme_constant_override("separation", 2)

	# Apply fantasy panel styling
	UIStyles.apply_panel_style(self, UIStyles.create_subtle_panel())
