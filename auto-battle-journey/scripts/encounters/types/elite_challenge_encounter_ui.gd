class_name EliteChallengeEncounterUI
extends RefCounted
## UI creation and reward preview for elite challenge encounters.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create elite challenge encounter UI."""
	var vbox = UIHelpers.create_vbox_container(12)

	var xp_reward = encounter_data["data"]["xp_reward"]
	var gold_reward = encounter_data["data"]["gold_reward"]

	vbox.add_child(UIHelpers.create_label("An elite challenge awaits!", GameConstants.FONT_SIZE_HEADING, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label("Complete this trial for great rewards.", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	vbox.add_child(UIHelpers.create_spacer(20))

	vbox.add_child(UIHelpers.create_label("Rewards:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label("+%d XP to ALL characters" % xp_reward, GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_SUCCESS, true))
	vbox.add_child(UIHelpers.create_label("+%d Gold" % gold_reward, GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_GOLD, true))

	vbox.add_child(UIHelpers.create_spacer(20))

	var on_complete = context.get("on_encounter_complete", Callable())
	var on_xp_reward_all = context.get("on_xp_reward_all", Callable())
	var on_gold_reward = context.get("on_gold_reward", Callable())

	var challenge_button = UIContainerHelpers.create_button("COMPLETE CHALLENGE")
	challenge_button.pressed.connect(_on_elite_challenge_completed.bind(xp_reward, gold_reward, challenge_button, on_complete, on_xp_reward_all, on_gold_reward))
	vbox.add_child(challenge_button)

	return vbox


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for elite challenge encounter."""
	var data = encounter_data.get("data", {})
	var xp = data.get("xp_reward", 0)
	var gold = data.get("gold_reward", 0)
	return "+%d XP (all), +%d Gold" % [xp, gold]


static func _on_elite_challenge_completed(xp_reward: int, gold_reward: int, button: Button, on_complete: Callable, on_xp_reward_all: Callable, on_gold_reward: Callable) -> void:
	"""Handle elite challenge completion."""
	# Award XP to all characters via callback
	if on_xp_reward_all.is_valid():
		on_xp_reward_all.call(xp_reward)

	# Award gold via callback
	if on_gold_reward.is_valid():
		on_gold_reward.call(gold_reward)

	button.text = "Challenge Complete!"
	button.disabled = true

	if on_complete.is_valid():
		on_complete.call()
