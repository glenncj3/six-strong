extends PanelContainer
# OptionsPanel - Container for encounter/combat options
# Mirrors TeamDisplay structure for consistent sizing

@onready var options_container: VBoxContainer = $MarginContainer/MainContainer/OptionsContainer


func _ready() -> void:
	UIStyles.apply_panel_style(self, UIStyles.create_dark_panel())


func get_options_container() -> VBoxContainer:
	return options_container
