class_name EncounterContext
extends RefCounted
## Typed context for encounter handlers.
## Provides compile-time safety and a clear interface for callbacks.
##
## Usage:
##   var context = EncounterContext.new()
##   context.on_encounter_complete = _enable_complete
##   context.on_gold_spend = _on_gold_spend
##   EncounterHandlers.create_ui(encounter_data, context)

# =============================================================================
# UI SETUP CALLBACKS
# =============================================================================

## Store reference to gold label for updates during encounter
## Signature: func(label: Label) -> void
var set_gold_label: Callable = Callable()

# =============================================================================
# PURCHASE CALLBACKS
# =============================================================================

## Handle item purchase from shop
## Signature: func(item_id: String, cost: int, selector: OptionButton, button: Button) -> void
var on_buy_item: Callable = Callable()

## Handle skill purchase from shop
## Signature: func(skill_id: String, cost: int, selector: OptionButton, button: Button) -> void
var on_buy_skill: Callable = Callable()

## Handle gold spending (returns true on success)
## Signature: func(amount: int) -> bool
var on_gold_spend: Callable = Callable()

# =============================================================================
# REWARD CALLBACKS
# =============================================================================

## Handle XP character selection
## Signature: func(char_index: int, xp_amount: int, button: Button) -> void
var on_xp_select: Callable = Callable()

## Handle gold reward
## Signature: func(amount: int) -> void
var on_gold_reward: Callable = Callable()

## Handle health restore for a character
## Signature: func(char_instance: CharacterInstance, heal_amount: int) -> void
var on_health_restore: Callable = Callable()

## Handle skill learning (returns true on success)
## Signature: func(char_instance: CharacterInstance, skill_id: String) -> bool
var on_skill_learn: Callable = Callable()

## Handle XP reward for all team members
## Signature: func(xp_amount: int) -> void
var on_xp_reward_all: Callable = Callable()

# =============================================================================
# COMPLETION CALLBACKS
# =============================================================================

## Signal that encounter can be completed (enables complete button)
## Signature: func() -> void
var on_encounter_complete: Callable = Callable()

# =============================================================================
# CONVENIENCE METHODS
# =============================================================================

## Check if a callback is set and valid
func has_callback(callback_name: String) -> bool:
	var callback = get(callback_name)
	return callback is Callable and callback.is_valid()


## Call a callback if it's valid, returns false if not called
func try_call(callback_name: String, args: Array = []) -> bool:
	var callback = get(callback_name)
	if callback is Callable and callback.is_valid():
		callback.callv(args)
		return true
	return false


## Convert to dictionary (for backwards compatibility with existing handlers)
func to_dict() -> Dictionary:
	return {
		"set_gold_label": set_gold_label,
		"on_buy_item": on_buy_item,
		"on_buy_skill": on_buy_skill,
		"on_xp_select": on_xp_select,
		"on_encounter_complete": on_encounter_complete,
		"on_gold_reward": on_gold_reward,
		"on_health_restore": on_health_restore,
		"on_skill_learn": on_skill_learn,
		"on_gold_spend": on_gold_spend,
		"on_xp_reward_all": on_xp_reward_all,
	}


## Create from dictionary (for backwards compatibility)
static func from_dict(dict: Dictionary) -> EncounterContext:
	var ctx = EncounterContext.new()
	ctx.set_gold_label = dict.get("set_gold_label", Callable())
	ctx.on_buy_item = dict.get("on_buy_item", Callable())
	ctx.on_buy_skill = dict.get("on_buy_skill", Callable())
	ctx.on_xp_select = dict.get("on_xp_select", Callable())
	ctx.on_encounter_complete = dict.get("on_encounter_complete", Callable())
	ctx.on_gold_reward = dict.get("on_gold_reward", Callable())
	ctx.on_health_restore = dict.get("on_health_restore", Callable())
	ctx.on_skill_learn = dict.get("on_skill_learn", Callable())
	ctx.on_gold_spend = dict.get("on_gold_spend", Callable())
	ctx.on_xp_reward_all = dict.get("on_xp_reward_all", Callable())
	return ctx
