class_name ShopEncounterUI
extends RefCounted
## UI creation and reward preview for shop encounters.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create shop encounter UI."""
	var vbox = UIHelpers.create_vbox_container()

	vbox.add_child(UIHelpers.create_label("Purchase items and skills with gold", GameConstants.FONT_SIZE_BODY, GameConstants.COLOR_TEXT_LIGHT, true))

	var gold_label = UIHelpers.create_label("Your Gold: %d" % RunManager.get_gold(), GameConstants.FONT_SIZE_GOLD_DISPLAY, GameConstants.COLOR_GOLD, true)
	vbox.add_child(gold_label)

	# Store gold label reference in context for updates
	if context.has("set_gold_label"):
		context["set_gold_label"].call(gold_label)

	vbox.add_child(UIHelpers.create_spacer(10))

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 400)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", GameConstants.CONTENT_SEPARATION)
	scroll.add_child(inventory_list)

	var team = RunManager.get_team()

	# Items for sale
	if encounter_data["data"].has("items") and encounter_data["data"]["items"].size() > 0:
		var items_title = Label.new()
		items_title.text = "--- ITEM UPGRADES FOR SALE ---"
		items_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_title.modulate = GameConstants.COLOR_MUTED
		inventory_list.add_child(items_title)

		for item_sale in encounter_data["data"]["items"]:
			var item_data = GameData.get_item_upgrade_by_id(item_sale["id"])
			if not item_data.is_empty():
				var item_row = UIHelpers.create_shop_row(
					item_data,
					item_sale["cost"],
					team,
					context.get("on_buy_item", Callable()),
					"item"
				)
				inventory_list.add_child(item_row)

	# Skills for sale
	if encounter_data["data"].has("skills") and encounter_data["data"]["skills"].size() > 0:
		var skills_title = Label.new()
		skills_title.text = "--- SKILLS FOR SALE ---"
		skills_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skills_title.modulate = GameConstants.COLOR_MUTED
		inventory_list.add_child(skills_title)

		for skill_sale in encounter_data["data"]["skills"]:
			var skill_data = GameData.get_skill_by_id(skill_sale["id"])
			if not skill_data.is_empty():
				var skill_row = UIHelpers.create_shop_row(
					skill_data,
					skill_sale["cost"],
					team,
					context.get("on_buy_skill", Callable()),
					"skill"
				)
				inventory_list.add_child(skill_row)

	return vbox


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for shop encounter."""
	var data = encounter_data.get("data", {})
	var item_count = data.get("items", []).size()
	var skill_count = data.get("skills", []).size()
	return "%d items, %d skills" % [item_count, skill_count]
