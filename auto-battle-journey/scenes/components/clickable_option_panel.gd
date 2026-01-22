class_name ClickableOptionPanel
extends ClickablePanelBase
## Interactive panel component with hover/pressed states.
## Used for combat and encounter option selection.

var _option_data: Dictionary = {}


func setup(option_data: Dictionary, styles: Dictionary) -> void:
	"""
	Initialize the clickable panel with data and styles.

	Args:
		option_data: The data associated with this option (passed to signal)
		styles: Dictionary with "normal", "hover", "pressed" StyleBoxFlat entries
	"""
	_option_data = option_data
	setup_styles(styles, option_data)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _handle_click() -> void:
	panel_clicked.emit(_option_data)
