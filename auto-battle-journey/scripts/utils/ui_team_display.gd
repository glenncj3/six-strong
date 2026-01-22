class_name UITeamDisplay
extends RefCounted
## Team display utilities for populating character card displays.


static func populate_team_display(parent_container: Control, team: Array, title_text: String = "YOUR TEAM", on_card_clicked: Callable = Callable()) -> void:
	"""
	Populate a container with a team display showing the player's characters.
	The parent_container must already be in the scene tree.

	Args:
		parent_container: Container already in the scene tree to populate
		team: Array of CharacterInstance objects from RunManager.get_team()
		title_text: Title to show above the team (default: "YOUR TEAM")
		on_card_clicked: Optional callback when a card is clicked (receives CharacterInstance)
	"""
	print("UITeamDisplay.populate_team_display() - team size: %d" % team.size())
	UIContainerHelpers.clear_children(parent_container)

	# Set parent to pass mouse events so cards can receive them
	parent_container.mouse_filter = Control.MOUSE_FILTER_PASS

	var container = VBoxContainer.new()
	parent_container.add_child(container)
	container.add_theme_constant_override("separation", 8)
	container.mouse_filter = Control.MOUSE_FILTER_PASS

	# Title
	var title = Label.new()
	container.add_child(title)
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_BODY)
	title.modulate = GameConstants.COLOR_TEXT_LIGHT
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Cards container (horizontal)
	var cards_container = HBoxContainer.new()
	container.add_child(cards_container)
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 8)
	cards_container.mouse_filter = Control.MOUSE_FILTER_PASS

	# Add cards for each team member
	var character_card_scene = load("res://scenes/components/character_card.tscn")
	for char_instance in team:
		var card = character_card_scene.instantiate()
		cards_container.add_child(card)

		# Setup card with character data
		var display_data = {
			"id": char_instance.base_character_id,
			"prestige": 1,
			"experience": char_instance.experience,
			"equipped_items": char_instance.equipped_items
		}

		card.setup(display_data, false)
		card.set_card_size(UIScaler.CardSize.SMALL)

		# Enable clickable with hover feedback
		card.set_clickable(true)

		# Connect click callback if provided
		if on_card_clicked.is_valid():
			card.card_clicked.connect(func(_data): on_card_clicked.call(char_instance))

		# Update with runtime stats
		_update_card_runtime_stats(card, char_instance)


static func _update_card_runtime_stats(card: Node, char_instance) -> void:
	"""Update card display with runtime character stats."""
	var stats_container = card.get_node("MarginContainer/VBoxContainer/StatsContainer")

	# Update health to show current/max
	stats_container.get_node("HealthLabel").text = "HP %d/%d" % [char_instance.current_health, char_instance.max_health]
	stats_container.get_node("AttackLabel").text = UIFormattingHelpers.format_stat(GameConstants.STAT_ATTACK, char_instance.stats.get(GameConstants.STAT_ATTACK, 0))
	stats_container.get_node("DefenseLabel").text = UIFormattingHelpers.format_stat(GameConstants.STAT_DEFENSE, char_instance.stats.get(GameConstants.STAT_DEFENSE, 0))
	stats_container.get_node("SpeedLabel").text = UIFormattingHelpers.format_stat(GameConstants.STAT_SPEED, char_instance.stats.get(GameConstants.STAT_SPEED, 0))
	stats_container.get_node("IncomeLabel").text = UIFormattingHelpers.format_stat(GameConstants.STAT_INCOME, char_instance.stats.get(GameConstants.STAT_INCOME, 0))

	# Show level in name
	var name_label = card.get_node("MarginContainer/VBoxContainer/NameLabel")
	name_label.text = "%s (Lv.%d)" % [char_instance.get_character_name(), char_instance.level]
