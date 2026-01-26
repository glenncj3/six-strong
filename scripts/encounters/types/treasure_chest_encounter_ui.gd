class_name TreasureChestEncounterUI
extends RefCounted
## UI creation and reward preview for treasure chest encounters.
## Shows 3 mystery item options with different elements. Player picks one to reveal
## a random item of that element, then chooses which character receives it plus gold bonus.

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")
const RewardClaimPopupScene = preload("res://scenes/components/reward_claim_popup.tscn")

# Store references for callback access
static var _selected_option: Dictionary = {}
static var _revealed_item_id: String = ""
static var _on_complete: Callable = Callable()
static var _on_buy_item: Callable = Callable()
static var _on_gold_reward: Callable = Callable()
static var _tiles: Array = []
static var _main_container: Control = null
static var _reward_popup: RewardClaimPopup = null
static var _gold_bonus: int = 2


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create treasure chest encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)
	_main_container = vbox

	var mystery_options: Array = encounter_data["data"].get("mystery_options", [])
	_gold_bonus = encounter_data["data"].get("gold_bonus", 2)
	_on_complete = context.get("on_encounter_complete", Callable())
	_on_buy_item = context.get("on_buy_item", Callable())
	_on_gold_reward = context.get("on_gold_reward", Callable())
	_selected_option = {}
	_revealed_item_id = ""
	_tiles.clear()
	_reward_popup = null

	if mystery_options.is_empty():
		vbox.add_child(UIHelpers.create_label("The chest is empty...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if _on_complete.is_valid():
			_on_complete.call()
		return vbox

	# Instructions label
	var instructions = UIHelpers.create_label("Choose a mystery item:", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true)
	vbox.add_child(instructions)

	# Create horizontal container for mystery option tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = UIScaler.calculate_tile_size(GameConstants.DESIGN_WIDTH, GameConstants.TEAM_SIZE, 48.0, 8.0, 180.0)

	for i in range(mystery_options.size()):
		var option = mystery_options[i]
		# Build tile data for mystery option
		var tile_data = {
			"id": option["element"],
			"element": option["element"],
			"name": "Random %s Item" % option["display_name"],
			"description": "+%d Gold" % _gold_bonus,
			"image_path": _get_element_image(option["element"]),
			"cost": 0  # Free, but gives gold!
		}

		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		tile.ready.connect(_setup_tile.bind(tile, tile_data, tile_size, option["element"]))
		_tiles.append(tile)

	return vbox


static func _setup_tile(tile: Control, tile_data: Dictionary, tile_size: float, element: String) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(tile_data, tile_size)
	# Color tile based on element
	tile.set_tile_color(_get_element_color(element))
	tile.tile_clicked.connect(_on_option_selected)


static func _on_option_selected(tile_data: Dictionary) -> void:
	"""Handle mystery option tile selection - reveal the item immediately."""
	_selected_option = tile_data

	# Dim all tiles and highlight selected (disable further selection)
	EncounterUIHelpers.highlight_selected_tile(_tiles, tile_data, "id", false)

	# Pick a random item of this element now (before showing popup)
	var element = tile_data.get("element", "")
	_revealed_item_id = _pick_random_item_of_element_any_char(element)

	if _revealed_item_id.is_empty():
		# No valid item found - shouldn't happen with proper filtering
		_show_no_item_message()
		return

	# Show the reveal popup with the item
	_show_reward_popup()


static func _pick_random_item_of_element_any_char(element: String) -> String:
	"""Pick a random item of the given element that at least one character can equip."""
	var all_items = GameData.get_all_item_upgrades()
	var team = RunManager.get_team()
	var valid_items: Array = []

	for item in all_items:
		if item.get("element", "neutral") != element:
			continue

		var item_id = item["id"]
		var level_req = item.get("level_requirement", 1)

		# Check if at least one character can equip this
		for char_instance in team:
			if char_instance.level < level_req:
				continue
			if item_id in char_instance.equipped_item_upgrades:
				continue
			var total_items = char_instance.equipped_items.size() + char_instance.equipped_item_upgrades.size()
			if total_items >= GameConstants.MAX_RUN_ITEMS:
				continue
			# This character can equip it
			valid_items.append(item_id)
			break

	if valid_items.is_empty():
		return ""

	valid_items.shuffle()
	return valid_items[0]


static func _show_no_item_message() -> void:
	"""Show message when no item is available."""
	var msg = UIHelpers.create_label("Bad luck! No items available for this element.", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_DANGER, true)
	_main_container.add_child(msg)

	if _on_complete.is_valid():
		_on_complete.call()


static func _show_reward_popup() -> void:
	"""Show popup with revealed item using RewardClaimPopup component."""
	if _reward_popup:
		_reward_popup.queue_free()

	_reward_popup = RewardClaimPopupScene.instantiate()
	_main_container.add_child(_reward_popup)

	# Get eligible characters for this specific item
	var team = RunManager.get_team()
	var eligible = _filter_item_eligible_for_revealed(team, _revealed_item_id)

	# Connect to claimed signal
	_reward_popup.claimed.connect(_on_reward_claimed)

	# Show the item with gold bonus
	_reward_popup.show_item(
		_revealed_item_id,
		eligible.characters,
		eligible.indices,
		"You found:",
		"+%d Gold" % _gold_bonus,
		"Claim (+%dg)" % _gold_bonus
	)


static func _filter_item_eligible_for_revealed(team: Array, item_id: String) -> Dictionary:
	"""Filter team to characters who can equip the revealed item."""
	var indices: Array = []
	var characters: Array = []

	var item_data = GameData.get_item_upgrade_by_id(item_id)
	var level_req = item_data.get("level_requirement", 1)

	for i in range(team.size()):
		var char_instance = team[i]

		# Check level requirement
		if char_instance.level < level_req:
			continue

		# Check not already equipped
		if item_id in char_instance.equipped_item_upgrades:
			continue

		# Check has room
		var total_items = char_instance.equipped_items.size() + char_instance.equipped_item_upgrades.size()
		if total_items >= GameConstants.MAX_RUN_ITEMS:
			continue

		indices.append(i)
		characters.append(char_instance)

	return {"indices": indices, "characters": characters}


static func _on_reward_claimed(reward_id: String, char_index: int) -> void:
	"""Handle reward claim from popup."""
	var team = RunManager.get_team()
	var char_instance = team[char_index]

	# Award the item
	if _on_buy_item.is_valid():
		# Use buy callback with cost 0 (pass null for selector/button since popup handles UI)
		_on_buy_item.call(reward_id, 0, null, null)
	else:
		# Fallback: equip directly
		char_instance.equip_item_upgrade(reward_id)

	# Award gold bonus
	if _on_gold_reward.is_valid():
		_on_gold_reward.call(_gold_bonus)
	else:
		RunManager.add_gold(_gold_bonus)

	# Complete encounter
	if _on_complete.is_valid():
		_on_complete.call()


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


static func _get_element_image(element: String) -> String:
	"""Get placeholder image path for an element."""
	# Use chest image as placeholder for all mystery items
	return "res://assets/encounters/chest.png"


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for treasure chest encounter."""
	var gold_bonus = encounter_data.get("data", {}).get("gold_bonus", 2)
	return "Mystery Item +%dg" % gold_bonus
