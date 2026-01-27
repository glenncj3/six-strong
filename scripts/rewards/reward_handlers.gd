class_name RewardHandlers
extends RefCounted
## Concrete handler implementations for each reward type.
## Extracted from RewardApplicator to follow the registry pattern.
##
## Code Quality Refactor (Phase 3):
## - Each handler is a static method
## - Validators paired with handlers
## - register_all() registers everything with the registry


# =============================================================================
# REGISTRATION
# =============================================================================

static func register_all(registry: RewardHandlerRegistry) -> void:
	"""Register all reward handlers with the given registry."""
	registry.register(
		RewardTypes.RewardType.GOLD,
		_handle_gold,
		_validate_gold
	)
	registry.register(
		RewardTypes.RewardType.HEALTH,
		_handle_health,
		_validate_health
	)
	registry.register(
		RewardTypes.RewardType.XP,
		_handle_xp,
		_validate_xp
	)
	registry.register(
		RewardTypes.RewardType.ITEM,
		_handle_item,
		_validate_item
	)
	registry.register(
		RewardTypes.RewardType.SKILL,
		_handle_skill,
		_validate_skill
	)
	registry.register(
		RewardTypes.RewardType.ITEM_RANDOM,
		_handle_random_item,
		_validate_random_item
	)
	registry.register(
		RewardTypes.RewardType.SKILL_RANDOM,
		_handle_random_skill,
		_validate_random_skill
	)


# =============================================================================
# GOLD HANDLER
# =============================================================================

static func _handle_gold(
	definition: RewardDefinition,
	context: Dictionary,
	_target_char: Variant
) -> RewardApplicator.ApplyResult:
	var amount = definition.params.get("amount", 0)
	if amount <= 0:
		return RewardApplicator.ApplyResult.new(false, "Invalid gold amount")

	var on_gold_reward = context.get("on_gold_reward", Callable())
	if on_gold_reward.is_valid():
		on_gold_reward.call(amount)
	else:
		RunManager.add_gold(amount)

	var result = RewardApplicator.ApplyResult.new(true, "+%d Gold" % amount)
	result.actual_reward = definition
	return result


static func _validate_gold(_definition: RewardDefinition, _target_char: Variant) -> Dictionary:
	return {"valid": true, "reason": ""}


# =============================================================================
# HEALTH HANDLER
# =============================================================================

static func _handle_health(
	definition: RewardDefinition,
	context: Dictionary,
	target_char: Variant
) -> RewardApplicator.ApplyResult:
	var team = RunManager.get_team()
	var targets: Array = []

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
				return RewardApplicator.ApplyResult.new(false, "No character selected for health")

	if targets.is_empty():
		return RewardApplicator.ApplyResult.new(false, "No valid targets for health")

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

	var result = RewardApplicator.ApplyResult.new(true, "+%d Health" % total_healed)
	result.actual_reward = definition
	return result


static func _validate_health(definition: RewardDefinition, target_char: Variant) -> Dictionary:
	if definition.target == RewardTypes.RewardTarget.ALL:
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


# =============================================================================
# XP HANDLER
# =============================================================================

static func _handle_xp(
	definition: RewardDefinition,
	context: Dictionary,
	_target_char: Variant
) -> RewardApplicator.ApplyResult:
	var amount = definition.params.get("amount", 0)
	if amount <= 0:
		return RewardApplicator.ApplyResult.new(false, "Invalid XP amount")

	var on_xp_reward = context.get("on_xp_reward", Callable())
	if on_xp_reward.is_valid():
		on_xp_reward.call(amount)
	else:
		RunManager.add_player_xp(amount)

	var result = RewardApplicator.ApplyResult.new(true, "+%d XP" % amount)
	result.actual_reward = definition
	return result


static func _validate_xp(_definition: RewardDefinition, _target_char: Variant) -> Dictionary:
	return {"valid": true, "reason": ""}


# =============================================================================
# ITEM HANDLER
# =============================================================================

