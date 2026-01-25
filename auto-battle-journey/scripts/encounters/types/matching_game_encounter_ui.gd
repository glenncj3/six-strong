class_name MatchingGameEncounterUI
extends RefCounted
## UI creation for matching game encounters.
## Player reveals tiles one at a time until two of the same type are found.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create matching game encounter UI."""
	var game = MatchingGameController.new()
	game.initialize(encounter_data, context)
	return game


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for matching game encounter."""
	var data = encounter_data.get("data", {})
	var big = data.get("big_gold", 50)
	var small = data.get("small_gold", 10)
	return "%d-%d Gold" % [small, big]


## Inner class that handles all game state and logic as a proper node
class MatchingGameController extends VBoxContainer:
	const TILE_SIZE := 130
	const TILE_SPACING := 12
	const GRID_SIZE := 3

	const TILE_BIG := "big"
	const TILE_MEDIUM := "medium"
	const TILE_SMALL := "small"

	const COLOR_BIG := Color("#FFD700")
	const COLOR_MEDIUM := Color("#C0C0C0")
	const COLOR_SMALL := Color("#CD7F32")
	const COLOR_FACE_DOWN := Color("#4A3D34")

	var encounter_data: Dictionary
	var context: Dictionary
	var tiles: Array = []  # Array of {type, is_revealed, button}
	var revealed_counts: Dictionary = {TILE_BIG: 0, TILE_MEDIUM: 0, TILE_SMALL: 0}
	var game_over: bool = false
	var result_label: Label


	func initialize(p_encounter_data: Dictionary, p_context: Dictionary) -> void:
		encounter_data = p_encounter_data
		context = p_context

		set_anchors_preset(Control.PRESET_FULL_RECT)
		add_theme_constant_override("separation", 12)
		alignment = BoxContainer.ALIGNMENT_CENTER

		var data = encounter_data.get("data", {})
		var big_gold = data.get("big_gold", 50)
		var medium_gold = data.get("medium_gold", 25)
		var small_gold = data.get("small_gold", 10)

		# Title
		var title = UIHelpers.create_label(
			"Flip tiles until you find a matching pair!",
			GameConstants.FONT_SIZE_HEADING,
			GameConstants.COLOR_TEXT_LIGHT,
			true
		)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(title)

		# Reward info
		var rewards = UIHelpers.create_label(
			"Big: %d | Medium: %d | Small: %d" % [big_gold, medium_gold, small_gold],
			GameConstants.FONT_SIZE_BODY,
			GameConstants.COLOR_GOLD,
			true
		)
		rewards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(rewards)

		# Result label (shown when match is found)
		result_label = UIHelpers.create_label("", GameConstants.FONT_SIZE_REWARD, GameConstants.COLOR_SUCCESS, true)
		result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(result_label)

		# Create grid
		_create_tile_grid()


	func _create_tile_grid() -> void:
		var center = CenterContainer.new()
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var grid = GridContainer.new()
		grid.columns = GRID_SIZE
		grid.add_theme_constant_override("h_separation", TILE_SPACING)
		grid.add_theme_constant_override("v_separation", TILE_SPACING)

		# Create tile types: 2 big, 3 medium, 4 small
		var tile_types: Array = []
		for i in range(2):
			tile_types.append(TILE_BIG)
		for i in range(3):
			tile_types.append(TILE_MEDIUM)
		for i in range(4):
			tile_types.append(TILE_SMALL)
		tile_types.shuffle()

		# Create buttons
		for i in range(9):
			var button = _create_tile_button(i)
			tiles.append({
				"type": tile_types[i],
				"is_revealed": false,
				"button": button
			})
			grid.add_child(button)

		center.add_child(grid)
		add_child(center)


	func _create_tile_button(index: int) -> Button:
		var button = Button.new()
		button.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		button.text = "?"
		button.add_theme_font_size_override("font_size", 40)

		var style = StyleBoxFlat.new()
		style.bg_color = COLOR_FACE_DOWN
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)
		style.border_color = GameConstants.COLOR_BORDER_GOLD
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style.duplicate())
		button.add_theme_stylebox_override("pressed", style.duplicate())
		button.add_theme_stylebox_override("disabled", style.duplicate())

		button.pressed.connect(_on_tile_pressed.bind(index))
		return button


	func _on_tile_pressed(index: int) -> void:
		if game_over:
			return

		var tile = tiles[index]
		if tile.is_revealed:
			return

		# Reveal the tile
		_reveal_tile(index)

		# Check for match
		var tile_type = tile.type
		revealed_counts[tile_type] += 1

		if revealed_counts[tile_type] >= 2:
			_complete_game(tile_type)


	func _reveal_tile(index: int) -> void:
		var tile = tiles[index]
		tile.is_revealed = true

		var button: Button = tile.button
		var color: Color
		var symbol: String

		match tile.type:
			TILE_BIG:
				color = COLOR_BIG
				symbol = "$$$"
			TILE_MEDIUM:
				color = COLOR_MEDIUM
				symbol = "$$"
			TILE_SMALL:
				color = COLOR_SMALL
				symbol = "$"
			_:
				color = COLOR_FACE_DOWN
				symbol = "?"

		button.text = symbol

		var style = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)
		style.border_color = GameConstants.COLOR_BORDER_GOLD
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style.duplicate())
		button.add_theme_stylebox_override("pressed", style.duplicate())
		button.add_theme_stylebox_override("disabled", style.duplicate())
		button.disabled = true


	func _complete_game(matched_type: String) -> void:
		game_over = true

		# Calculate reward
		var data = encounter_data.get("data", {})
		var gold_reward: int = 0
		var type_name: String = ""

		match matched_type:
			TILE_BIG:
				gold_reward = data.get("big_gold", 50)
				type_name = "BIG"
			TILE_MEDIUM:
				gold_reward = data.get("medium_gold", 25)
				type_name = "MEDIUM"
			TILE_SMALL:
				gold_reward = data.get("small_gold", 10)
				type_name = "SMALL"

		# Award gold
		var on_gold_reward = context.get("on_gold_reward", Callable())
		if on_gold_reward.is_valid():
			on_gold_reward.call(gold_reward)
		else:
			RunManager.add_gold(gold_reward)

		# Update UI
		result_label.text = "%s Match! +%d Gold!" % [type_name, gold_reward]

		# Disable all remaining buttons
		for tile in tiles:
			tile.button.disabled = true

		# Signal completion
		var on_complete = context.get("on_encounter_complete", Callable())
		if on_complete.is_valid():
			on_complete.call()
