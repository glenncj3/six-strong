class_name CharacterShopEncounterUI
extends RefCounted
## UI creation and reward preview for character shop encounters.
##
## Auto-registration metadata (Phase 4):
const ENCOUNTER_TYPE := "character_shop"
## Displays 2-3 characters from the run pool for purchase.
## Players spend gold to add characters to their grid.
##
## Phase 6 Implementation:
## - Characters come from RunPool (level-gated)
## - Handles grid-full scenario by triggering replacement popup
## - Shows name, stats preview, cost

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")
const CharacterReplacementPopupScene = preload("res://scenes/components/character_replacement_popup.tscn")


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create character shop encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var offerings: Array = encounter_data["data"].get("offerings", [])
	var on_complete: Callable = context.get("on_encounter_complete", Callable())
	var on_gold_spend: Callable = context.get("on_gold_spend", Callable())
	var tiles: Array = []

	if offerings.is_empty():
		EncounterUIHelpers.handle_empty_offerings(vbox, "No adventurers available...", on_complete)
		return vbox

	# Create horizontal container for character tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = EncounterUIHelpers.calculate_purchasable_tile_size()

	# Add spacer and result label area (create before tiles so state is ready)
	vbox.add_child(UIHelpers.create_spacer(16))
	var result_label = Label.new()
	result_label.theme_type_variation = "HeaderLabel"
	result_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_HEADING)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.modulate.a = 0.0
	vbox.add_child(result_label)

	# Create state dictionary to pass through bindings
	var state = {
		"tiles": tiles,
		"result_label": result_label,
		"purchases_made": 0,
		"on_complete": on_complete,
		"on_gold_spend": on_gold_spend
	}

	# Create and setup tiles in single pass - call _setup_tile directly after add_child
	# (ready signal fires during add_child, so connecting after would be too late)
	for i in range(offerings.size()):
		var offering = offerings[i]
		var tile_data = _build_character_tile_data(offering)
		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		tiles.append(tile)
		_setup_tile(tile, tile_data, tile_size, state)

	return vbox


static func _build_character_tile_data(offering: Dictionary) -> Dictionary:
	"""Build tile data from character offering."""
	var base_stats = offering.get("base_stats", {})
	var stat_preview = _format_stat_preview(base_stats)

	return {
		"id": offering.get("id", ""),
		"offering_type": "character",
		"name": offering.get("name", "Unknown"),
		"description": stat_preview,
		"image_path": offering.get("image_path", ""),
		"display_color": offering.get("display_color", ""),
		"cost": offering.get("cost", 40),
		"level_requirement": offering.get("level_requirement", 1),
		"base_stats": base_stats
	}


static func _format_stat_preview(base_stats: Dictionary) -> String:
	"""Format stats for display on tile."""
	var parts: Array = []

	var health = base_stats.get(GameConstants.STAT_HEALTH, 0)
	if health > 0:
		parts.append("HP:%d" % health)

	var charges = base_stats.get(GameConstants.STAT_CHARGES, 0)
	if charges > 0:
		parts.append("MP:%d" % charges)

	var defend = base_stats.get(GameConstants.STAT_agility, 0)
	if defend > 0:
		parts.append("DEF:%d%%" % defend)

	if parts.is_empty():
		return "New recruit"

	return " ".join(parts)


static func _setup_tile(tile: Control, tile_data: Dictionary, tile_size: float, state: Dictionary) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(tile_data, tile_size)
	tile.tile_clicked.connect(_on_character_selected.bind(state))


static func _on_character_selected(tile_data: Dictionary, state: Dictionary) -> void:
	"""Handle character tile selection - purchase immediately."""
	var tiles: Array = state.tiles
	var result_label: Label = state.result_label
	var on_gold_spend: Callable = state.on_gold_spend

	var char_id = tile_data.get("id", "")
	var cost = tile_data.get("cost", 0)

	# Check if player can afford
	if not SkillEncounterHelpers.can_afford(cost):
		_show_animated_result(result_label, "Not enough gold!", GameConstants.COLOR_ERROR)
		return

	# Spend gold
	if not EncounterUIHelpers.try_spend_gold(cost, on_gold_spend):
		_show_animated_result(result_label, "Purchase failed!", GameConstants.COLOR_ERROR)
		return

	# Try to acquire the character
	var result = RunManager.acquire_character(char_id)

	if not result.get("success", false):
		# Refund gold
		RunManager.add_gold(cost)
		_show_animated_result(result_label, "Failed to recruit!", GameConstants.COLOR_ERROR)
		return

	# Dim the selected tile
	SkillEncounterHelpers.dim_tile_by_id(tiles, char_id)

	state.purchases_made += 1

	if result.get("grid_full", false):
		# Grid is full - show replacement popup
		_show_animated_result(result_label, "Choose who to replace!", GameConstants.COLOR_WARNING, false)
		_show_replacement_popup(tile_data, cost, state)
	else:
		var char_name = tile_data.get("name", "Character")
		_show_animated_result(result_label, "Recruited %s!" % char_name, GameConstants.COLOR_SUCCESS)
		_complete_encounter(state)


