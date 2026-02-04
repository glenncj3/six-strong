extends ClickablePanelBase
class_name CharacterTile
## A character display tile that can be used standalone or as a grid slot.
## Can display a character or be empty (placeholder).
## Supports grid positioning and drag-and-drop for character repositioning.

signal slot_clicked(row: int, col: int, character: CharacterInstance)
signal tile_clicked_data(char_data: Dictionary)
signal drag_started(row: int, col: int, character: CharacterInstance)
@warning_ignore("unused_signal")  # Reserved for future use
signal drop_received(row: int, col: int, from_row: int, from_col: int)

const SLOT_BORDER_WIDTH := 3
const STAT_ICON_SIZE := 48
const STAT_FONT_SIZE := 28
const NAME_FONT_SIZE := 20
const NAME_MARGIN_BOTTOM := 55
const HP_BAR_HEIGHT := 6
const TOP_STATS_CORNER_MARGIN := 8

const TOP_STATS_LEFT := [
	{"key": "damage", "icon": "res://assets/sprites/icons/icon_damage.Png"},
	{"key": "burn_value", "icon": "res://assets/sprites/icons/icon_burn.Png"},
	{"key": "poison_value", "icon": "res://assets/sprites/icons/icon_poison.Png"},
]
const TOP_STATS_RIGHT := [
	{"key": "heal_value", "icon": "res://assets/sprites/icons/icon_heal.Png"},
	{"key": "shield_value", "icon": "res://assets/sprites/icons/icon_shield.Png"},
]
const BOTTOM_STATS := [
	{"key": "charges", "icon": "res://assets/sprites/icons/icon_charges.Png"},
	{"key": "multistrike_value", "icon": "res://assets/sprites/icons/icon_multistrike.Png"},
	{"key": "speed", "icon": "res://assets/sprites/icons/icon_speed.Png"},
]

@onready var content_margin: MarginContainer = $ContentMargin
@onready var portrait: TextureRect = $ContentMargin/Portrait
@onready var border_overlay: Panel = $BorderOverlay
@onready var name_margin: MarginContainer = $ContentMargin/NameMargin
@onready var name_label: Label = $ContentMargin/NameMargin/NameLabel
@onready var highlight_rect: ColorRect = $HighlightRect

var row: int = -1
var col: int = -1
var character: CharacterInstance = null
var char_data: Dictionary = {}  # For collection mode (dictionary-based)
var _is_drag_target: bool = false
var _is_valid_drop_target: bool = false
var _stat_badges: Dictionary = {}  # key -> {container, label}
var _top_stats_left_container: HBoxContainer
var _top_stats_right_container: HBoxContainer
var _bottom_stats_container: HBoxContainer
var _stats_overlay: Control
var _hp_container: Control
var _hp_bar: ColorRect
var _hp_bar_bg: ColorRect

# Long-press drag detection
const LONG_PRESS_DURATION := 0.12
var _long_press_timer: Timer
var _press_position: Vector2 = Vector2.ZERO
var _long_press_triggered: bool = false


func _init_default_styles() -> void:
	# Empty slot style
	var normal = StyleBoxFlat.new()
	normal.bg_color = GameConstants.COLOR_PANEL_DARK.darkened(0.2)
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = GameConstants.COLOR_PANEL_DARK
	var pressed = normal.duplicate()
	pressed.bg_color = GameConstants.COLOR_PANEL_DARK.darkened(0.3)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})


func _on_ready() -> void:
	UIHelpers.set_children_mouse_filter_ignore(self)
	UIStyles.set_margin_all(content_margin, SLOT_BORDER_WIDTH)
	_setup_border_overlay()
	_setup_highlight()
	_build_stat_containers()
	_build_health_bar()
	_clear_display()
	_setup_long_press_timer()


func _setup_long_press_timer() -> void:
	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = LONG_PRESS_DURATION
	_long_press_timer.timeout.connect(_on_long_press_timeout)
	add_child(_long_press_timer)


func _on_long_press_timeout() -> void:
	if character == null:
		return
	_long_press_triggered = true
	drag_started.emit(row, col, character)


func _setup_border_overlay() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(SLOT_BORDER_WIDTH)
	style.border_color = GameConstants.COLOR_BORDER_GOLD.darkened(0.3)
	style.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	border_overlay.add_theme_stylebox_override("panel", style)


func _setup_highlight() -> void:
	highlight_rect.visible = false
	highlight_rect.color = Color(0.3, 0.8, 0.3, 0.3)


