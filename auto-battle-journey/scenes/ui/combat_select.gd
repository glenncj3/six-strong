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

	# Create UI for each option
	for i in range(combat_options.size()):
		_create_option_panel(combat_options[i])


func _create_option_panel(combat_data: Dictionary) -> void:
	"""Create a selectable combat option panel."""
	var panel = PanelContainer.new()
	options_container.add_child(panel)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	hbox.add_theme_constant_override("separation", 12)

	# Left margin with image
	var margin = MarginContainer.new()
	hbox.add_child(margin)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)

	# Image - use UIHelpers for safe texture loading
	var image = TextureRect.new()
	margin.add_child(image)
	image.custom_minimum_size = Vector2(100, 100)
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIHelpers.set_texture_safe(image, combat_data["image_path"])

	# Info section
	var info_vbox = VBoxContainer.new()
	hbox.add_child(info_vbox)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)

	# Name
	var name_label = Label.new()
	info_vbox.add_child(name_label)
	name_label.text = combat_data["name"]
	name_label.add_theme_font_size_override("font_size", 20)

	# Type
	var type_label = Label.new()
	info_vbox.add_child(type_label)
	type_label.text = "[%s]" % combat_data["type"].to_upper()
	type_label.modulate = GameConstants.COLOR_DISABLED
	type_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Description
	var desc_label = Label.new()
	info_vbox.add_child(desc_label)
	desc_label.text = combat_data["description"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Difficulty or Rank
	if combat_data["type"] == "ai":
		var diff_label = Label.new()
		info_vbox.add_child(diff_label)
		diff_label.text = "Difficulty: %s" % combat_data["difficulty"]
		diff_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

		# Color code difficulty
		match combat_data["difficulty"]:
			"Easy":
				diff_label.modulate = Color.GREEN
			"Medium":
				diff_label.modulate = Color.YELLOW
			"Hard":
				diff_label.modulate = Color.RED

	elif combat_data["type"] == "ghost":
		var rank_label = Label.new()
		info_vbox.add_child(rank_label)
		rank_label.text = "Player Rank: %d" % combat_data["rank"]
		rank_label.modulate = GameConstants.COLOR_GHOST_RANK
		rank_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Rewards
	var reward_label = Label.new()
	info_vbox.add_child(reward_label)
	reward_label.text = "Rewards: +%d Gold  +%d XP" % [combat_data["reward_gold"], combat_data["reward_xp"]]
	reward_label.modulate = GameConstants.COLOR_SUCCESS
	reward_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_SMALL)

	# Spacer
	var spacer = Control.new()
	info_vbox.add_child(spacer)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Fight button
	var fight_button = Button.new()
	info_vbox.add_child(fight_button)
	fight_button.text = "FIGHT"
	fight_button.custom_minimum_size = Vector2(100, 40)
	fight_button.pressed.connect(_on_combat_selected.bind(combat_data))


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
