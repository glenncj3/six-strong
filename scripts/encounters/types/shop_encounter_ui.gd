class_name ShopEncounterUI
extends RefCounted
## UI creation and reward preview for shop encounters.
## Shows up to 3 offerings (items/skills) in tiles, player picks one.

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")

# Store references for callback access
static var _selected_offering: Dictionary = {}
static var _on_complete: Callable = Callable()
static var _on_buy_item: Callable = Callable()
static var _on_buy_skill: Callable = Callable()
static var _on_gold_spend: Callable = Callable()
static var _tiles: Array = []
static var _char_selector_container: Control = null
static var _confirm_btn: Button = null
static var _max_purchases: int = 1
static var _purchases_made: int = 0
static var _eligible_char_indices: Array = []  # Maps selector index to team index


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

	# Character selector (hidden until offering is selected)
	_char_selector_container = UIHelpers.create_vbox_container(8)
	_char_selector_container.visible = false
	vbox.add_child(_char_selector_container)

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
	"""Handle offering tile selection."""
	_selected_offering = tile_data

	# Dim all tiles and highlight selected (keep all clickable so user can change selection)
	EncounterUIHelpers.highlight_selected_tile(_tiles, tile_data, "id", true)

	# Show character selector
	_show_character_selector()


static func _show_character_selector() -> void:
	"""Show dropdown to select which character receives the item/skill."""
	UIHelpers.clear_children(_char_selector_container)
	_char_selector_container.visible = true

	var cost = _selected_offering.get("cost", 0)
	var can_afford = RunManager.get_gold() >= cost
	var offering_type = _selected_offering.get("offering_type", "item")
	var offering_id = _selected_offering.get("id", "")

	var team = RunManager.get_team()

	# Filter to only characters who can receive this offering
	var eligible: Dictionary
	if offering_type == "skill":
		eligible = EncounterUIHelpers.filter_skill_eligible_characters(team, offering_id)
	else:
		eligible = EncounterUIHelpers.filter_item_eligible_characters(team, offering_id)
	_eligible_char_indices = eligible.indices
	var eligible_chars: Array = eligible.characters

	var selector = UIPanelFactory.create_team_selector(eligible_chars)
	_char_selector_container.add_child(selector)

	var action_text = "Equip" if offering_type == "item" else "Learn"
	_confirm_btn = UIContainerHelpers.create_button("%s (%dg)" % [action_text, cost])
	EncounterUIHelpers.setup_confirm_button(_confirm_btn, action_text, cost, can_afford, not eligible_chars.is_empty())
	_confirm_btn.pressed.connect(_on_confirm_purchase.bind(selector))
	_char_selector_container.add_child(_confirm_btn)


static func _on_confirm_purchase(selector: OptionButton) -> void:
	"""Confirm purchase for selected character."""
	var selector_index = selector.selected - 1  # First option is "Select..."
	if selector_index < 0 or selector_index >= _eligible_char_indices.size():
		return

	var cost = _selected_offering.get("cost", 0)
	var offering_type = _selected_offering.get("offering_type", "item")
	var offering_id = _selected_offering.get("id", "")

	# The buy callbacks handle gold spending internally and disable the button on success
	var button_was_enabled = not _confirm_btn.disabled

	var team = RunManager.get_team()
	var char_index = _eligible_char_indices[selector_index]

	if offering_type == "skill":
		if _on_buy_skill.is_valid():
			_on_buy_skill.call(offering_id, cost, selector, _confirm_btn)
		else:
			# Fallback: handle locally
			if RunManager.spend_gold(cost):
				team[char_index].learn_skill(offering_id)
				_confirm_btn.disabled = true
				_confirm_btn.text = "LEARNED"
	else:
		if _on_buy_item.is_valid():
			_on_buy_item.call(offering_id, cost, selector, _confirm_btn)
		else:
			# Fallback: handle locally
			if RunManager.spend_gold(cost):
				team[char_index].equip_item_upgrade(offering_id)
				_confirm_btn.disabled = true
				_confirm_btn.text = "PURCHASED"

	# Check if purchase succeeded by seeing if button was disabled
	var success = button_was_enabled and _confirm_btn.disabled

	if success:
		_purchases_made += 1

		# Hide selector
		_char_selector_container.visible = false

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
