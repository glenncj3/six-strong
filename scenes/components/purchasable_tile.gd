extends ClickablePanelBase
class_name PurchasableTile
## PurchasableTile - Clickable square tile for purchasable options
## Shows icon, name, description, and cost in a compact square format
## Reusable for health options, items, skills in shop, etc.

signal tile_clicked(tile_data: Dictionary)

const TILE_BORDER_WIDTH := 4
const LONG_PRESS_DURATION := 0.12
const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")

# Static drag state — shared across all PurchasableTile instances
static var _active_drag_tile: PurchasableTile = null
static var _active_drag_preview: Control = null
static var _active_drag_canvas: CanvasLayer = null

@onready var content_margin: MarginContainer = $ContentMargin
@onready var icon: TextureRect = $ContentMargin/Icon
@onready var border_overlay: Panel = $BorderOverlay
@onready var name_label: Label = $ContentMargin/NameMargin/NameLabel
@onready var gold_cost_icon: PanelContainer = $ContentMargin/CostMargin/GoldCostIcon

var tile_data: Dictionary = {}
var cost: int = 0
var _embedded_character_tile: CharacterTile = null

# Pending setup data (for when setup() called before node is ready)
var _pending_setup: Dictionary = {}

# Long-press drag detection
var _long_press_timer: Timer
var _press_position: Vector2 = Vector2.ZERO
var _long_press_triggered: bool = false
var _original_global_pos: Vector2 = Vector2.ZERO


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
	_setup_long_press_timer()

	# Apply any pending setup that was called before node was ready
	if not _pending_setup.is_empty():
		_apply_setup(_pending_setup.tile_data, _pending_setup.tile_size)
		_pending_setup = {}


func _setup_long_press_timer() -> void:
	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = LONG_PRESS_DURATION
	_long_press_timer.timeout.connect(_on_long_press_timeout)
	add_child(_long_press_timer)


func _setup_border_overlay() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(TILE_BORDER_WIDTH)
	style.border_color = GameConstants.COLOR_BORDER_GOLD
	style.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	border_overlay.add_theme_stylebox_override("panel", style)


func _on_gui_input(event: InputEvent) -> void:
	if not clickable:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_long_press_triggered = false
			_press_position = event.global_position
			_apply_state_style()
			if enable_scale_animation:
				_scaler.press()
			if not tile_data.is_empty():
				_long_press_timer.start()
		else:
			_long_press_timer.stop()
			if _long_press_triggered:
				_long_press_triggered = false
			elif _is_pressed and _is_hovered:
				_handle_click()
			_is_pressed = false
			_apply_state_style()
			if enable_scale_animation:
				_scaler.release(_is_hovered)

	elif event is InputEventMouseMotion and _is_pressed:
		if _press_position.distance_to(event.global_position) > 15:
			_long_press_timer.stop()


func _handle_click() -> void:
	if not tile_data.is_empty():
		tile_clicked.emit(tile_data)


# =============================================================================
# DRAG AND DROP
# =============================================================================

func _on_long_press_timeout() -> void:
	if tile_data.is_empty():
		return
	_long_press_triggered = true
	_original_global_pos = global_position
	_start_drag()


func _start_drag() -> void:
	_active_drag_tile = self
	modulate.a = 0.3

	# Create preview on a high CanvasLayer
	_active_drag_canvas = CanvasLayer.new()
	_active_drag_canvas.layer = GameConstants.LAYER_TOOLTIP
	get_tree().root.add_child(_active_drag_canvas)

	_active_drag_preview = duplicate()
	_active_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_active_drag_preview.modulate = Color(1, 1, 1, 0.85)
	_active_drag_preview.scale = Vector2(1.05, 1.05)
	_active_drag_canvas.add_child(_active_drag_preview)

	var preview_size = custom_minimum_size
	_active_drag_preview.position = get_viewport().get_mouse_position() - preview_size / 2.0


