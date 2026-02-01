class_name SkillManager
extends RefCounted
## Owns LingeringEffects and SkillEffectRegistry. Handles effect lifecycle.
## Extracted from RunManager for SRP.

const LingeringEffectsScript = preload("res://scripts/managers/lingering_effects.gd")
const SkillEffectRegistryScript = preload("res://scripts/skills/skill_effect_registry.gd")
const SkillEffectsScript = preload("res://scripts/skills/skill_effects.gd")
const SkillContextScript = preload("res://scripts/skills/skill_context.gd")

signal lingering_effect_added(effect: Dictionary)
signal lingering_effect_triggered(effect: Dictionary, trigger: String)

var _lingering_effects = null  # LingeringEffects instance
var _skill_registry = null  # SkillEffectRegistry instance


func _init() -> void:
	_lingering_effects = LingeringEffectsScript.new()
	_skill_registry = SkillEffectRegistryScript.new()
	_init_registry()
	_connect_signals()


func _init_registry() -> void:
	_skill_registry.clear()
	SkillEffectsScript.register_all(_skill_registry)


func _connect_signals() -> void:
	_lingering_effects.effect_added.connect(func(e): lingering_effect_added.emit(e))
	_lingering_effects.effect_triggered.connect(func(e, t): lingering_effect_triggered.emit(e, t))


# =============================================================================
# ACCESSORS
# =============================================================================

func get_lingering_effects():
	return _lingering_effects


func get_skill_registry():
	return _skill_registry


# =============================================================================
# LINGERING EFFECT OPERATIONS
# =============================================================================

func add_lingering_effect(skill_data: Dictionary, current_round: int = 0) -> bool:
	var effect_id = _lingering_effects.add_effect(skill_data, current_round)
	return effect_id > 0


func trigger_effects(trigger_type: String, run_manager) -> Array[Dictionary]:
	var context = SkillContextScript.from_run_manager(run_manager)
	return _lingering_effects.trigger(trigger_type, context, _skill_registry)


func trigger_character_acquired_effects(character, run_manager) -> Array[Dictionary]:
	var context = SkillContextScript.from_run_manager(run_manager)
	return _lingering_effects.trigger_for_character("next_character_acquired", character, context)


func has_pending_effects(trigger_type: String) -> bool:
	return _lingering_effects.has_effects_for_trigger(trigger_type)


func get_pending_effects(trigger_type: String) -> Array[Dictionary]:
	return _lingering_effects.get_effects_by_trigger(trigger_type)


# =============================================================================
# SERIALIZATION
# =============================================================================

func clear() -> void:
	_lingering_effects.clear()


func to_dict() -> Dictionary:
	return _lingering_effects.to_dict()


func load_from_dict(data: Dictionary) -> void:
	if data.has("effects"):
		_lingering_effects = LingeringEffectsScript.from_dict(data)
		_connect_signals()
