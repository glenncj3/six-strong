class_name HealthRestoreEncounterUI
extends RefCounted
## UI creation and reward preview for health restore encounters.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create health restore encounter UI."""
	var vbox = UIHelpers.create_vbox_container(16)

	vbox.add_child(UIHelpers.create_label("Your team's health is restored!", GameConstants.FONT_SIZE_HEADING, GameConstants.COLOR_TEXT_LIGHT, true))

	var heal_percentage = encounter_data["data"]["heal_percentage"]
	var team = RunManager.get_team()
	var on_health_restore = context.get("on_health_restore", Callable())

	for char_instance in team:
		var heal_amount = int(char_instance.max_health * heal_percentage)
		if on_health_restore.is_valid():
			on_health_restore.call(char_instance, heal_amount)

		var char_label = UIHelpers.create_label(
			"%s: +%d HP (%d/%d)" % [
				char_instance.get_character_name(),
				heal_amount,
				char_instance.current_health,
				char_instance.max_health
			],
			GameConstants.FONT_SIZE_BODY,
			GameConstants.COLOR_SUCCESS,
			true
		)
		vbox.add_child(char_label)

	return vbox


static func get_reward_preview(_encounter_data: Dictionary) -> String:
	"""Get reward preview for health restore encounter."""
	return "Restore 50% HP"
