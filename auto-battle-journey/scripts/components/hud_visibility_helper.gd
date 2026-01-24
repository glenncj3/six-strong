class_name HudVisibilityHelper
extends RefCounted
## Composition helper for HUD visibility and fade animations.
## Encapsulates shared GAMEPLAY_SCENES matching and tween-based fading.

const GAMEPLAY_SCENES: Array[String] = [
	"res://scenes/ui/draft.tscn",
	"res://scenes/ui/run_view.tscn",
	"res://scenes/ui/encounter_active.tscn",
	"res://scenes/ui/combat_stub.tscn",
]

const FADE_DURATION := 0.3

var _target: Control
var _tween: Tween = null


func _init(target: Control) -> void:
	_target = target


func is_gameplay_scene(scene_path: String) -> bool:
	return scene_path in GAMEPLAY_SCENES


func fade_in() -> void:
	_kill_tween()
	_target.modulate.a = 0.0
	_target.visible = true
	_tween = _target.create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_target, "modulate:a", 1.0, FADE_DURATION)


func fade_out() -> void:
	_kill_tween()
	_tween = _target.create_tween()
	_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_target, "modulate:a", 0.0, FADE_DURATION)
	_tween.tween_callback(func(): _target.visible = false)


func fade_in_node(node: Control) -> void:
	"""Fade in a specific child node (not the target)."""
	_kill_tween()
	node.modulate.a = 0.0
	_target.visible = true
	_tween = _target.create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(node, "modulate:a", 1.0, FADE_DURATION)


func fade_out_node(node: Control) -> void:
	"""Fade out a specific child node (not the target)."""
	_kill_tween()
	_tween = _target.create_tween()
	_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(node, "modulate:a", 0.0, FADE_DURATION)
	_tween.tween_callback(func(): _target.visible = false)


func kill_tween() -> void:
	_kill_tween()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
