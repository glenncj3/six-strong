extends PanelContainer
# CharacterInfoPanel - Sliding panel showing character details
# Slides up from the bottom when a character tile is clicked

@onready var portrait: TextureRect = $MarginContainer/HBoxContainer/Portrait
@onready var name_label: Label = $MarginContainer/HBoxContainer/InfoContainer/NameLabel
@onready var stats_container: GridContainer = $MarginContainer/HBoxContainer/InfoContainer/StatsContainer

var current_char_instance: CharacterInstance = null
var _tween: Tween = null
var _is_visible: bool = false
var _dismissed_char: CharacterInstance = null

const SLIDE_DURATION := 0.25


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


func _input(event: InputEvent) -> void:
	if not _is_visible:
		return
	if event is InputEventMouseButton and event.pressed:
		if not get_global_rect().has_point(event.position):
			_dismissed_char = current_char_instance
			hide_panel()
			get_tree().process_frame.connect(func(): _dismissed_char = null, CONNECT_ONE_SHOT)


func show_character(char_instance: CharacterInstance) -> void:
	"""Show the panel with character info, sliding up from the bottom."""
	if char_instance == _dismissed_char:
		return  # Don't re-show a character dismissed by clicking its own tile

	current_char_instance = char_instance
	_populate(char_instance)

	if _is_visible:
		return  # Content updated above, skip animation

	_is_visible = true
	visible = true

	# Animate slide up from bottom using offsets (not position)
	# to avoid resizing with FULL_RECT anchors
	if _tween and _tween.is_valid():
		_tween.kill()

	var slide_distance = get_parent().size.y
	offset_top = slide_distance
	offset_bottom = slide_distance
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

	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	_tween.tween_property(self, "offset_top", slide_distance, SLIDE_DURATION * 0.8)
	_tween.tween_property(self, "offset_bottom", slide_distance, SLIDE_DURATION * 0.8)
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

	# Portrait
	UIHelpers.set_texture_safe(portrait, char_master.get("image_path", ""))

	# Name with level
	name_label.text = "%s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]

	# Stats
	UIHelpers.clear_children(stats_container)

	var stats = [
		["HP", "%d/%d" % [char_instance.current_health, char_instance.max_health]],
		["MP", "%d" % char_instance.stats.get(GameConstants.STAT_MANA, 0)],
		["INC", "%d" % char_instance.stats.get(GameConstants.STAT_INCOME, 0)],
		["DEF", "%d%%" % char_instance.stats.get(GameConstants.STAT_DEFEND_RATE, 0)],
	]

	for stat in stats:
		var label_name = Label.new()
		label_name.text = stat[0]
		label_name.add_theme_font_size_override("font_size", 22)
		label_name.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)
		stats_container.add_child(label_name)

		var label_value = Label.new()
		label_value.text = stat[1]
		label_value.add_theme_font_size_override("font_size", 22)
		label_value.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
		stats_container.add_child(label_value)
