extends PanelContainer
class_name RewardClaimPopup
## Reusable popup for claiming items or skills with character selection.
## Shows reward details (icon, name, description, stats) and a character selector.
## Used by treasure chest, reward encounters, and anywhere players receive loot.

signal claimed(reward_id: String, character_index: int)
signal cancelled

@onready var header_label: Label = $MarginContainer/ContentVBox/HeaderLabel
@onready var icon: TextureRect = $MarginContainer/ContentVBox/ItemHeader/Icon
@onready var name_label: Label = $MarginContainer/ContentVBox/ItemHeader/NameLabel
@onready var description_label: Label = $MarginContainer/ContentVBox/DescriptionLabel
@onready var stats_container: VBoxContainer = $MarginContainer/ContentVBox/StatsContainer
@onready var bonus_label: Label = $MarginContainer/ContentVBox/BonusLabel
@onready var selector_label: Label = $MarginContainer/ContentVBox/SelectorLabel
@onready var selector_container: VBoxContainer = $MarginContainer/ContentVBox/SelectorContainer
@onready var confirm_button: Button = $MarginContainer/ContentVBox/ConfirmButton

var _reward_id: String = ""
var _reward_type: String = "item"  # "item" or "skill"
var _eligible_char_indices: Array = []
var _selector: OptionButton = null


func _ready() -> void:
	_apply_styling()
	confirm_button.pressed.connect(_on_confirm_pressed)
	visible = false


func _apply_styling() -> void:
	"""Apply warm panel styling."""
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2A2520")
	style.border_color = GameConstants.COLOR_GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(0)
	add_theme_stylebox_override("panel", style)

	header_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
	name_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	description_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	bonus_label.add_theme_color_override("font_color", GameConstants.COLOR_GOLD)
	selector_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)


func show_item(item_id: String, eligible_characters: Array, eligible_indices: Array, header_text: String = "You found:", bonus_text: String = "", button_text: String = "Claim") -> void:
	"""
	Show popup for claiming an item.

	Args:
		item_id: The item upgrade ID
		eligible_characters: Array of character instances who can receive the item
		eligible_indices: Array of team indices corresponding to eligible_characters
		header_text: Text shown above the item (default: "You found:")
		bonus_text: Optional bonus text (e.g., "+2 Gold")
		button_text: Text for the confirm button
	"""
	_reward_id = item_id
	_reward_type = "item"
	_eligible_char_indices = eligible_indices

	var item_data = GameData.get_item_upgrade_by_id(item_id)
	if item_data.is_empty():
		item_data = GameData.get_item_by_id(item_id)

	if item_data.is_empty():
		push_error("RewardClaimPopup: Item not found: %s" % item_id)
		return

	_setup_display(
		header_text,
		item_data.get("name", "Unknown Item"),
		item_data.get("image_path", ""),
		item_data.get("description", ""),
		item_data.get("stat_modifiers", {}),
		bonus_text,
		button_text,
		eligible_characters
	)
	_show_popup()


func show_skill(skill_id: String, eligible_characters: Array, eligible_indices: Array, header_text: String = "You learned:", bonus_text: String = "", button_text: String = "Learn") -> void:
	"""
	Show popup for claiming a skill.

	Args:
		skill_id: The skill ID
		eligible_characters: Array of character instances who can learn the skill
		eligible_indices: Array of team indices corresponding to eligible_characters
		header_text: Text shown above the skill (default: "You learned:")
		bonus_text: Optional bonus text
		button_text: Text for the confirm button
	"""
	_reward_id = skill_id
	_reward_type = "skill"
	_eligible_char_indices = eligible_indices

	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		push_error("RewardClaimPopup: Skill not found: %s" % skill_id)
		return

	# Convert effects to stat modifiers format for display
	var effects_dict = {}
	for effect in skill_data.get("effects", []):
		var stat = effect.get("stat", "unknown")
		var value = effect.get("value", 0)
		var effect_type = effect.get("type", "stat_add")
		if effect_type == "stat_multiply":
			effects_dict[stat] = "+%d%%" % int((value - 1.0) * 100)
		else:
			effects_dict[stat] = value

	_setup_display(
		header_text,
		skill_data.get("name", "Unknown Skill"),
		skill_data.get("image_path", ""),
		skill_data.get("description", ""),
		effects_dict,
		bonus_text,
		button_text,
		eligible_characters
	)
	_show_popup()


