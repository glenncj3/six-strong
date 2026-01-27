extends ClickablePanelBase
## PurchasableTile - Clickable square tile for purchasable options
## Shows icon, name, description, and cost in a compact square format
## Reusable for health options, items, skills in shop, etc.

signal tile_clicked(tile_data: Dictionary)

const TILE_BORDER_WIDTH := 4

@onready var content_margin: MarginContainer = $ContentMargin
@onready var icon: TextureRect = $ContentMargin/Icon
@onready var border_overlay: Panel = $BorderOverlay
@onready var name_label: Label = $ContentMargin/NameMargin/NameLabel
@onready var gold_cost_icon: PanelContainer = $ContentMargin/CostMargin/GoldCostIcon

var tile_data: Dictionary = {}
var cost: int = 0

# Pending setup data (for when setup() called before node is ready)
var _pending_setup: Dictionary = {}


func _init_default_styles() -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = GameConstants.COLOR_SUCCESS.darkened(0.3)
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = GameConstants.COLOR_SUCCESS.darkened(0.1)
	var pressed = normal.duplicate()
	pressed.bg_color = GameConstants.COLOR_SUCCESS.darkened(0.5)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})


func _on_ready() -> void:
	UIHelpers.set_children_mouse_filter_ignore(self)
	UIStyles.set_margin_all(content_margin, TILE_BORDER_WIDTH)
	_setup_border_overlay()

	# Apply any pending setup that was called before node was ready
	if not _pending_setup.is_empty():
		_apply_setup(_pending_setup.tile_data, _pending_setup.tile_size)
		_pending_setup = {}


func _setup_border_overlay() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(TILE_BORDER_WIDTH)
	style.border_color = GameConstants.COLOR_BORDER_GOLD
	style.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	border_overlay.add_theme_stylebox_override("panel", style)


func _handle_click() -> void:
	if not tile_data.is_empty():
		tile_clicked.emit(tile_data)


func setup(p_tile_data: Dictionary, tile_size: float) -> void:
	"""Configure the tile with data."""
	tile_data = p_tile_data
	custom_minimum_size = Vector2(tile_size, tile_size)

	if tile_data.is_empty():
		push_error("PurchasableTile: Empty tile data provided")
		return

	# If not ready yet (node not in tree), defer setup
	if not is_node_ready():
		_pending_setup = {"tile_data": tile_data, "tile_size": tile_size}
		return

	_apply_setup(tile_data, tile_size)


func _apply_setup(p_tile_data: Dictionary, _tile_size: float) -> void:
	"""Apply the setup to UI elements (called when node is ready)."""
	UIHelpers.set_texture_safe(icon, p_tile_data.get("image_path", ""))
	name_label.text = p_tile_data.get("name", "Unknown")
	cost = p_tile_data.get("cost", 0)
	gold_cost_icon.set_cost(cost)


func set_tile_color(bg_color: Color) -> void:
	"""Override the tile background color."""
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = bg_color.lightened(0.15)
	var pressed = normal.duplicate()
	pressed.bg_color = bg_color.darkened(0.1)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})