static func _show_replacement_popup(tile_data: Dictionary, cost: int, state: Dictionary) -> void:
	"""Show the character replacement popup when grid is full."""
	var pending_character = RunManager.get_pending_character()
	var grid = RunManager.get_character_grid()

	if not pending_character or not grid:
		# Shouldn't happen, but refund and fail gracefully
		RunManager.add_gold(cost)
		_show_animated_result(state.result_label, "Recruitment failed!", GameConstants.COLOR_ERROR)
		_complete_encounter(state)
		return

	# Create and show popup
	var popup = CharacterReplacementPopupScene.instantiate()

	# Add to scene tree (will be reparented by ModalPopup base)
	var scene_tree = Engine.get_main_loop() as SceneTree
	scene_tree.root.add_child(popup)

	# Connect signals before showing
	popup.character_replaced.connect(_on_replacement_confirmed.bind(tile_data, state), CONNECT_ONE_SHOT)
	popup.replacement_cancelled.connect(_on_replacement_cancelled.bind(cost, state), CONNECT_ONE_SHOT)

	# Show the popup
	popup.show_replacement(pending_character, grid)


static func _on_replacement_confirmed(_removed: CharacterInstance, _slot: Vector2i, tile_data: Dictionary, state: Dictionary) -> void:
	"""Called when player confirms character replacement."""
	var new_character = RunManager.get_pending_character()

	# Clear the pending character
	RunManager.cancel_pending_character()

	if new_character:
		# Popup already modified the grid directly, just emit signal and save
		RunManager.character_acquired.emit(new_character)
		RunManager.trigger_character_acquired_effects(new_character)
		RunManager.save_run_state()

	var char_name = tile_data.get("name", "Character")
	_show_animated_result(state.result_label, "Recruited %s!" % char_name, GameConstants.COLOR_SUCCESS)
	_complete_encounter(state)


static func _on_replacement_cancelled(cost: int, state: Dictionary) -> void:
	"""Called when player cancels character replacement."""
	# Refund the gold
	RunManager.add_gold(cost)
	RunManager.cancel_pending_character()

	_show_animated_result(state.result_label, "Recruitment cancelled", GameConstants.COLOR_TEXT_LIGHT)
	_complete_encounter(state)


static func _show_animated_result(label: Label, message: String, color: Color, fade_out: bool = true) -> void:
	"""Show result message with pop-up and fade animation."""
	if not label:
		return

	# Kill any existing tween on this label
	var existing_tweens = label.get_tree().get_processed_tweens()
	for tween in existing_tweens:
		if not tween.is_valid():
			continue
		# Can't check tween target directly, so we just set up fresh

	label.text = message
	label.add_theme_color_override("font_color", color)

	# Reset state for animation
	label.scale = Vector2(0.5, 0.5)
	label.pivot_offset = label.size / 2
	label.modulate.a = 0.0

	var tween = label.create_tween()
	tween.set_parallel(true)

	# Pop in: scale up and fade in
	tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "modulate:a", 1.0, 0.1)

	# Settle to normal scale
	tween.set_parallel(false)
	tween.tween_property(label, "scale", Vector2.ONE, 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Fade out after delay (if enabled)
	if fade_out:
		tween.tween_interval(1.5)
		tween.tween_property(label, "modulate:a", 0.0, 0.5)


static func _complete_encounter(state: Dictionary) -> void:
	"""Complete the encounter."""
	var on_complete: Callable = state.on_complete
	# Always complete after one purchase (like shop)
	if on_complete.is_valid():
		on_complete.call()


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for character shop encounter."""
	var offerings = encounter_data.get("data", {}).get("offerings", [])
	if offerings.is_empty():
		return "Hire Adventurers"
	return "%d Mercenaries" % offerings.size()
