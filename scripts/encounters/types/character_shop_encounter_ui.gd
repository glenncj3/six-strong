class_name CharacterShopEncounterUI
extends RefCounted
## UI creation and reward preview for character shop encounters.
## Displays 2-3 characters from the run pool for purchase.
## Players spend gold to add characters to their grid.
##
## Phase 6 Implementation:
## - Characters come from RunPool (level-gated)
## - Handles grid-full scenario by triggering replacement popup
## - Shows name, stats preview, cost

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create character shop encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var offerings: Array = encounter_data["data"].get("offerings", [])
	var on_complete: Callable = context.get("on_encounter_complete", Callable())
	var on_gold_spend: Callable = context.get("on_gold_spend", Callable())
	var tiles: Array = []

	if offerings.is_empty():
		vbox.add_child(UIHelpers.create_label("No adventurers available...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if on_complete.is_valid():
			on_complete.call()
		return vbox

	# Create horizontal container for character tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = UIScaler.calculate_tile_size(GameConstants.DESIGN_WIDTH, GameConstants.TEAM_SIZE, 48.0, 8.0, 180.0)

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

	var mana = base_stats.get(GameConstants.STAT_MANA, 0)
	if mana > 0:
		parts.append("MP:%d" % mana)

	var defend = base_stats.get(GameConstants.STAT_DEFEND_RATE, 0)
	if defend > 0:
		parts.append("DEF:%d%%" % defend)

	if parts.is_empty():
		return "New recruit"

	return " ".join(parts)


static func _setup_tile(tile: Control, tile_data: Dictionary, tile_size: float, state: Dictionary) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(tile_data, tile_size)

	# Use character's display_color if available, otherwise default
	var display_color_str = tile_data.get("display_color", "")
	if not display_color_str.is_empty():
		tile.set_tile_color(Color(display_color_str))
	else:
		# Default color for characters without display_color (they have images)
		tile.set_tile_color(GameConstants.COLOR_PANEL_DARK)

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
		# Grid is full - RunManager will emit signal for replacement popup
		_show_animated_result(result_label, "Party full!", GameConstants.COLOR_WARNING, false)
		# Don't complete yet - wait for replacement
		_wait_for_replacement(state)
	else:
		var char_name = tile_data.get("name", "Character")
		_show_animated_result(result_label, "Recruited %s!" % char_name, GameConstants.COLOR_SUCCESS)
		_complete_encounter(state)


static func _wait_for_replacement(state: Dictionary) -> void:
	"""Wait for the player to complete or cancel character replacement."""
	# Use CONNECT_ONE_SHOT with bound state - no static variable needed
	# The signal auto-disconnects after firing once, and state is passed directly
	RunManager.character_acquired.connect(_on_replacement_completed.bind(state), CONNECT_ONE_SHOT)


static func _on_replacement_completed(_character, state: Dictionary) -> void:
	"""Called when character replacement is completed."""
	# Signal auto-disconnected via CONNECT_ONE_SHOT, state passed via bind()
	var result_label: Label = state.get("result_label")
	if result_label:
		_show_animated_result(result_label, "New member joined!", GameConstants.COLOR_SUCCESS)
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
