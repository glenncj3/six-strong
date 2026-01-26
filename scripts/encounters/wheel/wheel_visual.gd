class_name WheelVisual
extends Control
## Visual component for the Wheel of Fortune.
## Handles rendering, animation, and segment display.
## Separated from business logic (WheelController).


## Emitted when wheel passes a segment during spin (for audio tick)
signal segment_passed(index: int)

## Emitted when spin animation completes
signal spin_complete(winning_index: int)

## Emitted when result display animation completes
signal result_shown()


## Reference to wheel sprite that rotates
var wheel_sprite: TextureRect

## Container that holds the wheel sprite
var wheel_container: Control

## Segment labels displayed on the wheel
var segment_labels: Array = []  # Array[Label]

## Pointer indicator at top
var pointer: Control

## Result display panel
var result_display: Control

## Current rotation angle in degrees
var current_angle: float = 0.0

## Target angle for landing
var target_angle: float = 0.0

## Is wheel currently spinning
var is_spinning: bool = false

## Tween for wheel animation
var spin_tween: Tween

## Last segment that was under the pointer
var last_segment_index: int = -1

## Segment data for display
var segments: Array = []  # Array[RewardDefinition]

## Segment colors for drawing
const SEGMENT_COLORS := [
	Color("#D9A621"),  # Gold
	Color("#2A7A4A"),  # Emerald
	Color("#6A3A8A"),  # Purple
	Color("#4A6AAA"),  # Blue
	Color("#8A2A3A"),  # Ruby
	Color("#5A4A3A"),  # Brown
]

## Icons for reward types (emoji)
const REWARD_TYPE_ICONS := {
	RewardTypes.RewardType.GOLD: "💰",
	RewardTypes.RewardType.HEALTH: "❤️",
	RewardTypes.RewardType.XP: "⭐",
	RewardTypes.RewardType.ITEM: "⚔️",
	RewardTypes.RewardType.SKILL: "📜",
	RewardTypes.RewardType.ITEM_RANDOM: "🎁",
	RewardTypes.RewardType.SKILL_RANDOM: "✨"
}


func _init() -> void:
	# Set up anchors for center positioning
	set_anchors_preset(Control.PRESET_CENTER)


func _ready() -> void:
	_build_wheel_ui()
	# If segments were set before ready, update labels now
	if segments.size() > 0:
		_update_segment_labels()


func _build_wheel_ui() -> void:
	# Main container
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Wheel area - use Control (not CenterContainer) so we can position children manually
	var wheel_area = Control.new()
	var area_width = GameConstants.WHEEL_SIZE + 40
	var area_height = GameConstants.WHEEL_SIZE + 50  # Extra space for pointer at top
	wheel_area.custom_minimum_size = Vector2(area_width, area_height)
	wheel_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(wheel_area)

	# Pointer at top center (ABOVE the wheel, pointing down)
	pointer = _create_pointer()
	pointer.position = Vector2(area_width / 2.0 - 15, 0)  # Centered at top
	wheel_area.add_child(pointer)

	# Wheel container (for rotation) - centered below pointer
	wheel_container = Control.new()
	wheel_container.custom_minimum_size = Vector2(GameConstants.WHEEL_SIZE, GameConstants.WHEEL_SIZE)
	wheel_container.position = Vector2((area_width - GameConstants.WHEEL_SIZE) / 2.0, 45)  # Below pointer
	wheel_container.pivot_offset = Vector2(GameConstants.WHEEL_SIZE / 2.0, GameConstants.WHEEL_SIZE / 2.0)
	wheel_area.add_child(wheel_container)

	# Wheel background (drawn segments)
	var wheel_bg = _create_wheel_background()
	wheel_container.add_child(wheel_bg)

	# Create segment labels on top of wheel
	_create_segment_labels()

	# Center hub decoration (centered in wheel_container)
	var hub = _create_center_hub()
	wheel_container.add_child(hub)

	# Result display (below wheel)
	result_display = _create_result_display()
	result_display.visible = false
	main_vbox.add_child(result_display)


func _create_wheel_background() -> Control:
	var bg = Control.new()
	bg.custom_minimum_size = Vector2(GameConstants.WHEEL_SIZE, GameConstants.WHEEL_SIZE)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Use custom draw for wheel segments
	bg.draw.connect(_draw_wheel_segments.bind(bg))

	return bg


