extends ModalPopup
class_name CharacterInspectPopup
## Popup that shows a large CharacterTile and ability descriptions.
## Clicking anywhere dismisses it.

const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")
const POPUP_WIDTH := 480.0
const POPUP_HEIGHT := 720.0
const POPUP_MARGIN := 16
const TILE_OVERHANG_MARGIN := 40
const TILE_SIDE_MARGIN := 8
const DISPLAY_SCALE := 2.0

var _tile: CharacterTile = null
var _content: VBoxContainer = null


func _ready() -> void:
	super._ready()
	UIStyles.apply_panel_style(self, UIStyles.create_warm_panel())
	_build_layout()


func _build_layout() -> void:
	var scroll = ScrollContainer.new()
	scroll.layout_mode = 2
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(POPUP_WIDTH, 0)
	add_child(scroll)

	var margin = MarginContainer.new()
	UIStyles.set_margin_all(margin, POPUP_MARGIN)
	scroll.add_child(margin)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_content)


func show_character(instance: CharacterInstance) -> void:
	var char_master = GameData.get_character_by_id(instance.base_character_id)
	_setup_tile()
	_tile.setup(instance, _tile.custom_minimum_size.x)
	_finalize_tile()
	_add_abilities(char_master.get("abilities", []))
	show_modal()


func show_character_data(data: Dictionary) -> void:
	var char_id = data.get("id", "")
	var char_master = GameData.get_character_by_id(char_id)
	_setup_tile()
	_tile.setup_from_data(data, _tile.custom_minimum_size.x)
	_finalize_tile()
	_add_abilities(char_master.get("abilities", []))
	show_modal()


func _setup_tile() -> void:
	var tile_width = POPUP_WIDTH - (POPUP_MARGIN + TILE_SIDE_MARGIN) * 2
	var tile_margin = MarginContainer.new()
	tile_margin.add_theme_constant_override("margin_top", TILE_OVERHANG_MARGIN)
	tile_margin.add_theme_constant_override("margin_bottom", TILE_OVERHANG_MARGIN)
	tile_margin.add_theme_constant_override("margin_left", TILE_SIDE_MARGIN)
	tile_margin.add_theme_constant_override("margin_right", TILE_SIDE_MARGIN)
	tile_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_content.add_child(tile_margin)

	_tile = CharacterTileScene.instantiate()
	_tile.custom_minimum_size = Vector2(tile_width, tile_width)
	_tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tile_margin.add_child(_tile)


func _finalize_tile() -> void:
	_tile.set_display_scale(DISPLAY_SCALE)
	_tile.clickable = false


func _add_abilities(ability_ids: Array) -> void:
	for ability_id in ability_ids:
		var ability = GameData.get_ability(ability_id)
		if ability.is_empty():
			continue

		var ability_box = VBoxContainer.new()
		ability_box.add_theme_constant_override("separation", 4)

		var name_label = Label.new()
		name_label.text = ability.get("name", ability_id)
		name_label.theme_type_variation = "HeaderLabel"
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
		ability_box.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = ability.get("description", "")
		desc_label.add_theme_font_size_override("font_size", 18)
		desc_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ability_box.add_child(desc_label)

		_content.add_child(ability_box)


# =============================================================================
# MODAL OVERRIDES
# =============================================================================

func _center_popup() -> void:
	anchor_left = 0
	anchor_top = 0
	anchor_right = 0
	anchor_bottom = 0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	size = Vector2(POPUP_WIDTH, POPUP_HEIGHT)
	var vp = get_viewport_rect().size
	position = Vector2(
		roundf((vp.x - POPUP_WIDTH) / 2.0),
		roundf((vp.y - POPUP_HEIGHT) / 2.0)
	)


func show_modal() -> void:
	super.show_modal()
	size = Vector2(POPUP_WIDTH, POPUP_HEIGHT)


func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dismiss()
		get_viewport().set_input_as_handled()


func _dismiss() -> void:
	hide_modal()
	queue_free()
