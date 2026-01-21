extends PanelContainer
# CharacterCard - Reusable component for displaying character info
# Used in: Collection, Draft, Run View
# Refactored to use StatCalculator for DRY stat calculations
# Supports multiple size variants: NORMAL, SMALL, MINI

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
var clickable: bool = true
var current_size: UIScaler.CardSize = UIScaler.CardSize.NORMAL
var _styles: Dictionary = {}
var _is_hovered: bool = false
var _is_pressed: bool = false


func _ready() -> void:
	# Allow parent to receive hover events by making display children transparent to mouse
	_set_children_mouse_filter_ignore()

	if clickable:
		gui_input.connect(_on_gui_input)
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	_init_styles()


func _set_children_mouse_filter_ignore() -> void:
	# All child Control nodes default to MOUSE_FILTER_STOP in Godot 4.x,
	# which blocks mouse events from reaching the parent PanelContainer.
	# Set ALL children (containers AND leaves) to IGNORE so hover/click events propagate.
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for label in stats_container.get_children():
		if label is Label:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _init_styles() -> void:
	_styles = UIStyles.create_clickable_panel_styles(
		GameConstants.COLOR_PANEL_DARK,
		GameConstants.COLOR_PANEL_DARK.lightened(0.15),
		GameConstants.COLOR_PANEL_DARK.darkened(0.1)
	)
	_apply_state_style()


func _on_mouse_entered() -> void:
	_is_hovered = true
	_apply_state_style()


func _on_mouse_exited() -> void:
	_is_hovered = false
	_is_pressed = false
	_apply_state_style()


func _apply_state_style() -> void:
	if _styles.is_empty() or not clickable:
		return
	var style: StyleBoxFlat
	if _is_pressed and _is_hovered:
		style = _styles.get("pressed", _styles.get("normal"))
	elif _is_hovered:
		style = _styles.get("hover", _styles.get("normal"))
	else:
		style = _styles.get("normal")
	if style:
		add_theme_stylebox_override("panel", style)


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
	if enabled and not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	elif not enabled:
		if mouse_entered.is_connected(_on_mouse_entered):
			mouse_entered.disconnect(_on_mouse_entered)
			mouse_exited.disconnect(_on_mouse_exited)
	_apply_state_style()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
				_apply_state_style()
			else:
				if _is_pressed and _is_hovered:
					card_clicked.emit(character_data)
				_is_pressed = false
				_apply_state_style()


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

	# Apply panel styling with hover support
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
