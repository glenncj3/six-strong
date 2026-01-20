extends PanelContainer
# CharacterCard - Reusable component for displaying character info
# Used in: Collection, Draft, Run View

signal card_clicked(character_data: Dictionary)

@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var health_label: Label = $MarginContainer/VBoxContainer/StatsContainer/HealthLabel
@onready var attack_label: Label = $MarginContainer/VBoxContainer/StatsContainer/AttackLabel
@onready var defense_label: Label = $MarginContainer/VBoxContainer/StatsContainer/DefenseLabel
@onready var speed_label: Label = $MarginContainer/VBoxContainer/StatsContainer/SpeedLabel
@onready var income_label: Label = $MarginContainer/VBoxContainer/StatsContainer/IncomeLabel

var character_data: Dictionary = {}
var clickable: bool = true


func _ready() -> void:
	if clickable:
		gui_input.connect(_on_gui_input)


func setup(char_data: Dictionary, with_equipped_items: bool = false) -> void:
	"""
	Configure the card with character data

	Args:
		char_data: Player's character data (from PlayerAccount)
		with_equipped_items: If true, calculate stats with equipped items
	"""
	character_data = char_data

	# Get master character data
	var char_master = GameData.get_character_by_id(char_data["id"])
	if char_master.is_empty():
		push_error("CharacterCard: Character master data not found: %s" % char_data["id"])
		return

	# Set portrait
	var portrait_path = char_master["image_path"]
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)

	# Set name
	name_label.text = char_master["name"]

	# Calculate stats
	var stats = _calculate_stats(char_master, char_data, with_equipped_items)

	# Display stats
	health_label.text = "HP %d" % stats["health"]
	attack_label.text = "ATK %d" % stats["basic_attack_damage"]
	defense_label.text = "DEF %d" % stats["defense"]
	speed_label.text = "SPD %d" % stats["speed"]
	income_label.text = "INC %d" % stats["income"]


func _calculate_stats(char_master: Dictionary, char_data: Dictionary, with_items: bool) -> Dictionary:
	"""Calculate character stats, optionally including equipped items"""
	var stats = {
		"health": char_master["base_stats"]["health"],
		"basic_attack_damage": char_master["base_stats"]["basic_attack_damage"],
		"defense": char_master["base_stats"]["defense"],
		"speed": char_master["base_stats"]["speed"],
		"income": char_master["base_stats"]["income"]
	}

	# Apply rank stat boosts
	if char_master.has("rank_rewards"):
		for rank_reward in char_master["rank_rewards"]:
			if rank_reward["rank"] <= char_data["rank"]:
				if rank_reward.has("stat_boost"):
					for stat_name in rank_reward["stat_boost"]:
						stats[stat_name] += rank_reward["stat_boost"][stat_name]

	# Apply equipped items if requested
	if with_items and char_data.has("equipped_items"):
		for item_id in char_data["equipped_items"]:
			var item_data = GameData.get_item_by_id(item_id)
			if item_data.has("stat_modifiers"):
				for stat_name in item_data["stat_modifiers"]:
					stats[stat_name] += item_data["stat_modifiers"][stat_name]

	return stats


func set_clickable(enabled: bool) -> void:
	"""Enable or disable click interaction"""
	clickable = enabled
	mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(character_data)


func highlight(enabled: bool) -> void:
	"""Visually highlight the card (for selection states)"""
	if enabled:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
