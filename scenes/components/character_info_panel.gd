extends PanelContainer
# CharacterInfoPanel - Sliding panel showing character info
# Phase 1 Refactor: Simplified to show only character stats (no items/skills)
# Items are now in player inventory, skills are one-shot effects

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
# StatsLabel is created dynamically if it doesn't exist in the scene
var stats_label: Label = null

# Deprecated nodes - hidden if they exist in scene
@onready var _items_section = get_node_or_null("MarginContainer/VBoxContainer/GridsContainer/ItemsSection")
@onready var _skills_section = get_node_or_null("MarginContainer/VBoxContainer/GridsContainer/SkillsSection")
@onready var _grids_container = get_node_or_null("MarginContainer/VBoxContainer/GridsContainer")

var current_char_instance: CharacterInstance = null
var _tween: Tween = null
var _is_visible: bool = false
var _suppress_dismiss: bool = false
var slide_down: bool = false  # If true, panel drops down from top instead of sliding up from bottom

const SLIDE_DURATION := 0.25


func _ready() -> void:
	_apply_style()
	_hide_deprecated_sections()
	_ensure_stats_label()
	# Start hidden (positioned below parent)
	modulate.a = 0
	visible = false


func _ensure_stats_label() -> void:
	"""Ensure stats_label exists (create if not in scene)."""
	var vbox = $MarginContainer/VBoxContainer
	stats_label = vbox.get_node_or_null("StatsLabel")
	if stats_label == null:
		stats_label = Label.new()
		stats_label.name = "StatsLabel"
		stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
		# Insert after name label
		vbox.add_child(stats_label)
		vbox.move_child(stats_label, 1)


func _hide_deprecated_sections() -> void:
	"""Hide deprecated items/skills sections from Phase 0 scene."""
	if _grids_container:
		_grids_container.visible = false
	if _items_section:
		_items_section.visible = false
	if _skills_section:
		_skills_section.visible = false


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

	# Name with level
	name_label.text = "%s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]

	# Stats summary
	var hp = char_instance.stats.get(GameConstants.STAT_HEALTH, 0)
	var mp = char_instance.stats.get(GameConstants.STAT_MANA, 0)
	var def = char_instance.stats.get(GameConstants.STAT_DEFEND_RATE, 0)

	stats_label.text = "HP: %d/%d  |  MP: %d  |  DEF: %d%%" % [
		char_instance.current_health, hp, mp, def
	]

	# Get description from master data
	var description = char_master.get("description", "")
	if not description.is_empty():
		stats_label.text += "\n\n" + description
