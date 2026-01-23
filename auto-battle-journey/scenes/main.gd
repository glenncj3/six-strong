extends Node
# Main scene - entry point and scene manager
# Now uses TransitionManager for enhanced transition effects

@onready var scene_container = $SceneContainer
@onready var transition_layer = $TransitionLayer/ColorRect

# Current loaded scene
var current_scene: Node = null

# Scene paths
const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"

# Default transition type (can be changed per transition)
var default_transition_type: GameConstants.TransitionType = GameConstants.TransitionType.FADE


func _ready() -> void:
	# Set up transition layer
	transition_layer.color = Color.BLACK
	transition_layer.modulate.a = 0

	# Wait for autoloads to initialize
	await get_tree().process_frame

	# Load main menu (no transition on initial load)
	_load_scene_internal(MAIN_MENU_SCENE)


func change_scene(scene_path: String, fade: bool = true,
		transition_type: GameConstants.TransitionType = GameConstants.TransitionType.FADE) -> void:
	"""
	Change to a new scene with optional transition effect.

	Args:
		scene_path: Path to the scene to load
		fade: Whether to use transition (kept for backward compatibility)
		transition_type: Type of transition to use (default: FADE)
	"""
	if fade and TransitionManager:
		await _change_scene_with_transition(scene_path, transition_type)
	else:
		_load_scene_internal(scene_path)


func _change_scene_with_transition(scene_path: String,
		transition_type: GameConstants.TransitionType) -> void:
	"""Change scene using TransitionManager."""
	# Transition out
	await TransitionManager.transition_out(transition_type)

	# Swap scenes
	_load_scene_internal(scene_path)
	SceneManager.scene_loaded.emit(scene_path)

	# Small delay for visual clarity
	await get_tree().create_timer(0.05).timeout

	# Transition in
	await TransitionManager.transition_in(transition_type)


func _load_scene_internal(scene_path: String) -> void:
	"""Internal method to load a scene without transition."""
	# Remove current scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# Load new scene
	var new_scene = load(scene_path).instantiate()
	scene_container.add_child(new_scene)
	current_scene = new_scene


# =============================================================================
# TRANSITION TYPE SHORTCUTS
# =============================================================================

func change_scene_fade(scene_path: String) -> void:
	"""Change scene with fade transition."""
	await change_scene(scene_path, true, GameConstants.TransitionType.FADE)


func change_scene_slide_left(scene_path: String) -> void:
	"""Change scene with slide left transition."""
	await change_scene(scene_path, true, GameConstants.TransitionType.SLIDE_LEFT)


func change_scene_slide_right(scene_path: String) -> void:
	"""Change scene with slide right transition."""
	await change_scene(scene_path, true, GameConstants.TransitionType.SLIDE_RIGHT)


func change_scene_scale(scene_path: String) -> void:
	"""Change scene with scale transition."""
	await change_scene(scene_path, true, GameConstants.TransitionType.SCALE)


func change_scene_dissolve(scene_path: String) -> void:
	"""Change scene with dissolve transition."""
	await change_scene(scene_path, true, GameConstants.TransitionType.DISSOLVE)


func change_scene_wipe(scene_path: String) -> void:
	"""Change scene with radial wipe transition."""
	await change_scene(scene_path, true, GameConstants.TransitionType.WIPE_RADIAL)


# =============================================================================
# LEGACY METHODS (for backward compatibility)
# =============================================================================

func _fade_out() -> void:
	"""Fade to black (legacy method, uses TransitionManager if available)"""
	if TransitionManager:
		await TransitionManager.transition_out(GameConstants.TransitionType.FADE)
	else:
		var tween = create_tween()
		tween.tween_property(transition_layer, "modulate:a", 1.0, 0.3)
		await tween.finished


func _fade_in() -> void:
	"""Fade from black (legacy method, uses TransitionManager if available)"""
	if TransitionManager:
		await TransitionManager.transition_in(GameConstants.TransitionType.FADE)
	else:
		var tween = create_tween()
		tween.tween_property(transition_layer, "modulate:a", 0.0, 0.3)
		await tween.finished
