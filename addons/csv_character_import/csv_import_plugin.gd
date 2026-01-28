@tool
extends EditorPlugin

var dock: Control

func _enter_tree() -> void:
	var dock_scene = preload("res://addons/csv_character_import/csv_import_dock.tscn")
	dock = dock_scene.instantiate()
	add_control_to_bottom_panel(dock, "CSV Characters")

func _exit_tree() -> void:
	if dock:
		remove_control_from_bottom_panel(dock)
		dock.queue_free()
