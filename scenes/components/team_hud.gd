extends Control
# TeamHUD - Persistent team tiles that stay visible during gameplay
# Lives on a CanvasLayer above the transition layer so it persists through scene changes

const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")
const CharacterInfoPanelScene = preload("res://scenes/components/character_info_panel.tscn")

@onready var tiles_container: HBoxContainer = $VBoxContainer/TilesContainer
@onready var info_panel_clip: Control = $VBoxContainer/InfoPanelClip

var _is_draft_mode: bool = false
var _visibility: HudVisibilityHelper = null
var info_panel: Node = null


func _ready() -> void:
	add_to_group("team_hud")
	visible = false
	_visibility = HudVisibilityHelper.new(self)
	_setup_info_panel()
	SceneManager.scene_loaded.connect(_on_scene_loaded)


func _setup_info_panel() -> void:
	# Fix info panel height to match tile height
	var tile_height = _get_tile_size()
	info_panel_clip.custom_minimum_size = Vector2(0, tile_height)
	info_panel_clip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_panel = CharacterInfoPanelScene.instantiate()
	info_panel_clip.add_child(info_panel)
	info_panel.set_anchors_preset(Control.PRESET_FULL_RECT)


# =============================================================================
# SCENE TRANSITIONS
# =============================================================================

func _on_scene_loaded(scene_path: String) -> void:
	if not _visibility.is_gameplay_scene(scene_path):
		if visible:
			_visibility.fade_out()
		return

	if scene_path == "res://scenes/ui/draft.tscn":
		reset_for_draft()
		if not visible:
			_visibility.fade_in()
		else:
			visible = true
	elif RunManager.is_run_active:
		_enter_run_mode()
		if not visible:
			_visibility.fade_in()
		else:
			visible = true
	else:
		visible = false


# =============================================================================
# DRAFT MODE
# =============================================================================

func reset_for_draft() -> void:
	_is_draft_mode = true
	if info_panel and info_panel.is_showing():
		info_panel.hide_panel()
	_add_placeholder_tiles()


func add_drafted_character(char_instance: CharacterInstance) -> void:
	if not _is_draft_mode:
		return
	# Find the first placeholder (alpha=0) and replace it
	for i in range(tiles_container.get_child_count()):
		var child = tiles_container.get_child(i)
		if child.modulate.a == 0:
			tiles_container.remove_child(child)
			child.queue_free()
			var tile = CharacterTileScene.instantiate()
			tiles_container.add_child(tile)
			tiles_container.move_child(tile, i)
			tile.setup(char_instance, _get_tile_size())
			tile.tile_clicked.connect(_on_tile_clicked)
			AnimationManager.fade_in(tile, 0.2)
			break


func _add_placeholder_tiles() -> void:
	UIHelpers.clear_children(tiles_container)
	var tile_size = _get_tile_size()
	for i in range(GameConstants.TEAM_SIZE):
		var placeholder = CharacterTileScene.instantiate()
		tiles_container.add_child(placeholder)
		placeholder.custom_minimum_size = Vector2(tile_size, tile_size)
		placeholder.modulate.a = 0
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE


# =============================================================================
# RUN MODE
# =============================================================================

func _enter_run_mode() -> void:
	_is_draft_mode = false
	if info_panel and info_panel.is_showing():
		info_panel.hide_panel()
	_update_team_display()


func _update_team_display() -> void:
	var team = RunManager.get_team()
	UIHelpers.clear_children(tiles_container)
	var tile_size = _get_tile_size()

	for char_instance in team:
		var tile = CharacterTileScene.instantiate()
		tiles_container.add_child(tile)
		tile.setup(char_instance, tile_size)
		tile.tile_clicked.connect(_on_tile_clicked)


# =============================================================================
# TILE INTERACTION
# =============================================================================

func _on_tile_clicked(char_instance: CharacterInstance) -> void:
	if info_panel.is_showing() and info_panel.current_char_instance == char_instance:
		info_panel.hide_panel()
	else:
		info_panel.show_character(char_instance)


# =============================================================================
# HELPERS
# =============================================================================

func _get_tile_size() -> float:
	var available_width = max(size.x, 688) - 24
	var tile_size = floor((available_width - 16) / float(GameConstants.TEAM_SIZE))
	return max(tile_size, 180)
