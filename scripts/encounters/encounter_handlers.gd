class_name EncounterHandlers
extends RefCounted
## Facade for encounter handling system.
## Maintains backwards compatibility by delegating to:
##   - EncounterRegistry: Handler registration and lookup
##   - Per-type UI classes (e.g., ShopEncounterUI, GambleEncounterUI)
##
## This class provides the same public API as before (SRP-2 refactoring).

# =============================================================================
# STANDARDIZED CONTEXT INTERFACE
# =============================================================================
# All handlers receive the same context dictionary structure. Handlers should
# check for the callbacks they need and ignore others.
#
# Expected context keys:
#   "set_gold_label": Callable(label: Label)  - Store reference to gold label for updates
#   "on_buy_item": Callable(item_id, cost, selector, button)  - Handle item purchase
#   "on_buy_skill": Callable(skill_id, cost, selector, button)  - Handle skill purchase
#   "on_xp_select": Callable(char_index, xp_amount, button)  - Handle XP award selection
#   "on_encounter_complete": Callable()  - Signal that encounter can be completed
#
# Handlers that don't use a particular callback simply don't call it.
# =============================================================================


static func register(encounter_type: String, handler: Dictionary) -> void:
	"""
	Register a handler for an encounter type.

	Args:
		encounter_type: The type name (e.g., "shop")
		handler: Dictionary with "create_ui" Callable and "immediate_complete" bool
	"""
	EncounterRegistry.register(encounter_type, handler)


static func has_handler(encounter_type: String) -> bool:
	"""Check if a handler exists for this encounter type."""
	return EncounterRegistry.has_handler(encounter_type)


static func get_handler(encounter_type: String) -> Dictionary:
	"""Get the handler for an encounter type."""
	return EncounterRegistry.get_handler(encounter_type)


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""
	Create UI for an encounter using its registered handler.

	Args:
		encounter_data: The encounter option data
		context: Context dictionary with callbacks (e.g., update_gold_label, on_complete)

	Returns:
		Control node with the encounter UI, or null if no handler
	"""
	return EncounterRegistry.create_ui(encounter_data, context)


static func should_complete_immediately(encounter_type: String) -> bool:
	"""Check if this encounter type should enable complete button immediately."""
	return EncounterRegistry.should_complete_immediately(encounter_type)
