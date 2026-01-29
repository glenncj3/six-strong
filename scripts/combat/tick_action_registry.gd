class_name TickActionRegistry
extends RefCounted
## Static registry mapping tick action ID strings to Callables.

static var _actions: Dictionary = {}
static var _registered: bool = false


static func register(id: String, action: Callable) -> void:
	_actions[id] = action


static func get_action(id: String) -> Callable:
	if _actions.has(id):
		return _actions[id]
	return Callable()


static func has_action(id: String) -> bool:
	return _actions.has(id)


static func register_defaults() -> void:
	if _registered:
		return
	_registered = true
	register("poison_tick", _poison_tick)
	register("burn_apply", _burn_apply)


static func _poison_tick(context: Dictionary) -> void:
	var character: CombatCharacter = context["character"]
	var effect: CombatEffect = context["effect"]
	var mgr_ctx: Dictionary = context["manager_context"]

	if effect.stacks <= 0:
		return

	# Deal damage equal to stacks (null source = no block/crit)
	var deal_damage: Callable = mgr_ctx["deal_damage"]
	deal_damage.call(null, character, float(effect.stacks))

	# Decrement stacks
	effect.stacks -= 1

	# Mark for removal at 0 stacks by setting duration to expire
	if effect.stacks <= 0:
		# Remove by setting to a duration type that will expire
		character.effects.erase(effect)


static func _burn_apply(context: Dictionary) -> void:
	var character: CombatCharacter = context["character"]
	var effect: CombatEffect = context["effect"]
	var mgr_ctx: Dictionary = context["manager_context"]

	if effect.stacks <= 0:
		return

	# Deal damage equal to total burn stacks (null source = no block/crit)
	var deal_damage: Callable = mgr_ctx["deal_damage"]
	deal_damage.call(null, character, float(effect.stacks))