func _draw_wheel_segments(canvas: Control) -> void:
	var center = Vector2(GameConstants.WHEEL_SIZE / 2.0, GameConstants.WHEEL_SIZE / 2.0)
	var radius = GameConstants.WHEEL_SIZE / 2.0 - 5
	var segment_angle = 360.0 / GameConstants.WHEEL_SEGMENT_COUNT

	# Draw each segment
	for i in range(GameConstants.WHEEL_SEGMENT_COUNT):
		var start_angle = deg_to_rad(i * segment_angle - 90)  # Start from top
		var end_angle = deg_to_rad((i + 1) * segment_angle - 90)

		# Get color for segment
		var color: Color
		if i < segments.size():
			color = segments[i].get_color()
		else:
			color = SEGMENT_COLORS[i % SEGMENT_COLORS.size()]

		# Draw segment as polygon
		var points = PackedVector2Array()
		points.append(center)

		var steps = 20
		for j in range(steps + 1):
			var angle = start_angle + (end_angle - start_angle) * (j / float(steps))
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)

		canvas.draw_colored_polygon(points, color)

		# Draw segment border
		var border_color = GameConstants.COLOR_BORDER_GOLD
		canvas.draw_arc(center, radius, start_angle, end_angle, 20, border_color, 3.0)

		# Draw divider line
		var divider_end = center + Vector2(cos(start_angle), sin(start_angle)) * radius
		canvas.draw_line(center, divider_end, border_color, 2.0)

	# Draw outer border
	canvas.draw_arc(center, radius, 0, TAU, 64, GameConstants.COLOR_BORDER_GOLD, 4.0)


func _create_segment_labels() -> void:
	var center = Vector2(GameConstants.WHEEL_SIZE / 2.0, GameConstants.WHEEL_SIZE / 2.0)
	var icon_radius = GameConstants.WHEEL_SIZE / 2.0 - 60  # Offset from edge
	var segment_angle = 360.0 / GameConstants.WHEEL_SEGMENT_COUNT

	for i in range(GameConstants.WHEEL_SEGMENT_COUNT):
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)  # Larger for icons
		label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

		# Position icon at center of segment
		var angle = deg_to_rad((i + 0.5) * segment_angle - 90)
		var pos = center + Vector2(cos(angle), sin(angle)) * icon_radius
		label.position = pos - Vector2(20, 20)  # Center the icon
		label.custom_minimum_size = Vector2(40, 40)

		wheel_container.add_child(label)
		segment_labels.append(label)


func _create_center_hub() -> Control:
	var hub = Control.new()
	var hub_size = 50
	hub.custom_minimum_size = Vector2(hub_size, hub_size)
	# Center in the wheel
	hub.position = Vector2(
		(GameConstants.WHEEL_SIZE - hub_size) / 2.0,
		(GameConstants.WHEEL_SIZE - hub_size) / 2.0
	)

	# Custom draw for hub
	hub.draw.connect(func():
		var center_pt = Vector2(hub_size / 2.0, hub_size / 2.0)
		hub.draw_circle(center_pt, 25, GameConstants.COLOR_PANEL_DARK)
		hub.draw_arc(center_pt, 25, 0, TAU, 32, GameConstants.COLOR_BORDER_GOLD, 3.0)
		hub.draw_circle(center_pt, 8, GameConstants.COLOR_GOLD)
	)

	return hub


func _create_pointer() -> Control:
	# Create a simple triangle pointer pointing down
	var ptr = Control.new()
	ptr.custom_minimum_size = Vector2(30, 40)
	# Position is set in _build_wheel_ui

	ptr.draw.connect(func():
		var points = PackedVector2Array([
			Vector2(15, 40),  # Bottom center (points down)
			Vector2(0, 0),    # Top left
			Vector2(30, 0)    # Top right
		])
		ptr.draw_colored_polygon(points, GameConstants.COLOR_GOLD)
		ptr.draw_polyline(points, GameConstants.COLOR_BORDER_GOLD, 2.0)
	)

	return ptr


func _create_result_display() -> Control:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 8)

	var label = Label.new()
	label.name = "ResultLabel"
	label.theme_type_variation = "HeaderLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_REWARD)
	label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(label)

	return container


## Set up the wheel with segment data
func setup(p_segments: Array) -> void:
	segments = p_segments

	# If UI is already built, update it now
	if segment_labels.size() > 0:
		_update_segment_labels()


## Update segment labels with current segment data (icons only)
func _update_segment_labels() -> void:
	for i in range(mini(segments.size(), segment_labels.size())):
		var reward: RewardDefinition = segments[i]
		var label: Label = segment_labels[i]
		# Use icon only, no text
		label.text = REWARD_TYPE_ICONS.get(reward.type, "🎲")

	# Redraw wheel
	if wheel_container and wheel_container.get_child_count() > 0:
		wheel_container.get_child(0).queue_redraw()


## Start the spinning animation
## Returns the target segment index
func start_spin(winning_index: int) -> void:
	if is_spinning:
		return

	is_spinning = true
	result_display.visible = false

	# Calculate target angle
	# Segment 0 is at top (angle 0), segments go clockwise
	var segment_angle = 360.0 / GameConstants.WHEEL_SEGMENT_COUNT
	# Target: land somewhere within the winning segment (0.2 to 0.8 to avoid edges)
	var offset_in_segment = randf_range(0.25, 0.75)
	var target_segment_angle = (winning_index + offset_in_segment) * segment_angle

	# Add multiple full rotations for dramatic effect
	var full_rotations = randi_range(3, 5) * 360.0
	target_angle = current_angle + full_rotations + (360.0 - target_segment_angle) - fmod(current_angle, 360.0)

	# Ensure we always spin forward
	if target_angle <= current_angle:
		target_angle += 360.0

	_animate_spin()


