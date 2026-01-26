class_name RewardApplicator
extends RefCounted
## Static methods to apply any reward to the game state.
## Handles validation, application, and fallback logic.
##
## Phase 2 Refactor:
## - Items now go to player inventory (no character selection)
## - Skills will be instant effects in Phase 3 (currently disabled)


## Result of applying a reward
class ApplyResult:
	var success: bool = false
	var message: String = ""
	var fallback_used: bool = false
	var actual_reward: RewardDefinition = null

	func _init(p_success: bool = false, p_message: String = "", p_fallback: bool = false) -> void:
		success = p_success
		message = p_message
		fallback_used = p_fallback


## Apply a reward to the game state
## Returns ApplyResult with success status and message
## Note: target_char is only used for HEALTH and XP rewards now
static func apply_reward(
	definition: RewardDefinition,
	context: Dictionary = {},
	target_char: Variant = null  # CharacterInstance or null (only for health/XP)
) -> ApplyResult:
	match definition.type:
		RewardTypes.RewardType.GOLD:
			return _apply_gold(definition, context)
		RewardTypes.RewardType.HEALTH:
			return _apply_health(definition, context, target_char)
		RewardTypes.RewardType.XP:
			return _apply_xp(definition, context, target_char)
		RewardTypes.RewardType.ITEM:
			return _apply_item(definition, context)
		RewardTypes.RewardType.SKILL:
			return _apply_skill(definition, context)
		RewardTypes.RewardType.ITEM_RANDOM:
			return _apply_random_item(definition, context)
		RewardTypes.RewardType.SKILL_RANDOM:
			return _apply_random_skill(definition, context)

	return ApplyResult.new(false, "Unknown reward type")


## Check if a reward can be applied
## Returns Dictionary with "valid": bool, "reason": String
static func can_apply_reward(
	definition: RewardDefinition,
	target_char: Variant = null
) -> Dictionary:
	match definition.type:
		RewardTypes.RewardType.GOLD:
			return {"valid": true, "reason": ""}
		RewardTypes.RewardType.HEALTH:
			return _can_apply_health(definition, target_char)
		RewardTypes.RewardType.XP:
			return {"valid": true, "reason": ""}
		RewardTypes.RewardType.ITEM:
			return _can_apply_item(definition)
		RewardTypes.RewardType.SKILL:
			return _can_apply_skill(definition)
		RewardTypes.RewardType.ITEM_RANDOM:
			return _can_apply_random_item(definition)
		RewardTypes.RewardType.SKILL_RANDOM:
			return _can_apply_random_skill(definition)

	return {"valid": false, "reason": "Unknown reward type"}


## Get a fallback reward when the primary can't be applied
## e.g., gold if item already owned
static func get_fallback_reward(definition: RewardDefinition) -> RewardDefinition:
	# Fallback amounts based on type
	match definition.type:
		RewardTypes.RewardType.SKILL, RewardTypes.RewardType.SKILL_RANDOM:
			# Skill fallback: 25-40 gold
			return RewardDefinition.create_gold(randi_range(25, 40))
		RewardTypes.RewardType.ITEM, RewardTypes.RewardType.ITEM_RANDOM:
			# Item fallback: 20-35 gold
			return RewardDefinition.create_gold(randi_range(20, 35))
		RewardTypes.RewardType.HEALTH:
			# Health fallback (if full): small gold
			return RewardDefinition.create_gold(randi_range(10, 20))

	# Default: just return the original
	return definition


## Get eligible characters for a reward
## Returns Dictionary with "indices": Array[int], "characters": Array[CharacterInstance]
## Note: Items and skills no longer need character selection in Phase 2
static func get_eligible_characters(definition: RewardDefinition) -> Dictionary:
	var team = RunManager.get_team()

	match definition.type:
		RewardTypes.RewardType.HEALTH:
			return EncounterUIHelpers.filter_heal_eligible_characters(team)
		RewardTypes.RewardType.XP:
			# XP goes to the player - no character selection needed
			return {"indices": [], "characters": [], "no_selection_needed": true}
		RewardTypes.RewardType.ITEM, RewardTypes.RewardType.ITEM_RANDOM:
			# Items go to player inventory - no character selection needed
			return {"indices": [], "characters": [], "no_selection_needed": true}
		RewardTypes.RewardType.SKILL, RewardTypes.RewardType.SKILL_RANDOM:
			# Skills are instant effects - no character selection needed
			return {"indices": [], "characters": [], "no_selection_needed": true}

	# Gold doesn't need character selection
	return {"indices": [], "characters": []}


