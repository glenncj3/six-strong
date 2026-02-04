class_name SkillTrainerEncounterUI
extends RefCounted
## UI creation and reward preview for skill trainer encounters.
##
## Auto-registration metadata (Phase 4):
const ENCOUNTER_ID := "skill_trainer"
## Shows 3 skill options that execute immediately on purchase.
##
## Phase 3 Refactor:
## - Skills are one-shot effects that execute immediately
## - No character assignment needed
## - Shows effect preview before purchase

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create skill trainer encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var skill_ids: Array = encounter_data["data"].get("skill_ids", [])
	var on_complete: Callable = context.get("on_encounter_complete", Callable())
	var on_gold_spend: Callable = context.get("on_gold_spend", Callable())
	var tiles: Array = []

	if skill_ids.is_empty():
		EncounterUIHelpers.handle_empty_offerings(vbox, "No skills available...", on_complete)
		return vbox

	# Add instruction label
	var instruction = UIHelpers.create_label("Select a skill to use:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true)
	vbox.add_child(instruction)
	vbox.add_child(UIHelpers.create_spacer(4))

	# Create horizontal container for skill tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = EncounterUIHelpers.calculate_purchasable_tile_size()

	# Add spacer and result label area (create before tiles so state is ready)
	vbox.add_child(UIHelpers.create_spacer(8))
	var result_label = UIHelpers.create_label("", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_SUCCESS, true)
	result_label.visible = false
	vbox.add_child(result_label)

	# Create state dictionary to pass through bindings
	var state = {
		"tiles": tiles,
		"result_label": result_label,
		"on_complete": on_complete,
		"on_gold_spend": on_gold_spend
	}

	# Create and setup tiles in single pass - call _setup_tile directly after add_child
	# (ready signal fires during add_child, so connecting after would be too late)
	for i in range(skill_ids.size()):
		var skill_id = skill_ids[i]
		var skill_data = GameData.get_skill_by_id(skill_id)
		if skill_data.is_empty():
			continue

		var tile_data = _build_skill_tile_data(skill_data)
		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		tiles.append(tile)
		_setup_tile(tile, tile_data, tile_size, state)

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
	tile_data["requires_target"] = SkillEncounterHelpers.skill_requires_target(skill_data)

	return tile_data


static func _setup_tile(tile: Control, skill_data: Dictionary, tile_size: float, state: Dictionary) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(skill_data, tile_size)
	tile.set_tile_color(GameConstants.COLOR_AMETHYST)
	tile.tile_clicked.connect(_on_skill_selected.bind(state))


static func _on_skill_selected(skill_data: Dictionary, state: Dictionary) -> void:
	"""Handle skill tile selection - purchase and execute immediately."""
	var tiles: Array = state.tiles
	var result_label: Label = state.result_label
	var on_complete: Callable = state.on_complete
	var on_gold_spend: Callable = state.on_gold_spend

	var skill_id = skill_data.get("id", "")
	var cost = skill_data.get("cost", 0)

	# Check if player can afford
	if not SkillEncounterHelpers.can_afford(cost):
		SkillEncounterHelpers.show_result(result_label, "Not enough gold!", GameConstants.COLOR_ERROR)
		return

	# Check if skill requires a target
	var requires_target = skill_data.get("requires_target", false)
	var drop_target = skill_data.get("drop_target", null)

	if requires_target and drop_target == null:
		SkillEncounterHelpers.show_result(result_label, "Drag onto a character to use!", GameConstants.COLOR_ERROR)
		return

	# Spend gold
	if not EncounterUIHelpers.try_spend_gold(cost, on_gold_spend):
		SkillEncounterHelpers.show_result(result_label, "Purchase failed!", GameConstants.COLOR_ERROR)
		return

	# Execute the skill with optional drop target
	var result = SkillEncounterHelpers.execute_skill(skill_data, drop_target)
	var color = GameConstants.COLOR_SUCCESS if result.success else GameConstants.COLOR_ERROR
	SkillEncounterHelpers.show_result(result_label, result.message, color)

	if result.success:
		# Refresh team display to show updated stats
		_refresh_team_hud()

		# Dim the selected tile
		SkillEncounterHelpers.dim_tile_by_id(tiles, skill_id)

		# Complete encounter after successful skill use
		if on_complete.is_valid():
			on_complete.call()
	else:
		# Refund gold if skill failed
		RunManager.add_gold(cost)


static func _refresh_team_hud() -> void:
	"""Refresh the team HUD to show updated character stats."""
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		var team_hud = tree.get_first_node_in_group("team_hud")
		if team_hud and team_hud.has_method("refresh_display"):
			team_hud.refresh_display()


static func get_reward_preview(_encounter_data: Dictionary) -> String:
	"""Get reward preview for skill trainer encounter."""
	return "Learn Skill"