func _on_gui_input(event: InputEvent) -> void:
	if not clickable:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			_long_press_triggered = false
			_press_position = event.global_position
			_apply_state_style()
			if enable_scale_animation:
				_scaler.press()
			if character != null:
				_long_press_timer.start()
		else:
			_long_press_timer.stop()
			if _long_press_triggered:
				# Drag was initiated — don't fire click
				_long_press_triggered = false
			elif _is_pressed and _is_hovered:
				_handle_click()
			_is_pressed = false
			_apply_state_style()
			if enable_scale_animation:
				_scaler.release(_is_hovered)

	elif event is InputEventMouseMotion and _is_pressed:
		# Cancel long-press if finger moves too far
		if _press_position.distance_to(event.global_position) > 15:
			_long_press_timer.stop()


func _handle_click() -> void:
	if not char_data.is_empty():
		tile_clicked_data.emit(char_data)
	slot_clicked.emit(row, col, character)
	_open_inspect_popup()


func _open_inspect_popup() -> void:
	if character == null and char_data.is_empty():
		return
	var popup = load("res://scenes/components/character_inspect_popup.tscn").instantiate()
	add_child(popup)
	if character != null:
		popup.show_character(character)
	else:
		popup.show_character_data(char_data)


# =============================================================================
# SETUP
# =============================================================================

func setup_slot(slot_row: int, slot_col: int, slot_size: Vector2) -> void:
	"""Configure the slot's position and size."""
	row = slot_row
	col = slot_col
	custom_minimum_size = slot_size


func setup(character_instance: CharacterInstance, tile_size: float) -> void:
	"""Configure as a standalone tile with a character instance."""
	character = character_instance
	char_data = {}
	custom_minimum_size = Vector2(tile_size, tile_size)

	if character == null:
		_clear_display()
		return

	var char_master = GameData.get_character_by_id(character.base_character_id)
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % character.base_character_id)
		_clear_display()
		return

	_apply_character_display(char_master)
	name_label.text = character.get_character_name()


func setup_from_data(character_data: Dictionary, tile_size: float) -> void:
	"""Configure with character dictionary data (for Collection)."""
	char_data = character_data
	character = null
	custom_minimum_size = Vector2(tile_size, tile_size)

	var char_id = char_data.get("id", "")
	var char_master = GameData.get_character_by_id(char_id)
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % char_id)
		_clear_display()
		return

	_apply_character_display(char_master)
	name_label.text = char_master.get("name", "Unknown")


func set_character(char_instance: CharacterInstance) -> void:
	"""Set a character to display in this slot."""
	character = char_instance

	if character == null:
		_clear_display()
		return

	# Get character data
	var char_master = GameData.get_character_by_id(character.base_character_id)
	if char_master.is_empty():
		push_error("CharacterTile: Character master data not found: %s" % character.base_character_id)
		_clear_display()
		return

	_apply_character_display(char_master)
	name_label.text = char_master.get("name", "?")


func _apply_character_display(char_master: Dictionary) -> void:
	"""Apply character visuals from master data."""
	# Try to load image, fall back to display_color
	var image_path = char_master.get("image_path", "")
	var image_loaded = false
	if not image_path.is_empty():
		image_loaded = UIHelpers.set_texture_safe(portrait, image_path)

	portrait.visible = image_loaded
	name_label.visible = true

	# Update stat icons — prefer live character stats over static master data
	var display_stats: Dictionary
	if character != null:
		display_stats = character.stats.duplicate()
	else:
		display_stats = char_master.get("base_stats", {})
	_update_stat_icons(display_stats)

	# Update health bar
	if character != null:
		update_health_bar(character.current_health, character.max_health)
	else:
		var base_stats = char_master.get("base_stats", {})
		var hp = int(base_stats.get("health", 0))
		update_health_bar(hp, hp)

	# Update border to gold
	_set_border_color(GameConstants.COLOR_BORDER_GOLD)

	# Determine background color
	var bg_color = GameConstants.COLOR_PANEL_DARK
	if not image_loaded:
		var display_color_str = char_master.get("display_color", "")
		if not display_color_str.is_empty():
			bg_color = Color(display_color_str)

	# Update styles for occupied slot
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = bg_color.lightened(0.15)
	var pressed = normal.duplicate()
	pressed.bg_color = bg_color.darkened(0.1)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})


