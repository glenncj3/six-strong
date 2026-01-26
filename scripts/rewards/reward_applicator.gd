class_name RewardApplicator
extends RefCounted
## Static methods to apply any reward to the game state.
## Handles validation, application, and fallback logic.


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
static func apply_reward(
	definition: RewardDefinition,
	context: Dictionary = {},
	target_char: Variant = null  # CharacterInstance or null
) -> ApplyResult:
	match definition.type:
		RewardTypes.RewardType.GOLD:
			return _apply_gold(definition, context)
		RewardTypes.RewardType.HEALTH:
			return _apply_health(definition, context, target_char)
		RewardTypes.RewardType.XP:
			return _apply_xp(definition, context, target_char)
		RewardTypes.RewardType.ITEM:
			return _apply_item(definition, context, target_char)
		RewardTypes.RewardType.SKILL:
			return _apply_skill(definition, context, target_char)
		RewardTypes.RewardType.ITEM_RANDOM:
			return _apply_random_item(definition, context, target_char)
		RewardTypes.RewardType.SKILL_RANDOM:
			return _apply_random_skill(definition, context, target_char)

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
			return _can_apply_item(definition, target_char)
		RewardTypes.RewardType.SKILL:
			return _can_apply_skill(definition, target_char)
		RewardTypes.RewardType.ITEM_RANDOM:
			return _can_apply_random_item(definition, target_char)
		RewardTypes.RewardType.SKILL_RANDOM:
			return _can_apply_random_skill(definition, target_char)

	return {"valid": false, "reason": "Unknown reward type"}


## Get a fallback reward when the primary can't be applied
## e.g., gold if skill slots are full
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
static func get_eligible_characters(definition: RewardDefinition) -> Dictionary:
	var team = RunManager.get_team()

	match definition.type:
		RewardTypes.RewardType.HEALTH:
			return EncounterUIHelpers.filter_heal_eligible_characters(team)
		RewardTypes.RewardType.ITEM:
			var item_id = definition.params.get("item_id", "")
			return EncounterUIHelpers.filter_item_eligible_characters(team, item_id)
		RewardTypes.RewardType.SKILL:
			var skill_id = definition.params.get("skill_id", "")
			return EncounterUIHelpers.filter_skill_eligible_characters(team, skill_id)
		RewardTypes.RewardType.ITEM_RANDOM:
			return _filter_any_item_eligible_characters(team)
		RewardTypes.RewardType.SKILL_RANDOM:
			return _filter_any_skill_eligible_characters(team)

	# XP and Gold don't need character selection
	return {"indices": [], "characters": []}


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


static func _apply_xp(definition: RewardDefinition, context: Dictionary, target_char: Variant) -> ApplyResult:
	var team = RunManager.get_team()
	var targets: Array = []
	var amount = definition.params.get("amount", 0)

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
				return ApplyResult.new(false, "No character selected for XP")

	if targets.is_empty():
		return ApplyResult.new(false, "No valid targets for XP")

	var on_xp_select = context.get("on_xp_select", Callable())

	for i in range(team.size()):
		if team[i] in targets:
			if on_xp_select.is_valid():
				on_xp_select.call(i, amount, null)
			else:
				team[i].xp += amount

	var result = ApplyResult.new(true, "+%d XP to %d characters" % [amount, targets.size()])
	result.actual_reward = definition
	return result


static func _apply_item(definition: RewardDefinition, context: Dictionary, target_char: Variant) -> ApplyResult:
	if target_char == null:
		return ApplyResult.new(false, "No character selected for item")

	var item_id = definition.params.get("item_id", "")
	if item_id.is_empty():
		return ApplyResult.new(false, "Invalid item ID")

	# Check eligibility
	var can_apply = _can_apply_item(definition, target_char)
	if not can_apply["valid"]:
		# Try fallback
		var fallback = get_fallback_reward(definition)
		var fallback_result = apply_reward(fallback, context, target_char)
		fallback_result.fallback_used = true
		return fallback_result

	# Apply item via context callback or directly
	var on_buy_item = context.get("on_buy_item", Callable())
	if on_buy_item.is_valid():
		# The callback signature is (item_id, cost, selector, button)
		# For free rewards, pass 0 cost and null for UI elements
		on_buy_item.call(item_id, 0, null, null)
	else:
		target_char.equipped_item_upgrades.append(item_id)

	var item_data = GameData.get_item_upgrade(item_id)
	var result = ApplyResult.new(true, "Equipped %s" % item_data.get("name", "Item"))
	result.actual_reward = definition
	return result


static func _apply_skill(definition: RewardDefinition, context: Dictionary, target_char: Variant) -> ApplyResult:
	if target_char == null:
		return ApplyResult.new(false, "No character selected for skill")

	var skill_id = definition.params.get("skill_id", "")
	if skill_id.is_empty():
		return ApplyResult.new(false, "Invalid skill ID")

	# Check eligibility
	var can_apply = _can_apply_skill(definition, target_char)
	if not can_apply["valid"]:
		# Try fallback
		var fallback = get_fallback_reward(definition)
		var fallback_result = apply_reward(fallback, context, target_char)
		fallback_result.fallback_used = true
		return fallback_result

	# Apply skill via context callback or directly
	var on_buy_skill = context.get("on_buy_skill", Callable())
	if on_buy_skill.is_valid():
		on_buy_skill.call(skill_id, 0, null, null)
	else:
		target_char.learned_skills.append(skill_id)

	var skill_data = GameData.get_skill(skill_id)
	var result = ApplyResult.new(true, "Learned %s" % skill_data.get("name", "Skill"))
	result.actual_reward = definition
	return result


