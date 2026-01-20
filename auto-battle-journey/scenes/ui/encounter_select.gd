extends Control
# EncounterSelect - Choose from 3 encounter options

@onready var options_container = $MainContainer/OptionsMargin/OptionsContainer
@onready var back_button = $BackButton

var encounter_options: Array = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = false  # Only for testing

	_generate_and_display_options()


func _generate_and_display_options() -> void:
	"""Generate 3 encounter options and display them."""
	# Clear existing using UIHelpers
	UIHelpers.clear_children(options_container)

	# Generate options
	encounter_options = EncounterFactory.generate_encounter_options(3)

	# Create UI for each option
	for i in range(encounter_options.size()):
		_create_option_panel(encounter_options[i], i)


func _create_option_panel(encounter_data: Dictionary, index: int) -> void:
	"""Create a selectable encounter option panel."""
	var panel = PanelContainer.new()
	options_container.add_child(panel)
	panel.custom_minimum_size = Vector2(200, 350)

	var margin = MarginContainer.new()
	panel.add_child(margin)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)

	var content = VBoxContainer.new()
	margin.add_child(content)
	content.add_theme_constant_override("separation", 8)

	# Image - use UIHelpers for safe texture loading
	var image = TextureRect.new()
	content.add_child(image)
	image.custom_minimum_size = Vector2(180, 180)
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIHelpers.set_texture_safe(image, encounter_data["image_path"])

	# Name
	var name_label = Label.new()
	content.add_child(name_label)
	name_label.text = encounter_data["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)

	# Type
	var type_label = Label.new()
	content.add_child(type_label)
	type_label.text = "[%s]" % encounter_data["type"].to_upper().replace("_", " ")
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_TINY)
	type_label.modulate = GameConstants.COLOR_DISABLED

	# Description
	var desc_label = Label.new()
	content.add_child(desc_label)
	desc_label.text = encounter_data["description"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.y = 40

	# Preview rewards (type-specific)
	var preview_label = Label.new()
	content.add_child(preview_label)
	preview_label.text = _get_reward_preview(encounter_data)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.modulate = GameConstants.COLOR_SUCCESS

	# Spacer
	var spacer = Control.new()
	content.add_child(spacer)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Select button
	var button = Button.new()
	content.add_child(button)
	button.text = "SELECT"
	button.custom_minimum_size = Vector2(0, 40)
	button.pressed.connect(_on_encounter_selected.bind(encounter_data))


func _get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get a preview of rewards for this encounter."""
	match encounter_data["type"]:
		"shop":
			var item_count = encounter_data["data"]["items"].size()
			var skill_count = encounter_data["data"]["skills"].size()
			return "%d items, %d skills" % [item_count, skill_count]
		"xp_reward":
			return "+%d XP" % encounter_data["data"]["xp_amount"]
		"gold_reward":
			return "+%d Gold" % encounter_data["data"]["gold_amount"]
		"health_restore":
			return "Restore 50%% HP"
		_:
			return ""


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
