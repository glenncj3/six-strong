extends Node
## SceneTransitionData Singleton
## Provides type-safe storage for data passed between scenes during transitions.
## Replaces the generic Dictionary-based scene_data mechanism with typed properties.
##
## Usage:
##   # Setting data before transition:
##   SceneTransitionData.set_encounter(encounter_dict)
##   SceneManager.go_to("encounter_active")
##
##   # Getting data after transition:
##   var data = SceneTransitionData.get_encounter()  # Auto-clears after retrieval

# =============================================================================
# ENCOUNTER DATA
# =============================================================================

var _selected_encounter: Dictionary = {}

func set_encounter(encounter_data: Dictionary) -> void:
	"""Store encounter data for the encounter_active scene."""
	_selected_encounter = encounter_data


func get_encounter(clear: bool = true) -> Dictionary:
	"""
	Retrieve stored encounter data.

	Args:
		clear: If true (default), clears the data after retrieval.

	Returns:
		The encounter data Dictionary, or empty Dictionary if none set.
	"""
	var data = _selected_encounter
	if clear:
		_selected_encounter = {}
	return data


func has_encounter() -> bool:
	"""Check if encounter data is available."""
	return not _selected_encounter.is_empty()


# =============================================================================
# COMBAT DATA
# =============================================================================

var _selected_combat: Dictionary = {}

func set_combat(combat_data: Dictionary) -> void:
	"""Store combat data for the combat scene."""
	_selected_combat = combat_data


func get_combat(clear: bool = true) -> Dictionary:
	"""
	Retrieve stored combat data.

	Args:
		clear: If true (default), clears the data after retrieval.

	Returns:
		The combat data Dictionary, or empty Dictionary if none set.
	"""
	var data = _selected_combat
	if clear:
		_selected_combat = {}
	return data


func has_combat() -> bool:
	"""Check if combat data is available."""
	return not _selected_combat.is_empty()


# =============================================================================
# RUN RESULTS DATA
# =============================================================================

var _run_results: Dictionary = {}

func set_run_results(results_data: Dictionary) -> void:
	"""Store run results data for the run_results scene."""
	_run_results = results_data


func get_run_results(clear: bool = true) -> Dictionary:
	"""
	Retrieve stored run results data.

	Args:
		clear: If true (default), clears the data after retrieval.

	Returns:
		The run results Dictionary, or empty Dictionary if none set.
	"""
	var data = _run_results
	if clear:
		_run_results = {}
	return data


func has_run_results() -> bool:
	"""Check if run results data is available."""
	return not _run_results.is_empty()


# =============================================================================
# UTILITY
# =============================================================================

func clear_all() -> void:
	"""Clear all stored transition data."""
	_selected_encounter = {}
	_selected_combat = {}
	_run_results = {}
