class_name UIHelpers
extends RefCounted
# UIHelpers - Common UI utility functions
# Eliminates repeated patterns across UI code

# =============================================================================
# CONTAINER MANAGEMENT
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
	label.modulate = color
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
# LOADING HELPERS
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
		push_warning("UIHelpers: Texture not found: %s" % path)
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


# =============================================================================
# FORMATTING HELPERS
# =============================================================================

static func format_currency(amount: int, symbol: String = "") -> String:
	"""
	Format a currency amount for display.

	Args:
		amount: The amount to format
		symbol: Optional symbol prefix (e.g., "💎")

	Returns:
		Formatted string
	"""
	if symbol.is_empty():
		return str(amount)
	return "%s %d" % [symbol, amount]


static func format_stat(stat_name: String, value: int) -> String:
	"""
	Format a stat for compact display.

	Args:
		stat_name: Full stat name
		value: Stat value

	Returns:
		Formatted string (e.g., "HP 100")
	"""
	var short_names = {
		GameConstants.STAT_HEALTH: "HP",
		GameConstants.STAT_ATTACK: "ATK",
		GameConstants.STAT_DEFENSE: "DEF",
		GameConstants.STAT_SPEED: "SPD",
		GameConstants.STAT_INCOME: "INC"
	}
	var short = short_names.get(stat_name, stat_name.to_upper().left(3))
	return "%s %d" % [short, value]
