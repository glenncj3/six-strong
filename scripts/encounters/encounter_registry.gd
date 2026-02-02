class_name EncounterRegistry
extends RefCounted
## Registry for encounter type handlers.
## Provides registration, lookup, and handler metadata.
## Separated from UI creation for Single Responsibility Principle (SRP-2).

# Handler definition structure:
# {
#   "create_ui": Callable,  # (encounter_data, context) -> Control
#   "immediate_complete": bool,  # Whether to enable complete button immediately
#   "on_complete": Callable (optional),  # Additional completion logic
#   "get_reward_preview": Callable (optional)  # (encounter_data) -> String
# }

static var _handlers: Dictionary = {}
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	"""Initialize handlers on first access."""
	if _initialized:
		return

	_register_default_handlers()
	_initialized = true


static func _register_default_handlers() -> void:
	"""Register all default encounter handlers by id."""

	var ui_handlers: Dictionary = {
		"traveling_merchant": {
			"create_ui": ShopEncounterUI.create_ui,
			"get_reward_preview": ShopEncounterUI.get_reward_preview
		},
		"skill_trainer": {
			"create_ui": SkillTrainerEncounterUI.create_ui,
			"get_reward_preview": SkillTrainerEncounterUI.get_reward_preview
		},
		"treasure_chest": {
			"create_ui": TreasureChestEncounterUI.create_ui,
			"get_reward_preview": TreasureChestEncounterUI.get_reward_preview
		},
		"health_restore": {
			"create_ui": HealthRestoreEncounterUI.create_ui,
			"get_reward_preview": HealthRestoreEncounterUI.get_reward_preview
		},
		"gamble": {
			"create_ui": GambleEncounterUI.create_ui,
			"get_reward_preview": GambleEncounterUI.get_reward_preview
		},
		"matching_game": {
			"create_ui": MatchingGameEncounterUI.create_ui,
			"get_reward_preview": MatchingGameEncounterUI.get_reward_preview
		},
		"slot_machine": {
			"create_ui": SlotMachineEncounterUI.create_ui,
			"get_reward_preview": SlotMachineEncounterUI.get_reward_preview
		},
		"wheel_of_fortune": {
			"create_ui": WheelOfFortuneEncounterUI.create_ui,
			"get_reward_preview": WheelOfFortuneEncounterUI.get_reward_preview
		},
		"mercenary_camp": {
			"create_ui": CharacterShopEncounterUI.create_ui,
			"get_reward_preview": CharacterShopEncounterUI.get_reward_preview
		},
		"castle_winterfell": {
			"create_ui": CharacterShopEncounterUI.create_ui,
			"get_reward_preview": CharacterShopEncounterUI.get_reward_preview
		},
	}

	for encounter_id in ui_handlers:
		var type_def = EncounterFactory.get_type_def_by_id(encounter_id)
		var handler = ui_handlers[encounter_id].duplicate()
		handler["immediate_complete"] = type_def.get("immediate_complete", false)
		register(encounter_id, handler)


static func register(encounter_type: String, handler: Dictionary) -> void:
	"""
	Register a handler for an encounter type.

	Args:
		encounter_type: The type name (e.g., "shop")
		handler: Dictionary with "create_ui" Callable and "immediate_complete" bool
	"""
	_handlers[encounter_type] = handler


static func has_handler(encounter_type: String) -> bool:
	"""Check if a handler exists for this encounter type."""
	_ensure_initialized()
	return _handlers.has(encounter_type)


static func get_handler(encounter_type: String) -> Dictionary:
	"""Get the handler for an encounter type."""
	_ensure_initialized()
	return _handlers.get(encounter_type, {})


static func should_complete_immediately(encounter_type: String) -> bool:
	"""Check if this encounter type should enable complete button immediately."""
	_ensure_initialized()
	var handler = _handlers.get(encounter_type, {})
	return handler.get("immediate_complete", false)


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""
	Get the reward preview text for an encounter.
	Uses the registered get_reward_preview callback if available.

	Args:
		encounter_data: The encounter option data

	Returns:
		Reward preview string, or empty string if no preview available
	"""
	_ensure_initialized()

	var encounter_id = encounter_data.get("id", "")
	if not _handlers.has(encounter_id):
		return ""

	var handler = _handlers[encounter_id]
	var preview_func: Callable = handler.get("get_reward_preview", Callable())
	if preview_func.is_valid():
		return preview_func.call(encounter_data)

	return ""


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""
	Create UI for an encounter using its registered handler.

	Args:
		encounter_data: The encounter option data
		context: Context dictionary with callbacks (e.g., update_gold_label, on_complete)

	Returns:
		Control node with the encounter UI, or null if no handler
	"""
	_ensure_initialized()

	var encounter_id = encounter_data.get("id", "")
	if not _handlers.has(encounter_id):
		push_error("EncounterRegistry: No handler for id: %s" % encounter_id)
		return null

	var handler = _handlers[encounter_id]
	var create_func: Callable = handler.get("create_ui")
	if create_func.is_valid():
		return create_func.call(encounter_data, context)

	return null