## Check if a reward requires character selection
static func requires_character_selection(definition: RewardDefinition) -> bool:
	match definition.type:
		RewardTypes.RewardType.HEALTH:
			return definition.target == RewardTypes.RewardTarget.SINGLE
		RewardTypes.RewardType.XP:
			return false  # XP goes to the player, not characters
		RewardTypes.RewardType.ITEM, RewardTypes.RewardType.ITEM_RANDOM:
			return false  # Items go to player inventory
		RewardTypes.RewardType.SKILL, RewardTypes.RewardType.SKILL_RANDOM:
			return false  # Skills are instant effects
	return false


# =============================================================================
# PRIVATE APPLY METHODS
# =============================================================================

static func _apply_gold(definition: RewardDefinition, context: Dictionary) -> ApplyResult:
	var amount = definition.params.get("amount", 0)
	if amount <= 0:
		return ApplyResult.new(false, "Invalid gold amount")

	# Use context callback if available
	var on_gold_reward = context.get("on_gold_reward", Callable())
	if on_gold_reward.is_valid():
		on_gold_reward.call(amount)
	else:
		RunManager.add_gold(amount)

	var result = ApplyResult.new(true, "+%d Gold" % amount)
	result.actual_reward = definition
	return result


static func _apply_health(definition: RewardDefinition, context: Dictionary, target_char: Variant) -> ApplyResult:
	var team = RunManager.get_team()
	var targets: Array = []

	# Determine targets based on target type
	match definition.target:
		RewardTypes.RewardTarget.ALL:
			targets = team
		RewardTypes.RewardTarget.RANDOM:
			if team.size() > 0:
				targets = [team[randi() % team.size()]]
		RewardTypes.RewardTarget.SINGLE:
			if target_char != null:
				targets = [target_char]
			else:
				return ApplyResult.new(false, "No character selected for health")

	if targets.is_empty():
		return ApplyResult.new(false, "No valid targets for health")

	var total_healed = 0
	var on_health_restore = context.get("on_health_restore", Callable())

	for char_instance in targets:
		var heal_amount: int
		if definition.params.has("percentage"):
			heal_amount = int(char_instance.max_health * definition.params["percentage"])
		else:
			heal_amount = definition.params.get("amount", 0)

		var actual_heal = mini(heal_amount, char_instance.max_health - char_instance.current_health)

		if on_health_restore.is_valid():
			on_health_restore.call(char_instance, actual_heal)
		else:
			char_instance.current_health = mini(char_instance.current_health + heal_amount, char_instance.max_health)

		total_healed += actual_heal

	var result = ApplyResult.new(true, "+%d Health" % total_healed)
	result.actual_reward = definition
	return result


static func _apply_xp(definition: RewardDefinition, context: Dictionary, _target_char: Variant) -> ApplyResult:
	"""Apply XP reward - XP goes to the player (gates content availability)."""
	var amount = definition.params.get("amount", 0)
	if amount <= 0:
		return ApplyResult.new(false, "Invalid XP amount")

	# Use context callback if available, otherwise use RunManager
	var on_xp_reward = context.get("on_xp_reward", Callable())
	if on_xp_reward.is_valid():
		on_xp_reward.call(amount)
	else:
		RunManager.add_player_xp(amount)

	var result = ApplyResult.new(true, "+%d XP" % amount)
	result.actual_reward = definition
	return result


static func _apply_item(definition: RewardDefinition, context: Dictionary) -> ApplyResult:
	"""Apply item reward - items go to player inventory (Phase 2)."""
	var item_id = definition.params.get("item_id", "")
	if item_id.is_empty():
		return ApplyResult.new(false, "Invalid item ID")

	# Check eligibility
	var can_apply = _can_apply_item(definition)
	if not can_apply["valid"]:
		# Try fallback
		var fallback = get_fallback_reward(definition)
		var fallback_result = apply_reward(fallback, context)
		fallback_result.fallback_used = true
		return fallback_result

	# Apply item via context callback or directly to player inventory
	var on_buy_item = context.get("on_buy_item", Callable())
	if on_buy_item.is_valid():
		# The callback should add to player inventory
		on_buy_item.call(item_id, 0, null, null)
	else:
		RunManager.add_item_to_inventory(item_id)

	var item_data = GameData.get_item_upgrade_by_id(item_id)
	var result = ApplyResult.new(true, "Acquired %s" % item_data.get("name", "Item"))
	result.actual_reward = definition
	return result


