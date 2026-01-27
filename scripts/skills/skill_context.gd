class_name SkillContext
extends RefCounted
## Context passed to skill effect handlers.
## Provides access to run state, team, inventory, and other game systems.
##
## Usage:
##   var context = SkillContext.from_run_manager(RunManager)
##   # or
##   var context = SkillContext.new()
##   context.get_team = run_manager.get_team
##   context.add_gold = run_manager.add_gold
##   registry.execute(skill_data, context)

# =============================================================================
# TEAM ACCESS
# =============================================================================

## Callable to get all team members: func() -> Array[CharacterInstance]
var get_team: Callable = Callable()

# =============================================================================
# GOLD ACCESS
# =============================================================================

## Callable to add gold: func(amount: int) -> void
var add_gold: Callable = Callable()

## Callable to get current gold: func() -> int
var get_gold: Callable = Callable()

## Callable to spend gold: func(amount: int) -> bool
var spend_gold: Callable = Callable()

# =============================================================================
# XP ACCESS
# =============================================================================

## Callable to add XP to the player: func(xp: int) -> bool
var add_player_xp: Callable = Callable()

# =============================================================================
# INVENTORY ACCESS
# =============================================================================

## Reference to player inventory
## Type: PlayerInventory
var player_inventory = null

# =============================================================================
# LINGERING EFFECTS ACCESS
# =============================================================================

## Callable to add a lingering effect: func(effect_data: Dictionary) -> void
var add_lingering_effect: Callable = Callable()

# =============================================================================
# RUN STATE ACCESS
# =============================================================================

## Current round number
var current_round: int = 0

## Current gold (cached for convenience)
var gold: int = 0

# =============================================================================
# VALIDATION
# =============================================================================

func is_valid() -> bool:
	"""Check if the context has minimum required references set."""
	# At minimum, we need team access for most effects
	return get_team.is_valid()


func has_gold_access() -> bool:
	"""Check if gold operations are available."""
	return add_gold.is_valid()


func has_xp_access() -> bool:
	"""Check if player XP operations are available."""
	return add_player_xp.is_valid()


func has_lingering_access() -> bool:
	"""Check if lingering effect operations are available."""
	return add_lingering_effect.is_valid()

# =============================================================================
# CONVENIENCE METHODS
# =============================================================================

func get_all_characters() -> Array:
	"""Get all team members."""
	if get_team.is_valid():
		return get_team.call()
	return []


func heal_character(character, amount: int) -> void:
	"""Heal a character by the specified amount."""
	if character != null and character.has_method("heal"):
		character.heal(amount)
	elif character != null:
		# Fallback: directly modify current_health
		character.current_health = min(
			character.current_health + amount,
			character.max_health
		)


func heal_all_characters(amount: int) -> void:
	"""Heal all team members by the specified amount."""
	for character in get_all_characters():
		heal_character(character, amount)


func grant_xp_to_player(amount: int) -> void:
	"""Grant XP to the player (gates content availability)."""
	if add_player_xp.is_valid():
		add_player_xp.call(amount)
	else:
		push_warning("SkillContext: add_player_xp not available")


# =============================================================================
# FACTORY
# =============================================================================

static func from_run_manager(run_manager):
	"""
	Create a SkillContext from a RunManager instance.

	Args:
		run_manager: The RunManager autoload

	Returns:
		Configured SkillContext
	"""
	var script = load("res://scripts/skills/skill_context.gd")
	var context = script.new()

	# Team access
	if run_manager.has_method("get_team"):
		context.get_team = run_manager.get_team

	# Gold access
	if run_manager.has_method("add_gold"):
		context.add_gold = run_manager.add_gold
	if run_manager.has_method("get_gold"):
		context.get_gold = run_manager.get_gold
		context.gold = run_manager.get_gold()
	if run_manager.has_method("spend_gold"):
		context.spend_gold = run_manager.spend_gold

	# XP access (player level system)
	if run_manager.has_method("add_player_xp"):
		context.add_player_xp = run_manager.add_player_xp

	# Inventory access
	if run_manager.get("_player_inventory") != null:
		context.player_inventory = run_manager._player_inventory

	# Lingering effects access
	if run_manager.has_method("add_lingering_effect"):
		context.add_lingering_effect = run_manager.add_lingering_effect

	# Run state
	if run_manager.has_method("get_round"):
		context.current_round = run_manager.get_round()

	return context