func _build_stat_containers() -> void:
	# Use a plain Control overlay so PanelContainer doesn't manage layout
	_stats_overlay = Control.new()
	_stats_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_stats_overlay)

	var half_icon = STAT_ICON_SIZE / 2.0

	# Top left stats (damage, burn, poison) - left justified
	_top_stats_left_container = _create_stat_row(TOP_STATS_LEFT)
	_top_stats_left_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_top_stats_left_container.position.x = TOP_STATS_CORNER_MARGIN
	_top_stats_left_container.position.y = -half_icon + SLOT_BORDER_WIDTH
	_stats_overlay.add_child(_top_stats_left_container)

	# Top right stats (heal, shield) - right justified
	_top_stats_right_container = _create_stat_row(TOP_STATS_RIGHT)
	_top_stats_right_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_top_stats_right_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_top_stats_right_container.position.x = -TOP_STATS_CORNER_MARGIN
	_top_stats_right_container.position.y = -half_icon + SLOT_BORDER_WIDTH
	_stats_overlay.add_child(_top_stats_right_container)

	_bottom_stats_container = _create_stat_row(BOTTOM_STATS)
	_bottom_stats_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bottom_stats_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bottom_stats_container.position.y = -30
	_stats_overlay.add_child(_bottom_stats_container)


func _build_health_bar() -> void:
	_hp_container = Control.new()
	_hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_container.anchor_left = 0.1
	_hp_container.anchor_right = 0.9
	_hp_container.anchor_top = 1.0
	_hp_container.anchor_bottom = 1.0
	var hp_bottom_offset = SLOT_BORDER_WIDTH + STAT_ICON_SIZE / 2.0 + 4 + 25
	_hp_container.offset_top = -HP_BAR_HEIGHT - hp_bottom_offset
	_hp_container.offset_bottom = -hp_bottom_offset
	_hp_container.offset_left = 0
	_hp_container.offset_right = 0
	_hp_container.visible = false
	border_overlay.add_child(_hp_container)

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_bar_bg.color = Color("#222222")
	_hp_container.add_child(_hp_bar_bg)

	_hp_bar = ColorRect.new()
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_bar.color = Color("#44AA44")
	_hp_bar_bg.add_child(_hp_bar)


func update_health_bar(current: int, maximum: int) -> void:
	if not _hp_container:
		return
	if maximum <= 0:
		_hp_container.visible = false
		return
	_hp_container.visible = true
	var ratio = clampf(float(current) / float(maximum), 0.0, 1.0)
	_hp_bar.anchor_right = ratio
	# Color shifts from green to red as health drops
	if ratio > 0.5:
		_hp_bar.color = Color("#44AA44")
	elif ratio > 0.25:
		_hp_bar.color = Color("#AAAA44")
	else:
		_hp_bar.color = Color("#AA4444")


func _create_stat_row(stat_defs: Array) -> HBoxContainer:
	var stat_row = HBoxContainer.new()
	stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_row.add_theme_constant_override("separation", 2)

	for stat_def in stat_defs:
		var badge = _create_stat_badge(stat_def.key, stat_def.icon)
		stat_row.add_child(badge)
	return stat_row


