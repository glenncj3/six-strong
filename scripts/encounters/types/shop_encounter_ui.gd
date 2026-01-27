class_name ShopEncounterUI
extends RefCounted
## UI creation and reward preview for shop encounters.
##
## Auto-registration metadata (Phase 4):
const ENCOUNTER_TYPE := "shop"
## Shows up to 3 offerings (items/skills) in tiles.
##
## Phase 2 Refactor:
## - Items go directly to player inventory (no character selection)
##
## Phase 3 Refactor:
## - Skills are one-shot effects that execute immediately
## - No character assignment for skills
## - Show effect preview before purchase

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create shop encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var offerings: Array = encounter_data["data"].get("offerings", [])
	var max_purchases: int = encounter_data["data"].get("max_purchases", 1)
	var on_complete: Callable = context.get("on_encounter_complete", Callable())
	var on_gold_spend: Callable = context.get("on_gold_spend", Callable())
	var tiles: Array = []

	if offerings.is_empty():
		vbox.add_child(UIHelpers.create_label("Nothing for sale...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if on_complete.is_valid():
			on_complete.call()
		return vbox

	# Create horizontal container for offering tiles
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
		"max_purchases": max_purchases,
		"purchases_made": 0,
		"on_complete": on_complete,
		"on_gold_spend": on_gold_spend
	}

	# Create and setup tiles in single pass - call _setup_tile directly after add_child
	# (ready signal fires during add_child, so connecting after would be too late)
	for i in range(offerings.size()):
		var offering = offerings[i]
		var tile_data = offering.duplicate()
		if tile_data.get("offering_type") == "skill":
			_enrich_skill_tile_data(tile_data)

		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		tiles.append(tile)
		_setup_tile(tile, tile_data, tile_size, state)

	return vbox


static func _enrich_skill_tile_data(tile_data: Dictionary) -> void:
	"""Add effect preview information to skill tile data."""
	var skill_id = tile_data.get("id", "")
	if skill_id.is_empty():
		return

	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		return

	# Add effect preview to description
	var effect = skill_data.get("effect", {})
	if not effect.is_empty():
		var effect_desc = SkillEffects.get_effect_description(effect)
		tile_data["effect_preview"] = effect_desc
		# Append effect preview to description if not already there
		var desc = tile_data.get("description", skill_data.get("description", ""))
		if not desc.contains(effect_desc):
			tile_data["description"] = desc

	# Copy effect type for display purposes
	tile_data["effect_type"] = skill_data.get("effect_type", "instant")
	tile_data["effect"] = skill_data.get("effect", {})
	tile_data["trigger"] = skill_data.get("trigger", "")


static func _setup_tile(tile: Control, tile_data: Dictionary, tile_size: float, state: Dictionary) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(tile_data, tile_size)
	# Color based on type: items are brown/gold, skills are purple
	if tile_data.get("offering_type") == "skill":
		tile.set_tile_color(GameConstants.COLOR_AMETHYST)
	else:
		tile.set_tile_color(Color("#5A4A3A"))
	tile.tile_clicked.connect(_on_offering_selected.bind(state))


static func _on_offering_selected(tile_data: Dictionary, state: Dictionary) -> void:
	"""Handle offering tile selection - purchase immediately."""
	var tiles: Array = state.tiles
	var result_label: Label = state.result_label
	var on_complete: Callable = state.on_complete
	var on_gold_spend: Callable = state.on_gold_spend
	var max_purchases: int = state.max_purchases

	var offering_id = tile_data.get("id", "")
	var offering_type = tile_data.get("offering_type", "item")
	var cost = tile_data.get("cost", 0)

	# Check if player can afford
	if not SkillEncounterHelpers.can_afford(cost):
		SkillEncounterHelpers.show_result(result_label, "Not enough gold!", GameConstants.COLOR_ERROR)
		return

	# Check if item already owned
	if offering_type == "item":
		if RunManager.has_item_in_inventory(offering_id):
			SkillEncounterHelpers.show_result(result_label, "Already owned!", GameConstants.COLOR_ERROR)
			return

	# Spend gold
	if not EncounterUIHelpers.try_spend_gold(cost, on_gold_spend):
		SkillEncounterHelpers.show_result(result_label, "Purchase failed!", GameConstants.COLOR_ERROR)
		return

	# Apply the reward - no character selection needed
	var success = false
	if offering_type == "skill":
		# Execute skill effect immediately
		var result = SkillEncounterHelpers.execute_skill(tile_data)
		success = result.success
		var color = GameConstants.COLOR_SUCCESS if success else GameConstants.COLOR_ERROR
		SkillEncounterHelpers.show_result(result_label, result.message, color)
		if not success:
			# Refund gold
			RunManager.add_gold(cost)
	else:
		# Add item to player inventory
		var item = RunManager.add_item_to_inventory(offering_id)
		success = item != null
		if success:
			var item_data = GameData.get_item_upgrade_by_id(offering_id)
			SkillEncounterHelpers.show_result(result_label, "Acquired %s!" % item_data.get("name", "Item"), GameConstants.COLOR_SUCCESS)
		else:
			# Refund gold if item couldn't be added
			RunManager.add_gold(cost)
			SkillEncounterHelpers.show_result(result_label, "Failed to acquire item!", GameConstants.COLOR_ERROR)

	if success:
		state.purchases_made += 1

		# Dim the selected tile (it's been purchased)
		SkillEncounterHelpers.dim_tile_by_id(tiles, offering_id)

		# Check if we've reached max purchases
		if state.purchases_made >= max_purchases:
			if on_complete.is_valid():
				on_complete.call()


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for shop encounter."""
	var offerings = encounter_data.get("data", {}).get("offerings", [])
	if offerings.is_empty():
		return "Shop"
	var item_count = 0
	var skill_count = 0
	for offering in offerings:
		if offering.get("offering_type") == "skill":
			skill_count += 1
		else:
			item_count += 1
	var parts = []
	if item_count > 0:
		parts.append("%d item%s" % [item_count, "s" if item_count > 1 else ""])
	if skill_count > 0:
		parts.append("%d skill%s" % [skill_count, "s" if skill_count > 1 else ""])
	return ", ".join(parts) if parts.size() > 0 else "Shop"
