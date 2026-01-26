class_name ShopEncounterUI
extends RefCounted
## UI creation and reward preview for shop encounters.
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
		# Build tile data - enrich with effect preview for skills
		var tile_data = offering.duplicate()
		if tile_data.get("offering_type") == "skill":
			_enrich_skill_tile_data(tile_data)

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
	"""Handle offering tile selection - purchase immediately."""
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
		# Phase 3: Execute skill effect immediately
		success = _execute_skill(offering_id, tile_data)
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


static func _execute_skill(skill_id: String, tile_data: Dictionary) -> bool:
	"""
	Execute a skill's effect immediately.

	Args:
		skill_id: The skill ID
		tile_data: The tile data (may contain enriched skill info)

	Returns:
		True if skill was executed successfully
	"""
	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		_show_result("Unknown skill!", GameConstants.COLOR_ERROR)
		return false

	var effect_type = skill_data.get("effect_type", "instant")
	var skill_name = skill_data.get("name", "Skill")

	# Check if this is a lingering effect
	if effect_type == "lingering":
		# Add to lingering effects instead of executing immediately
		var success = RunManager.add_lingering_effect(skill_data)
		if success:
			var trigger = skill_data.get("trigger", "")
			var trigger_desc = _get_trigger_description(trigger)
			_show_result("%s will activate %s!" % [skill_name, trigger_desc], GameConstants.COLOR_SUCCESS)
			return true
		else:
			_show_result("Failed to prepare %s!" % skill_name, GameConstants.COLOR_ERROR)
			return false

	# Execute instant effect
	var context = SkillContext.from_run_manager(RunManager)
	var registry = _get_skill_registry()

	var success = registry.execute(skill_data, context)
	if success:
		var effect = skill_data.get("effect", {})
		var effect_desc = SkillEffects.get_effect_description(effect)
		_show_result("%s!" % effect_desc, GameConstants.COLOR_SUCCESS)
		return true
	else:
		_show_result("Failed to use %s!" % skill_name, GameConstants.COLOR_ERROR)
		return false


static func _get_skill_registry() -> SkillEffectRegistry:
	"""Get or create the skill effect registry."""
	# Try to get from RunManager if it has one
	if RunManager.has_method("get_skill_registry"):
		return RunManager.get_skill_registry()

	# Create a temporary one with all effects registered
	var registry = SkillEffectRegistry.new()
	SkillEffects.register_all(registry)
	return registry


static func _get_trigger_description(trigger: String) -> String:
	"""Get a human-readable description of a trigger."""
	match trigger:
		"next_character_acquired":
			return "when you get a new character"
		"next_combat":
			return "before your next combat"
		"next_encounter":
			return "at your next encounter"
		"next_round":
			return "at the start of next round"
		_:
			return "later"


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
