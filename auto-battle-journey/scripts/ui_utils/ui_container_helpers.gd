class_name UIContainerHelpers
extends RefCounted
## Container management utilities for UI.
## Handles child control manipulation, mouse filter propagation, and placeholder elements.


# =============================================================================
# MOUSE FILTER PROPAGATION
# =============================================================================

static func set_children_mouse_filter_ignore(parent: Control, recursive: bool = true) -> void:
	"""
	Set all child Control nodes to MOUSE_FILTER_IGNORE.
	Use this to allow parent panels to receive hover events.

	In Godot 4.x, all child Control nodes default to MOUSE_FILTER_STOP,
	which blocks mouse events from reaching the parent PanelContainer.
	This function sets all children (containers AND leaves) to IGNORE
	so hover/click events propagate properly.

	Args:
		parent: The parent Control whose children should be modified
		recursive: If true, also process children of children (default: true)
	"""
	for child in parent.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if recursive:
				set_children_mouse_filter_ignore(child, true)


# =============================================================================
# CONTAINER CREATION
# =============================================================================

static func create_vbox_container(separation: int = GameConstants.CONTENT_SEPARATION, full_rect: bool = true) -> VBoxContainer:
	"""
	Create a configured VBoxContainer with standard settings.

	Args:
		separation: Vertical separation between children (default: CONTENT_SEPARATION)
		full_rect: Whether to set PRESET_FULL_RECT anchor (default: true)

	Returns:
		Configured VBoxContainer
	"""
	var vbox = VBoxContainer.new()
	if full_rect:
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", separation)
	return vbox


static func create_hbox_container(separation: int = GameConstants.CONTENT_SEPARATION, alignment: BoxContainer.AlignmentMode = BoxContainer.ALIGNMENT_CENTER) -> HBoxContainer:
	"""Create a configured HBoxContainer with standard settings."""
	var hbox = HBoxContainer.new()
	hbox.alignment = alignment
	hbox.add_theme_constant_override("separation", separation)
	return hbox


static func create_spacer(height: int = 20) -> Control:
	"""
	Create a vertical spacer control.

	Args:
		height: Minimum height of the spacer (default: 20)

	Returns:
		Control configured as a spacer
	"""
	var spacer = Control.new()
	spacer.custom_minimum_size.y = height
	return spacer


static func create_label(
	text: String,
	font_size: int = GameConstants.FONT_SIZE_BODY,
	color: Color = Color.WHITE,
	centered: bool = false
) -> Label:
	"""
	Create a configured label with common settings.

	Args:
		text: Label text
		font_size: Font size override (default: FONT_SIZE_BODY)
		color: Text color via modulate (default: white)
		centered: Whether to center the text horizontally (default: false)

	Returns:
		Configured Label node
	"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


# =============================================================================
# CHILD MANAGEMENT
# =============================================================================

static func clear_children(container: Node) -> void:
	"""
	Remove and free all children from a container.
	Safer than manual iteration as it handles edge cases.

	Args:
		container: The parent node to clear
	"""
	for child in container.get_children():
		child.queue_free()


static func clear_children_immediate(container: Node) -> void:
	"""
	Remove and free all children immediately (use with caution).
	Use when you need children gone before next frame.

	Args:
		container: The parent node to clear
	"""
	for child in container.get_children():
		container.remove_child(child)
		child.free()


static func get_child_count_of_type(container: Node, type: Variant) -> int:
	"""
	Count children of a specific type.

	Args:
		container: Parent node to search
		type: The class/type to filter by

	Returns:
		Number of matching children
	"""
	var count = 0
	for child in container.get_children():
		if is_instance_of(child, type):
			count += 1
	return count


# =============================================================================
# PLACEHOLDER UI ELEMENTS
# =============================================================================

static func create_empty_placeholder(text: String, color: Color = Color(0.7, 0.7, 0.7)) -> Label:
	"""
	Create a placeholder label for empty states.

	Args:
		text: Text to display (e.g., "No items equipped")
		color: Text color (default gray)

	Returns:
		Configured Label node
	"""
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label


static func add_empty_placeholder(container: Node, text: String) -> void:
	"""
	Add a placeholder label to a container if it's empty.

	Args:
		container: Container to check and potentially add to
		text: Placeholder text if empty
	"""
	if container.get_child_count() == 0:
		var placeholder = create_empty_placeholder(text)
		container.add_child(placeholder)


# =============================================================================
# TEXTURE LOADING
# =============================================================================

static func load_texture_safe(path: String) -> Texture2D:
	"""
	Safely load a texture, returning null if not found.

	Args:
		path: Resource path to texture

	Returns:
		Loaded texture or null
	"""
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("UIContainerHelpers: Texture not found: %s" % path)
		return null
	return load(path)


static func set_texture_safe(texture_rect: TextureRect, path: String) -> bool:
	"""
	Safely set a TextureRect's texture from a path.

	Args:
		texture_rect: The TextureRect to update
		path: Resource path to texture

	Returns:
		true if texture was set successfully
	"""
	var texture = load_texture_safe(path)
	if texture != null:
		texture_rect.texture = texture
		return true
	return false


# =============================================================================
# BUTTON HELPERS
# =============================================================================

static func set_button_enabled(button: Button, enabled: bool, disabled_text: String = "") -> void:
	"""
	Enable/disable a button with optional text change.

	Args:
		button: Button to modify
		enabled: Whether button should be enabled
		disabled_text: Optional text to show when disabled (empty = keep current)
	"""
	button.disabled = not enabled
	if not enabled and not disabled_text.is_empty():
		button.text = disabled_text


static func create_button(
	text: String,
	callback: Callable = Callable(),
	width: int = GameConstants.BUTTON_WIDTH_STANDARD,
	height: int = GameConstants.BUTTON_HEIGHT_STANDARD
) -> Button:
	"""
	Create a styled button with optional press callback.

	Args:
		text: Button label text
		callback: Optional callable to connect to pressed signal
		width: Minimum button width (default: BUTTON_WIDTH_STANDARD)
		height: Minimum button height (default: BUTTON_HEIGHT_STANDARD)

	Returns:
		Configured Button node
	"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, height)
	UIStyles.setup_button(button)
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


static func disable_all_buttons(container: Control) -> void:
	"""Recursively disable all Button children in a container."""
	for child in container.get_children():
		if child is Button:
			child.disabled = true
		elif child.get_child_count() > 0:
			disable_all_buttons(child)
