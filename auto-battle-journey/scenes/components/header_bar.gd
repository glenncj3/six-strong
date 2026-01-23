extends Panel
# HeaderBar - Reusable top bar component for all scenes
# Provides left, center, and right sections for flexible content

@onready var left_section: Control = $MarginContainer/HBoxContainer/LeftSection
@onready var center_section: HBoxContainer = $MarginContainer/HBoxContainer/CenterSection
@onready var right_section: Control = $MarginContainer/HBoxContainer/RightSection


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyles.create_warm_panel())


func get_left_section() -> Control:
	return left_section


func get_center_section() -> HBoxContainer:
	return center_section


func get_right_section() -> Control:
	return right_section
