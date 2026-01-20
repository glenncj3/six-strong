extends PanelContainer
# ItemSlot - Reusable component for displaying item slots
# Shows equipped item or empty slot

signal slot_clicked(item_id: String)

@onready var item_icon: TextureRect = $MarginContainer/VBoxContainer/ItemIcon
@onready var item_name: Label = $MarginContainer/VBoxContainer/ItemName

var equipped_item_id: String = ""
var clickable: bool = true


func _ready() -> void:
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
	modulate = Color(0.7, 0.7, 0.7)


func _show_equipped_item(item_id: String) -> void:
	"""Display an equipped item"""
	var item_data = GameData.get_item_by_id(item_id)
	if item_data.is_empty():
		push_error("ItemSlot: Item not found: %s" % item_id)
		_show_empty_slot()
		return

	# Set icon
	var icon_path = item_data["image_path"]
	if ResourceLoader.exists(icon_path):
		item_icon.texture = load(icon_path)

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
		modulate = Color(1.3, 1.3, 1.0)  # Yellow tint
	else:
		if equipped_item_id.is_empty():
			modulate = Color(0.7, 0.7, 0.7)
		else:
			modulate = Color.WHITE
