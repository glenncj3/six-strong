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
	"""Register all default encounter type handlers."""

	# Shop encounter
	register("shop", {
		"create_ui": EncounterUIFactory._create_shop_ui,
		"immediate_complete": true,
		"get_reward_preview": EncounterUIFactory._get_shop_preview
	})

	# XP reward encounter
	register("xp_reward", {
		"create_ui": EncounterUIFactory._create_xp_reward_ui,
		"immediate_complete": true,
		"get_reward_preview": EncounterUIFactory._get_xp_reward_preview
	})

	# Gold reward encounter
	register("gold_reward", {
		"create_ui": EncounterUIFactory._create_gold_reward_ui,
		"immediate_complete": true,
		"get_reward_preview": EncounterUIFactory._get_gold_reward_preview
	})

	# Health restore encounter
	register("health_restore", {
		"create_ui": EncounterUIFactory._create_health_restore_ui,
		"immediate_complete": true,
		"get_reward_preview": EncounterUIFactory._get_health_restore_preview
	})

	# Skill trainer encounter
	register("skill_trainer", {
		"create_ui": EncounterUIFactory._create_skill_trainer_ui,
		"immediate_complete": false,  # Must select a character
		"get_reward_preview": EncounterUIFactory._get_skill_trainer_preview
	})

	# Gamble encounter
	register("gamble", {
		"create_ui": EncounterUIFactory._create_gamble_ui,
		"immediate_complete": false,  # Must gamble or decline
		"get_reward_preview": EncounterUIFactory._get_gamble_preview
	})

	# Elite challenge encounter
	register("elite_challenge", {
		"create_ui": EncounterUIFactory._create_elite_challenge_ui,
		"immediate_complete": false,  # Must click complete challenge
		"get_reward_preview": EncounterUIFactory._get_elite_challenge_preview
	})


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

	var encounter_type = encounter_data.get("type", "")
	if not _handlers.has(encounter_type):
		return ""

	var handler = _handlers[encounter_type]
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

	var encounter_type = encounter_data.get("type", "")
	if not _handlers.has(encounter_type):
		push_error("EncounterRegistry: No handler for type: %s" % encounter_type)
		return null

	var handler = _handlers[encounter_type]
	var create_func: Callable = handler.get("create_ui")
	if create_func.is_valid():
		return create_func.call(encounter_data, context)

	return null
