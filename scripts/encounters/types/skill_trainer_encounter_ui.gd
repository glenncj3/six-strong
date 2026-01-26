class_name SkillTrainerEncounterUI
extends RefCounted
## UI creation and reward preview for skill trainer encounters.
## Shows 3 skill options that execute immediately on purchase.
##
## Phase 3 Refactor:
## - Skills are one-shot effects that execute immediately
## - No character assignment needed
## - Shows effect preview before purchase

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")

# Store references for callback access
static var _selected_skill_data: Dictionary = {}
static var _on_complete: Callable = Callable()
static var _on_gold_spend: Callable = Callable()
static var _tiles: Array = []
static var _result_label: Label = null


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create skill trainer encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var skill_ids: Array = encounter_data["data"].get("skill_ids", [])
	_on_complete = context.get("on_encounter_complete", Callable())
	_on_gold_spend = context.get("on_gold_spend", Callable())
	_selected_skill_data = {}
	_tiles.clear()
	_result_label = null

	if skill_ids.is_empty():
		vbox.add_child(UIHelpers.create_label("No skills available...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if _on_complete.is_valid():
			_on_complete.call()
		return vbox

	# Add instruction label
	var instruction = UIHelpers.create_label("Select a skill to use:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true)
	vbox.add_child(instruction)
	vbox.add_child(UIHelpers.create_spacer(4))

	# Create horizontal container for skill tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = UIScaler.calculate_tile_size(GameConstants.DESIGN_WIDTH, GameConstants.TEAM_SIZE, 48.0, 8.0, 180.0)

	for i in range(skill_ids.size()):
		var skill_id = skill_ids[i]
		var skill_data = GameData.get_skill_by_id(skill_id)
		if skill_data.is_empty():
			continue

		# Build tile data with effect preview
		var tile_data = _build_skill_tile_data(skill_data)

		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		# Defer setup until tile enters the scene tree
		tile.ready.connect(_setup_tile.bind(tile, tile_data, tile_size))
		_tiles.append(tile)

	# Add spacer and result label area
	vbox.add_child(UIHelpers.create_spacer(8))
	_result_label = UIHelpers.create_label("", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_SUCCESS, true)
	_result_label.visible = false
	vbox.add_child(_result_label)

	return vbox


static func _build_skill_tile_data(skill_data: Dictionary) -> Dictionary:
	"""Build tile data for a skill with effect preview."""
	var tile_data = skill_data.duplicate()

	# Add effect preview
	var effect = skill_data.get("effect", {})
	if not effect.is_empty():
		var effect_desc = SkillEffects.get_effect_description(effect)
		tile_data["effect_preview"] = effect_desc

	# Mark effect type
	tile_data["effect_type"] = skill_data.get("effect_type", "instant")
	tile_data["trigger"] = skill_data.get("trigger", "")

	return tile_data


static func _setup_tile(tile: Control, skill_data: Dictionary, tile_size: float) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(skill_data, tile_size)
	tile.set_tile_color(GameConstants.COLOR_AMETHYST)
	tile.tile_clicked.connect(_on_skill_selected)


static func _on_skill_selected(skill_data: Dictionary) -> void:
	"""Handle skill tile selection - purchase and execute immediately."""
	_selected_skill_data = skill_data

	var skill_id = skill_data.get("id", "")
	var skill_name = skill_data.get("name", "Skill")
	var cost = skill_data.get("cost", 0)

	# Check if player can afford
	if not _can_afford(cost):
		_show_result("Not enough gold!", GameConstants.COLOR_ERROR)
		return

	# Spend gold
	if not EncounterUIHelpers.try_spend_gold(cost, _on_gold_spend):
		_show_result("Purchase failed!", GameConstants.COLOR_ERROR)
		return

	# Execute the skill
	var success = _execute_skill(skill_data)

	if success:
		# Dim the selected tile
		for tile in _tiles:
			if tile.tile_data.get("id") == skill_id:
				tile.modulate = GameConstants.COLOR_TILE_DIMMED
				tile.set_clickable(false)
				break

		# Complete encounter after successful skill use
		if _on_complete.is_valid():
			_on_complete.call()
	else:
		# Refund gold if skill failed
		RunManager.add_gold(cost)


static func _execute_skill(skill_data: Dictionary) -> bool:
	"""
	Execute a skill's effect immediately.

	Args:
		skill_data: The skill data dictionary

	Returns:
		True if skill was executed successfully
	"""
	var effect_type = skill_data.get("effect_type", "instant")
	var skill_name = skill_data.get("name", "Skill")

	# Check if this is a lingering effect
	if effect_type == "lingering":
		# Add to lingering effects instead of executing immediately
		var success = RunManager.add_lingering_effect(skill_data)
		if success:
			var trigger = skill_data.get("trigger", "")
			var trigger_desc = _get_trigger_description(trigger)
			_show_result("%s will activate %s!" % [skill_name, trigger_desc], GameConstants.COLOR_SUCCESS)
			return true
		else:
			_show_result("Failed to prepare %s!" % skill_name, GameConstants.COLOR_ERROR)
			return false

	# Execute instant effect
	var context = SkillContext.from_run_manager(RunManager)
	var registry = _get_skill_registry()

	var success = registry.execute(skill_data, context)
	if success:
		var effect = skill_data.get("effect", {})
		var effect_desc = SkillEffects.get_effect_description(effect)
		_show_result("%s!" % effect_desc, GameConstants.COLOR_SUCCESS)
		return true
	else:
		_show_result("Failed to use %s!" % skill_name, GameConstants.COLOR_ERROR)
		return false


static func _get_skill_registry() -> SkillEffectRegistry:
	"""Get or create the skill effect registry."""
	# Try to get from RunManager if it has one
	if RunManager.has_method("get_skill_registry"):
		return RunManager.get_skill_registry()

	# Create a temporary one with all effects registered
	var registry = SkillEffectRegistry.new()
	SkillEffects.register_all(registry)
	return registry


static func _get_trigger_description(trigger: String) -> String:
	"""Get a human-readable description of a trigger."""
	match trigger:
		"next_character_acquired":
			return "when you get a new character"
		"next_combat":
			return "before your next combat"
		"next_encounter":
			return "at your next encounter"
		"next_round":
			return "at the start of next round"
		_:
			return "later"


static func _can_afford(cost: int) -> bool:
	"""Check if player can afford the cost."""
	return RunManager.get_gold() >= cost


static func _show_result(message: String, color: Color) -> void:
	"""Show result message."""
	if _result_label:
		_result_label.text = message
		_result_label.add_theme_color_override("font_color", color)
		_result_label.visible = true


static func get_reward_preview(_encounter_data: Dictionary) -> String:
	"""Get reward preview for skill trainer encounter."""
	return "Learn Skill"
