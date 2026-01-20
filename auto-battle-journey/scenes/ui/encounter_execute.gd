extends Control
# EncounterExecute - Execute the selected encounter

@onready var title_label = $EncounterContainer/TitleLabel
@onready var content_container = $EncounterContainer/ContentContainer
@onready var complete_button = $CompleteButton

var encounter_data: Dictionary = {}
var encounter_completed: bool = false

# Reference to gold label for shop UI updates
var _gold_label: Label = null


func _ready() -> void:
	complete_button.pressed.connect(_on_complete_pressed)
	complete_button.disabled = true  # Enable after encounter interaction

	# Get selected encounter data from SceneManager
	encounter_data = SceneManager.get_scene_data("selected_encounter", {})
	if not encounter_data.is_empty():
		_setup_encounter()
	else:
		push_error("EncounterExecute: No encounter data found!")


func _setup_encounter() -> void:
	"""Setup the encounter UI based on type."""
	title_label.text = encounter_data["name"]

	match encounter_data["type"]:
		"shop":
			_setup_shop_encounter()
		"xp_reward":
			_setup_xp_reward_encounter()
		"gold_reward":
			_setup_gold_reward_encounter()
		"health_restore":
			_setup_health_restore_encounter()
		_:
			push_error("EncounterExecute: Unknown encounter type: %s" % encounter_data["type"])


# =============================================================================
# SHOP ENCOUNTER
# =============================================================================

func _setup_shop_encounter() -> void:
	"""Setup shop encounter UI."""
	var shop_ui = _create_shop_ui()
	content_container.add_child(shop_ui)


func _create_shop_ui() -> Control:
	"""Create shop UI with purchasable items."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	var label = Label.new()
	label.text = "Purchase items and skills with gold"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	_gold_label = Label.new()
	_gold_label.text = "Your Gold: %d" % RunManager.get_gold()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override("font_size", 20)
	_gold_label.modulate = Color(1.0, 0.84, 0.0)
	vbox.add_child(_gold_label)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 400)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 8)
	scroll.add_child(inventory_list)

	# Items for sale
	if encounter_data["data"].has("items") and encounter_data["data"]["items"].size() > 0:
		var items_title = Label.new()
		items_title.text = "--- ITEM UPGRADES FOR SALE ---"
		items_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_title.modulate = Color(0.8, 0.8, 0.8)
		inventory_list.add_child(items_title)

		for item_sale in encounter_data["data"]["items"]:
			var item_row = _create_shop_item_row(item_sale)
			inventory_list.add_child(item_row)

	# Skills for sale
	if encounter_data["data"].has("skills") and encounter_data["data"]["skills"].size() > 0:
		var skills_title = Label.new()
		skills_title.text = "--- SKILLS FOR SALE ---"
		skills_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skills_title.modulate = Color(0.8, 0.8, 0.8)
		inventory_list.add_child(skills_title)

		for skill_sale in encounter_data["data"]["skills"]:
			var skill_row = _create_shop_skill_row(skill_sale)
			inventory_list.add_child(skill_row)

	# Can complete shop after any interaction (or none)
	complete_button.disabled = false
	encounter_completed = true

	return vbox


func _create_shop_item_row(item_sale: Dictionary) -> Control:
	"""Create a row for a shop item upgrade."""
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var item_id = item_sale["id"]
	var cost = item_sale["cost"]

	var item_data = GameData.get_item_upgrade_by_id(item_id)
	if item_data.is_empty():
		return row

	# Icon - use UIHelpers for safe texture loading
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIHelpers.set_texture_safe(icon, item_data.get("image_path", ""))
	row.add_child(icon)

	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = item_data.get("name", "Unknown Item")
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item_data.get("description", "")
	desc_label.modulate = Color(0.7, 0.7, 0.7)
	desc_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(desc_label)

	# Level requirement
	var level_req = item_data.get("level_requirement", 1)
	if level_req > 1:
		var req_label = Label.new()
		req_label.text = "Requires Level %d" % level_req
		req_label.modulate = Color(1.0, 0.5, 0.5)
		req_label.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(req_label)

	# Character selector
	var char_selector = _create_character_selector()
	row.add_child(char_selector)

	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Buy (%d G)" % cost
	buy_button.custom_minimum_size = Vector2(80, 40)
	buy_button.pressed.connect(_on_buy_item.bind(item_id, cost, char_selector, buy_button))
	row.add_child(buy_button)

	return row


func _create_shop_skill_row(skill_sale: Dictionary) -> Control:
	"""Create a row for a shop skill."""
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var skill_id = skill_sale["id"]
	var cost = skill_sale["cost"]

	var skill_data = GameData.get_skill_by_id(skill_id)
	if skill_data.is_empty():
		return row

	# Icon - use UIHelpers for safe texture loading
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UIHelpers.set_texture_safe(icon, skill_data.get("image_path", ""))
	row.add_child(icon)

	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = skill_data.get("name", "Unknown Skill")
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = skill_data.get("description", "")
	desc_label.modulate = Color(0.7, 0.7, 0.7)
	desc_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(desc_label)

	# Level requirement
	var level_req = skill_data.get("level_requirement", 1)
	if level_req > 1:
		var req_label = Label.new()
		req_label.text = "Requires Level %d" % level_req
		req_label.modulate = Color(1.0, 0.5, 0.5)
		req_label.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(req_label)

	# Character selector
	var char_selector = _create_character_selector()
	row.add_child(char_selector)

	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Buy (%d G)" % cost
	buy_button.custom_minimum_size = Vector2(80, 40)
	buy_button.pressed.connect(_on_buy_skill.bind(skill_id, cost, char_selector, buy_button))
	row.add_child(buy_button)

	return row


func _create_character_selector() -> OptionButton:
	"""Create a character selector dropdown (DRY helper)."""
	var selector = OptionButton.new()
	selector.add_item("Select Character...")
	var team = RunManager.get_team()
	for i in range(team.size()):
		selector.add_item("%s (Lv.%d)" % [team[i].get_character_name(), team[i].level])
	return selector


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


func _update_gold_label() -> void:
	"""Update the gold display in shop."""
	if _gold_label:
		_gold_label.text = "Your Gold: %d" % RunManager.get_gold()


# =============================================================================
# XP REWARD ENCOUNTER
# =============================================================================

func _setup_xp_reward_encounter() -> void:
	"""Setup XP reward encounter UI."""
	var xp_ui = _create_xp_reward_ui()
	content_container.add_child(xp_ui)

	# Enable complete button immediately (no interaction needed)
	complete_button.disabled = false
	encounter_completed = true


func _create_xp_reward_ui() -> Control:
	"""Create XP reward UI."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)

	var label = Label.new()
	label.text = "Choose a character to receive XP"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)

	var xp_amount = encounter_data["data"]["xp_amount"]
	var xp_label = Label.new()
	xp_label.text = "XP Award: +%d" % xp_amount
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.add_theme_font_size_override("font_size", 32)
	xp_label.modulate = Color(0.3, 1.0, 0.3)
	vbox.add_child(xp_label)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)

	var team = RunManager.get_team()
	for i in range(team.size()):
		var char_instance = team[i]
		var button = Button.new()
		button.text = "Give to %s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
		button.custom_minimum_size = Vector2(300, 50)
		button.pressed.connect(_on_xp_character_selected.bind(i, xp_amount, button))
		vbox.add_child(button)

	return vbox


