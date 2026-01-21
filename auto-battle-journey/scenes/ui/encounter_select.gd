extends Control
# EncounterSelect - Choose from 3 encounter options

@onready var options_container = $MainContainer/ScrollContainer/OptionsMargin/OptionsContainer
@onready var team_display_container = $TeamDisplayContainer
@onready var back_button = $BackButton

var encounter_options: Array = []


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
	"""Generate 3 encounter options and display them."""
	# Clear existing using UIHelpers
	UIHelpers.clear_children(options_container)

	# Generate options
	encounter_options = EncounterFactory.generate_encounter_options(3)

	# Create UI for each option using UIHelpers
	for encounter_data in encounter_options:
		var panel = UIHelpers.create_encounter_option_panel(encounter_data, _on_encounter_selected)
		options_container.add_child(panel)


func _on_encounter_selected(encounter_data: Dictionary) -> void:
	"""Handle encounter selection."""
	print("EncounterSelect: Selected %s" % encounter_data["name"])

	# Store selected encounter data for next scene via SceneManager
	SceneManager.set_scene_data("selected_encounter", encounter_data)

	# Navigate to encounter execution scene
	SceneManager.go_to("encounter_execute")


func _on_back_pressed() -> void:
	"""Return to run view (debug only)."""
	SceneManager.go_to("run_view")
