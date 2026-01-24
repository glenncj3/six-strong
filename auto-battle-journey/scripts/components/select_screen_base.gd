class_name SelectScreenBase
extends Control
## Base class for option selection screens (combat, encounter).
## Provides common team display and option generation/display logic.
##
## Subclasses must override:
## - _generate_options() -> Array: Generate option data
## - _create_option_panel(data: Dictionary) -> Control: Create panel for option
## - _get_data_key() -> String: Scene data key for storing selection
## - _get_next_scene() -> String: Scene to navigate to after selection
## - _get_log_prefix() -> String: Prefix for log messages

const CharacterTileScene = preload("res://scenes/components/character_tile.tscn")

@onready var background = $Background
@onready var options_container = $OptionsWrapper/MainContainer/ScrollContainer/OptionsMargin/OptionsContainer
@onready var team_display_container = $TeamDisplayContainer
@onready var back_button = $BackButton

var _options: Array = []


func _ready() -> void:
	_apply_visual_styling()
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = false  # Only for testing

	_setup_team_display()
	_generate_and_display_options()


func _apply_visual_styling() -> void:
	"""Apply consistent visual styling."""
	UIStyles.setup_button(back_button)
	ButtonEffects.apply_effects(back_button)


func _setup_team_display() -> void:
	"""Display the player's team using CharacterTile instances."""
	var team = RunManager.get_team()
	if team.size() == 0:
		return

	UIHelpers.clear_children(team_display_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	team_display_container.add_child(vbox)

	var title = Label.new()
	title.text = "YOUR TEAM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	vbox.add_child(title)

	var tiles_container = HBoxContainer.new()
	tiles_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tiles_container.add_theme_constant_override("separation", 8)
	vbox.add_child(tiles_container)

	var available_width = max(team_display_container.size.x, 688) - 24
	var tile_size = floor((available_width - 16) / 3.0)
	tile_size = max(tile_size, 180)

	for char_instance in team:
		var tile = CharacterTileScene.instantiate()
		tiles_container.add_child(tile)
		tile.setup(char_instance, tile_size)


func _generate_and_display_options() -> void:
	"""Generate options and display them."""
	UIHelpers.clear_children(options_container)

	_options = _generate_options()

	for option_data in _options:
		var panel = _create_option_panel(option_data)
		options_container.add_child(panel)


func _on_option_selected(option_data: Dictionary) -> void:
	"""Handle option selection."""
	print("%s: Selected %s" % [_get_log_prefix(), option_data.get("name", "Unknown")])

	SceneManager.set_scene_data(_get_data_key(), option_data)
	SceneManager.go_to(_get_next_scene())


func _on_back_pressed() -> void:
	"""Return to run view (debug only)."""
	SceneManager.go_to("run_view")


# Override points - subclasses must implement these

func _generate_options() -> Array:
	"""Generate option data. Override in subclass."""
	push_error("SelectScreenBase._generate_options() not implemented")
	return []


func _create_option_panel(_data: Dictionary) -> Control:
	"""Create panel for option. Override in subclass."""
	push_error("SelectScreenBase._create_option_panel() not implemented")
	return null


func _get_data_key() -> String:
	"""Get scene data key for storing selection. Override in subclass."""
	push_error("SelectScreenBase._get_data_key() not implemented")
	return ""


func _get_next_scene() -> String:
	"""Get scene to navigate to. Override in subclass."""
	push_error("SelectScreenBase._get_next_scene() not implemented")
	return ""


func _get_log_prefix() -> String:
	"""Get prefix for log messages. Override in subclass."""
	return "SelectScreen"
