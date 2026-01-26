class_name HealthRestoreEncounterUI
extends RefCounted
## UI creation and reward preview for health restore encounters.
## Shows 3 heal options, player picks one, then picks a character to heal.

const PurchasableTileScene = preload("res://scenes/components/purchasable_tile.tscn")


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create health restore encounter UI."""
	var vbox = UIHelpers.create_vbox_container(8)

	var heal_options: Array = encounter_data["data"].get("heal_options", [])
	var on_complete: Callable = context.get("on_encounter_complete", Callable())
	var on_health_restore: Callable = context.get("on_health_restore", Callable())
	var on_gold_spend: Callable = context.get("on_gold_spend", Callable())
	var tiles: Array = []

	if heal_options.is_empty():
		vbox.add_child(UIHelpers.create_label("No healing options available...", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))
		if on_complete.is_valid():
			on_complete.call()
		return vbox

	# Create horizontal container for heal option tiles
	var hbox = UIHelpers.create_hbox_container(8, BoxContainer.ALIGNMENT_CENTER)
	vbox.add_child(hbox)

	var tile_size = UIScaler.calculate_tile_size(GameConstants.DESIGN_WIDTH, GameConstants.TEAM_SIZE, 48.0, 8.0, 180.0)

	# Character selector (hidden until option is selected)
	var char_selector_container = UIHelpers.create_vbox_container(8)
	char_selector_container.visible = false
	vbox.add_child(char_selector_container)

	# Create state dictionary to pass through bindings
	var state = {
		"tiles": tiles,
		"char_selector_container": char_selector_container,
		"selected_option": {},
		"eligible_char_indices": [],
		"on_complete": on_complete,
		"on_health_restore": on_health_restore,
		"on_gold_spend": on_gold_spend
	}

	# Create and setup tiles in single pass - call _setup_tile directly after add_child
	# (ready signal fires during add_child, so connecting after would be too late)
	for i in range(heal_options.size()):
		var option = heal_options[i]
		var tile_data = {
			"id": "heal_option_%d" % i,
			"heal_amount": option.get("heal_amount", 10),
			"cost": option.get("cost", 10),
			"name": "+%d HP" % option.get("heal_amount", 10),
			"image_path": "res://assets/encounters/fountain.png"
		}

		var tile = PurchasableTileScene.instantiate()
		hbox.add_child(tile)
		tiles.append(tile)
		_setup_tile(tile, tile_data, tile_size, state)

	return vbox


static func _setup_tile(tile: Control, tile_data: Dictionary, tile_size: float, state: Dictionary) -> void:
	"""Setup tile after it enters the scene tree."""
	tile.setup(tile_data, tile_size)
	tile.tile_clicked.connect(_on_option_selected.bind(state))


static func _on_option_selected(tile_data: Dictionary, state: Dictionary) -> void:
	"""Handle heal option tile selection."""
	state.selected_option = tile_data

	EncounterUIHelpers.highlight_selected_tile(state.tiles, tile_data, "id", true)

	# Show character selector
	_show_character_selector(state)


static func _show_character_selector(state: Dictionary) -> void:
	"""Show dropdown to select which character gets healed."""
	var char_selector_container: Control = state.char_selector_container
	UIHelpers.clear_children(char_selector_container)
	char_selector_container.visible = true

	var selected_option: Dictionary = state.selected_option
	var on_gold_spend: Callable = state.on_gold_spend

	var cost = selected_option.get("cost", 0)
	var can_afford = RunManager.get_gold() >= cost

	var team = RunManager.get_team()

	# Filter to only characters who need healing
	var eligible = EncounterUIHelpers.filter_heal_eligible_characters(team)
	state.eligible_char_indices = eligible.indices
	var eligible_chars: Array = eligible.characters

	var selector = UIPanelFactory.create_team_selector(eligible_chars)
	char_selector_container.add_child(selector)

	var confirm_btn = UIContainerHelpers.create_button("Heal (%dg)" % cost)
	EncounterUIHelpers.setup_confirm_button(confirm_btn, "Heal", cost, can_afford, not eligible_chars.is_empty())
	confirm_btn.pressed.connect(_on_confirm_heal.bind(selector, state))
	char_selector_container.add_child(confirm_btn)


static func _on_confirm_heal(selector: OptionButton, state: Dictionary) -> void:
	"""Confirm healing for selected character."""
	var eligible_char_indices: Array = state.eligible_char_indices
	var selected_option: Dictionary = state.selected_option
	var char_selector_container: Control = state.char_selector_container
	var on_complete: Callable = state.on_complete
	var on_health_restore: Callable = state.on_health_restore
	var on_gold_spend: Callable = state.on_gold_spend

	var selector_index = selector.selected - 1  # First option is "Select..."
	if selector_index < 0 or selector_index >= eligible_char_indices.size():
		return

	var cost = selected_option.get("cost", 0)
	var heal_amount = selected_option.get("heal_amount", 0)

	if not EncounterUIHelpers.try_spend_gold(cost, on_gold_spend):
		return

	var team = RunManager.get_team()
	var char_index = eligible_char_indices[selector_index]
	var char_instance = team[char_index]

	# Apply healing
	if on_health_restore.is_valid():
		on_health_restore.call(char_instance, heal_amount)
	else:
		char_instance.current_health = mini(char_instance.current_health + heal_amount, char_instance.max_health)

	# Hide selector and complete
	char_selector_container.visible = false
	if on_complete.is_valid():
		on_complete.call()


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for health restore encounter."""
	var heal_options = encounter_data.get("data", {}).get("heal_options", [])
	if heal_options.is_empty():
		return "Buy Healing"
	var min_heal = heal_options[0].get("heal_amount", 10)
	var max_heal = heal_options[-1].get("heal_amount", 50)
	return "%d-%d HP" % [min_heal, max_heal]
