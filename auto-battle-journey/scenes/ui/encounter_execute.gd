extends Control
# EncounterExecute - Execute the selected encounter
# Refactored to use data-driven EncounterHandlers for extensibility

@onready var title_label = $EncounterContainer/TitleLabel
@onready var content_container = $EncounterContainer/ContentContainer
@onready var complete_button = $CompleteButton
@onready var skip_button = $SkipButton

var encounter_data: Dictionary = {}
var encounter_completed: bool = false

# Reference to gold label for shop UI updates
var _gold_label: Label = null


func _ready() -> void:
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
		"on_encounter_complete": _enable_complete
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
	var selected_index = char_selector.selected - 1  # -1 because first item is "Select Character..."

	if selected_index < 0:
		print("EncounterExecute: Must select a character first")
		return

	if not RunManager.spend_gold(cost):
		print("EncounterExecute: Not enough gold")
		return

	var team = RunManager.get_team()
	var char_instance = team[selected_index]

	var success = char_instance.equip_item_upgrade(item_id)
	if success:
		print("EncounterExecute: Purchased and equipped item upgrade: %s" % item_id)
		button.disabled = true
		button.text = "PURCHASED"
		_update_gold_label()
	else:
		# Refund if level requirement not met
		RunManager.add_gold(cost)
		print("EncounterExecute: Cannot equip - level requirement not met")


func _on_buy_skill(skill_id: String, cost: int, char_selector: OptionButton, button: Button) -> void:
	"""Handle buying a skill."""
	var selected_index = char_selector.selected - 1

	if selected_index < 0:
		print("EncounterExecute: Must select a character first")
		return

	if not RunManager.spend_gold(cost):
		print("EncounterExecute: Not enough gold")
		return

	var team = RunManager.get_team()
	var char_instance = team[selected_index]

	var success = char_instance.learn_skill(skill_id)
	if success:
		print("EncounterExecute: Purchased and learned skill: %s" % skill_id)
		button.disabled = true
		button.text = "LEARNED"
		_update_gold_label()
	else:
		# Refund if already learned or level requirement not met
		RunManager.add_gold(cost)
		print("EncounterExecute: Cannot learn skill")


func _on_xp_character_selected(char_index: int, xp_amount: int, button: Button) -> void:
	"""Give XP to selected character."""
	var team = RunManager.get_team()
	var char_instance = team[char_index]

	var leveled_up = char_instance.add_experience(xp_amount)

	button.text = "XP Given! %s" % ("(LEVEL UP!)" if leveled_up else "")
	button.disabled = true

	print("EncounterExecute: Gave %d XP to %s" % [xp_amount, char_instance.get_character_name()])


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
	print("EncounterExecute: Skipping encounter...")

	# Complete encounter (advances game state) but player gets no rewards
	RunManager.complete_encounter()

	# Return to run view using SceneManager
	SceneManager.go_to("run_view")


func _on_complete_pressed() -> void:
	"""Complete the encounter and return to run view."""
	if not encounter_completed:
		print("EncounterExecute: Encounter not ready to complete")
		return

	print("EncounterExecute: Completing encounter...")

	# Switch to combat phase
	RunManager.complete_encounter()

	# Return to run view using SceneManager
	SceneManager.go_to("run_view")
