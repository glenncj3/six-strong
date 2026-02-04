extends ModalPopup
## ItemsPopup - Shows collected items in a 3-column grid during runs
## Tap and hold on an item shows a tooltip with name and description

signal closed

const GRID_COLUMNS := 3
const ITEM_SIZE := 80
const ITEM_SPACING := 8
const HOLD_DURATION := 0.3  # Seconds to trigger tooltip

@onready var margin_container: MarginContainer = $MarginContainer
@onready var main_container: VBoxContainer = $MarginContainer/MainContainer
@onready var title_label: Label = $MarginContainer/MainContainer/TitleLabel
@onready var scroll_container: ScrollContainer = $MarginContainer/MainContainer/ScrollContainer
@onready var items_grid: GridContainer = $MarginContainer/MainContainer/ScrollContainer/ItemsGrid
@onready var empty_label: Label = $MarginContainer/MainContainer/EmptyLabel
@onready var close_button: Button = $MarginContainer/MainContainer/CloseButton

var _tooltip_popup: Control = null
var _tooltip_canvas_layer: CanvasLayer = null
var _hold_timer: Timer = null
var _held_item: ItemInstance = null


func _ready() -> void:
	super._ready()
	close_button.pressed.connect(_on_close_pressed)
	UIStyles.apply_panel_style(self, UIStyles.create_warm_panel())
	UIStyles.apply_button_styles(close_button)
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)

	# Setup hold timer for tooltips
	_hold_timer = Timer.new()
	_hold_timer.one_shot = true
	_hold_timer.wait_time = HOLD_DURATION
	_hold_timer.timeout.connect(_on_hold_timer_timeout)
	add_child(_hold_timer)


func show_items(items: Array) -> void:
	"""Display the items popup with the given items."""
	_populate_grid(items)
	show_modal()


func _populate_grid(items: Array) -> void:
	"""Populate the grid with item tiles."""
	UIHelpers.clear_children(items_grid)

	if items.is_empty():
		empty_label.visible = true
		scroll_container.visible = false
		return

	empty_label.visible = false
	scroll_container.visible = true

	for item in items:
		var item_tile = _create_item_tile(item)
		items_grid.add_child(item_tile)


func _create_item_tile(item: ItemInstance) -> PanelContainer:
	"""Create a single item tile with icon."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(ITEM_SIZE, ITEM_SIZE)
	UIStyles.apply_panel_style(panel, UIStyles.create_subtle_panel())

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ITEM_SIZE - 8, ITEM_SIZE - 8)
	UIHelpers.set_texture_safe(icon, item.image_path)
	margin.add_child(icon)

	# Store item reference for tooltip
	panel.set_meta("item", item)

	# Setup touch/click handling for tooltip
	panel.gui_input.connect(_on_item_gui_input.bind(panel, item))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	return panel


func _on_item_gui_input(event: InputEvent, panel: PanelContainer, item: ItemInstance) -> void:
	"""Handle input on item tiles for tap-and-hold tooltips."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_hold(item, panel.global_position + panel.size / 2)
			else:
				_cancel_hold()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_hold(item, event.position)
		else:
			_cancel_hold()


func _start_hold(item: ItemInstance, _position: Vector2) -> void:
	"""Start the hold timer for showing tooltip."""
	_held_item = item
	_hold_timer.start()


func _cancel_hold() -> void:
	"""Cancel the hold and hide tooltip."""
	_hold_timer.stop()
	_held_item = null
	_hide_tooltip()


func _on_hold_timer_timeout() -> void:
	"""Show tooltip when hold duration is reached."""
	if _held_item:
		_show_tooltip(_held_item)


func _show_tooltip(item: ItemInstance) -> void:
	"""Show a tooltip with item name and description."""
	_ensure_tooltip_canvas_layer()

	# Create tooltip panel
	_tooltip_popup = PanelContainer.new()
	_tooltip_popup.custom_minimum_size = Vector2(250, 0)
	UIStyles.apply_panel_style(_tooltip_popup, UIStyles.create_dark_panel())

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_tooltip_popup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Name label
	var name_label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	vbox.add_child(name_label)

	# Description label
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	# Stat modifiers
	if not item.stat_modifiers.is_empty():
		var stats_container = VBoxContainer.new()
		stats_container.add_theme_constant_override("separation", 2)
		vbox.add_child(stats_container)

		for stat_name in item.stat_modifiers:
			var value = item.stat_modifiers[stat_name]
			var stat_label = Label.new()
			var display_value = "+%d" % value if value >= 0 else "%d" % value
			stat_label.text = "%s: %s" % [_format_stat_name(stat_name), display_value]
			stat_label.add_theme_font_size_override("font_size", 12)
			stat_label.add_theme_color_override("font_color", GameConstants.COLOR_EMERALD)
			stats_container.add_child(stat_label)

	_tooltip_canvas_layer.add_child(_tooltip_popup)

	# Position tooltip in center of screen
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	_tooltip_popup.position = (viewport_size - _tooltip_popup.size) / 2


func _hide_tooltip() -> void:
	"""Hide and cleanup the tooltip."""
	if _tooltip_popup and is_instance_valid(_tooltip_popup):
		_tooltip_popup.queue_free()
		_tooltip_popup = null


func _ensure_tooltip_canvas_layer() -> void:
	"""Ensure tooltip canvas layer exists."""
	if _tooltip_canvas_layer and is_instance_valid(_tooltip_canvas_layer):
		return
	_tooltip_canvas_layer = CanvasLayer.new()
	_tooltip_canvas_layer.layer = GameConstants.LAYER_TOOLTIP
	get_tree().root.add_child(_tooltip_canvas_layer)


func _format_stat_name(stat_name: String) -> String:
	"""Format stat name for display."""
	match stat_name:
		"health":
			return "Health"
		"charges":
			return "Charges"
		"agility":
			return "Defend Rate"
		"speed":
			return "Speed"
		"damage":
			return "Damage"
		"crit_chance":
			return "Crit Chance"
		_:
			return stat_name.capitalize().replace("_", " ")


func hide_popup() -> void:
	"""Hide the popup and emit closed signal."""
	_hide_tooltip()
	hide_modal()
	closed.emit()


func _on_close_pressed() -> void:
	hide_popup()


func _exit_tree() -> void:
	_hide_tooltip()
	if _tooltip_canvas_layer and is_instance_valid(_tooltip_canvas_layer):
		_tooltip_canvas_layer.queue_free()
		_tooltip_canvas_layer = null
