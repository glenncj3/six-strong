extends ClickablePanelBase
## LegacyTile - Tile for legacy display during draft
## Shows legacy portrait, name, income, and starting character preview

signal tile_clicked(legacy: LegacyData)

const TILE_BORDER_WIDTH := 4

@onready var content_margin: MarginContainer = $ContentMargin
@onready var portrait: TextureRect = $ContentMargin/Portrait
@onready var name_label: Label = $ContentMargin/NameMargin/NameLabel
@onready var info_container: VBoxContainer = $ContentMargin/InfoContainer
@onready var income_label: Label = $ContentMargin/InfoContainer/IncomeLabel
@onready var prestige_label: Label = $ContentMargin/InfoContainer/PrestigeLabel
@onready var starter_label: Label = $ContentMargin/InfoContainer/StarterLabel

var legacy_data: LegacyData = null


func _init_default_styles() -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = GameConstants.COLOR_PANEL_DARK
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = GameConstants.COLOR_PANEL_DARK.lightened(0.15)
	var pressed = normal.duplicate()
	pressed.bg_color = GameConstants.COLOR_PANEL_DARK.darkened(0.1)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})


func _on_ready() -> void:
	UIHelpers.set_children_mouse_filter_ignore(self)
	UIStyles.set_margin_all(content_margin, TILE_BORDER_WIDTH)
	_setup_info_labels()


func _setup_info_labels() -> void:
	# Style the info labels
	for label in [income_label, prestige_label, starter_label]:
		if label:
			label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)
			label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)


func _handle_click() -> void:
	if legacy_data:
		tile_clicked.emit(legacy_data)


func setup(legacy: LegacyData, tile_size: float) -> void:
	"""Configure the tile with a legacy."""
	legacy_data = legacy
	custom_minimum_size = Vector2(tile_size, tile_size)

	# Set portrait
	UIHelpers.set_texture_safe(portrait, legacy.image_path)

	# Set name
	name_label.text = legacy.legacy_name

	# Set income
	if income_label:
		income_label.text = "Income: %d" % legacy.income

	# Set prestige
	if prestige_label:
		prestige_label.text = "Prestige: %d" % legacy.get_prestige()

	# Set starting character preview
	if starter_label:
		var starter_name = _get_starter_name(legacy)
		starter_label.text = "Starts: %s" % starter_name


func _get_starter_name(legacy: LegacyData) -> String:
	"""Get the display name of the starting character."""
	if legacy.selected_starting_character_id.is_empty():
		return "None"

	var char_data = GameData.get_character_by_id(legacy.selected_starting_character_id)
	if char_data.is_empty():
		return legacy.selected_starting_character_id

	return char_data.get("name", "Unknown")


func set_selected(is_selected: bool) -> void:
	"""Update visual state for selection."""
	if is_selected:
		modulate = GameConstants.COLOR_TILE_SELECTED
	else:
		modulate = Color.WHITE


func set_dimmed(is_dimmed: bool) -> void:
	"""Dim the tile when not selectable."""
	if is_dimmed:
		modulate = GameConstants.COLOR_TILE_DIMMED
	else:
		modulate = Color.WHITE
