extends PanelContainer
# TeamDisplay - Manages team display with overview and focus modes
# Overview: Shows all characters as square tiles
# Focus: Shows detailed view of a single character
# Follows SOLID/DRY - composes reusable sub-components

signal overview_shown  # Emitted when returning to overview mode (tiles recreated)

enum DisplayMode { OVERVIEW, FOCUS }

const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")
const CharacterDetailScene = preload("res://scenes/components/character_detail.tscn")
const DetailPopupScene = preload("res://scenes/components/detail_popup.tscn")

@onready var margin_container: MarginContainer = $MarginContainer
@onready var main_container: VBoxContainer = $MarginContainer/MainContainer
@onready var title_label: Label = $MarginContainer/MainContainer/TitleLabel
@onready var overview_container: HBoxContainer = $MarginContainer/MainContainer/OverviewContainer
@onready var focus_container: Control = $MarginContainer/MainContainer/FocusContainer

var current_mode: DisplayMode = DisplayMode.OVERVIEW
var team: Array = []  # Array of CharacterInstance
var character_tiles: Array = []  # References to tile nodes
var character_detail: Node = null
var detail_popup: Node = null
var focused_character: CharacterInstance = null
var _pending_overview: bool = false  # Flag to transition to overview on next frame


func _ready() -> void:
	UIStyles.apply_panel_style(self, UIStyles.create_dark_panel())
	self_modulate.a = 0  # Make panel background invisible for debugging
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Create the detail popup (shared instance)
	detail_popup = DetailPopupScene.instantiate()
	add_child(detail_popup)
	detail_popup.closed.connect(_on_popup_closed)

	# Enable processing for pending transitions
	set_process(true)


func _process(_delta: float) -> void:
	# Handle pending transition to overview mode
	if _pending_overview:
		_pending_overview = false
		_show_overview()


func setup(team_array: Array, title: String = "YOUR TEAM") -> void:
	"""
	Setup the team display with character instances.

	Args:
		team_array: Array of CharacterInstance objects
		title: Title text to display
	"""
	team = team_array
	title_label.text = title

	# Always start in overview mode
	_show_overview()


func refresh() -> void:
	"""Refresh the display with current team data."""
	if current_mode == DisplayMode.OVERVIEW:
		_show_overview()
	else:
		_show_focus(focused_character)


func _show_overview() -> void:
	"""Show overview mode with all character tiles."""
	# Safety check - ensure we're still valid and in tree
	if not is_inside_tree():
		return

	current_mode = DisplayMode.OVERVIEW
	focused_character = null

	# Clean up character detail from focus mode
	_cleanup_character_detail()

	# Show/hide containers
	overview_container.visible = true
	focus_container.visible = false
	title_label.visible = true

	# Clear existing tiles
	UIHelpers.clear_children(overview_container)
	character_tiles.clear()

	# Calculate tile size (just under 1/3 of available width)
	# Use a minimum width fallback if size not yet calculated
	var available_width = max(size.x, 680) - 24  # Account for margins, min ~720 screen
	var tile_size = floor((available_width - 16) / 3.0)  # 16 = spacing between tiles
	tile_size = max(tile_size, 180)  # Minimum tile size for readability

	# Create tiles for each character
	for char_instance in team:
		var tile = CharacterTileScene.instantiate()
		overview_container.add_child(tile)
		tile.setup(char_instance, tile_size)
		tile.tile_clicked.connect(_on_character_tile_clicked)
		character_tiles.append(tile)

	# Notify listeners that overview is shown (tiles recreated)
	overview_shown.emit()


func _show_focus(char_instance: CharacterInstance) -> void:
	"""Show focus mode for a specific character."""
	current_mode = DisplayMode.FOCUS
	focused_character = char_instance

	# Show/hide containers
	overview_container.visible = false
	focus_container.visible = true
	title_label.visible = false  # Hide title in focus mode, detail view has name

	# Clean up existing detail view (disconnect signals before freeing)
	_cleanup_character_detail()

	# Create and setup detail view
	character_detail = CharacterDetailScene.instantiate()
	focus_container.add_child(character_detail)
	character_detail.setup(char_instance)

	# Connect signals
	character_detail.back_pressed.connect(_on_back_to_overview)
	character_detail.item_clicked.connect(_on_item_clicked)
	character_detail.skill_clicked.connect(_on_skill_clicked)


func _cleanup_character_detail() -> void:
	"""Safely clean up the character detail view."""
	if character_detail and is_instance_valid(character_detail):
		# Disconnect signals before freeing
		if character_detail.back_pressed.is_connected(_on_back_to_overview):
			character_detail.back_pressed.disconnect(_on_back_to_overview)
		if character_detail.item_clicked.is_connected(_on_item_clicked):
			character_detail.item_clicked.disconnect(_on_item_clicked)
		if character_detail.skill_clicked.is_connected(_on_skill_clicked):
			character_detail.skill_clicked.disconnect(_on_skill_clicked)
		character_detail.queue_free()
		character_detail = null


func _on_character_tile_clicked(char_instance: CharacterInstance) -> void:
	"""Handle character tile click - switch to focus mode."""
	_show_focus(char_instance)


func _on_back_to_overview() -> void:
	"""Handle back button - return to overview mode."""
	# Set flag to transition on next frame to avoid issues during signal processing
	_pending_overview = true


func _on_item_clicked(item_id: String) -> void:
	"""Handle item click - show detail popup."""
	detail_popup.show_item(item_id)


func _on_skill_clicked(skill_id: String) -> void:
	"""Handle skill click - show detail popup."""
	detail_popup.show_skill(skill_id)


func _on_popup_closed() -> void:
	"""Handle popup close."""
	pass  # Could add additional behavior here