func _animate_spin() -> void:
	if spin_tween:
		spin_tween.kill()

	spin_tween = create_tween()

	# Phase 1: Spin up to max speed
	var spinup_target = current_angle + GameConstants.WHEEL_MAX_SPEED * GameConstants.WHEEL_SPINUP_DURATION
	spin_tween.tween_property(self, "current_angle", spinup_target, GameConstants.WHEEL_SPINUP_DURATION)
	spin_tween.set_ease(Tween.EASE_OUT)
	spin_tween.set_trans(Tween.TRANS_CUBIC)

	# Phase 2: Full speed
	var full_speed_duration = GameConstants.WHEEL_SPIN_DURATION - GameConstants.WHEEL_SPINUP_DURATION - GameConstants.WHEEL_DECEL_DURATION
	var full_speed_target = spinup_target + GameConstants.WHEEL_MAX_SPEED * full_speed_duration
	spin_tween.tween_property(self, "current_angle", full_speed_target, full_speed_duration)
	spin_tween.set_trans(Tween.TRANS_LINEAR)

	# Phase 3: Deceleration to target
	spin_tween.tween_property(self, "current_angle", target_angle + GameConstants.WHEEL_BOUNCE_OVERSHOOT, GameConstants.WHEEL_DECEL_DURATION)
	spin_tween.set_ease(Tween.EASE_OUT)
	spin_tween.set_trans(Tween.TRANS_QUAD)

	# Phase 4: Bounce back
	spin_tween.tween_property(self, "current_angle", target_angle, GameConstants.WHEEL_BOUNCE_DURATION)
	spin_tween.set_ease(Tween.EASE_OUT)
	spin_tween.set_trans(Tween.TRANS_BACK)

	# On complete
	spin_tween.tween_callback(_on_spin_complete)


func _on_spin_complete() -> void:
	is_spinning = false
	var winning_idx = _get_segment_at_pointer()
	spin_complete.emit(winning_idx)


## Called every frame to update wheel rotation
func _process(_delta: float) -> void:
	if wheel_container:
		wheel_container.rotation_degrees = current_angle

	# Track segment changes for tick sound
	if is_spinning:
		var current_segment = _get_segment_at_pointer()
		if current_segment != last_segment_index:
			last_segment_index = current_segment
			segment_passed.emit(current_segment)


## Get which segment is currently at the pointer (top)
func _get_segment_at_pointer() -> int:
	var segment_angle = 360.0 / GameConstants.WHEEL_SEGMENT_COUNT
	# Normalize angle to 0-360
	var normalized = fmod(current_angle, 360.0)
	if normalized < 0:
		normalized += 360.0
	# Convert to segment index
	var index = int((360.0 - normalized) / segment_angle) % GameConstants.WHEEL_SEGMENT_COUNT
	return index


## Show the winning result with animation
func show_result(reward: RewardDefinition) -> void:
	var label: Label = result_display.get_node("ResultLabel")
	label.text = "You won: %s!" % reward.get_label()

	result_display.visible = true
	result_display.modulate.a = 0

	# Fade in animation
	var tween = create_tween()
	tween.tween_property(result_display, "modulate:a", 1.0, 0.3)
	tween.set_ease(Tween.EASE_OUT)

	# Scale pop on winning segment label
	if last_segment_index >= 0 and last_segment_index < segment_labels.size():
		var winning_label: Label = segment_labels[last_segment_index]
		winning_label.pivot_offset = winning_label.size / 2.0
		var label_tween = create_tween()
		label_tween.tween_property(winning_label, "scale", Vector2(1.3, 1.3), 0.15)
		label_tween.set_ease(Tween.EASE_OUT)
		label_tween.set_trans(Tween.TRANS_BACK)
		label_tween.tween_property(winning_label, "scale", Vector2(1.0, 1.0), 0.15)

	# Emit after animation
	tween.tween_callback(func(): result_shown.emit())


## Flash the winning segment
func flash_winning_segment(index: int) -> void:
	if index < 0 or index >= segment_labels.size():
		return

	var label: Label = segment_labels[index]
	var original_color = label.get_theme_color("font_color")

	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(label, "theme_override_colors/font_color", Color.WHITE, 0.1)
	tween.tween_property(label, "theme_override_colors/font_color", original_color, 0.1)


## Reset visual state for new spin
func reset() -> void:
	result_display.visible = false
	last_segment_index = -1

	# Reset segment label scales
	for label in segment_labels:
		label.scale = Vector2.ONE
