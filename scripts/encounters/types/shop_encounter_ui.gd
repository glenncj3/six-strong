class_name ShopEncounterUI
extends RefCounted
## UI creation and reward preview for shop encounters.
## Shows up to 3 offerings (items/skills) in tiles.
##
## Phase 2 Refactor:
## - Items go directly to player inventory (no character selection)
## - Skills are instant effects (no character selection needed)
## - Simplified purchase flow without popup character picker

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")

# Store references for callback access
static var _selected_offering: Dictionary = {}
static var _on_complete: Callable = Callable()
static var _on_gold_spend: Callable = Callable()
static var _tiles: Array = []
static var _main_container: Control = null
static var _max_purchases: int = 1
static var _purchases_made: int = 0
static var _result_label: Label = null


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create shop encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)
	_main_container = vbox

	var offerings: Array = encounter_data["data"].get("offerings", [])
	_max_purchases = encounter_data["data"].get("max_purchases", 1)
	_purchases_made = 0
	_on_complete = context.get("on_encounter_complete", Callable())
	_on_gold_spend = context.get("on_gold_spend", Callable())
	_selected_offering = {}
	_tiles.clear()
	_result_label = null

	if offerings.is_empty():
		vbox.add_child(UIHelpers.create_label("Nothing for sale...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if _on_complete.is_valid():
			_on_complete.call()
		return vbox

	# Create horizontal container for offering tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = UIScaler.calculate_tile_size(GameConstants.DESIGN_WIDTH, GameConstants.TEAM_SIZE, 48.0, 8.0, 180.0)

	for i in range(offerings.size()):
		var offering = offerings[i]
		# Build tile data
		var tile_data = offering.duplicate()

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


static func _setup_tile(tile: Control, tile_data: Dictionary, tile_size: float) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(tile_data, tile_size)
	# Color based on type: items are brown/gold, skills are purple
	if tile_data.get("offering_type") == "skill":
		tile.set_tile_color(GameConstants.COLOR_AMETHYST)
	else:
		tile.set_tile_color(Color("#5A4A3A"))
	tile.tile_clicked.connect(_on_offering_selected)


static func _on_offering_selected(tile_data: Dictionary) -> void:
	"""Handle offering tile selection - purchase immediately (Phase 2)."""
	_selected_offering = tile_data

	var offering_id = tile_data.get("id", "")
	var offering_type = tile_data.get("offering_type", "item")
	var cost = tile_data.get("cost", 0)

	# Check if player can afford
	if not _can_afford(cost):
		_show_result("Not enough gold!", GameConstants.COLOR_ERROR)
		return

	# Check if item already owned
	if offering_type == "item":
		if RunManager.has_item_in_inventory(offering_id):
			_show_result("Already owned!", GameConstants.COLOR_ERROR)
			return

	# Spend gold
	if not EncounterUIHelpers.try_spend_gold(cost, _on_gold_spend):
		_show_result("Purchase failed!", GameConstants.COLOR_ERROR)
		return

	# Apply the reward - no character selection needed
	var success = false
	if offering_type == "skill":
		# Phase 3 TODO: Skills are instant effects
		# For now, just acknowledge the purchase
		success = true
		_show_result("Used skill!", GameConstants.COLOR_SUCCESS)
	else:
		# Add item to player inventory
		var item = RunManager.add_item_to_inventory(offering_id)
		success = item != null
		if success:
			var item_data = GameData.get_item_upgrade_by_id(offering_id)
			_show_result("Acquired %s!" % item_data.get("name", "Item"), GameConstants.COLOR_SUCCESS)
		else:
			# Refund gold if item couldn't be added
			RunManager.add_gold(cost)
			_show_result("Failed to acquire item!", GameConstants.COLOR_ERROR)

	if success:
		_purchases_made += 1

		# Dim the selected tile (it's been purchased)
		for tile in _tiles:
			if tile.tile_data.get("id") == offering_id:
				tile.modulate = GameConstants.COLOR_TILE_DIMMED
				tile.set_clickable(false)
				break

		# Check if we've reached max purchases
		if _purchases_made >= _max_purchases:
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
