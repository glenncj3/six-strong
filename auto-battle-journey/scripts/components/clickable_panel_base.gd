class_name ClickablePanelBase
extends PanelContainer
## Base class for PanelContainers with hover/click interaction.
## Provides consistent mouse interaction across components.
## Uses InteractiveScale for scale animations.
##
## Usage:
##   1. Extend this class
##   2. Call setup_styles() with your style dictionary
##   3. Override _handle_click() to handle click events
##   4. Override _on_ready() for additional initialization

const InteractiveScaleClass = preload("res://scripts/effects/interactive_scale.gd")

signal panel_clicked(data: Variant)

var _styles: Dictionary = {}
var _is_hovered: bool = false
var _is_pressed: bool = false
var _click_data: Variant = null
var clickable: bool = true

# Animation settings
var enable_scale_animation: bool = true
var hover_scale: float = 1.0  # No scale on hover (prevents container clipping)
var press_scale: float = 0.96  # Subtle press feedback
var _scaler = null  # InteractiveScale instance


func _ready() -> void:
	_scaler = InteractiveScaleClass.new(self, hover_scale, press_scale)
	if clickable:
		_setup_mouse_interaction()
	_on_ready()


func _on_ready() -> void:
	## Override in subclass for additional initialization
	pass


func _setup_mouse_interaction() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup_styles(styles: Dictionary, click_data: Variant = null) -> void:
	_styles = styles
	_click_data = click_data
	_apply_state_style()


func _on_mouse_entered() -> void:
	if not clickable:
		return
	_is_hovered = true
	_apply_state_style()
	if enable_scale_animation:
		_scaler.hover()


func _on_mouse_exited() -> void:
	_is_hovered = false
	_is_pressed = false
	_apply_state_style()
	if enable_scale_animation:
		_scaler.unhover()


func _apply_state_style() -> void:
	if _styles.is_empty() or not clickable:
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


func _on_gui_input(event: InputEvent) -> void:
	if not clickable:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
				_apply_state_style()
				if enable_scale_animation:
					_scaler.press()
			else:
				if _is_pressed and _is_hovered:
					_handle_click()
				_is_pressed = false
				_apply_state_style()
				if enable_scale_animation:
					_scaler.release(_is_hovered)


func _handle_click() -> void:
	## Override in subclass to customize click behavior.
	## Default emits panel_clicked signal with _click_data.
	panel_clicked.emit(_click_data)


func set_clickable(enabled: bool) -> void:
	clickable = enabled
	mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE

	if enabled and not mouse_entered.is_connected(_on_mouse_entered):
		_setup_mouse_interaction()
	elif not enabled:
		if mouse_entered.is_connected(_on_mouse_entered):
			mouse_entered.disconnect(_on_mouse_entered)
			mouse_exited.disconnect(_on_mouse_exited)
			gui_input.disconnect(_on_gui_input)

	_apply_state_style()
