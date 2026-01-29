class_name EffectManager
extends RefCounted
## Manages effect lifecycle: application, removal, merging, cleansing, and triggered effects.


func apply_effect(target: CombatCharacter, effect_to_apply: CombatEffect) -> Dictionary:
	## Applies an effect to a target. Returns {"merged": bool, "recalc": bool, "trigger_id": String}.
	if effect_to_apply.effect_id != "" and effect_to_apply.merge_behavior != "none":
		var existing = target.get_effect(effect_to_apply.effect_id)
		if existing != null:
			match effect_to_apply.merge_behavior:
				"add_stacks":
					existing.stacks += effect_to_apply.stacks
					if existing.max_stacks > 0:
						existing.stacks = min(existing.stacks, existing.max_stacks)
				"refresh_duration":
					existing.duration_value = effect_to_apply.duration_value
				"extend_duration":
					existing.duration_value += effect_to_apply.duration_value
			return {"merged": true, "recalc": false, "trigger_id": effect_to_apply.effect_id}

	target.effects.append(effect_to_apply)
	var needs_recalc = effect_to_apply.effect_type == "stat_modifier" or effect_to_apply.continuous_modifier != ""
	if needs_recalc:
		target.recalculate_stats()
	return {"merged": false, "recalc": needs_recalc, "trigger_id": effect_to_apply.effect_id}


func remove_effect(target: CombatCharacter, effect_to_remove: CombatEffect) -> bool:
	## Removes an effect and recalculates stats if needed. Returns true if recalc happened.
	target.effects.erase(effect_to_remove)
	if effect_to_remove.effect_type == "stat_modifier" or effect_to_remove.continuous_modifier != "":
		target.recalculate_stats()
		return true
	return false


func remove_effects_from_source(source_id: String, characters: Array) -> Array:
	## Removes all effects from source_id across all characters. Returns [{target, effect}] pairs removed.
	var removed_pairs: Array = []
	for character in characters:
		var to_remove: Array = []
		for effect in character.effects:
			if effect.source_id == source_id:
				to_remove.append(effect)
		for effect in to_remove:
			remove_effect(character, effect)
			removed_pairs.append({"target": character, "effect": effect})
	return removed_pairs


func cleanse_effects_by_tag(target: CombatCharacter, tag: String) -> Array:
	## Removes effects by tag. Returns the removed effects. Recalculates stats if needed.
	var removed = target.cleanse_by_tag(tag)
	var needs_recalc = false
	for effect in removed:
		if effect.effect_type == "stat_modifier" or effect.continuous_modifier != "":
			needs_recalc = true
	if needs_recalc:
		target.recalculate_stats()
	return removed


func process_triggered_effects(character: CombatCharacter, trigger: String, data: Dictionary) -> void:
	## Fires all triggered effects matching the given trigger.
	for effect in character.effects:
		if effect.effect_type == "triggered" and effect.trigger == trigger:
			if effect.action.is_valid():
				effect.action.call(data)
