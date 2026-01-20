extends Control
# CombatSelect - Choose from 3 combat options

@onready var options_container = $MainContainer/ScrollContainer/OptionsMargin/OptionsContainer
@onready var back_button = $BackButton

var combat_options: Array = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = false  # Only for testing

	_generate_and_display_options()


func _generate_and_display_options() -> void:
	"""Generate 3 combat options and display them."""
	# Clear existing using UIHelpers
	UIHelpers.clear_children(options_container)

	# Generate options
	combat_options = RunManager.generate_combat_options(3)

	# Create UI for each option using UIHelpers
	for combat_data in combat_options:
		var panel = UIHelpers.create_combat_option_panel(combat_data, _on_combat_selected)
		options_container.add_child(panel)


func _on_combat_selected(combat_data: Dictionary) -> void:
	"""Handle combat selection."""
	print("CombatSelect: Selected %s" % combat_data["name"])

	# Store selected combat data for next scene via SceneManager
	SceneManager.set_scene_data("selected_combat", combat_data)

	# Navigate to combat stub scene
	SceneManager.go_to("combat_stub")


func _on_back_pressed() -> void:
	"""Return to run view (debug only)."""
	SceneManager.go_to("run_view")
