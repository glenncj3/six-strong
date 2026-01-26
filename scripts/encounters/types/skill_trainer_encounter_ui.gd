class_name SkillTrainerEncounterUI
extends RefCounted
## UI creation and reward preview for skill trainer encounters.
## Shows 3 skill options, player picks one, popup shows skill details and character selector.

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")
const RewardClaimPopupScene = preload("res://scenes/components/reward_claim_popup.tscn")

# Store references for callback access
static var _selected_skill_data: Dictionary = {}
static var _on_complete: Callable = Callable()
static var _on_skill_learn: Callable = Callable()
static var _on_gold_spend: Callable = Callable()
static var _tiles: Array = []
static var _reward_popup: RewardClaimPopup = null


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create skill trainer encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var skill_ids: Array = encounter_data["data"].get("skill_ids", [])
	_on_complete = context.get("on_encounter_complete", Callable())
	_on_skill_learn = context.get("on_skill_learn", Callable())
	_on_gold_spend = context.get("on_gold_spend", Callable())
	_selected_skill_data = {}
	_tiles.clear()
	_reward_popup = null

	if skill_ids.is_empty():
		vbox.add_child(UIHelpers.create_label("No skills available...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if _on_complete.is_valid():
			_on_complete.call()
		return vbox

	# Create horizontal container for skill tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = UIScaler.calculate_tile_size(GameConstants.DESIGN_WIDTH, GameConstants.TEAM_SIZE, 48.0, 8.0, 180.0)

	for i in range(skill_ids.size()):
		var skill_id = skill_ids[i]
		var skill_data = GameData.get_skill_by_id(skill_id)
		if skill_data.is_empty():
			continue

		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		# Defer setup until tile enters the scene tree
		tile.ready.connect(_setup_tile.bind(tile, skill_data, tile_size))
		_tiles.append(tile)

	return vbox


static func _setup_tile(tile: Control, skill_data: Dictionary, tile_size: float) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(skill_data, tile_size)
	tile.set_tile_color(GameConstants.COLOR_AMETHYST)
	tile.tile_clicked.connect(_on_skill_selected)


static func _on_skill_selected(skill_data: Dictionary) -> void:
	"""Handle skill tile selection - show popup."""
	_selected_skill_data = skill_data

	# Highlight selected tile (allow reselection)
	EncounterUIHelpers.highlight_selected_tile(_tiles, skill_data, "id", true)

	# Show reward claim popup
	_show_skill_popup()


static func _show_skill_popup() -> void:
	"""Show popup with skill details and character selector."""
	if _reward_popup:
		_reward_popup.queue_free()

	_reward_popup = RewardClaimPopupScene.instantiate()
	# Add to scene tree temporarily so it can reparent itself
	var scene_root = Engine.get_main_loop().current_scene
	scene_root.add_child(_reward_popup)

	var skill_id = _selected_skill_data.get("id", "")
	var cost = _selected_skill_data.get("cost", 0)

	# Get eligible characters
	var team = RunManager.get_team()
	var eligible = EncounterUIHelpers.filter_skill_eligible_characters(team, skill_id)

	# Connect to signals
	_reward_popup.claimed.connect(_on_skill_claimed)

	# Show the skill
	_reward_popup.show_skill(
		skill_id,
		eligible.characters,
		eligible.indices,
		"",  # No header
		"",  # No bonus text
		"%dg and Learn" % cost,
		cost
	)


static func _on_skill_claimed(skill_id: String, char_index: int) -> void:
	"""Handle skill claim from popup."""
	var cost = _selected_skill_data.get("cost", 0)

	# Spend gold
	if not EncounterUIHelpers.try_spend_gold(cost, _on_gold_spend):
		return

	var team = RunManager.get_team()
	var char_instance = team[char_index]

	# Learn the skill
	var success = false
	if _on_skill_learn.is_valid():
		success = _on_skill_learn.call(char_instance, skill_id)
	else:
		success = char_instance.learn_skill(skill_id)

	if success:
		# Clean up popup
		if _reward_popup:
			_reward_popup.hide_popup()
			_reward_popup.queue_free()
			_reward_popup = null

		# Complete encounter
		if _on_complete.is_valid():
			_on_complete.call()


static func get_reward_preview(_encounter_data: Dictionary) -> String:
	"""Get reward preview for skill trainer encounter."""
	return "Buy Skill"