static func _handle_item(
	definition: RewardDefinition,
	context: Dictionary,
	_target_char: Variant
) -> RewardApplicator.ApplyResult:
	var item_id = definition.params.get("item_id", "")
	if item_id.is_empty():
		return RewardApplicator.ApplyResult.new(false, "Invalid item ID")

	# Check eligibility
	var can_apply = _validate_item(definition, null)
	if not can_apply["valid"]:
		# Try fallback
		var fallback = RewardApplicator.get_fallback_reward(definition)
		var fallback_result = RewardApplicator.apply_reward(fallback, context)
		fallback_result.fallback_used = true
		return fallback_result

	var on_buy_item = context.get("on_buy_item", Callable())
	if on_buy_item.is_valid():
		on_buy_item.call(item_id, 0, null, null)
	else:
		RunManager.add_item_to_inventory(item_id)

	var item_data = GameData.get_item_upgrade_by_id(item_id)
	var result = RewardApplicator.ApplyResult.new(true, "Acquired %s" % item_data.get("name", "Item"))
	result.actual_reward = definition
	return result


static func _validate_item(definition: RewardDefinition, _target_char: Variant) -> Dictionary:
	var item_id = definition.params.get("item_id", "")
	if item_id.is_empty():
		return {"valid": false, "reason": "Invalid item ID"}

	if RunManager.has_item_in_inventory(item_id):
		return {"valid": false, "reason": "Already owned"}

	return {"valid": true, "reason": ""}


# =============================================================================
# SKILL HANDLER
# =============================================================================

static func _handle_skill(
	definition: RewardDefinition,
	context: Dictionary,
	_target_char: Variant
) -> RewardApplicator.ApplyResult:
	var skill_id = definition.params.get("skill_id", "")
	if skill_id.is_empty():
		return RewardApplicator.ApplyResult.new(false, "Invalid skill ID")

	var can_apply = _validate_skill(definition, null)
	if not can_apply["valid"]:
		var fallback = RewardApplicator.get_fallback_reward(definition)
		var fallback_result = RewardApplicator.apply_reward(fallback, context)
		fallback_result.fallback_used = true
		return fallback_result

	var on_buy_skill = context.get("on_buy_skill", Callable())
	if on_buy_skill.is_valid():
		on_buy_skill.call(skill_id, 0, null, null)
	else:
		# Phase 3: Skills are instant effects
		pass

	var skill_data = GameData.get_skill(skill_id)
	var result = RewardApplicator.ApplyResult.new(true, "Used %s" % skill_data.get("name", "Skill"))
	result.actual_reward = definition
	return result


static func _validate_skill(definition: RewardDefinition, _target_char: Variant) -> Dictionary:
	var skill_id = definition.params.get("skill_id", "")
	if skill_id.is_empty():
		return {"valid": false, "reason": "Invalid skill ID"}
	return {"valid": true, "reason": ""}


# =============================================================================
# RANDOM ITEM HANDLER
# =============================================================================

static func _handle_random_item(
	definition: RewardDefinition,
	context: Dictionary,
	_target_char: Variant
) -> RewardApplicator.ApplyResult:
	var resolved = RewardGenerator.resolve_reward(definition)
	if resolved.type == RewardTypes.RewardType.GOLD:
		return RewardApplicator.apply_reward(resolved, context)
	return _handle_item(resolved, context, null)


static func _validate_random_item(_definition: RewardDefinition, _target_char: Variant) -> Dictionary:
	return {"valid": true, "reason": ""}


# =============================================================================
# RANDOM SKILL HANDLER
# =============================================================================

static func _handle_random_skill(
	definition: RewardDefinition,
	context: Dictionary,
	_target_char: Variant
) -> RewardApplicator.ApplyResult:
	var resolved = RewardGenerator.resolve_reward(definition)
	if resolved.type == RewardTypes.RewardType.GOLD:
		return RewardApplicator.apply_reward(resolved, context)
	return _handle_skill(resolved, context, null)


static func _validate_random_skill(_definition: RewardDefinition, _target_char: Variant) -> Dictionary:
	return {"valid": true, "reason": ""}
