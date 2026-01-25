class_name SkillTrainerEncounterUI
extends RefCounted
## UI creation and reward preview for skill trainer encounters.
## Shows 3 skill options, player picks one, then picks a character to learn it.

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")

# Store references for callback access
static var _selected_skill_data: Dictionary = {}
static var _on_complete: Callable = Callable()
static var _on_skill_learn: Callable = Callable()
static var _on_gold_spend: Callable = Callable()
static var _tiles: Array = []
static var _char_selector_container: Control = null
static var _confirm_btn: Button = null
static var _eligible_char_indices: Array = []  # Maps selector index to team index


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create skill trainer encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var skill_ids: Array = encounter_data["data"].get("skill_ids", [])
	_on_complete = context.get("on_encounter_complete", Callable())
	_on_skill_learn = context.get("on_skill_learn", Callable())
	_on_gold_spend = context.get("on_gold_spend", Callable())
	_selected_skill_data = {}
	_tiles.clear()

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

	# Character selector (hidden until skill is selected)
	_char_selector_container = UIHelpers.create_vbox_container(8)
	_char_selector_container.visible = false
	vbox.add_child(_char_selector_container)

	return vbox


static func _setup_tile(tile: Control, skill_data: Dictionary, tile_size: float) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(skill_data, tile_size)
	tile.set_tile_color(GameConstants.COLOR_AMETHYST)
	tile.tile_clicked.connect(_on_skill_selected)


static func _on_skill_selected(skill_data: Dictionary) -> void:
	"""Handle skill tile selection."""
	_selected_skill_data = skill_data

	EncounterUIHelpers.highlight_selected_tile(_tiles, skill_data, "id", true)

	# Show character selector
	_show_character_selector()


static func _show_character_selector() -> void:
	"""Show dropdown to select which character learns the skill."""
	UIHelpers.clear_children(_char_selector_container)
	_char_selector_container.visible = true

	var cost = _selected_skill_data.get("cost", 0)
	var skill_id = _selected_skill_data.get("id", "")
	var can_afford = RunManager.get_gold() >= cost

	var team = RunManager.get_team()

	# Filter to only characters who can learn this skill
	var eligible = EncounterUIHelpers.filter_skill_eligible_characters(team, skill_id)
	_eligible_char_indices = eligible.indices
	var eligible_chars: Array = eligible.characters

	var selector = UIPanelFactory.create_team_selector(eligible_chars)
	_char_selector_container.add_child(selector)

	_confirm_btn = UIContainerHelpers.create_button("Learn (%dg)" % cost)
	EncounterUIHelpers.setup_confirm_button(_confirm_btn, "Learn", cost, can_afford, not eligible_chars.is_empty())
	_confirm_btn.pressed.connect(_on_confirm_learn.bind(selector))
	_char_selector_container.add_child(_confirm_btn)


static func _on_confirm_learn(selector: OptionButton) -> void:
	"""Confirm skill learning for selected character."""
	var selector_index = selector.selected - 1  # First option is "Select..."
	if selector_index < 0 or selector_index >= _eligible_char_indices.size():
		return

	var cost = _selected_skill_data.get("cost", 0)

	if not EncounterUIHelpers.try_spend_gold(cost, _on_gold_spend):
		return

	var team = RunManager.get_team()
	var char_index = _eligible_char_indices[selector_index]
	var char_instance = team[char_index]
	var skill_id = _selected_skill_data.get("id", "")

	var success = false
	if _on_skill_learn.is_valid():
		success = _on_skill_learn.call(char_instance, skill_id)
	else:
		success = char_instance.learn_skill(skill_id)

	if success:
		# Hide selector and show success
		_char_selector_container.visible = false
		if _on_complete.is_valid():
			_on_complete.call()


static func get_reward_preview(_encounter_data: Dictionary) -> String:
	"""Get reward preview for skill trainer encounter."""
	return "Buy Skill"
