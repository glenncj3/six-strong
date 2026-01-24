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
@onready var mana_label: Label = $MarginContainer/VBoxContainer/StatsContainer/ManaLabel
@onready var income_label: Label = $MarginContainer/VBoxContainer/StatsContainer/IncomeLabel
@onready var defend_rate_label: Label = $MarginContainer/VBoxContainer/StatsContainer/DefendRateLabel

var character_data: Dictionary = {}
var current_size: UIScaler.CardSize = UIScaler.CardSize.NORMAL


func _on_ready() -> void:
	UIHelpers.set_children_mouse_filter_ignore(self)


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
	mana_label.text = UIHelpers.format_stat(GameConstants.STAT_MANA, stats.get(GameConstants.STAT_MANA, 0))
	income_label.text = UIHelpers.format_stat(GameConstants.STAT_INCOME, stats.get(GameConstants.STAT_INCOME, 0))
	defend_rate_label.text = UIHelpers.format_stat(GameConstants.STAT_DEFEND_RATE, stats.get(GameConstants.STAT_DEFEND_RATE, 0))


const SIZE_CONFIG := {
	UIScaler.CardSize.NORMAL: {"margin": 8, "separation": 6, "portrait": 160, "stats": true, "stat_font": 11},
	UIScaler.CardSize.SMALL: {"margin": 4, "separation": 2, "portrait": 80, "stats": false, "stat_font": 11},
	UIScaler.CardSize.MINI: {"margin": 2, "separation": 1, "portrait": 60, "stats": false, "stat_font": 11},
}


func set_card_size(card_size_variant: UIScaler.CardSize) -> void:
	"""Set the card to a specific size variant."""
	current_size = card_size_variant
	custom_minimum_size = UIScaler.get_character_card_size(card_size_variant)

	var config = SIZE_CONFIG[card_size_variant]
	var m = config["margin"]
	margin_container.add_theme_constant_override("margin_left", m)
	margin_container.add_theme_constant_override("margin_top", m)
	margin_container.add_theme_constant_override("margin_right", m)
	margin_container.add_theme_constant_override("margin_bottom", m)
	vbox.add_theme_constant_override("separation", config["separation"])
	portrait.custom_minimum_size = Vector2(config["portrait"], config["portrait"])
	stats_container.visible = config["stats"]

	if config["stats"]:
		for label in stats_container.get_children():
			if label is Label:
				label.add_theme_font_size_override("font_size", config["stat_font"])

	_apply_state_style()


func apply_rarity_border(rarity: String = "common") -> void:
	"""
	Apply rarity-based border color.

	Args:
		rarity: "common", "uncommon", "rare", "epic", "legendary"
	"""
	UIStyles.apply_panel_style(self, UIStyles.create_card_panel(rarity))
