extends CompactableIconBase
# ItemSlot - Reusable component for displaying item slots
# Shows equipped item or empty slot
# Supports compact mode for space-constrained layouts

signal slot_clicked(item_id: String)

@onready var _margin_container: MarginContainer = $MarginContainer
@onready var _vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var item_icon: TextureRect = $MarginContainer/VBoxContainer/ItemIcon
@onready var item_name: Label = $MarginContainer/VBoxContainer/ItemName

var equipped_item_id: String = ""
var clickable: bool = true


func _on_ready() -> void:
	# Set base class references
	margin_container = _margin_container
	vbox = _vbox
	_icon = item_icon
	_label = item_name

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


func _get_compact_size() -> Vector2:
	return UIScaler.get_item_slot_size(true)


func _get_normal_size() -> Vector2:
	return UIScaler.get_item_slot_size(false)


func _get_compact_icon_size() -> float:
	return UIScaler.get_item_icon_size(true)


func _get_normal_icon_size() -> float:
	return UIScaler.get_item_icon_size(false)
