class_name CompactableIconBase
extends PanelContainer
## Base class for icon panels that support compact mode.
## Provides consistent compact/normal mode switching across components.
##
## Usage:
##   1. Extend this class
##   2. Set _icon and _label references in _on_ready()
##   3. Override size getter methods
##   4. Optionally override _get_normal_separation()

## Child node references - set by subclass in _on_ready()
var margin_container: MarginContainer
var vbox: VBoxContainer
var _icon: TextureRect
var _label: Label

var is_compact: bool = false


func _ready() -> void:
	_on_ready()
	# Allow parent to receive hover events by making display children transparent to mouse
	UIHelpers.set_children_mouse_filter_ignore(self)


func _on_ready() -> void:
	## Override in subclass to set node references and perform initialization
	pass


func set_compact(enabled: bool) -> void:
	"""
	Enable or disable compact mode.
	Compact mode hides the label and reduces margins/sizes.

	Args:
		enabled: Whether to enable compact mode
	"""
	is_compact = enabled

	if enabled:
		# Compact: hide label, reduce margins
		custom_minimum_size = _get_compact_size()

		margin_container.add_theme_constant_override("margin_left", 2)
		margin_container.add_theme_constant_override("margin_top", 2)
		margin_container.add_theme_constant_override("margin_right", 2)
		margin_container.add_theme_constant_override("margin_bottom", 2)

		var icon_size = _get_compact_icon_size()
		_icon.custom_minimum_size = Vector2(icon_size, icon_size)
		_label.visible = false
		vbox.add_theme_constant_override("separation", 0)
	else:
		# Normal: show label, normal margins
		custom_minimum_size = _get_normal_size()

		margin_container.add_theme_constant_override("margin_left", 4)
		margin_container.add_theme_constant_override("margin_top", 4)
		margin_container.add_theme_constant_override("margin_right", 4)
		margin_container.add_theme_constant_override("margin_bottom", 4)

		var icon_size = _get_normal_icon_size()
		_icon.custom_minimum_size = Vector2(icon_size, icon_size)
		_label.visible = true
		vbox.add_theme_constant_override("separation", _get_normal_separation())

	# Apply fantasy panel styling
	UIStyles.apply_panel_style(self, UIStyles.create_subtle_panel())


func _get_compact_size() -> Vector2:
	## Override in subclass to return panel size in compact mode
	return Vector2.ZERO


func _get_normal_size() -> Vector2:
	## Override in subclass to return panel size in normal mode
	return Vector2.ZERO


func _get_compact_icon_size() -> float:
	## Override in subclass to return icon size in compact mode
	return 0.0


func _get_normal_icon_size() -> float:
	## Override in subclass to return icon size in normal mode
	return 0.0


func _get_normal_separation() -> int:
	## Override in subclass to return vbox separation in normal mode.
	## Default is 4.
	return 4
