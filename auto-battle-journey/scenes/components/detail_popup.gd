extends PanelContainer
# DetailPopup - Reusable popup for showing item/skill/upgrade details
# Follows SOLID principles - single responsibility for detail display
# Can be used anywhere a detail overlay is needed

signal closed

@onready var margin_container: MarginContainer = $MarginContainer
@onready var main_container: VBoxContainer = $MarginContainer/MainContainer
@onready var header_container: HBoxContainer = $MarginContainer/MainContainer/HeaderContainer
@onready var icon: TextureRect = $MarginContainer/MainContainer/HeaderContainer/Icon
@onready var title_label: Label = $MarginContainer/MainContainer/HeaderContainer/TitleLabel
@onready var type_label: Label = $MarginContainer/MainContainer/TypeLabel
@onready var description_label: Label = $MarginContainer/MainContainer/DescriptionLabel
@onready var effects_container: VBoxContainer = $MarginContainer/MainContainer/EffectsContainer
@onready var close_button: Button = $MarginContainer/MainContainer/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	UIStyles.apply_panel_style(self, UIStyles.create_warm_panel())
	UIStyles.apply_button_styles(close_button)

	# Start hidden
	visible = false


func show_item(item_id: String) -> void:
	"""Show details for an item."""
	var item_data = GameData.get_item_by_id(item_id)
	if item_data.is_empty():
		# Try item upgrade
		item_data = GameData.get_item_upgrade_by_id(item_id)

	if item_data.is_empty():
		push_error("DetailPopup: Item not found: %s" % item_id)
		return

	_setup_display(
		item_data.get("name", "Unknown"),
		item_data.get("image_path", ""),
		"ITEM",
		item_data.get("description", ""),
		item_data.get("stat_modifiers", {})
	)
	_show_popup()


func show_skill(skill_id: String) -> void:
	"""Show details for a skill."""
	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		push_error("DetailPopup: Skill not found: %s" % skill_id)
		return

	# Convert effects array to display format
	var effects_dict = {}
	for effect in skill_data.get("effects", []):
		var stat = effect.get("stat", "unknown")
		var value = effect.get("value", 0)
		var effect_type = effect.get("type", "stat_add")
		if effect_type == "stat_multiply":
			effects_dict[stat] = "+%d%%" % int((value - 1.0) * 100)
		else:
			effects_dict[stat] = "+%d" % value if value >= 0 else "%d" % value

	_setup_display(
		skill_data.get("name", "Unknown"),
		skill_data.get("image_path", ""),
		"SKILL",
		skill_data.get("description", ""),
		effects_dict
	)
	_show_popup()


func show_custom(title: String, image_path: String, type_text: String, description: String, effects: Dictionary = {}) -> void:
	"""Show custom content - for extensibility."""
	_setup_display(title, image_path, type_text, description, effects)
	_show_popup()


func _setup_display(title: String, image_path: String, type_text: String, description: String, effects: Dictionary) -> void:
	"""Internal setup for display content."""
	# Set icon
	UIHelpers.set_texture_safe(icon, image_path)

	# Set title
	title_label.text = title
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)

	# Set type
	type_label.text = "[%s]" % type_text
	type_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)

	# Set description
	description_label.text = description
	description_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Populate effects
	UIHelpers.clear_children(effects_container)
	if effects.is_empty():
		effects_container.visible = false
	else:
		effects_container.visible = true
		for stat_name in effects:
			var effect_label = Label.new()
			var display_value = effects[stat_name]
			if display_value is int:
				display_value = "+%d" % display_value if display_value >= 0 else "%d" % display_value
			effect_label.text = "%s: %s" % [_format_stat_name(stat_name), display_value]
			effect_label.add_theme_font_size_override("font_size", 12)
			effect_label.add_theme_color_override("font_color", GameConstants.COLOR_EMERALD)
			effects_container.add_child(effect_label)


func _format_stat_name(stat_name: String) -> String:
	"""Format stat name for display."""
	match stat_name:
		GameConstants.STAT_HEALTH:
			return "Health"
		GameConstants.STAT_ATTACK:
			return "Attack"
		GameConstants.STAT_DEFENSE:
			return "Defense"
		GameConstants.STAT_SPEED:
			return "Speed"
		GameConstants.STAT_INCOME:
			return "Income"
		_:
			return stat_name.capitalize().replace("_", " ")


func _show_popup() -> void:
	"""Show the popup centered."""
	visible = true
	# Ensure we're on top
	move_to_front()


func hide_popup() -> void:
	"""Hide the popup."""
	visible = false
	closed.emit()


func _on_close_pressed() -> void:
	hide_popup()


func _gui_input(event: InputEvent) -> void:
	"""Close on background click."""
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check if click is outside the popup content
			hide_popup()
			get_viewport().set_input_as_handled()
