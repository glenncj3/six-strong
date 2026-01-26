extends Control
# DEPRECATED: This screen has been replaced by LegacyCollection (Phase 8)
# Kept for reference during transition period. Use legacy_collection.tscn instead.
#
# Collection - Browse and manage character collection
# Portrait mobile layout with full-screen details overlay
# Uses CharacterTile in rows of 3

@onready var background = $Background
@onready var title_label = $MainContainer/VBoxContainer/Title
@onready var character_list: VBoxContainer = $MainContainer/VBoxContainer/CharacterListScroll/CharacterList
@onready var character_details_panel: Panel = $CharacterDetailsPanel
@onready var details_background = $CharacterDetailsPanel/DetailsBackground
@onready var details_content: Control = $CharacterDetailsPanel/DetailsMargin/DetailsContainer/DetailsContent
@onready var details_title = $CharacterDetailsPanel/DetailsMargin/DetailsContainer/DetailsTitle
@onready var back_button: Button = $HeaderBar/MarginContainer/HBoxContainer/LeftSection/BackButton
@onready var gems_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GemsLabel
@onready var reroll_tokens_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/RerollTokensLabel

# Preload scenes
const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")
const CharacterDetailsScene = preload("res://scenes/ui/character_details.tscn")

var character_details_instance: Node = null
var selected_character_id: String = ""
var character_tiles: Array = []  # References to tile nodes


func _ready() -> void:
	_apply_visual_styling()

	back_button.pressed.connect(_on_back_pressed)

	# Hide details panel initially
	character_details_panel.visible = false

	# Initialize currency display
	_update_currency_display()
	PlayerAccount.gems_changed.connect(_on_gems_changed)
	PlayerAccount.reroll_tokens_changed.connect(_on_reroll_tokens_changed)

	_populate_character_list()
	_play_entrance_animations()


func _exit_tree() -> void:
	# Disconnect from autoload signals to prevent memory leaks
	if PlayerAccount.gems_changed.is_connected(_on_gems_changed):
		PlayerAccount.gems_changed.disconnect(_on_gems_changed)
	if PlayerAccount.reroll_tokens_changed.is_connected(_on_reroll_tokens_changed):
		PlayerAccount.reroll_tokens_changed.disconnect(_on_reroll_tokens_changed)


func _play_entrance_animations() -> void:
	"""Play entrance animations for UI elements."""
	AnimationManager.fade_in(title_label, GameConstants.ANIM_DURATION_NORMAL, 0.0)

	# Cascade fade in character tiles
	var delay = 0.1
	for tile in character_tiles:
		AnimationManager.fade_in(tile, GameConstants.ANIM_DURATION_NORMAL, delay)
		delay += 0.03


func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling."""
	# Backgrounds
	details_background.color = GameConstants.COLOR_BG_DARK

	# Title styling
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	details_title.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Currency label colors
	gems_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	reroll_tokens_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Button styling
	UIStyles.apply_button_styles(back_button)


func _populate_character_list() -> void:
	"""Create character tiles in rows of 3."""
	# Clear existing tiles
	UIHelpers.clear_children(character_list)
	character_tiles.clear()

	# Get unlocked characters
	var unlocked_chars = PlayerAccount.get_unlocked_characters()

	# Calculate tile size
	var tile_size = UIScaler.calculate_tile_size(size.x, 3, 32.0, 16.0, 180.0, 680.0)

	# Create rows of 3 tiles
	var current_row: HBoxContainer = null
	var tiles_in_row = 0

	for i in range(unlocked_chars.size()):
		# Create new row every 3 tiles
		if tiles_in_row == 0:
			current_row = HBoxContainer.new()
			current_row.alignment = BoxContainer.ALIGNMENT_CENTER
			current_row.add_theme_constant_override("separation", 8)
			character_list.add_child(current_row)

		var char_data = unlocked_chars[i]
		var tile = CharacterTileScene.instantiate()
		current_row.add_child(tile)
		tile.setup_from_data(char_data, tile_size)
		tile.tile_clicked_data.connect(_on_character_tile_clicked)
		character_tiles.append(tile)

		tiles_in_row += 1
		if tiles_in_row >= 3:
			tiles_in_row = 0


func _on_character_tile_clicked(char_data: Dictionary) -> void:
	"""Handle character tile selection - show details overlay."""
	_select_character(char_data.get("id", ""))


func _select_character(char_id: String) -> void:
	"""Display details for selected character in full-screen overlay."""
	selected_character_id = char_id

	# Get character data
	var char_data = PlayerAccount.get_character_data(char_id)
	if char_data.is_empty():
		push_error("Collection: Character data not found: %s" % char_id)
		return

	# Clear existing details
	if character_details_instance:
		character_details_instance.queue_free()

	# Create new details panel
	character_details_instance = CharacterDetailsScene.instantiate()
	details_content.add_child(character_details_instance)
	character_details_instance.display_character(char_data)

	# Show the details overlay
	character_details_panel.visible = true

	# Highlight selected tile
	_highlight_selected_tile()


func _on_close_details_pressed() -> void:
	"""Close the details overlay and return to grid view."""
	character_details_panel.visible = false


func _highlight_selected_tile() -> void:
	"""Highlight the currently selected character tile."""
	for tile in character_tiles:
		var tile_id = tile.char_data.get("id", "")
		tile.highlight(tile_id == selected_character_id)


func refresh_display() -> void:
	"""Refresh the entire collection display."""
	_populate_character_list()
	if not selected_character_id.is_empty():
		_select_character(selected_character_id)


func _update_currency_display() -> void:
	gems_label.text = UIHelpers.format_currency(PlayerAccount.get_gems(), GameConstants.EMOJI_GEM)
	reroll_tokens_label.text = UIHelpers.format_currency(PlayerAccount.get_reroll_tokens(), GameConstants.EMOJI_REROLL)


func _on_gems_changed(new_amount: int) -> void:
	gems_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_GEM)


func _on_reroll_tokens_changed(new_amount: int) -> void:
	reroll_tokens_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_REROLL)


func _on_back_pressed() -> void:
	"""Context-aware back: close details if open, else return to main menu."""
	if character_details_panel.visible:
		_on_close_details_pressed()
	else:
		var tween = AnimationManager.fade_out(back_button, GameConstants.ANIM_DURATION_NORMAL)
		tween.finished.connect(func(): SceneManager.go_to("main_menu", false))
