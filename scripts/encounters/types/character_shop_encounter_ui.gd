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

# Store references for callback access
static var _selected_character: Dictionary = {}
static var _on_complete: Callable = Callable()
static var _on_gold_spend: Callable = Callable()
static var _tiles: Array = []
static var _main_container: Control = null
static var _result_label: Label = null
static var _purchases_made: int = 0


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create character shop encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)
	_main_container = vbox

	var offerings: Array = encounter_data["data"].get("offerings", [])
	_on_complete = context.get("on_encounter_complete", Callable())
	_on_gold_spend = context.get("on_gold_spend", Callable())
	_selected_character = {}
	_tiles.clear()
	_purchases_made = 0
	_result_label = null

	if offerings.is_empty():
		vbox.add_child(UIHelpers.create_label("No adventurers available...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if _on_complete.is_valid():
			_on_complete.call()
		return vbox

	# Instructions label
	var instructions = UIHelpers.create_label("Hire a new party member:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true)
	vbox.add_child(instructions)

	# Create horizontal container for character tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = UIScaler.calculate_tile_size(GameConstants.DESIGN_WIDTH, GameConstants.TEAM_SIZE, 48.0, 8.0, 180.0)

	for i in range(offerings.size()):
		var offering = offerings[i]
		# Build tile data for character
		var tile_data = _build_character_tile_data(offering)

		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		tile.ready.connect(_setup_tile.bind(tile, tile_data, tile_size))
		_tiles.append(tile)

	# Add spacer and result label area
	vbox.add_child(UIHelpers.create_spacer(8))
	_result_label = UIHelpers.create_label("", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_SUCCESS, true)
	_result_label.visible = false
	vbox.add_child(_result_label)

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


static func _setup_tile(tile: Control, tile_data: Dictionary, tile_size: float) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(tile_data, tile_size)
	# Use a distinct green/brown color for character shop
	tile.set_tile_color(Color("#4A5A3A"))
	tile.tile_clicked.connect(_on_character_selected)


static func _on_character_selected(tile_data: Dictionary) -> void:
	"""Handle character tile selection - purchase immediately."""
	_selected_character = tile_data

	var char_id = tile_data.get("id", "")
	var cost = tile_data.get("cost", 0)

	# Check if player can afford
	if not _can_afford(cost):
		_show_result("Not enough gold!", GameConstants.COLOR_ERROR)
		return

	# Spend gold
	if not EncounterUIHelpers.try_spend_gold(cost, _on_gold_spend):
		_show_result("Purchase failed!", GameConstants.COLOR_ERROR)
		return

	# Try to acquire the character
	var result = RunManager.acquire_character(char_id)

	if not result.get("success", false):
		# Refund gold
		RunManager.add_gold(cost)
		_show_result("Failed to recruit!", GameConstants.COLOR_ERROR)
		return

	# Dim the selected tile
	for tile in _tiles:
		if tile.tile_data.get("id") == char_id:
			tile.modulate = GameConstants.COLOR_TILE_DIMMED
			tile.set_clickable(false)
			break

	_purchases_made += 1

	if result.get("grid_full", false):
		# Grid is full - RunManager will emit signal for replacement popup
		_show_result("Party full! Choose who to replace...", GameConstants.COLOR_WARNING)
		# Don't complete yet - wait for replacement
		_wait_for_replacement()
	else:
		var char_name = tile_data.get("name", "Character")
		_show_result("Recruited %s!" % char_name, GameConstants.COLOR_SUCCESS)
		_complete_encounter()


static func _wait_for_replacement() -> void:
	"""Wait for the player to complete or cancel character replacement."""
	# Connect to RunManager signals for replacement result
	if not RunManager.character_acquired.is_connected(_on_replacement_completed):
		RunManager.character_acquired.connect(_on_replacement_completed)


static func _on_replacement_completed(_character) -> void:
	"""Called when character replacement is completed."""
	# Disconnect signal
	if RunManager.character_acquired.is_connected(_on_replacement_completed):
		RunManager.character_acquired.disconnect(_on_replacement_completed)

	_show_result("New member joined!", GameConstants.COLOR_SUCCESS)
	_complete_encounter()


static func _complete_encounter() -> void:
	"""Complete the encounter."""
	# Always complete after one purchase (like shop)
	if _on_complete.is_valid():
		_on_complete.call()


static func _can_afford(cost: int) -> bool:
	"""Check if player can afford the cost."""
	return RunManager.get_gold() >= cost


static func _show_result(message: String, color: Color) -> void:
	"""Show result message."""
	if _result_label:
		_result_label.text = message
		_result_label.add_theme_color_override("font_color", color)
		_result_label.visible = true


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for character shop encounter."""
	var offerings = encounter_data.get("data", {}).get("offerings", [])
	if offerings.is_empty():
		return "Hire Adventurers"
	return "%d Mercenaries" % offerings.size()
