extends PanelContainer
# CharacterCard - Reusable component for displaying character info
# Used in: Collection, Draft, Run View
# Refactored to use StatCalculator for DRY stat calculations

signal card_clicked(character_data: Dictionary)

@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var health_label: Label = $MarginContainer/VBoxContainer/StatsContainer/HealthLabel
@onready var attack_label: Label = $MarginContainer/VBoxContainer/StatsContainer/AttackLabel
@onready var defense_label: Label = $MarginContainer/VBoxContainer/StatsContainer/DefenseLabel
@onready var speed_label: Label = $MarginContainer/VBoxContainer/StatsContainer/SpeedLabel
@onready var income_label: Label = $MarginContainer/VBoxContainer/StatsContainer/IncomeLabel

var character_data: Dictionary = {}
var clickable: bool = true


func _ready() -> void:
	if clickable:
		gui_input.connect(_on_gui_input)


func setup(char_data: Dictionary, with_equipped_items: bool = false) -> void:
	"""
	Configure the card with character data.

	Args:
		char_data: Player's character data (from PlayerAccount)
		with_equipped_items: If true, calculate stats with equipped items
	"""
	character_data = char_data

	# Get master character data
	var char_master = GameData.get_character_by_id(char_data.get("id", ""))
	if char_master.is_empty():
		push_error("CharacterCard: Character master data not found: %s" % char_data.get("id", ""))
		return

	# Set portrait using UIHelpers
	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))

	# Set name
	name_label.text = char_master.get("name", "Unknown")

	# Calculate stats using StatCalculator (single source of truth)
	var stats = StatCalculator.calculate_character_stats(char_master, char_data, with_equipped_items)

	# Display stats
	health_label.text = UIHelpers.format_stat(GameConstants.STAT_HEALTH, stats.get(GameConstants.STAT_HEALTH, 0))
	attack_label.text = UIHelpers.format_stat(GameConstants.STAT_ATTACK, stats.get(GameConstants.STAT_ATTACK, 0))
	defense_label.text = UIHelpers.format_stat(GameConstants.STAT_DEFENSE, stats.get(GameConstants.STAT_DEFENSE, 0))
	speed_label.text = UIHelpers.format_stat(GameConstants.STAT_SPEED, stats.get(GameConstants.STAT_SPEED, 0))
	income_label.text = UIHelpers.format_stat(GameConstants.STAT_INCOME, stats.get(GameConstants.STAT_INCOME, 0))


func set_clickable(enabled: bool) -> void:
	"""Enable or disable click interaction."""
	clickable = enabled
	mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(character_data)


func highlight(enabled: bool) -> void:
	"""Visually highlight the card (for selection states)."""
	if enabled:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
