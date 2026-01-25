class_name EncounterUIHelpers
extends RefCounted
## Shared helper functions for encounter UI components.
## Reduces code duplication across shop, health restore, and skill trainer UIs.


# =============================================================================
# BUTTON SETUP
# =============================================================================

static func setup_confirm_button(
	btn: Button,
	action_text: String,
	cost: int,
	can_afford: bool,
	has_eligible_targets: bool = true
) -> void:
	"""
	Configure a confirm button with appropriate styling based on affordability and eligibility.

	Args:
		btn: The button to configure
		action_text: Base action text (e.g., "Learn", "Heal", "Equip")
		cost: Gold cost to display
		can_afford: Whether the player has enough gold
		has_eligible_targets: Whether there are valid targets for the action
	"""
	btn.text = "%s (%dg)" % [action_text, cost]

	if not has_eligible_targets:
		UIStyles.setup_danger_button(btn, GameConstants.FONT_SIZE_BUTTON)
		btn.disabled = true
		btn.text = "No eligible characters"
	elif can_afford:
		UIStyles.setup_success_button(btn, GameConstants.FONT_SIZE_BUTTON)
	else:
		UIStyles.setup_danger_button(btn, GameConstants.FONT_SIZE_BUTTON)
		btn.disabled = true
		btn.text = "Not enough gold (%dg)" % cost


# =============================================================================
# GOLD SPENDING
# =============================================================================

static func try_spend_gold(cost: int, gold_spend_callback: Callable) -> bool:
	"""
	Attempt to spend gold using callback if available, otherwise use RunManager directly.

	Args:
		cost: Amount of gold to spend
		gold_spend_callback: Optional callback for gold spending (may update UI)

	Returns:
		true if gold was successfully spent
	"""
	if gold_spend_callback.is_valid():
		return gold_spend_callback.call(cost)
	return RunManager.spend_gold(cost)


# =============================================================================
# TILE SELECTION
# =============================================================================

static func highlight_selected_tile(
	tiles: Array,
	selected_data: Dictionary,
	id_key: String = "id",
	allow_reselect: bool = false
) -> void:
	"""
	Highlight the selected tile and dim others.

	Args:
		tiles: Array of tile Controls to update
		selected_data: The data of the selected tile
		id_key: Dictionary key to use for comparison (default: "id")
		allow_reselect: If true, keeps other tiles clickable (default: false)
	"""
	var selected_id = selected_data.get(id_key)
	for tile in tiles:
		if tile.tile_data.get(id_key) == selected_id:
			tile.modulate = GameConstants.COLOR_TILE_SELECTED
		else:
			tile.modulate = GameConstants.COLOR_TILE_DIMMED
			if not allow_reselect:
				tile.set_clickable(false)


# =============================================================================
# ELIGIBILITY CHECKING
# =============================================================================

static func filter_skill_eligible_characters(team: Array, skill_id: String) -> Dictionary:
	"""
	Filter team to only characters who can learn a specific skill.

	Args:
		team: Array of character instances
		skill_id: ID of the skill to check

	Returns:
		Dictionary with "indices" (Array of team indices) and "characters" (Array of char instances)
	"""
	var indices: Array = []
	var characters: Array = []

	for i in range(team.size()):
		var char_instance = team[i]
		var already_learned = skill_id in char_instance.learned_skills
		var max_skills_reached = char_instance.learned_skills.size() >= GameConstants.MAX_RUN_SKILLS
		if not already_learned and not max_skills_reached:
			indices.append(i)
			characters.append(char_instance)

	return {"indices": indices, "characters": characters}


static func filter_item_eligible_characters(team: Array, item_id: String) -> Dictionary:
	"""
	Filter team to only characters who can equip a specific item upgrade.

	Args:
		team: Array of character instances
		item_id: ID of the item upgrade to check

	Returns:
		Dictionary with "indices" (Array of team indices) and "characters" (Array of char instances)
	"""
	var indices: Array = []
	var characters: Array = []

	for i in range(team.size()):
		var char_instance = team[i]
		var already_equipped = item_id in char_instance.equipped_item_upgrades
		var total_items = char_instance.equipped_items.size() + char_instance.equipped_item_upgrades.size()
		var max_items_reached = total_items >= GameConstants.MAX_RUN_ITEMS
		if not already_equipped and not max_items_reached:
			indices.append(i)
			characters.append(char_instance)

	return {"indices": indices, "characters": characters}


static func filter_heal_eligible_characters(team: Array) -> Dictionary:
	"""
	Filter team to only characters who can benefit from healing (not at full health).

	Args:
		team: Array of character instances

	Returns:
		Dictionary with "indices" (Array of team indices) and "characters" (Array of char instances)
	"""
	var indices: Array = []
	var characters: Array = []

	for i in range(team.size()):
		var char_instance = team[i]
		var needs_healing = char_instance.current_health < char_instance.max_health
		if needs_healing:
			indices.append(i)
			characters.append(char_instance)

	return {"indices": indices, "characters": characters}
