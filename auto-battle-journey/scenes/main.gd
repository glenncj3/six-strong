extends Node
# Main scene - entry point and scene manager

@onready var scene_container = $SceneContainer
@onready var transition_layer = $TransitionLayer/ColorRect

# Current loaded scene
var current_scene: Node = null

# Scene paths
const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"


func _ready() -> void:
	# Set up transition layer
	transition_layer.color = Color.BLACK
	transition_layer.modulate.a = 0

	# Wait for autoloads to initialize
	await get_tree().process_frame

	# Load main menu
	change_scene(MAIN_MENU_SCENE)


func change_scene(scene_path: String, fade: bool = true) -> void:
	"""Change to a new scene with optional fade transition"""
	if fade:
		await _fade_out()

	# Remove current scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# Load new scene
	var new_scene = load(scene_path).instantiate()
	scene_container.add_child(new_scene)
	current_scene = new_scene

	if fade:
		await _fade_in()


func _fade_out() -> void:
	"""Fade to black"""
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 1.0, 0.3)
	await tween.finished


func _fade_in() -> void:
	"""Fade from black"""
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 0.0, 0.3)
	await tween.finished
