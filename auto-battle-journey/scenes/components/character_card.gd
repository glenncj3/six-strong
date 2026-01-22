extends ClickablePanelBase
## CharacterCard - Reusable component for displaying character info
## Used in: Collection, Draft, Run View
## Refactored to use StatCalculator for DRY stat calculations
## Supports multiple size variants: NORMAL, SMALL, MINI

signal card_clicked(character_data: Dictionary)

@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var stats_container: VBoxContainer = $MarginContainer/VBoxContainer/StatsContainer
@onready var health_label: Label = $MarginContainer/VBoxContainer/StatsContainer/HealthLabel
@onready var attack_label: Label = $MarginContainer/VBoxContainer/StatsContainer/AttackLabel
@onready var defense_label: Label = $MarginContainer/VBoxContainer/StatsContainer/DefenseLabel
@onready var speed_label: Label = $MarginContainer/VBoxContainer/StatsContainer/SpeedLabel
@onready var income_label: Label = $MarginContainer/VBoxContainer/StatsContainer/IncomeLabel

var character_data: Dictionary = {}
var current_size: UIScaler.CardSize = UIScaler.CardSize.NORMAL


func _on_ready() -> void:
	UIHelpers.set_children_mouse_filter_ignore(self)
	_init_styles()


func _init_styles() -> void:
	var styles = UIStyles.create_clickable_panel_styles(
		GameConstants.COLOR_PANEL_DARK,
		GameConstants.COLOR_PANEL_DARK.lightened(0.15),
		GameConstants.COLOR_PANEL_DARK.darkened(0.1)
	)
	setup_styles(styles)


func _handle_click() -> void:
	card_clicked.emit(character_data)


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


func highlight(enabled: bool) -> void:
	"""Visually highlight the card (for selection states)."""
	if enabled:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE


func set_card_size(card_size_variant: UIScaler.CardSize) -> void:
	"""
	Set the card to a specific size variant.

	Args:
		card_size_variant: UIScaler.CardSize enum (NORMAL, SMALL, MINI)
	"""
	current_size = card_size_variant
	var new_size = UIScaler.get_character_card_size(card_size_variant)
	custom_minimum_size = new_size

	match card_size_variant:
		UIScaler.CardSize.NORMAL:
			_apply_normal_size()
		UIScaler.CardSize.SMALL:
			_apply_small_size()
		UIScaler.CardSize.MINI:
			_apply_mini_size()

	_apply_state_style()


func _apply_normal_size() -> void:
	"""Apply normal size styling (200x280)."""
	margin_container.add_theme_constant_override("margin_left", 8)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_right", 8)
	margin_container.add_theme_constant_override("margin_bottom", 8)
	vbox.add_theme_constant_override("separation", 6)

	portrait.custom_minimum_size = Vector2(160, 160)

	name_label.add_theme_font_size_override("font_size", 14)
	name_label.visible = true

	stats_container.visible = true
	for label in stats_container.get_children():
		if label is Label:
			label.add_theme_font_size_override("font_size", 11)


func _apply_small_size() -> void:
	"""Apply small size styling (100x140)."""
	margin_container.add_theme_constant_override("margin_left", 4)
	margin_container.add_theme_constant_override("margin_top", 4)
	margin_container.add_theme_constant_override("margin_right", 4)
	margin_container.add_theme_constant_override("margin_bottom", 4)
	vbox.add_theme_constant_override("separation", 2)

	portrait.custom_minimum_size = Vector2(80, 80)

	name_label.add_theme_font_size_override("font_size", 10)
	name_label.visible = true

	# Hide individual stats in small mode
	stats_container.visible = false


func _apply_mini_size() -> void:
	"""Apply mini size styling (80x110)."""
	margin_container.add_theme_constant_override("margin_left", 2)
	margin_container.add_theme_constant_override("margin_top", 2)
	margin_container.add_theme_constant_override("margin_right", 2)
	margin_container.add_theme_constant_override("margin_bottom", 2)
	vbox.add_theme_constant_override("separation", 1)

	portrait.custom_minimum_size = Vector2(60, 60)

	name_label.add_theme_font_size_override("font_size", 9)
	name_label.visible = true

	# Hide stats in mini mode
	stats_container.visible = false


func apply_rarity_border(rarity: String = "common") -> void:
	"""
	Apply rarity-based border color.

	Args:
		rarity: "common", "uncommon", "rare", "epic", "legendary"
	"""
	UIStyles.apply_panel_style(self, UIStyles.create_card_panel(rarity))
