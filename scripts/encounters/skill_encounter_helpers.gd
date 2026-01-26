class_name SkillEncounterHelpers
extends RefCounted
## Shared helpers for encounters that execute skills.
## Extracted from ShopEncounterUI and SkillTrainerEncounterUI to reduce duplication.


static func execute_skill(skill_data: Dictionary) -> Dictionary:
	"""
	Execute a skill's effect immediately.

	Args:
		skill_data: The skill data dictionary

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

	# Execute instant effect
	var context = SkillContext.from_run_manager(RunManager)
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
