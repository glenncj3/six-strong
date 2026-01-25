extends SelectScreenBase
## CombatSelect - Choose from 3 combat options


func _generate_options() -> Array:
	return RunManager.generate_combat_options(3)


func _create_option_panel(data: Dictionary) -> Control:
	return UIHelpers.create_combat_option_panel(data, _on_option_selected)


func _get_data_key() -> String:
	return "selected_combat"


func _get_next_scene() -> String:
	return "combat_stub"


func _get_log_prefix() -> String:
	return "CombatSelect"
