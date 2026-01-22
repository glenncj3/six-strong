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

@onready var options_container = $OptionsWrapper/MainContainer/ScrollContainer/OptionsMargin/OptionsContainer
@onready var team_display_container = $TeamDisplayContainer
@onready var back_button = $BackButton

var _options: Array = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = false  # Only for testing

	_setup_team_display()
	_generate_and_display_options()


func _setup_team_display() -> void:
	"""Display the player's team at the top of the screen."""
	var team = RunManager.get_team()
	if team.size() > 0:
		UIHelpers.populate_team_display(team_display_container, team, "YOUR TEAM")


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
