extends PanelContainer
# CharacterInfoPanel - Sliding panel showing character name, items, and skills
# Slides up from the bottom when a character tile is clicked

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var items_label: Label = $MarginContainer/VBoxContainer/GridsContainer/ItemsSection/ItemsLabel
@onready var skills_label: Label = $MarginContainer/VBoxContainer/GridsContainer/SkillsSection/SkillsLabel
@onready var items_grid: GridContainer = $MarginContainer/VBoxContainer/GridsContainer/ItemsSection/ItemsGrid
@onready var skills_grid: GridContainer = $MarginContainer/VBoxContainer/GridsContainer/SkillsSection/SkillsGrid

var current_char_instance: CharacterInstance = null
var _tween: Tween = null
var _is_visible: bool = false
var _suppress_dismiss: bool = false
var slide_down: bool = false  # If true, panel drops down from top instead of sliding up from bottom

const SLIDE_DURATION := 0.25
const MAX_ITEMS := GameConstants.MAX_RUN_ITEMS
const MAX_SKILLS := GameConstants.MAX_RUN_SKILLS
const SLOT_ICON_SIZE := 68


func _ready() -> void:
	_apply_style()
	# Start hidden (positioned below parent)
	modulate.a = 0
	visible = false


func _apply_style() -> void:
	var style = UIStyles.create_panel_style(
		GameConstants.COLOR_PANEL_DARK,
		GameConstants.COLOR_BORDER_GOLD,
		UIStyles.BORDER_WIDTH_NORMAL,
		UIStyles.CORNER_RADIUS_MEDIUM,
		true
	)
	add_theme_stylebox_override("panel", style)
	name_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	items_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	skills_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)


func _input(event: InputEvent) -> void:
	if not _is_visible:
		return
	if event is InputEventMouseButton and not event.pressed:
		if not get_global_rect().has_point(event.position):
			call_deferred("_deferred_dismiss")


func _deferred_dismiss() -> void:
	if _suppress_dismiss:
		_suppress_dismiss = false
		return
	if _is_visible:
		hide_panel()


func show_character(char_instance: CharacterInstance) -> void:
	"""Show the panel with character info, sliding up from the bottom."""
	current_char_instance = char_instance
	_populate(char_instance)

	if _is_visible:
		_suppress_dismiss = true
		return  # Content updated above, skip animation

	_is_visible = true
	visible = true

	# Animate slide up from bottom using offsets (not position)
	# to avoid resizing with FULL_RECT anchors
	if _tween and _tween.is_valid():
		_tween.kill()

	var slide_distance = get_parent().size.y
	var direction = -1.0 if slide_down else 1.0
	offset_top = slide_distance * direction
	offset_bottom = slide_distance * direction
	modulate.a = 0

	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	_tween.tween_property(self, "offset_top", 0.0, SLIDE_DURATION)
	_tween.tween_property(self, "offset_bottom", 0.0, SLIDE_DURATION)
	_tween.tween_property(self, "modulate:a", 1.0, SLIDE_DURATION * 0.7)


func hide_panel() -> void:
	"""Hide the panel by sliding it down."""
	if not _is_visible:
		return

	_is_visible = false

	if _tween and _tween.is_valid():
		_tween.kill()

	var slide_distance = get_parent().size.y
	var direction = -1.0 if slide_down else 1.0

	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	_tween.tween_property(self, "offset_top", slide_distance * direction, SLIDE_DURATION * 0.8)
	_tween.tween_property(self, "offset_bottom", slide_distance * direction, SLIDE_DURATION * 0.8)
	_tween.tween_property(self, "modulate:a", 0.0, SLIDE_DURATION * 0.8)
	_tween.chain().tween_callback(func():
		visible = false
		offset_top = 0
		offset_bottom = 0
	)


func is_showing() -> bool:
	return _is_visible


func _populate(char_instance: CharacterInstance) -> void:
	"""Populate the panel with character data."""
	var char_master = GameData.get_character_by_id(char_instance.base_character_id)
	if char_master.is_empty():
		return

	# Name (centered, header style)
	name_label.text = char_instance.get_character_name()

	# Items grid
	_populate_items_grid(char_instance)

	# Skills grid
	_populate_skills_grid(char_instance)


func _populate_items_grid(char_instance: CharacterInstance) -> void:
	"""Fill the items grid with icons for equipped items and upgrades."""
	var icons: Array[String] = []
	for item_id in char_instance.equipped_items:
		if icons.size() >= MAX_ITEMS:
			break
		var item_data = GameData.get_item_by_id(item_id)
		if not item_data.is_empty():
			icons.append(item_data.get("image_path", ""))
	for upgrade_id in char_instance.equipped_item_upgrades:
		if icons.size() >= MAX_ITEMS:
			break
		var upgrade_data = GameData.get_item_upgrade_by_id(upgrade_id)
		if not upgrade_data.is_empty():
			icons.append(upgrade_data.get("image_path", ""))
	_populate_grid(items_grid, icons, MAX_ITEMS)


func _populate_skills_grid(char_instance: CharacterInstance) -> void:
	"""Fill the skills grid with icons for learned skills."""
	var icons: Array[String] = []
	for skill_id in char_instance.learned_skills:
		if icons.size() >= MAX_SKILLS:
			break
		var skill_data = GameData.get_skill_by_id(skill_id)
		if not skill_data.is_empty():
			icons.append(skill_data.get("image_path", ""))
	_populate_grid(skills_grid, icons, MAX_SKILLS)


func _populate_grid(grid: GridContainer, icons: Array[String], max_slots: int) -> void:
	"""Fill a grid with icon slots, populated or empty."""
	UIHelpers.clear_children(grid)
	for i in range(max_slots):
		var slot = _create_icon_slot()
		if i < icons.size() and icons[i] != "":
			var icon_rect = slot.get_child(0) as TextureRect
			UIHelpers.set_texture_safe(icon_rect, icons[i])
		grid.add_child(slot)


func _create_icon_slot() -> PanelContainer:
	"""Create a single icon slot with background and a TextureRect child."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(SLOT_ICON_SIZE, SLOT_ICON_SIZE)

	# Slot background style
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.12, 0.1, 0.6)
	bg.border_color = GameConstants.COLOR_BORDER_SILVER
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", bg)

	# Icon TextureRect inside the panel
	var icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(icon)

	return panel
