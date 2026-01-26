class_name EncounterUIHelpers
extends RefCounted
## Shared helper functions for encounter UI components.
## Reduces code duplication across shop, health restore, and skill trainer UIs.
##
## Phase 2 Refactor:
## - Removed filter_item_eligible_characters (items go to player inventory)
## - Removed filter_skill_eligible_characters (skills are instant effects)
## - Kept filter_heal_eligible_characters (health still targets characters)


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

static func filter_heal_eligible_characters(team: Array) -> Dictionary:
	"""
	Return all team members as eligible for healing.
	Players can heal any character, even at full health (overheal or just confirmation).

	Args:
		team: Array of character instances

	Returns:
		Dictionary with "indices" (Array of team indices) and "characters" (Array of char instances)
	"""
	var indices: Array = []
	var characters: Array = []

	for i in range(team.size()):
		indices.append(i)
		characters.append(team[i])

	return {"indices": indices, "characters": characters}


# =============================================================================
# ITEM AVAILABILITY (Phase 2 - Player Inventory)
# =============================================================================

static func is_item_available(item_id: String) -> bool:
	"""
	Check if an item can be acquired (not already in player inventory).

	Args:
		item_id: ID of the item to check

	Returns:
		True if item is not yet owned
	"""
	return not RunManager.has_item_in_inventory(item_id)


static func filter_available_items(items: Array) -> Array:
	"""
	Filter a list of items to only those not already in player inventory.

	Args:
		items: Array of item dictionaries with "id" field

	Returns:
		Filtered array of available items
	"""
	var available: Array = []
	for item in items:
		var item_id = item.get("id", "")
		if not item_id.is_empty() and not RunManager.has_item_in_inventory(item_id):
			available.append(item)
	return available


# =============================================================================
# XP ELIGIBILITY
# =============================================================================

static func filter_xp_eligible_characters(team: Array) -> Dictionary:
	"""
	Filter team to characters who can receive XP (all characters).

	Args:
		team: Array of character instances

	Returns:
		Dictionary with "indices" (Array of team indices) and "characters" (Array of char instances)
	"""
	var indices: Array = []
	var characters: Array = []

	for i in range(team.size()):
		indices.append(i)
		characters.append(team[i])

	return {"indices": indices, "characters": characters}
