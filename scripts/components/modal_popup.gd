class_name ModalPopup
extends PanelContainer
## Base class for modal popup windows.
## Handles overlay creation, reparenting, input blocking, and cleanup.
##
## Usage:
##   1. Create a scene that extends ModalPopup
##   2. Call show_modal() to display as overlay
##   3. Call hide_modal() to close and clean up
##
## The popup will:
##   - Create a dimming overlay behind itself
##   - Reparent to scene root for guaranteed top positioning
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

	var scene_root = get_tree().current_scene
	if not scene_root:
		push_error("ModalPopup: No current scene found")
		return

	# Create dimming overlay
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.5)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_root.add_child(_overlay)

	# Reparent popup to scene root
	reparent(scene_root)

	# Center the popup
	_center_popup()

	visible = true
	move_to_front()
	popup_opened.emit()


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
	var half_width = size.x / 2 if size.x > 0 else 150
	var half_height = size.y / 2 if size.y > 0 else 150
	offset_left = -half_width
	offset_top = -half_height
	offset_right = half_width
	offset_bottom = half_height


func _cleanup_overlay() -> void:
	"""Remove overlay if it exists."""
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
		_overlay = null
