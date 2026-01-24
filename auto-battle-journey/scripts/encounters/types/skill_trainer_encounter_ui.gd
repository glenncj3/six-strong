class_name SkillTrainerEncounterUI
extends RefCounted
## UI creation and reward preview for skill trainer encounters.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create skill trainer encounter UI."""
	var vbox = UIHelpers.create_vbox_container(12)

	var skill_id = encounter_data["data"]["skill_id"]
	var skill_data = GameData.get_skill_by_id(skill_id)
	var on_complete = context.get("on_encounter_complete", Callable())
	var on_skill_learn = context.get("on_skill_learn", Callable())

	if skill_data.is_empty():
		vbox.add_child(UIHelpers.create_label("No skill available...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if on_complete.is_valid():
			on_complete.call()
		return vbox

	vbox.add_child(UIHelpers.create_label("The trainer offers to teach:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label(skill_data["name"], GameConstants.FONT_SIZE_REWARD, GameConstants.COLOR_SUCCESS, true))
	vbox.add_child(UIHelpers.create_label(skill_data["description"], GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	if skill_data.has("level_requirement"):
		vbox.add_child(UIHelpers.create_label("(Requires Level %d)" % skill_data["level_requirement"], GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_WARNING, true))

	vbox.add_child(UIHelpers.create_spacer(20))
	vbox.add_child(UIHelpers.create_label("Choose a character to learn this skill:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	var team = RunManager.get_team()

	for i in range(team.size()):
		var char_instance = team[i]
		var button = UIContainerHelpers.create_button(
			"Teach %s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
		)
		button.pressed.connect(_on_skill_trainer_selected.bind(i, skill_id, button, vbox, on_complete, on_skill_learn))
		vbox.add_child(button)

	return vbox


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for skill trainer encounter."""
	var data = encounter_data.get("data", {})
	var skill_data = GameData.get_skill_by_id(data.get("skill_id", ""))
	if not skill_data.is_empty():
		return "Free: %s" % skill_data["name"]
	return "Free Skill"


static func _on_skill_trainer_selected(char_index: int, skill_id: String, button: Button, container: VBoxContainer, on_complete: Callable, on_skill_learn: Callable) -> void:
	"""Handle skill trainer selection."""
	var team = RunManager.get_team()
	var char_instance = team[char_index]

	var success = false
	if on_skill_learn.is_valid():
		success = on_skill_learn.call(char_instance, skill_id)
	else:
		success = char_instance.learn_skill(skill_id)

	if success:
		button.text = "Skill Learned!"
		UIContainerHelpers.disable_all_buttons(container)
		if on_complete.is_valid():
			on_complete.call()
	else:
		button.text = "Cannot Learn (Level/Already Known)"
		button.disabled = true
