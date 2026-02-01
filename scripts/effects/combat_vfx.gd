extends RefCounted
## CombatVFX - Maps combat events to visual effects.
## Connect to a CombatManager and provide slot_displays to resolve screen positions.
##
## To add a new projectile+impact VFX:
##   1. Add the effect_id to _effect_scenes (impact) and _effect_config
##   2. Add the effect_id to _projectile_scenes and _projectile_config
##   3. The ability's "applies_effect" field will auto-route through _on_ability_used
##   4. Use "hue_shift" (0.0–1.0) to recolor effects without changing the base scene
##
## To add an impact-only VFX (no projectile):
##   1. Add the effect_id to _effect_scenes and _effect_config only

const VFXPlayer = preload("res://scripts/effects/vfx_player.gd")

var _slot_displays: Dictionary = {}
var _vfx_parent: Node = null
var _scene_cache: Dictionary = {}  # path → PackedScene

# Impact effect scenes (played at target on arrival, or standalone for non-projectile effects)
var _effect_scenes: Dictionary = {
	"burn": "res://assets/external-assets/EffectBlocks/assets/explosions/explosion_light.tscn",
	"poison": "res://assets/external-assets/EffectBlocks/assets/explosions/explosion_light.tscn",
}

var _effect_config: Dictionary = {
	"burn": {"size": Vector2(128, 128), "duration": 1.2, "hue_shift": 0.0},
	"poison": {"size": Vector2(128, 128), "duration": 1.2, "hue_shift": 0.69},
}

# Projectile scenes (arcs from source to target; effect_id must also be in _effect_scenes for impact)
var _projectile_scenes: Dictionary = {
	"burn": "res://assets/external-assets/EffectBlocks/assets/fire/fire_light.tscn",
	"poison": "res://assets/external-assets/EffectBlocks/assets/fire/fire_light.tscn",
}

var _projectile_config: Dictionary = {
	"burn": {"size": Vector2(256, 256), "duration": 0.4, "arc_height": 80.0, "hue_shift": 0.0},
	"poison": {"size": Vector2(256, 256), "duration": 0.4, "arc_height": 80.0, "hue_shift": 0.69},
}


func connect_to_manager(manager: CombatManager, slot_displays: Dictionary, vfx_parent: Node) -> void:
	_slot_displays = slot_displays
	_vfx_parent = vfx_parent
	manager.effect_applied.connect(_on_effect_applied)
	manager.ability_used.connect(_on_ability_used)


func _on_ability_used(source: CombatCharacter, ability: Dictionary, targets: Array) -> void:
	var effect_id = ability.get("applies_effect", "")
	if not _projectile_scenes.has(effect_id):
		return

	var from_pos = _get_slot_center(source)
	if from_pos == null:
		return

	var proj_scene = _load_cached(_projectile_scenes[effect_id])
	if not proj_scene:
		return

	var config = _projectile_config.get(effect_id, {})
	var proj_size: Vector2 = config.get("size", Vector2(96, 96))
	var proj_duration: float = config.get("duration", 0.4)
	var arc_height: float = config.get("arc_height", 80.0)
	var hue: float = config.get("hue_shift", 0.0)

	for target in targets:
		var to_pos = _get_slot_center(target)
		if to_pos == null:
			continue

		var eid = effect_id
		var pos = to_pos
		VFXPlayer.play_arc(_vfx_parent, proj_scene, from_pos, to_pos,
			proj_size, proj_duration, arc_height, func(): _spawn_impact(eid, pos),
			hue)


func _on_effect_applied(target: CombatCharacter, effect: CombatEffect) -> void:
	if _projectile_scenes.has(effect.effect_id):
		return  # Handled by _on_ability_used with projectile + impact

	if not _effect_scenes.has(effect.effect_id):
		return

	var target_pos = _get_slot_center(target)
	if target_pos == null:
		return

	var scene = _load_cached(_effect_scenes[effect.effect_id])
	if not scene:
		return

	var config = _effect_config.get(effect.effect_id, {})
	VFXPlayer.play_at(_vfx_parent, scene, target_pos,
		config.get("size", Vector2(128, 128)), config.get("duration", 1.5),
		config.get("hue_shift", 0.0))


func _spawn_impact(effect_id: String, pos: Vector2) -> void:
	if not _effect_scenes.has(effect_id):
		return
	var scene = _load_cached(_effect_scenes[effect_id])
	if not scene:
		return
	var config = _effect_config.get(effect_id, {})
	VFXPlayer.play_at(_vfx_parent, scene, pos,
		config.get("size", Vector2(128, 128)), config.get("duration", 1.5),
		config.get("hue_shift", 0.0))


func _get_slot_center(character: CombatCharacter):
	var key = "%d_%d_%d" % [character.team, character.row, character.column]
	if not _slot_displays.has(key):
		return null
	var slot: Control = _slot_displays[key]["slot"]
	return slot.global_position + slot.size / 2.0


func _load_cached(path: String) -> PackedScene:
	if _scene_cache.has(path):
		return _scene_cache[path]
	var scene = load(path) as PackedScene
	if not scene:
		push_warning("CombatVFX: Could not load scene: %s" % path)
		return null
	_scene_cache[path] = scene
	return scene
