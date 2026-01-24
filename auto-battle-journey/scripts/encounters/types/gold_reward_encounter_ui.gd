class_name GoldRewardEncounterUI
extends RefCounted
## UI creation and reward preview for gold reward encounters.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create gold reward encounter UI."""
	var vbox = UIHelpers.create_vbox_container(16)

	var gold_amount = encounter_data["data"]["gold_amount"]

	vbox.add_child(UIHelpers.create_label("You found gold!", GameConstants.FONT_SIZE_HEADING, GameConstants.COLOR_TEXT_LIGHT, true))
	vbox.add_child(UIHelpers.create_label("+%d Gold" % gold_amount, 48, GameConstants.COLOR_GOLD, true))

	# Award gold via context callback
	var on_gold_reward = context.get("on_gold_reward", Callable())
	if on_gold_reward.is_valid():
		on_gold_reward.call(gold_amount)

	return vbox


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for gold reward encounter."""
	var data = encounter_data.get("data", {})
	return "+%d Gold" % data.get("gold_amount", 0)
