extends Panel
# CharacterDetails - Detailed character view
# Phase 1 Refactor: Simplified to show character stats and description
# Removed: prestige/fame (now on legacies), items/skills (now player-level)

@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/TopBar/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/TopBar/InfoContainer/NameLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/TopBar/InfoContainer/DescriptionLabel

@onready var health_value: Label = $MarginContainer/VBoxContainer/StatsSection/StatsGrid/HealthValue
@onready var mana_value: Label = $MarginContainer/VBoxContainer/StatsSection/StatsGrid/ManaValue
@onready var defend_rate_value: Label = $MarginContainer/VBoxContainer/StatsSection/StatsGrid/DefendRateValue

# Deprecated nodes - will be hidden if they exist
@onready var _rank_label = get_node_or_null("MarginContainer/VBoxContainer/TopBar/InfoContainer/RankLabel")
@onready var _rank_progress = get_node_or_null("MarginContainer/VBoxContainer/TopBar/InfoContainer/RankProgressBar")
@onready var _income_value = get_node_or_null("MarginContainer/VBoxContainer/StatsSection/StatsGrid/IncomeValue")
@onready var _income_label = get_node_or_null("MarginContainer/VBoxContainer/StatsSection/StatsGrid/IncomeLabel")
@onready var _equipment_section = get_node_or_null("MarginContainer/VBoxContainer/EquipmentSection")
@onready var _items_section = get_node_or_null("MarginContainer/VBoxContainer/ItemsSection")
@onready var _skills_section = get_node_or_null("MarginContainer/VBoxContainer/SkillsSection")

var current_character_data: Dictionary = {}


func _ready() -> void:
	_apply_visual_styling()
	_hide_deprecated_sections()


func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling to the panel."""
	# Background color
	var style = StyleBoxFlat.new()
	style.bg_color = GameConstants.COLOR_BG_DARK
	add_theme_stylebox_override("panel", style)

	# Apply text colors
	name_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)


func _hide_deprecated_sections() -> void:
	"""Hide deprecated sections from Phase 0 scene."""
	# Hide prestige/fame display (now on legacies)
	if _rank_label:
		_rank_label.visible = false
	if _rank_progress:
		_rank_progress.visible = false

	# Hide income (characters no longer have income)
	if _income_value:
		_income_value.visible = false
	if _income_label:
		_income_label.visible = false

	# Hide equipment section (items now in player inventory)
	if _equipment_section:
		_equipment_section.visible = false

	# Hide items section (items now in player inventory)
	if _items_section:
		_items_section.visible = false

	# Hide skills section (skills are now one-shot effects)
	if _skills_section:
		_skills_section.visible = false


func display_character(char_data: Dictionary) -> void:
	"""Display detailed information for a character."""
	current_character_data = char_data

	# Get master data
	var char_id = char_data.get("id", "")
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("CharacterDetails: Character master data not found")
		return

	# Set portrait using UIHelpers
	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))

	# Set name
	name_label.text = char_master.get("name", "Unknown")

	# Set description (new in Phase 1)
	if description_label:
		description_label.text = char_master.get("description", "")
		description_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)

	# Calculate and display stats using StatCalculator
	_update_stats_display(char_master)


func display_character_instance(char_instance: CharacterInstance) -> void:
	"""Display detailed information for a CharacterInstance (during run)."""
	var char_master = GameData.get_character_by_id(char_instance.base_character_id)
	if char_master.is_empty():
		push_error("CharacterDetails: Character master data not found")
		return

	# Set portrait using UIHelpers
	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))

	# Set name
	name_label.text = char_instance.get_character_name()

	# Set description
	if description_label:
		description_label.text = char_master.get("description", "")
		description_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)

	# Display instance stats (includes level bonuses)
	_update_stats_from_instance(char_instance)


func _update_stats_display(char_master: Dictionary) -> void:
	"""Display base stats from master data."""
	var stats = StatCalculator.calculate_character_stats(char_master)

	health_value.text = str(stats.get(GameConstants.STAT_HEALTH, 0))
	mana_value.text = str(stats.get(GameConstants.STAT_MANA, 0))
	defend_rate_value.text = "%d%%" % stats.get(GameConstants.STAT_DEFEND_RATE, 0)

	# Apply gold color to stat values
	for label in [health_value, mana_value, defend_rate_value]:
		label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)


func _update_stats_from_instance(char_instance: CharacterInstance) -> void:
	"""Display stats from a CharacterInstance."""
	health_value.text = "%d/%d" % [char_instance.current_health, char_instance.max_health]
	mana_value.text = str(char_instance.mana)
	defend_rate_value.text = "%d%%" % char_instance.defend_rate

	# Apply gold color to stat values
	for label in [health_value, mana_value, defend_rate_value]:
		label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
