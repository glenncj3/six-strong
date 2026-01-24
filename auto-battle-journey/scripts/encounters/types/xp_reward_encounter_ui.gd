class_name XpRewardEncounterUI
extends RefCounted
## UI creation and reward preview for XP reward encounters.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create XP reward encounter UI."""
	var vbox = UIHelpers.create_vbox_container(16)

	vbox.add_child(UIHelpers.create_label("Choose a character to receive XP", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	var xp_amount = encounter_data["data"]["xp_amount"]
	vbox.add_child(UIHelpers.create_label("XP Award: +%d" % xp_amount, GameConstants.FONT_SIZE_REWARD, GameConstants.COLOR_SUCCESS, true))

	vbox.add_child(UIHelpers.create_spacer(20))

	var team = RunManager.get_team()
	var on_select = context.get("on_xp_select", Callable())

	for i in range(team.size()):
		var char_instance = team[i]
		var button = UIContainerHelpers.create_button(
			"Give to %s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
		)
		if on_select.is_valid():
			button.pressed.connect(on_select.bind(i, xp_amount, button))
		vbox.add_child(button)

	return vbox


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for XP reward encounter."""
	var data = encounter_data.get("data", {})
	return "+%d XP" % data.get("xp_amount", 0)
