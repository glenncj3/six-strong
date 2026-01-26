class_name ShopEncounterUI
extends RefCounted
## UI creation and reward preview for shop encounters.
## Shows up to 3 offerings (items/skills) in tiles, player picks one, popup shows details.

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")
const RewardClaimPopupScene = preload("res://scenes/components/reward_claim_popup.tscn")

# Store references for callback access
static var _selected_offering: Dictionary = {}
static var _on_complete: Callable = Callable()
static var _on_buy_item: Callable = Callable()
static var _on_buy_skill: Callable = Callable()
static var _on_gold_spend: Callable = Callable()
static var _tiles: Array = []
static var _reward_popup: RewardClaimPopup = null
static var _max_purchases: int = 1
static var _purchases_made: int = 0


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create shop encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var offerings: Array = encounter_data["data"].get("offerings", [])
	_max_purchases = encounter_data["data"].get("max_purchases", 1)
	_purchases_made = 0
	_on_complete = context.get("on_encounter_complete", Callable())
	_on_buy_item = context.get("on_buy_item", Callable())
	_on_buy_skill = context.get("on_buy_skill", Callable())
	_on_gold_spend = context.get("on_gold_spend", Callable())
	_selected_offering = {}
	_tiles.clear()
	_reward_popup = null

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
	"""Handle offering tile selection - show popup."""
	_selected_offering = tile_data

	# Highlight selected tile (allow reselection)
	EncounterUIHelpers.highlight_selected_tile(_tiles, tile_data, "id", true)

	# Show reward claim popup
	_show_offering_popup()


static func _show_offering_popup() -> void:
	"""Show popup with offering details and character selector."""
	if _reward_popup:
		_reward_popup.queue_free()

	_reward_popup = RewardClaimPopupScene.instantiate()
	# Add to scene tree so it can reparent itself
	var scene_root = Engine.get_main_loop().current_scene
	scene_root.add_child(_reward_popup)

	var offering_id = _selected_offering.get("id", "")
	var offering_type = _selected_offering.get("offering_type", "item")
	var cost = _selected_offering.get("cost", 0)

	# Get eligible characters
	var team = RunManager.get_team()
	var eligible: Dictionary
	if offering_type == "skill":
		eligible = EncounterUIHelpers.filter_skill_eligible_characters(team, offering_id)
	else:
		eligible = EncounterUIHelpers.filter_item_eligible_characters(team, offering_id)

	# Connect to signals
	_reward_popup.claimed.connect(_on_offering_claimed)

	# Determine button text based on type
	var action_text = "Learn" if offering_type == "skill" else "Equip"
	var button_text = "%dg and %s" % [cost, action_text]

	# Show the offering
	if offering_type == "skill":
		_reward_popup.show_skill(
			offering_id,
			eligible.characters,
			eligible.indices,
			"",  # No header
			"",  # No bonus text
			button_text,
			cost
		)
	else:
		_reward_popup.show_item(
			offering_id,
			eligible.characters,
			eligible.indices,
			"",  # No header
			"",  # No bonus text
			button_text,
			cost
		)


static func _on_offering_claimed(offering_id: String, char_index: int) -> void:
	"""Handle offering claim from popup."""
	var cost = _selected_offering.get("cost", 0)
	var offering_type = _selected_offering.get("offering_type", "item")

	# Spend gold
	if not EncounterUIHelpers.try_spend_gold(cost, _on_gold_spend):
		return

	var team = RunManager.get_team()
	var char_instance = team[char_index]

	# Apply the reward
	var success = false
	if offering_type == "skill":
		if _on_buy_skill.is_valid():
			# Use callback (it handles the skill learning)
			_on_buy_skill.call(offering_id, 0, null, null)  # Cost already spent
			success = true
		else:
			success = char_instance.learn_skill(offering_id)
	else:
		if _on_buy_item.is_valid():
			# Use callback (it handles item equipping)
			_on_buy_item.call(offering_id, 0, null, null)  # Cost already spent
			success = true
		else:
			char_instance.equip_item_upgrade(offering_id)
			success = true

	if success:
		_purchases_made += 1

		# Clean up popup
		if _reward_popup:
			_reward_popup.hide_popup()
			_reward_popup.queue_free()
			_reward_popup = null

		# Check if we've reached max purchases
		if _purchases_made >= _max_purchases:
			if _on_complete.is_valid():
				_on_complete.call()
		else:
			# Reset for next purchase
			_reset_for_next_purchase()


static func _reset_for_next_purchase() -> void:
	"""Reset tiles for another purchase selection."""
	_selected_offering = {}
	for tile in _tiles:
		# Re-enable tiles that haven't been purchased
		tile.modulate = Color.WHITE
		tile.set_clickable(true)


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
