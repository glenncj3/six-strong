class_name HealthRestoreEncounterUI
extends RefCounted
## UI creation and reward preview for health restore encounters.
## Shows 3 heal options, player picks one, then picks a character to heal.

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")

# Store references for callback access
static var _selected_option: Dictionary = {}
static var _on_complete: Callable = Callable()
static var _on_health_restore: Callable = Callable()
static var _on_gold_spend: Callable = Callable()
static var _tiles: Array = []
static var _char_selector_container: Control = null
static var _confirm_btn: Button = null
static var _eligible_char_indices: Array = []  # Maps selector index to team index


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create health restore encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var heal_options: Array = encounter_data["data"].get("heal_options", [])
	_on_complete = context.get("on_encounter_complete", Callable())
	_on_health_restore = context.get("on_health_restore", Callable())
	_on_gold_spend = context.get("on_gold_spend", Callable())
	_selected_option = {}
	_tiles.clear()

	if heal_options.is_empty():
		vbox.add_child(UIHelpers.create_label("No healing options available...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if _on_complete.is_valid():
			_on_complete.call()
		return vbox

	# Create horizontal container for heal option tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = UIScaler.calculate_tile_size(GameConstants.DESIGN_WIDTH, GameConstants.TEAM_SIZE, 48.0, 8.0, 180.0)

	for i in range(heal_options.size()):
		var option = heal_options[i]
		# Build tile data with display info (use index as unique ID)
		var tile_data = {
			"id": "heal_option_%d" % i,
			"heal_amount": option.get("heal_amount", 10),
			"cost": option.get("cost", 10),
			"name": "+%d HP" % option.get("heal_amount", 10),
			"image_path": "res://assets/encounters/fountain.png"
		}

		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		# Defer setup until tile enters the scene tree
		tile.ready.connect(_setup_tile.bind(tile, tile_data, tile_size))
		_tiles.append(tile)

	# Character selector (hidden until option is selected)
	_char_selector_container = UIHelpers.create_vbox_container(8)
	_char_selector_container.visible = false
	vbox.add_child(_char_selector_container)

	return vbox


static func _setup_tile(tile: Control, tile_data: Dictionary, tile_size: float) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(tile_data, tile_size)
	tile.tile_clicked.connect(_on_option_selected)


static func _on_option_selected(tile_data: Dictionary) -> void:
	"""Handle heal option tile selection."""
	_selected_option = tile_data

	EncounterUIHelpers.highlight_selected_tile(_tiles, tile_data, "id", false)

	# Show character selector
	_show_character_selector()


static func _show_character_selector() -> void:
	"""Show dropdown to select which character gets healed."""
	UIHelpers.clear_children(_char_selector_container)
	_char_selector_container.visible = true

	var cost = _selected_option.get("cost", 0)
	var can_afford = RunManager.get_gold() >= cost

	var team = RunManager.get_team()

	# Filter to only characters who need healing
	var eligible = EncounterUIHelpers.filter_heal_eligible_characters(team)
	_eligible_char_indices = eligible.indices
	var eligible_chars: Array = eligible.characters

	var selector = UIPanelFactory.create_team_selector(eligible_chars)
	_char_selector_container.add_child(selector)

	_confirm_btn = UIContainerHelpers.create_button("Heal (%dg)" % cost)
	EncounterUIHelpers.setup_confirm_button(_confirm_btn, "Heal", cost, can_afford, not eligible_chars.is_empty())
	_confirm_btn.pressed.connect(_on_confirm_heal.bind(selector))
	_char_selector_container.add_child(_confirm_btn)


static func _on_confirm_heal(selector: OptionButton) -> void:
	"""Confirm healing for selected character."""
	var selector_index = selector.selected - 1  # First option is "Select..."
	if selector_index < 0 or selector_index >= _eligible_char_indices.size():
		return

	var cost = _selected_option.get("cost", 0)
	var heal_amount = _selected_option.get("heal_amount", 0)

	if not EncounterUIHelpers.try_spend_gold(cost, _on_gold_spend):
		return

	var team = RunManager.get_team()
	var char_index = _eligible_char_indices[selector_index]
	var char_instance = team[char_index]

	# Apply healing
	if _on_health_restore.is_valid():
		_on_health_restore.call(char_instance, heal_amount)
	else:
		char_instance.current_health = mini(char_instance.current_health + heal_amount, char_instance.max_health)

	# Hide selector and complete
	_char_selector_container.visible = false
	if _on_complete.is_valid():
		_on_complete.call()


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for health restore encounter."""
	var heal_options = encounter_data.get("data", {}).get("heal_options", [])
	if heal_options.is_empty():
		return "Buy Healing"
	var min_heal = heal_options[0].get("heal_amount", 10)
	var max_heal = heal_options[-1].get("heal_amount", 50)
	return "%d-%d HP" % [min_heal, max_heal]
