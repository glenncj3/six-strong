class_name SkillEncounterHelpers
extends RefCounted
## Shared helpers for encounters that execute skills.
## Extracted from ShopEncounterUI and SkillTrainerEncounterUI to reduce duplication.


static func execute_skill(skill_data: Dictionary, drop_target = null) -> Dictionary:
	"""
	Execute a skill's effect immediately.

	Args:
		skill_data: The skill data dictionary
		drop_target: Optional CharacterInstance for targeted effects

	Returns:
		Dictionary with "success" (bool) and "message" (String)
	"""
	var effect_type = skill_data.get("effect_type", "instant")
	var skill_name = skill_data.get("name", "Skill")

	# Check if this is a lingering effect
	if effect_type == "lingering":
		# Add to lingering effects instead of executing immediately
		var lingering_success = RunManager.add_lingering_effect(skill_data)
		if lingering_success:
			var trigger = skill_data.get("trigger", "")
			var trigger_desc = get_trigger_description(trigger)
			return {
				"success": true,
				"message": "%s will activate %s!" % [skill_name, trigger_desc]
			}
		else:
			return {
				"success": false,
				"message": "Failed to prepare %s!" % skill_name
			}

	# Create context with drop_target
	var context = SkillContext.from_run_manager(RunManager)
	context.drop_target = drop_target

	# Check for multi-effect skills (effects array)
	if skill_data.has("effects"):
		return _execute_multi_effect(skill_data, context)

	# Execute single effect
	var registry = get_skill_registry()
	var exec_success = registry.execute(skill_data, context)
	if exec_success:
		var effect = skill_data.get("effect", {})
		var effect_desc = SkillEffects.get_effect_description(effect)
		return {
			"success": true,
			"message": "%s!" % effect_desc
		}
	else:
		return {
			"success": false,
			"message": "Failed to use %s!" % skill_name
		}


static func _execute_multi_effect(skill_data: Dictionary, context) -> Dictionary:
	"""
	Execute a skill with multiple effects.

	Args:
		skill_data: The skill data with "effects" array
		context: SkillContext with drop_target set

	Returns:
		Dictionary with "success" (bool) and "message" (String)
	"""
	var effects = skill_data.get("effects", [])
	var skill_name = skill_data.get("name", "Skill")

	if effects.is_empty():
		return {
			"success": false,
			"message": "No effects to execute for %s!" % skill_name
		}

	var registry = get_skill_registry()
	var all_success = true
	var descriptions: Array[String] = []

	for effect_data in effects:
		if not effect_data is Dictionary:
			continue

		# Create a temporary skill_data wrapper for each effect
		var temp_skill = {"effect": effect_data}
		var success = registry.execute(temp_skill, context)

		if success:
			var desc = SkillEffects.get_effect_description(effect_data)
			if not desc.is_empty() and not desc.begins_with("Unknown"):
				descriptions.append(desc)
		else:
			all_success = false

	if all_success and not descriptions.is_empty():
		return {
			"success": true,
			"message": "%s!" % ", ".join(descriptions)
		}
	elif all_success:
		return {
			"success": true,
			"message": "%s activated!" % skill_name
		}
	else:
		return {
			"success": false,
			"message": "Some effects failed for %s!" % skill_name
		}


static func get_skill_registry() -> SkillEffectRegistry:
	"""Get or create the skill effect registry."""
	# Try to get from RunManager if it has one
	if RunManager.has_method("get_skill_registry"):
		return RunManager.get_skill_registry()

	# Create a temporary one with all effects registered
	var registry = SkillEffectRegistry.new()
	SkillEffects.register_all(registry)
	return registry


static func get_trigger_description(trigger: String) -> String:
	"""Get a human-readable description of a trigger."""
	match trigger:
		"next_character_acquired":
			return "when you get a new character"
		"next_combat":
			return "before your next combat"
		"next_encounter":
			return "at your next encounter"
		"next_round":
			return "at the start of next round"
		_:
			return "later"


static func can_afford(cost: int) -> bool:
	"""Check if player can afford the cost."""
	return RunManager.get_gold() >= cost


static func show_result(result_label: Label, message: String, color: Color) -> void:
	"""Show result message on a label."""
	if result_label:
		result_label.text = message
		result_label.add_theme_color_override("font_color", color)
		result_label.visible = true


static func dim_tile_by_id(tiles: Array, offering_id: String) -> void:
	"""Find and dim a tile by its ID."""
	for tile in tiles:
		if tile.tile_data.get("id") == offering_id:
			tile.modulate = GameConstants.COLOR_TILE_DIMMED
			tile.set_clickable(false)
			break


static func validate_skill_target(skill_data: Dictionary, drop_target) -> Dictionary:
	"""
	Validate if a drop target is valid for a skill.

	Args:
		skill_data: The skill data dictionary
		drop_target: CharacterInstance to validate

	Returns:
		Dictionary with "valid" (bool) and "error" (String)
	"""
	var context = SkillContext.from_run_manager(RunManager)
	context.drop_target = drop_target

	# Check multi-effect skills
	if skill_data.has("effects"):
		for effect_data in skill_data.get("effects", []):
			if not effect_data is Dictionary:
				continue
			var effect_type = effect_data.get("type", "")
			if effect_type == "stat_buff":
				var effect = StatBuffEffect.from_dict(effect_data)
				if not effect.validate_target(drop_target, context, effect_data):
					return {
						"valid": false,
						"error": effect.get_validation_error(drop_target, context, effect_data)
					}
		return {"valid": true, "error": ""}

	# Check single effect
	var effect = skill_data.get("effect", {})
	var effect_type = effect.get("type", "")

	if effect_type == "stat_buff":
		var buff_effect = StatBuffEffect.from_dict(effect)
		if not buff_effect.validate_target(drop_target, context, effect):
			return {
				"valid": false,
				"error": buff_effect.get_validation_error(drop_target, context, effect)
			}

	return {"valid": true, "error": ""}


static func skill_requires_target(skill_data: Dictionary) -> bool:
	"""
	Check if a skill requires a drop target.

	Args:
		skill_data: The skill data dictionary

	Returns:
		True if the skill needs a target character
	"""
	# Check multi-effect skills
	if skill_data.has("effects"):
		for effect_data in skill_data.get("effects", []):
			if not effect_data is Dictionary:
				continue
			var target_mode = effect_data.get("target_mode", "dropped")
			if SkillTargetResolver.requires_drop_target(target_mode):
				return true
		return false

	# Check single effect
	var effect = skill_data.get("effect", {})
	var target_mode = effect.get("target_mode", "")

	# If no target_mode specified, use default behavior (no target required)
	if target_mode.is_empty():
		return false

	return SkillTargetResolver.requires_drop_target(target_mode)
