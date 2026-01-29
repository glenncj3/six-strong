class_name StatusEffectFactory
extends RefCounted
## Creates CombatEffect instances from JSON status effect templates.


static func create_from_template(template: Dictionary, source_id: String, overrides: Dictionary = {}) -> CombatEffect:
	var config = {
		"source_type": "ability",
		"source_id": source_id,
		"effect_id": template.get("id", ""),
		"tags": template.get("tags", []),
		"merge_behavior": template.get("merge_behavior", "none"),
		"duration_type": template.get("duration_type", "permanent"),
		"duration_value": overrides.get("duration_value", template.get("duration_value", 0.0)),
		"stacks": overrides.get("stacks", template.get("stacks", 0)),
		"max_stacks": template.get("max_stacks", 0),
		"tick_interval": template.get("tick_interval", 0.0),
		"continuous_modifier": template.get("continuous_modifier", ""),
		"continuous_value": template.get("continuous_value", 0.0),
	}

	# Wire on_tick from TickActionRegistry
	var tick_action_id = template.get("tick_action", "")
	if tick_action_id != "":
		var action = TickActionRegistry.get_action(tick_action_id)
		if action.is_valid():
			config["on_tick"] = action

	return CombatEffect.create_status_effect(config)
