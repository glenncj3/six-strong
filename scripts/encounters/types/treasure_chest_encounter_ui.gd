class_name TreasureChestEncounterUI
extends RefCounted
## UI creation and reward preview for treasure chest encounters.
##
## Auto-registration metadata (Phase 4):
const ENCOUNTER_TYPE := "treasure_chest"
## Shows 3 mystery item options with different elements. Player picks one to reveal
## a random item of that element, which goes directly to player inventory.
##
## Phase 2 Refactor:
## - Items go to player inventory (no character selection)
## - Simplified UI flow without character picker

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create treasure chest encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var mystery_options: Array = encounter_data["data"].get("mystery_options", [])
	var gold_bonus: int = encounter_data["data"].get("gold_bonus", 2)
	var on_complete: Callable = context.get("on_encounter_complete", Callable())
	var on_gold_reward: Callable = context.get("on_gold_reward", Callable())
	var tiles: Array = []

	if mystery_options.is_empty():
		EncounterUIHelpers.handle_empty_offerings(vbox, "The chest is empty...", on_complete)
		return vbox

	# Instructions label
	var instructions = UIHelpers.create_label("Choose a mystery item:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true)
	vbox.add_child(instructions)

	# Create horizontal container for mystery option tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = EncounterUIHelpers.calculate_purchasable_tile_size()

	# Create and setup tiles in single pass - call _setup_tile directly after add_child
	# (ready signal fires during add_child, so connecting after would be too late)
	for i in range(mystery_options.size()):
		var option = mystery_options[i]
		var tile_data = {
			"id": option["element"],
			"element": option["element"],
			"name": "Random %s Item" % option["display_name"],
			"description": "+%d Gold" % gold_bonus,
			"image_path": _get_element_image(option["element"]),
			"cost": 0  # Free, but gives gold!
		}

		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		tiles.append(tile)
		_setup_tile(tile, tile_data, tile_size, option["element"], tiles, vbox, gold_bonus, on_complete, on_gold_reward)

	return vbox


static func _setup_tile(tile: Control, tile_data: Dictionary, tile_size: float, element: String, tiles: Array, container: Control, gold_bonus: int, on_complete: Callable, on_gold_reward: Callable) -> void:
	"""Setup tile after it enters the scene tree."""
	# Defer setup until tile enters the scene tree and @onready vars are initialized
	tile.ready.connect(func(): tile.setup(tile_data, tile_size), CONNECT_ONE_SHOT)
	# Color tile based on element
	tile.set_tile_color(_get_element_color(element))
	# Bind all required state to the click handler
	tile.tile_clicked.connect(_on_option_selected.bind(tiles, container, gold_bonus, on_complete, on_gold_reward))


static func _on_option_selected(tile_data: Dictionary, tiles: Array, container: Control, gold_bonus: int, on_complete: Callable, on_gold_reward: Callable) -> void:
	"""Handle mystery option tile selection - reveal and acquire the item immediately."""
	# Dim all tiles and highlight selected (disable further selection)
	EncounterUIHelpers.highlight_selected_tile(tiles, tile_data, "id", false)

	# Pick a random item of this element that's not already owned
	var element = tile_data.get("element", "")
	var revealed_item_id = _pick_random_item_of_element(element)

	if revealed_item_id.is_empty():
		# No valid item found - give gold instead
		_show_no_item_fallback(container, gold_bonus, on_complete, on_gold_reward)
		return

	# Add item to player inventory and show result
	_acquire_item_and_complete(revealed_item_id, container, gold_bonus, on_complete, on_gold_reward)


static func _pick_random_item_of_element(element: String) -> String:
	"""Pick a random item of the given element that's not in player inventory."""
	var all_items = GameData.get_all_item_upgrades()
	var max_level = RunManager.get_player_level()

	var valid_items: Array = []

	for item in all_items:
		if item.get("element", "neutral") != element:
			continue

		var item_id = item["id"]
		var level_req = item.get("level_requirement", 1)

		# Check level requirement
		if level_req > max_level:
			continue

		# Check if already in player inventory
		if RunManager.has_item_in_inventory(item_id):
			continue

		valid_items.append(item_id)

	if valid_items.is_empty():
		return ""

	valid_items.shuffle()
	return valid_items[0]


static func _show_no_item_fallback(container: Control, gold_bonus: int, on_complete: Callable, on_gold_reward: Callable) -> void:
	"""Show message when no item is available, give gold instead."""
	# Give extra gold as compensation
	var fallback_gold = gold_bonus * 3

	EncounterUIHelpers.try_reward_gold(fallback_gold, on_gold_reward)

	# Show message
	var msg = UIHelpers.create_label(
		"No items available! Received +%d Gold instead." % fallback_gold,
		GameConstants.FONT_SIZE_BODY,
		GameConstants.COLOR_GOLD,
		true
	)
	container.add_child(msg)

	if on_complete.is_valid():
		on_complete.call()


static func _acquire_item_and_complete(item_id: String, container: Control, gold_bonus: int, on_complete: Callable, on_gold_reward: Callable) -> void:
	"""Add item to player inventory and complete the encounter."""
	# Add item to inventory
	var item = RunManager.add_item_to_inventory(item_id)

	# Award gold bonus
	EncounterUIHelpers.try_reward_gold(gold_bonus, on_gold_reward)

	if item != null:
		# Show what was acquired
		var item_data = GameData.get_item_upgrade_by_id(item_id)
		var item_name = item_data.get("name", "Item")

		var result_label = UIHelpers.create_label(
			"Acquired: %s (+%dg)" % [item_name, gold_bonus],
			GameConstants.FONT_SIZE_BODY,
			GameConstants.COLOR_SUCCESS,
			true
		)
		container.add_child(result_label)
	else:
		# Item failed to add - give extra gold as compensation
		var fallback_gold = gold_bonus * 2
		EncounterUIHelpers.try_reward_gold(fallback_gold, on_gold_reward)
		var result_label = UIHelpers.create_label(
			"Item unavailable! +%dg instead" % (gold_bonus + fallback_gold),
			GameConstants.FONT_SIZE_BODY,
			GameConstants.COLOR_GOLD,
			true
		)
		container.add_child(result_label)

	# Complete encounter
	if on_complete.is_valid():
		on_complete.call()


static func _get_element_color(element: String) -> Color:
	"""Get display color for an element."""
	match element:
		"fire":
			return Color("#AA3333")
		"earth":
			return Color("#8B7355")
		"arcane":
			return Color("#6A3A8A")
		"shadow":
			return Color("#3A3A4A")
		"ice":
			return Color("#4A7A9A")
		"lightning":
			return Color("#9A8A3A")
		_:
			return Color("#5A5A5A")


static func _get_element_image(_element: String) -> String:
	"""Get placeholder image path for an element."""
	# Use chest image as placeholder for all mystery items
	return "res://assets/encounters/chest.png"


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for treasure chest encounter."""
	var gold_bonus = encounter_data.get("data", {}).get("gold_bonus", 2)
	return "Mystery Item +%dg" % gold_bonus
