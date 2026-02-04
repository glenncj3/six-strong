class_name ModalPopup
extends PanelContainer
## Base class for modal popup windows.
## Handles overlay creation, reparenting to ModalLayer, input blocking, and cleanup.
##
## Usage:
##   1. Create a scene that extends ModalPopup
##   2. Call show_modal() to display as overlay
##   3. Call hide_modal() to close and clean up
##
## The popup will:
##   - Reparent to ModalLayer (CanvasLayer 200) for guaranteed top positioning
##   - Create a dimming overlay behind itself
##   - Block input behind the overlay
##   - Restore to original parent when hidden

signal popup_opened
signal popup_closed

var _overlay: ColorRect = null
var _original_parent: Node = null


func _ready() -> void:
	visible = false


func _exit_tree() -> void:
	_cleanup_overlay()


func show_modal() -> void:
	"""Show the popup as a modal overlay on top of everything."""
	_original_parent = get_parent()

	# Find ModalLayer (CanvasLayer at layer 200) for guaranteed top rendering
	var modal_layer = _find_modal_layer()
	if not modal_layer:
		push_error("ModalPopup: ModalLayer not found, falling back to scene root")
		modal_layer = get_tree().current_scene
		if not modal_layer:
			push_error("ModalPopup: No scene root found either")
			return

	# Create dimming overlay
	_overlay = ColorRect.new()
	_overlay.color = GameConstants.COLOR_OVERLAY_DIM
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.add_child(_overlay)

	# Reparent popup to modal layer
	reparent(modal_layer)

	# Center the popup
	_center_popup()

	visible = true
	move_to_front()
	popup_opened.emit()


func _find_modal_layer() -> Node:
	"""Find the ModalLayer CanvasLayer in the scene tree."""
	var root = get_tree().root
	if not root:
		return null

	# Look for ModalLayer in Main scene
	var main = root.get_node_or_null("Main")
	if main:
		var modal_layer = main.get_node_or_null("ModalLayer")
		if modal_layer:
			return modal_layer

	# Fallback: search for any node named ModalLayer
	return _find_node_by_name(root, "ModalLayer")


func _find_node_by_name(parent: Node, name_to_find: String) -> Node:
	"""Recursively search for a node by name."""
	for child in parent.get_children():
		if child.name == name_to_find:
			return child
		var found = _find_node_by_name(child, name_to_find)
		if found:
			return found
	return null


func hide_modal() -> void:
	"""Hide the popup and clean up."""
	visible = false
	_cleanup_overlay()

	# Restore to original parent
	if _original_parent and is_instance_valid(_original_parent):
		reparent(_original_parent)
		_original_parent = null

	popup_closed.emit()


func _center_popup() -> void:
	"""Center popup on screen. Override for custom positioning."""
	set_anchors_preset(Control.PRESET_CENTER)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	# Use current size for offsets
	var half_width: float = size.x / 2.0 if size.x > 0 else GameConstants.MODAL_FALLBACK_HALF_SIZE
	var half_height: float = size.y / 2.0 if size.y > 0 else GameConstants.MODAL_FALLBACK_HALF_SIZE
	offset_left = -half_width
	offset_top = -half_height
	offset_right = half_width
	offset_bottom = half_height


func _cleanup_overlay() -> void:
	"""Remove overlay if it exists."""
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
		_overlay = null
