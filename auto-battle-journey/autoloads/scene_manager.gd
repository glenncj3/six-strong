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
	"run_view": "res://scenes/ui/run_view.tscn",
	"encounter_select": "res://scenes/ui/encounter_select.tscn",
	"encounter_execute": "res://scenes/ui/encounter_execute.tscn",
	"combat_select": "res://scenes/ui/combat_select.tscn",
	"combat_stub": "res://scenes/ui/combat_stub.tscn",
	# Add more scenes as they're created
	# "run_results": "res://scenes/ui/run_results.tscn",
}

# Reference to main scene (set after tree is ready)
var _main_node: Node = null
var _is_transitioning: bool = false

# Scene data storage for passing data between scenes
var _scene_data: Dictionary = {}


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


func go_to_run_view(fade: bool = true) -> void:
	"""Convenience method: Go to run view screen."""
	go_to("run_view", fade)


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


# =============================================================================
# SCENE DATA PASSING
# =============================================================================

func set_scene_data(key: String, data: Variant) -> void:
	"""
	Store data to be retrieved by the next scene.
	Data persists until explicitly cleared or retrieved with clear flag.

	Args:
		key: Unique identifier for the data
		data: Any data to store (Dictionary, Array, etc.)
	"""
	_scene_data[key] = data


func get_scene_data(key: String, default: Variant = null, clear: bool = true) -> Variant:
	"""
	Retrieve data stored for this scene.

	Args:
		key: The data key to retrieve
		default: Value to return if key not found
		clear: If true, removes the data after retrieval (default: true)

	Returns:
		The stored data, or default if not found
	"""
	if not _scene_data.has(key):
		return default

	var data = _scene_data[key]
	if clear:
		_scene_data.erase(key)
	return data


func has_scene_data(key: String) -> bool:
	"""Check if scene data exists for a key."""
	return _scene_data.has(key)


func clear_scene_data(key: String = "") -> void:
	"""
	Clear scene data.

	Args:
		key: Specific key to clear, or empty string to clear all
	"""
	if key.is_empty():
		_scene_data.clear()
	elif _scene_data.has(key):
		_scene_data.erase(key)