func _create_stat_badge(stat_key: String, icon_path: String) -> Control:
	# Container sized to the icon
	var badge = Control.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2(STAT_ICON_SIZE, STAT_ICON_SIZE)
	badge.visible = false

	# Icon fills the badge
	var icon = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex = load(icon_path)
	if tex:
		icon.texture = tex
	badge.add_child(icon)

	# Label centered on top of icon
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = "HeaderLabel"
	label.add_theme_font_size_override("font_size", STAT_FONT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(label)

	_stat_badges[stat_key] = {"container": badge, "label": label}
	return badge


func _update_stat_icons(stats: Dictionary, keep_visible_keys: Array = []) -> void:
	for stat_key in _stat_badges:
		var val = stats.get(stat_key, 0)
		var badge_data = _stat_badges[stat_key]
		if val is float:
			val = int(val)
		badge_data.container.visible = val > 0 or stat_key in keep_visible_keys
		badge_data.label.text = str(val)


func update_stats_from_combat(combat_char: CombatCharacter) -> void:
	"""Update stat icons from a live CombatCharacter's current values."""
	var stats := {}
	stats["damage"] = int(combat_char.damage)
	stats["speed"] = int(combat_char.speed)
	stats["charges"] = combat_char.charges if combat_char.charges >= 0 else 0
	# Extra stats hold heal_value, shield_value, burn_value, poison_value, multistrike_value
	for key in combat_char.extra_stats:
		if key == "charges":
			continue  # Already set from combat_char.charges (live value)
		stats[key] = int(combat_char.extra_stats[key])
	# Keep charges icon visible at 0 if the character uses charges (not unlimited)
	var keep_visible: Array = []
	if combat_char.charges >= 0:
		keep_visible.append("charges")
	_update_stat_icons(stats, keep_visible)


func set_display_scale(scale_factor: float) -> void:
	"""Scale stat icons, stat fonts, and name label relative to defaults."""
	var scaled_icon = int(STAT_ICON_SIZE * scale_factor)
	var scaled_stat_font = int(STAT_FONT_SIZE * scale_factor)
	var scaled_name_font = int(NAME_FONT_SIZE * scale_factor)

	name_label.add_theme_font_size_override("font_size", scaled_name_font)

	for stat_key in _stat_badges:
		var badge_data = _stat_badges[stat_key]
		badge_data.container.custom_minimum_size = Vector2(scaled_icon, scaled_icon)
		badge_data.label.add_theme_font_size_override("font_size", scaled_stat_font)

	# Reposition stat rows using anchor offsets for new icon size
	var half_icon = scaled_icon / 2.0
	var scaled_corner_margin = int(TOP_STATS_CORNER_MARGIN * scale_factor)
	_top_stats_left_container.position.x = scaled_corner_margin
	_top_stats_left_container.position.y = -half_icon + SLOT_BORDER_WIDTH
	_top_stats_right_container.position.x = -scaled_corner_margin
	_top_stats_right_container.position.y = -half_icon + SLOT_BORDER_WIDTH
	_bottom_stats_container.position.y = -30 * scale_factor

	# Scale name margin bottom to keep name above bottom stats
	name_margin.add_theme_constant_override("margin_bottom", int(NAME_MARGIN_BOTTOM * scale_factor))

	# Reposition health bar above scaled bottom stats
	if _hp_container:
		var hp_h = int(HP_BAR_HEIGHT * scale_factor)
		var hp_bottom_offset = SLOT_BORDER_WIDTH + half_icon + (4 + 25) * scale_factor
		_hp_container.offset_top = -hp_h - hp_bottom_offset
		_hp_container.offset_bottom = -hp_bottom_offset


func _hide_all_stat_icons() -> void:
	for stat_key in _stat_badges:
		_stat_badges[stat_key].container.visible = false


func _clear_display() -> void:
	"""Show empty placeholder state."""
	character = null
	portrait.visible = false
	name_label.visible = false
	_hide_all_stat_icons()
	if _hp_container:
		_hp_container.visible = false

	# Update border to dim
	_set_border_color(GameConstants.COLOR_BORDER_GOLD.darkened(0.5))


func _set_border_color(color: Color) -> void:
	var style = border_overlay.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		var new_style = style.duplicate()
		new_style.border_color = color
		border_overlay.add_theme_stylebox_override("panel", new_style)


# =============================================================================
# DRAG AND DROP
# =============================================================================

func set_drag_highlight(enabled: bool, is_valid: bool = true) -> void:
	"""Show/hide drag target highlight."""
	_is_drag_target = enabled
	_is_valid_drop_target = is_valid

	highlight_rect.visible = enabled
	if enabled:
		if is_valid:
			highlight_rect.color = Color(0.3, 0.8, 0.3, 0.4)  # Green for valid
		else:
			highlight_rect.color = Color(0.8, 0.3, 0.3, 0.4)  # Red for invalid


func shake(intensity: float = 4.0, duration: float = 0.2) -> void:
	"""Play a small vertical shake animation with slight randomization."""
	var rand_intensity = intensity * randf_range(0.8, 1.2)
	var rand_duration = duration * randf_range(0.85, 1.15)
	var tween = create_tween()
	var original_pos = position
	var step = rand_duration / 4.0
	tween.tween_property(self, "position", original_pos + Vector2(0, -rand_intensity), step)
	tween.tween_property(self, "position", original_pos + Vector2(0, rand_intensity), step)
	tween.tween_property(self, "position", original_pos + Vector2(0, -rand_intensity * 0.5), step)
	tween.tween_property(self, "position", original_pos, step)


func is_empty() -> bool:
	"""Check if slot has no character."""
	return character == null


func has_character() -> bool:
	"""Check if slot has a character."""
	return character != null


func get_position_vector() -> Vector2i:
	"""Get slot position as Vector2i."""
	return Vector2i(row, col)
