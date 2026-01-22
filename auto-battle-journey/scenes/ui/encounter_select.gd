extends SelectScreenBase
## EncounterSelect - Choose from 3 encounter options


func _generate_options() -> Array:
	return EncounterFactory.generate_encounter_options(3)


func _create_option_panel(data: Dictionary) -> Control:
	return UIHelpers.create_encounter_option_panel(data, _on_option_selected)


func _get_data_key() -> String:
	return "selected_encounter"


func _get_next_scene() -> String:
	return "encounter_execute"


func _get_log_prefix() -> String:
	return "EncounterSelect"