static func _apply_skill(definition: RewardDefinition, context: Dictionary) -> ApplyResult:
	"""
	Apply skill reward.
	Phase 2: Skills will become instant effects in Phase 3.
	For now, we just give gold as a placeholder.
	"""
	var skill_id = definition.params.get("skill_id", "")
	if skill_id.is_empty():
		return ApplyResult.new(false, "Invalid skill ID")

	# Check eligibility
	var can_apply = _can_apply_skill(definition)
	if not can_apply["valid"]:
		# Fallback to gold
		var fallback = get_fallback_reward(definition)
		var fallback_result = apply_reward(fallback, context)
		fallback_result.fallback_used = true
		return fallback_result

	# Apply skill via context callback
	var on_buy_skill = context.get("on_buy_skill", Callable())
	if on_buy_skill.is_valid():
		on_buy_skill.call(skill_id, 0, null, null)
	else:
		# Phase 3 TODO: Execute skill effect immediately
		# For now, just acknowledge the skill was "used"
		pass

	var skill_data = GameData.get_skill(skill_id)
	var result = ApplyResult.new(true, "Used %s" % skill_data.get("name", "Skill"))
	result.actual_reward = definition
	return result


static func _apply_random_item(definition: RewardDefinition, context: Dictionary) -> ApplyResult:
	# Resolve to a concrete item
	var resolved = RewardGenerator.resolve_reward(definition)
	if resolved.type == RewardTypes.RewardType.GOLD:
		# Fallback was used during resolution
		return apply_reward(resolved, context)

	return _apply_item(resolved, context)


static func _apply_random_skill(definition: RewardDefinition, context: Dictionary) -> ApplyResult:
	# Resolve to a concrete skill
	var resolved = RewardGenerator.resolve_reward(definition)
	if resolved.type == RewardTypes.RewardType.GOLD:
		# Fallback was used during resolution
		return apply_reward(resolved, context)

	return _apply_skill(resolved, context)


# =============================================================================
# PRIVATE VALIDATION METHODS
# =============================================================================

static func _can_apply_health(definition: RewardDefinition, target_char: Variant) -> Dictionary:
	if definition.target == RewardTypes.RewardTarget.ALL:
		# Check if any character needs healing
		var team = RunManager.get_team()
		for char_instance in team:
			if char_instance.current_health < char_instance.max_health:
				return {"valid": true, "reason": ""}
		return {"valid": false, "reason": "All characters at full health"}

	if target_char == null:
		return {"valid": false, "reason": "No character selected"}

	if target_char.current_health >= target_char.max_health:
		return {"valid": false, "reason": "Character at full health"}

	return {"valid": true, "reason": ""}


static func _can_apply_item(definition: RewardDefinition) -> Dictionary:
	"""Check if item can be applied - items go to player inventory (Phase 2)."""
	var item_id = definition.params.get("item_id", "")
	if item_id.is_empty():
		return {"valid": false, "reason": "Invalid item ID"}

	# Check if already in player inventory
	if RunManager.has_item_in_inventory(item_id):
		return {"valid": false, "reason": "Already owned"}

	# No slot limit for player inventory (Phase 2)
	return {"valid": true, "reason": ""}


static func _can_apply_skill(definition: RewardDefinition) -> Dictionary:
	"""Check if skill can be applied."""
	var skill_id = definition.params.get("skill_id", "")
	if skill_id.is_empty():
		return {"valid": false, "reason": "Invalid skill ID"}

	# Phase 3 TODO: Skills are instant effects, so they can always be applied
	# For now, always allow
	return {"valid": true, "reason": ""}


static func _can_apply_random_item(_definition: RewardDefinition) -> Dictionary:
	"""Check if a random item can be applied."""
	# With player inventory, we can always add items (no slot limit)
	# But we might want to check if there are any items available
	return {"valid": true, "reason": ""}


static func _can_apply_random_skill(_definition: RewardDefinition) -> Dictionary:
	"""Check if a random skill can be applied."""
	# Skills are instant effects in Phase 3
	return {"valid": true, "reason": ""}