func show_custom(reward_id: String, reward_type: String, title: String, image_path: String, description: String, stats: Dictionary, eligible_characters: Array, eligible_indices: Array, header_text: String = "You received:", bonus_text: String = "", button_text: String = "Claim") -> void:
	"""
	Show popup with custom reward data.

	Args:
		reward_id: ID to pass back in claimed signal
		reward_type: "item" or "skill" for signal handling
		title: Display name
		image_path: Path to icon
		description: Description text
		stats: Dictionary of stat modifiers to display
		eligible_characters: Array of character instances
		eligible_indices: Array of team indices
		header_text: Header text
		bonus_text: Optional bonus text
		button_text: Button text
	"""
	_reward_id = reward_id
	_reward_type = reward_type
	_eligible_char_indices = eligible_indices

	_setup_display(
		header_text,
		title,
		image_path,
		description,
		stats,
		bonus_text,
		button_text,
		eligible_characters
	)
	_show_popup()


func _setup_display(header_text: String, title: String, image_path: String, description: String, stats: Dictionary, bonus_text: String, button_text: String, eligible_characters: Array) -> void:
	"""Internal setup for display content."""
	# Header
	header_label.text = header_text

	# Icon
	UIHelpers.set_texture_safe(icon, image_path)

	# Name
	name_label.text = title

	# Description
	description_label.text = description
	description_label.visible = not description.is_empty()

	# Stats
	UIHelpers.clear_children(stats_container)
	if stats.is_empty():
		stats_container.visible = false
	else:
		stats_container.visible = true
		for stat_name in stats:
			var value = stats[stat_name]
			var display_value: String
			if value is String:
				display_value = value
			elif value is int or value is float:
				display_value = "+%d" % int(value) if value >= 0 else "%d" % int(value)
			else:
				display_value = str(value)

			var stat_label = Label.new()
			stat_label.text = "%s: %s" % [_format_stat_name(stat_name), display_value]
			stat_label.add_theme_font_size_override("font_size", 14)
			stat_label.add_theme_color_override("font_color", GameConstants.COLOR_EMERALD)
			stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stats_container.add_child(stat_label)

	# Bonus text
	bonus_label.text = bonus_text
	bonus_label.visible = not bonus_text.is_empty()

	# Character selector
	UIHelpers.clear_children(selector_container)
	_selector = UIPanelFactory.create_team_selector(eligible_characters)
	selector_container.add_child(_selector)

	# Confirm button
	confirm_button.text = button_text
	if eligible_characters.is_empty():
		UIStyles.setup_danger_button(confirm_button, GameConstants.FONT_SIZE_BUTTON)
		confirm_button.disabled = true
		confirm_button.text = "No eligible characters"
	else:
		UIStyles.setup_success_button(confirm_button, GameConstants.FONT_SIZE_BUTTON)
		confirm_button.disabled = false


func _format_stat_name(stat_name: String) -> String:
	"""Format stat name for display."""
	match stat_name:
		"health":
			return "Health"
		"mana":
			return "Mana"
		"income":
			return "Income"
		"defendRate":
			return "Defend Rate"
		_:
			return stat_name.capitalize().replace("_", " ")


func _show_popup() -> void:
	"""Show the popup."""
	visible = true
	move_to_front()


func hide_popup() -> void:
	"""Hide the popup."""
	visible = false


func _on_confirm_pressed() -> void:
	"""Handle confirm button press."""
	if _selector == null:
		return

	var selector_index = _selector.selected - 1  # First option is "Select..."
	if selector_index < 0 or selector_index >= _eligible_char_indices.size():
		return

	var char_index = _eligible_char_indices[selector_index]

	# Update button to show success
	confirm_button.text = "Claimed!"
	confirm_button.disabled = true

	# Emit signal with reward info
	claimed.emit(_reward_id, char_index)


func get_reward_id() -> String:
	"""Get the current reward ID."""
	return _reward_id


func get_reward_type() -> String:
	"""Get the current reward type ('item' or 'skill')."""
	return _reward_type
