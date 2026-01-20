extends Node
# SceneManager Autoload
# Provides clean API for scene transitions, eliminating deep node path chaining
# Delegates actual transitions to the Main scene

signal scene_changed(scene_path: String)
signal transition_started
signal transition_completed

# Scene path constants for type safety
const SCENES = {
	"main_menu": "res://scenes/ui/main_menu.tscn",
	"collection": "res://scenes/ui/collection.tscn",
	"character_details": "res://scenes/ui/character_details.tscn",
	"draft": "res://scenes/ui/draft.tscn",
	# Add more scenes as they're created
	# "run_view": "res://scenes/ui/run_view.tscn",
	# "combat": "res://scenes/ui/combat.tscn",
	# "results": "res://scenes/ui/results.tscn",
}

# Reference to main scene (set after tree is ready)
var _main_node: Node = null
var _is_transitioning: bool = false


func _ready() -> void:
	# Defer getting main node until tree is fully built
	call_deferred("_find_main_node")


func _find_main_node() -> void:
	"""Find and cache reference to Main node."""
	_main_node = get_tree().root.get_node_or_null("Main")
	if _main_node == null:
		push_warning("SceneManager: Main node not found. Scene transitions may not work.")


# =============================================================================
# PUBLIC API
# =============================================================================

func change_scene(scene_path: String, fade: bool = true) -> void:
	"""
	Change to a new scene by path.

	Args:
		scene_path: Full resource path to the scene
		fade: Whether to use fade transition
	"""
	if _is_transitioning:
		push_warning("SceneManager: Scene transition already in progress")
		return

	if _main_node == null:
		_find_main_node()
		if _main_node == null:
			push_error("SceneManager: Cannot change scene - Main node not found")
			return

	_is_transitioning = true
	transition_started.emit()

	# Use the Main node's change_scene method
	await _main_node.change_scene(scene_path, fade)

	_is_transitioning = false
	transition_completed.emit()
	scene_changed.emit(scene_path)


func go_to(scene_name: String, fade: bool = true) -> void:
	"""
	Change to a scene by name (uses SCENES constant).

	Args:
		scene_name: Key from SCENES dictionary
		fade: Whether to use fade transition
	"""
	if not SCENES.has(scene_name):
		push_error("SceneManager: Unknown scene name '%s'" % scene_name)
		return

	change_scene(SCENES[scene_name], fade)


func go_to_main_menu(fade: bool = true) -> void:
	"""Convenience method: Go to main menu."""
	go_to("main_menu", fade)


func go_to_collection(fade: bool = true) -> void:
	"""Convenience method: Go to collection screen."""
	go_to("collection", fade)


func go_to_draft(fade: bool = true) -> void:
	"""Convenience method: Go to draft screen."""
	go_to("draft", fade)


# =============================================================================
# STATE QUERIES
# =============================================================================

func is_transitioning() -> bool:
	"""Check if a scene transition is in progress."""
	return _is_transitioning


func get_scene_path(scene_name: String) -> String:
	"""Get the resource path for a scene name."""
	return SCENES.get(scene_name, "")


func has_scene(scene_name: String) -> bool:
	"""Check if a scene name is registered."""
	return SCENES.has(scene_name)
