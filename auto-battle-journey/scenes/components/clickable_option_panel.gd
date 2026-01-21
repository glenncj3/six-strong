class_name ClickableOptionPanel
extends PanelContainer
# ClickableOptionPanel - Interactive panel component with hover/pressed states
# Used for combat and encounter option selection

signal panel_clicked(option_data: Dictionary)

var _option_data: Dictionary = {}
var _styles: Dictionary = {}
var _is_hovered: bool = false
var _is_pressed: bool = false


func setup(option_data: Dictionary, styles: Dictionary) -> void:
	"""
	Initialize the clickable panel with data and styles.

	Args:
		option_data: The data associated with this option (passed to signal)
		styles: Dictionary with "normal", "hover", "pressed" StyleBoxFlat entries
	"""
	_option_data = option_data
	_styles = styles
	_apply_state_style()

	# Enable mouse input
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
				_apply_state_style()
			else:
				if _is_pressed and _is_hovered:
					panel_clicked.emit(_option_data)
				_is_pressed = false
				_apply_state_style()


func _on_mouse_entered() -> void:
	_is_hovered = true
	_apply_state_style()


func _on_mouse_exited() -> void:
	_is_hovered = false
	_is_pressed = false
	_apply_state_style()


func _apply_state_style() -> void:
	if _styles.is_empty():
		return

	var style: StyleBoxFlat
	if _is_pressed and _is_hovered:
		style = _styles.get("pressed", _styles.get("normal"))
	elif _is_hovered:
		style = _styles.get("hover", _styles.get("normal"))
	else:
		style = _styles.get("normal")

	if style:
		add_theme_stylebox_override("panel", style)