func _on_xp_character_selected(char_index: int, xp_amount: int, button: Button) -> void:
	"""Give XP to selected character."""
	var team = RunManager.get_team()
	var char_instance = team[char_index]

	var leveled_up = char_instance.add_experience(xp_amount)

	button.text = "XP Given! %s" % ("(LEVEL UP!)" if leveled_up else "")
	button.disabled = true

	print("EncounterExecute: Gave %d XP to %s" % [xp_amount, char_instance.get_character_name()])


# =============================================================================
# GOLD REWARD ENCOUNTER
# =============================================================================

func _setup_gold_reward_encounter() -> void:
	"""Setup gold reward encounter UI."""
	var gold_ui = _create_gold_reward_ui()
	content_container.add_child(gold_ui)

	# Enable complete button immediately
	complete_button.disabled = false
	encounter_completed = true


func _create_gold_reward_ui() -> Control:
	"""Create gold reward UI."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)

	var gold_amount = encounter_data["data"]["gold_amount"]

	var label = Label.new()
	label.text = "You found gold!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(label)

	var gold_label = Label.new()
	gold_label.text = "+%d Gold" % gold_amount
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 48)
	gold_label.modulate = Color(1.0, 0.84, 0.0)
	vbox.add_child(gold_label)

	# Award gold immediately
	RunManager.add_gold(gold_amount)
	print("EncounterExecute: Awarded %d gold" % gold_amount)

	return vbox


# =============================================================================
# HEALTH RESTORE ENCOUNTER
# =============================================================================

func _setup_health_restore_encounter() -> void:
	"""Setup health restore encounter UI."""
	var health_ui = _create_health_restore_ui()
	content_container.add_child(health_ui)

	# Enable complete button immediately
	complete_button.disabled = false
	encounter_completed = true


func _create_health_restore_ui() -> Control:
	"""Create health restore UI."""
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)

	var label = Label.new()
	label.text = "Your team's health is restored!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(label)

	var heal_percentage = encounter_data["data"]["heal_percentage"]
	var team = RunManager.get_team()

	for char_instance in team:
		var heal_amount = int(char_instance.max_health * heal_percentage)
		char_instance.heal(heal_amount)

		var char_label = Label.new()
		char_label.text = "%s: +%d HP (%d/%d)" % [
			char_instance.get_character_name(),
			heal_amount,
			char_instance.current_health,
			char_instance.max_health
		]
		char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		char_label.add_theme_font_size_override("font_size", 18)
		char_label.modulate = Color(0.3, 1.0, 0.3)
		vbox.add_child(char_label)

	print("EncounterExecute: Healed all characters by %d%%" % int(heal_percentage * 100))

	return vbox


# =============================================================================
# COMPLETION
# =============================================================================

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