static func _apply_random_item(definition: RewardDefinition, context: Dictionary, target_char: Variant) -> ApplyResult:
	# Resolve to a concrete item
	var resolved = RewardGenerator.resolve_reward(definition)
	if resolved.type == RewardTypes.RewardType.GOLD:
		# Fallback was used during resolution
		return apply_reward(resolved, context, target_char)

	return _apply_item(resolved, context, target_char)


static func _apply_random_skill(definition: RewardDefinition, context: Dictionary, target_char: Variant) -> ApplyResult:
	# Resolve to a concrete skill
	var resolved = RewardGenerator.resolve_reward(definition)
	if resolved.type == RewardTypes.RewardType.GOLD:
		# Fallback was used during resolution
		return apply_reward(resolved, context, target_char)

	return _apply_skill(resolved, context, target_char)


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


static func _can_apply_item(definition: RewardDefinition, target_char: Variant) -> Dictionary:
	if target_char == null:
		return {"valid": false, "reason": "No character selected"}

	var item_id = definition.params.get("item_id", "")
	if item_id.is_empty():
		return {"valid": false, "reason": "Invalid item ID"}

	# Check if already equipped
	if item_id in target_char.equipped_item_upgrades:
		return {"valid": false, "reason": "Already equipped"}

	# Check item slots
	var total_items = target_char.equipped_items.size() + target_char.equipped_item_upgrades.size()
	if total_items >= GameConstants.MAX_RUN_ITEMS:
		return {"valid": false, "reason": "Item slots full"}

	return {"valid": true, "reason": ""}


static func _can_apply_skill(definition: RewardDefinition, target_char: Variant) -> Dictionary:
	if target_char == null:
		return {"valid": false, "reason": "No character selected"}

	var skill_id = definition.params.get("skill_id", "")
	if skill_id.is_empty():
		return {"valid": false, "reason": "Invalid skill ID"}

	# Check if already learned
	if skill_id in target_char.learned_skills:
		return {"valid": false, "reason": "Already learned"}

	# Check skill slots
	if target_char.learned_skills.size() >= GameConstants.MAX_RUN_SKILLS:
		return {"valid": false, "reason": "Skill slots full"}

	return {"valid": true, "reason": ""}


static func _can_apply_random_item(_definition: RewardDefinition, target_char: Variant) -> Dictionary:
	if target_char == null:
		# Check if any character has space
		var team = RunManager.get_team()
		for char_instance in team:
			var char_total_items = char_instance.equipped_items.size() + char_instance.equipped_item_upgrades.size()
			if char_total_items < GameConstants.MAX_RUN_ITEMS:
				return {"valid": true, "reason": ""}
		return {"valid": false, "reason": "All item slots full"}

	var total_items = target_char.equipped_items.size() + target_char.equipped_item_upgrades.size()
	if total_items >= GameConstants.MAX_RUN_ITEMS:
		return {"valid": false, "reason": "Item slots full"}

	return {"valid": true, "reason": ""}


static func _can_apply_random_skill(_definition: RewardDefinition, target_char: Variant) -> Dictionary:
	if target_char == null:
		# Check if any character has space
		var team = RunManager.get_team()
		for char_instance in team:
			if char_instance.learned_skills.size() < GameConstants.MAX_RUN_SKILLS:
				return {"valid": true, "reason": ""}
		return {"valid": false, "reason": "All skill slots full"}

	if target_char.learned_skills.size() >= GameConstants.MAX_RUN_SKILLS:
		return {"valid": false, "reason": "Skill slots full"}

	return {"valid": true, "reason": ""}


# =============================================================================
# HELPER METHODS
# =============================================================================

static func _filter_any_item_eligible_characters(team: Array) -> Dictionary:
	"""Filter to characters who have space for any item."""
	var indices: Array = []
	var characters: Array = []

	for i in range(team.size()):
		var char_instance = team[i]
		var total_items = char_instance.equipped_items.size() + char_instance.equipped_item_upgrades.size()
		if total_items < GameConstants.MAX_RUN_ITEMS:
			indices.append(i)
			characters.append(char_instance)

	return {"indices": indices, "characters": characters}


static func _filter_any_skill_eligible_characters(team: Array) -> Dictionary:
	"""Filter to characters who have space for any skill."""
	var indices: Array = []
	var characters: Array = []

	for i in range(team.size()):
		var char_instance = team[i]
		if char_instance.learned_skills.size() < GameConstants.MAX_RUN_SKILLS:
			indices.append(i)
			characters.append(char_instance)

	return {"indices": indices, "characters": characters}
