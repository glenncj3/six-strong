extends ModalPopup
class_name CharacterReplacementPopup
## Popup shown when the grid is full and a new character is acquired.
## Displays the new character and the current grid.
## Player can tap a grid slot to replace that character, or cancel.

signal character_replaced(removed: CharacterInstance, slot: Vector2i)
signal replacement_cancelled

const CharacterGridUIScene = preload("res://scenes/components/character_grid_ui.tscn")
const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")

@onready var title_label: Label = $Content/TitleLabel
@onready var instruction_label: Label = $Content/InstructionLabel
@onready var new_character_container: PanelContainer = $Content/NewCharacterPanel
@onready var new_character_tile_container: CenterContainer = $Content/NewCharacterPanel/VBox/TileContainer
@onready var new_character_name: Label = $Content/NewCharacterPanel/VBox/CharacterName
@onready var grid_container: Control = $Content/GridContainer
@onready var cancel_button: Button = $Content/ButtonContainer/CancelButton

var _new_character: CharacterInstance = null
var _grid: CharacterGrid = null
var _grid_ui: CharacterGridUI = null
var _new_character_tile = null


func _ready() -> void:
	super._ready()
	cancel_button.pressed.connect(_on_cancel_pressed)
	_setup_grid_ui()


func _setup_grid_ui() -> void:
	"""Create and add the grid UI component."""
	_grid_ui = CharacterGridUIScene.instantiate()
	grid_container.add_child(_grid_ui)
	_grid_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grid_ui.slot_clicked.connect(_on_slot_selected)


# =============================================================================
# PUBLIC API
# =============================================================================

func show_replacement(new_char: CharacterInstance, grid: CharacterGrid) -> void:
	"""
	Show the replacement popup.

	Args:
		new_char: The new character to potentially add
		grid: The current character grid (must be full)
	"""
	_new_character = new_char
	_grid = grid

	_display_new_character()
	_display_grid()
	_highlight_all_slots()

	show_modal()


# =============================================================================
# DISPLAY
# =============================================================================

func _display_new_character() -> void:
	"""Display the new character that wants to join."""
	if not _new_character:
		return

	# Create character tile
	if _new_character_tile:
		_new_character_tile.queue_free()

	_new_character_tile = CharacterTileScene.instantiate()
	new_character_tile_container.add_child(_new_character_tile)
	_new_character_tile.setup(_new_character, 120)

	# Set name label
	new_character_name.text = _new_character.get_character_name()


func _display_grid() -> void:
	"""Display the current grid for selection."""
	if not _grid or not _grid_ui:
		return

	# Populate grid display from grid data
	for row in range(GameConstants.GRID_ROWS):
		for col in range(GameConstants.GRID_COLS):
			var character = _grid.get_character_at(row, col)
			_grid_ui.set_slot_character(row, col, character)


func _highlight_all_slots() -> void:
	"""Highlight all slots as selectable."""
	if _grid_ui:
		_grid_ui.highlight_all_slots(true, true)


# =============================================================================
# SLOT SELECTION
# =============================================================================

func _on_slot_selected(row: int, col: int, _character: CharacterInstance) -> void:
	"""Handle slot selection - replace the character in that slot."""
	if not _grid or not _new_character:
		return

	# Remove the existing character
	var removed = _grid.remove_character(row, col)

	# Place the new character
	_grid.place_character(_new_character, row, col)

	# Emit signal and close
	character_replaced.emit(removed, Vector2i(row, col))
	_cleanup_and_hide()


func _on_cancel_pressed() -> void:
	"""Handle cancel button - decline the new character."""
	replacement_cancelled.emit()
	_cleanup_and_hide()


func _cleanup_and_hide() -> void:
	"""Clean up state and hide the popup."""
	_new_character = null
	_grid = null

	if _new_character_tile:
		_new_character_tile.queue_free()
		_new_character_tile = null

	if _grid_ui:
		_grid_ui.highlight_all_slots(false)

	hide_modal()


# =============================================================================
# MODAL OVERRIDE
# =============================================================================

func _center_popup() -> void:
	"""Override to use larger centered popup."""
	set_anchors_preset(Control.PRESET_CENTER)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5

	# Larger popup for grid display
	var popup_width: float = 650.0
	var popup_height: float = 700.0
	offset_left = -popup_width / 2
	offset_top = -popup_height / 2
	offset_right = popup_width / 2
	offset_bottom = popup_height / 2
