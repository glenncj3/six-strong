extends PanelContainer
# ItemSlot - Reusable component for displaying item slots
# Shows equipped item or empty slot
# Supports compact mode for space-constrained layouts

signal slot_clicked(item_id: String)

@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var item_icon: TextureRect = $MarginContainer/VBoxContainer/ItemIcon
@onready var item_name: Label = $MarginContainer/VBoxContainer/ItemName

var equipped_item_id: String = ""
var clickable: bool = true
var is_compact: bool = false


func _ready() -> void:
	# Allow parent to receive hover events by making display children transparent to mouse
	UIHelpers.set_children_mouse_filter_ignore(self)

	if clickable:
		gui_input.connect(_on_gui_input)


func setup(item_id: String = "") -> void:
	"""
	Configure the slot

	Args:
		item_id: ID of equipped item, or empty string for empty slot
	"""
	equipped_item_id = item_id

	if item_id.is_empty():
		_show_empty_slot()
	else:
		_show_equipped_item(item_id)


func _show_empty_slot() -> void:
	"""Display an empty slot"""
	item_icon.texture = null
	item_name.text = "[Empty]"
	modulate = GameConstants.COLOR_DISABLED


func _show_equipped_item(item_id: String) -> void:
	"""Display an equipped item"""
	var item_data = GameData.get_item_by_id(item_id)
	if item_data.is_empty():
		push_error("ItemSlot: Item not found: %s" % item_id)
		_show_empty_slot()
		return

	# Set icon using UIHelpers for safe texture loading
	UIHelpers.set_texture_safe(item_icon, item_data.get("image_path", ""))

	# Set name
	item_name.text = item_data["name"]

	# Normal color for equipped items
	modulate = Color.WHITE


func set_clickable(enabled: bool) -> void:
	"""Enable or disable click interaction"""
	clickable = enabled
	mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicked.emit(equipped_item_id)


func highlight(enabled: bool) -> void:
	"""Visually highlight the slot"""
	if enabled:
		modulate = GameConstants.COLOR_HIGHLIGHT
	else:
		if equipped_item_id.is_empty():
			modulate = GameConstants.COLOR_DISABLED
		else:
			modulate = Color.WHITE


func set_compact(enabled: bool) -> void:
	"""
	Enable or disable compact mode.
	Compact mode hides the label and reduces margins.

	Args:
		enabled: Whether to enable compact mode
	"""
	is_compact = enabled

	if enabled:
		# Compact: hide label, reduce margins
		var compact_size = UIScaler.get_item_slot_size(true)
		custom_minimum_size = compact_size

		margin_container.add_theme_constant_override("margin_left", 2)
		margin_container.add_theme_constant_override("margin_top", 2)
		margin_container.add_theme_constant_override("margin_right", 2)
		margin_container.add_theme_constant_override("margin_bottom", 2)

		item_icon.custom_minimum_size = Vector2(UIScaler.get_item_icon_size(true), UIScaler.get_item_icon_size(true))
		item_name.visible = false
		vbox.add_theme_constant_override("separation", 0)
	else:
		# Normal: show label, normal margins
		var normal_size = UIScaler.get_item_slot_size(false)
		custom_minimum_size = normal_size

		margin_container.add_theme_constant_override("margin_left", 4)
		margin_container.add_theme_constant_override("margin_top", 4)
		margin_container.add_theme_constant_override("margin_right", 4)
		margin_container.add_theme_constant_override("margin_bottom", 4)

		item_icon.custom_minimum_size = Vector2(UIScaler.get_item_icon_size(false), UIScaler.get_item_icon_size(false))
		item_name.visible = true
		vbox.add_theme_constant_override("separation", 4)

	# Apply fantasy panel styling
	UIStyles.apply_panel_style(self, UIStyles.create_subtle_panel())