func _input(event: InputEvent) -> void:
	if _active_drag_tile != self:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		var pos = event.position if event is InputEventScreenDrag else event.global_position
		if _active_drag_preview:
			var preview_size = custom_minimum_size
			_active_drag_preview.position = pos - preview_size / 2.0

	elif _is_drag_release_event(event):
		# Check if dropped on a TeamHUD slot — handled by TeamHUD._handle_purchasable_drop
		# If TeamHUD consumed it, _active_drag_tile will be null already
		# Otherwise cancel (snap back, no purchase)
		if _active_drag_tile == self:
			_cancel_drag()


func _cancel_drag() -> void:
	if _active_drag_preview and is_instance_valid(_active_drag_preview):
		# Animate back to original position
		var tween = _active_drag_preview.create_tween()
		tween.tween_property(_active_drag_preview, "position", _original_global_pos, 0.15) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(_finish_drag_cleanup)
	else:
		_finish_drag_cleanup()


func _finish_drag_cleanup() -> void:
	modulate.a = 1.0
	if _active_drag_preview and is_instance_valid(_active_drag_preview):
		_active_drag_preview.queue_free()
	_active_drag_preview = null
	if _active_drag_canvas and is_instance_valid(_active_drag_canvas):
		_active_drag_canvas.queue_free()
	_active_drag_canvas = null
	_active_drag_tile = null


static func is_drag_active() -> bool:
	return _active_drag_tile != null and is_instance_valid(_active_drag_tile)


static func complete_drag_on_slot() -> void:
	"""Called by TeamHUD when a purchasable drag is dropped on a valid slot."""
	if not is_drag_active():
		return
	var tile = _active_drag_tile
	# Emit tile_clicked to trigger the existing purchase flow
	tile.tile_clicked.emit(tile.tile_data)
	tile._finish_drag_cleanup()


func _is_drag_release_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return not event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return not event.pressed
	return false


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


func _apply_setup(p_tile_data: Dictionary, tile_size: float) -> void:
	"""Apply the setup to UI elements (called when node is ready)."""
	cost = p_tile_data.get("cost", 0)
	gold_cost_icon.set_cost(cost)

	if p_tile_data.get("offering_type", "") == "character":
		_embed_character_tile(p_tile_data, tile_size)
	else:
		UIHelpers.set_texture_safe(icon, p_tile_data.get("image_path", ""))
		name_label.text = p_tile_data.get("name", "Unknown")


func _embed_character_tile(p_tile_data: Dictionary, tile_size: float) -> void:
	"""Embed a CharacterTile to display the character visuals (portrait, name, stats)."""
	# Hide generic display elements — CharacterTile handles portrait, name, stats
	icon.visible = false
	name_label.visible = false
	$ContentMargin/NameMargin/NameHaze.visible = false
	# Disable clip_contents so CharacterTile's stat badges can overflow the edges
	clip_contents = false

	# Remove previous embedded tile if any
	if _embedded_character_tile and is_instance_valid(_embedded_character_tile):
		_embedded_character_tile.queue_free()

	_embedded_character_tile = CharacterTileScene.instantiate()
	_embedded_character_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_embedded_character_tile.clickable = false

	# Insert at the bottom so ContentMargin (cost badge) and BorderOverlay draw on top
	add_child(_embedded_character_tile)
	move_child(_embedded_character_tile, 0)

	# Make it fill the PurchasableTile
	_embedded_character_tile.set_anchors_preset(Control.PRESET_FULL_RECT)
	_embedded_character_tile.size_flags_horizontal = Control.SIZE_FILL
	_embedded_character_tile.size_flags_vertical = Control.SIZE_FILL

	# Use CharacterTile's dictionary-based setup (looks up master data by id)
	_embedded_character_tile.setup_from_data(p_tile_data, tile_size)

	# Hide CharacterTile's own border — PurchasableTile's BorderOverlay handles it
	_embedded_character_tile.border_overlay.visible = false


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
