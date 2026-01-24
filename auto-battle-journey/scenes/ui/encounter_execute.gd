extends Control
# EncounterExecute - Execute the selected encounter
# Refactored to use data-driven EncounterHandlers for extensibility

@onready var background = $Background
@onready var title_label = $EncounterContainer/TitleLabel
@onready var content_container = $EncounterContainer/ContentContainer
@onready var complete_button = $ButtonContainer/CompleteButton
@onready var skip_button = $ButtonContainer/SkipButton

var encounter_data: Dictionary = {}
var encounter_completed: bool = false

# Reference to gold label for shop UI updates
var _gold_label: Label = null


func _ready() -> void:
	_apply_visual_styling()
	complete_button.pressed.connect(_on_complete_pressed)
	complete_button.disabled = true  # Enable after encounter interaction
	skip_button.pressed.connect(_on_skip_pressed)

	# Get selected encounter data from SceneManager
	encounter_data = SceneManager.get_scene_data("selected_encounter", {})
	if not encounter_data.is_empty():
		_setup_encounter()
		_play_entrance_animations()
	else:
		push_error("EncounterExecute: No encounter data found!")


func _apply_visual_styling() -> void:
	"""Apply consistent visual styling."""
	UIStyles.setup_danger_button(skip_button, GameConstants.FONT_SIZE_BUTTON)
	ButtonEffects.apply_effects(skip_button)
	UIStyles.setup_success_button(complete_button, GameConstants.FONT_SIZE_BUTTON)
	ButtonEffects.apply_effects(complete_button)


func _play_entrance_animations() -> void:
	"""Play entrance animations."""
	AnimationManager.fade_in(title_label, GameConstants.ANIM_DURATION_NORMAL, 0.0)
	AnimationManager.fade_in(content_container, GameConstants.ANIM_DURATION_NORMAL, 0.1)


func _setup_encounter() -> void:
	"""Setup the encounter UI using the data-driven handler system."""
	title_label.text = encounter_data["name"]

	var encounter_type = encounter_data.get("type", "")

	# Check if handler exists
	if not EncounterHandlers.has_handler(encounter_type):
		push_error("EncounterExecute: Unknown encounter type: %s" % encounter_type)
		return

	# Create context with callbacks for handlers
	var context = {
		"set_gold_label": _set_gold_label,
		"on_buy_item": _on_buy_item,
		"on_buy_skill": _on_buy_skill,
		"on_xp_select": _on_xp_character_selected,
		"on_encounter_complete": _enable_complete,
		"on_gold_reward": _on_gold_reward,
		"on_health_restore": _on_health_restore,
		"on_skill_learn": _on_skill_learn,
		"on_gold_spend": _on_gold_spend,
		"on_xp_reward_all": _on_xp_reward_all,
	}

	# Create UI using the handler
	var ui = EncounterHandlers.create_ui(encounter_data, context)
	if ui:
		content_container.add_child(ui)

	# Check if encounter completes immediately
	if EncounterHandlers.should_complete_immediately(encounter_type):
		complete_button.disabled = false
		encounter_completed = true


# =============================================================================
# CALLBACK METHODS FOR HANDLERS
# =============================================================================

func _set_gold_label(label: Label) -> void:
	"""Store reference to gold label for updates."""
	_gold_label = label


func _on_buy_item(item_id: String, cost: int, char_selector: OptionButton, button: Button) -> void:
	"""Handle buying an item upgrade."""
	_handle_purchase(item_id, cost, char_selector, button, func(ci, id): return ci.equip_item_upgrade(id), "PURCHASED")


func _on_buy_skill(skill_id: String, cost: int, char_selector: OptionButton, button: Button) -> void:
	"""Handle buying a skill."""
	_handle_purchase(skill_id, cost, char_selector, button, func(ci, id): return ci.learn_skill(id), "LEARNED")


func _handle_purchase(content_id: String, cost: int, char_selector: OptionButton, button: Button, action: Callable, success_text: String) -> void:
	"""Handle a purchase (item or skill) with character selection."""
	var char_index = char_selector.selected - 1
	var result = RunManager.attempt_purchase(cost, char_index, func(ci): return action.call(ci, content_id))
	if result["success"]:
		button.disabled = true
		button.text = success_text
		_update_gold_label()


func _on_xp_character_selected(char_index: int, xp_amount: int, button: Button) -> void:
	"""Give XP to selected character."""
	var team = RunManager.get_team()
	var char_instance = team[char_index]

	var leveled_up = char_instance.add_experience(xp_amount)

	button.text = "XP Given! %s" % ("(LEVEL UP!)" if leveled_up else "")
	button.disabled = true


func _on_gold_reward(amount: int) -> void:
	"""Handle gold reward from encounters."""
	RunManager.add_gold(amount)
	_update_gold_label()


func _on_health_restore(char_instance: CharacterInstance, heal_amount: int) -> void:
	"""Handle health restore for a character."""
	char_instance.heal(heal_amount)


func _on_skill_learn(char_instance: CharacterInstance, skill_id: String) -> bool:
	"""Handle skill learning. Returns true on success."""
	return char_instance.learn_skill(skill_id)


func _on_gold_spend(amount: int) -> bool:
	"""Handle gold spending. Returns true on success."""
	var success = RunManager.spend_gold(amount)
	if success:
		_update_gold_label()
	return success


func _on_xp_reward_all(xp_amount: int) -> void:
	"""Handle XP reward for all team members."""
	for char_instance in RunManager.get_team():
		char_instance.add_experience(xp_amount)


func _update_gold_label() -> void:
	"""Update the gold display in shop."""
	if _gold_label:
		_gold_label.text = "Your Gold: %d" % RunManager.get_gold()


# =============================================================================
# COMPLETION
# =============================================================================

func _enable_complete() -> void:
	"""Enable the complete button - called by handlers when encounter is ready to complete."""
	complete_button.disabled = false
	encounter_completed = true


func _on_skip_pressed() -> void:
	"""Skip the encounter without taking rewards and return to run view."""

	# Complete encounter (advances game state) but player gets no rewards
	RunManager.complete_encounter()

	# Return to run view using SceneManager
	SceneManager.go_to("run_view")


func _on_complete_pressed() -> void:
	"""Complete the encounter and return to run view."""
	if not encounter_completed:
		return

	# Switch to combat phase
	RunManager.complete_encounter()

	# Return to run view using SceneManager
	SceneManager.go_to("run_view")
