class_name TweenTracker
extends RefCounted
## Utility class for tracking and managing multiple tweens.
## Provides centralized cleanup on node exit to prevent callbacks on freed nodes.
##
## Usage:
##   var _tweens: TweenTracker
##
##   func _ready() -> void:
##       _tweens = TweenTracker.new(self)
##
##   func _some_animation() -> void:
##       var tween = _tweens.create()
##       tween.tween_property(...)
##
##   func _exit_tree() -> void:
##       _tweens.kill_all()

var _tweens: Array[Tween] = []
var _owner: Node


func _init(owner: Node) -> void:
	"""
	Initialize the tween tracker.

	Args:
		owner: The node that owns these tweens (used for create_tween())
	"""
	_owner = owner


func create() -> Tween:
	"""
	Create a new tween and track it.

	Returns:
		The created tween
	"""
	if not is_instance_valid(_owner):
		push_warning("TweenTracker: Cannot create tween - owner is invalid")
		return null

	var tween = _owner.create_tween()
	_tweens.append(tween)
	return tween


func kill_all() -> void:
	"""Kill all tracked tweens and clear the list."""
	for tween in _tweens:
		if tween and tween.is_valid():
			tween.kill()
	_tweens.clear()


func get_active_count() -> int:
	"""Get the count of currently active (valid) tweens."""
	var count = 0
	for tween in _tweens:
		if tween and tween.is_valid() and tween.is_running():
			count += 1
	return count


func cleanup_finished() -> void:
	"""Remove finished/invalid tweens from the tracking list."""
	var active_tweens: Array[Tween] = []
	for tween in _tweens:
		if tween and tween.is_valid():
			active_tweens.append(tween)
	_tweens = active_tweens


func is_any_running() -> bool:
	"""Check if any tracked tweens are still running."""
	for tween in _tweens:
		if tween and tween.is_valid() and tween.is_running():
			return true
	return false
