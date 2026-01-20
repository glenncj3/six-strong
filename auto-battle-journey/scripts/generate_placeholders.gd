@tool
extends EditorScript
# Run this script from Godot Editor: Script -> Run (Ctrl+Shift+X)
# Generates placeholder images for all game assets

func _run() -> void:
	print("Generating placeholder assets...")

	# Character portraits (128x128)
	var characters = {
		"knight": Color.RED,
		"mage": Color.BLUE,
		"rogue": Color.GREEN,
		"cleric": Color.YELLOW,
		"ranger": Color.PURPLE
	}

	for char_name in characters:
		_create_placeholder("res://assets/characters/%s.png" % char_name, 128, 128, characters[char_name])

	# Item icons (64x64)
	var items = {
		"rusty_sword": Color.GRAY,
		"rusty_dagger": Color.DIM_GRAY,
		"wooden_staff": Color.SADDLE_BROWN,
		"prayer_book": Color.WHITE,
		"short_bow": Color.DARK_GREEN,
		"leather_armor": Color.SIENNA,
		"flaming_sword": Color.ORANGE_RED,
		"iron_sword": Color.SILVER
	}

	for item_name in items:
		_create_placeholder("res://assets/items/%s.png" % item_name, 64, 64, items[item_name])

	# Skill icons (64x64)
	var skills = {
		"power_strike": Color.CRIMSON,
		"dodge": Color.DODGER_BLUE,
		"iron_skin": Color.SLATE_GRAY,
		"vitality": Color.LIME_GREEN
	}

	for skill_name in skills:
		_create_placeholder("res://assets/skills/%s.png" % skill_name, 64, 64, skills[skill_name])

	# Encounter icons (128x128)
	_create_placeholder("res://assets/encounters/merchant.png", 128, 128, Color.ORANGE)
	_create_placeholder("res://assets/encounters/training.png", 128, 128, Color.DODGER_BLUE)
	_create_placeholder("res://assets/encounters/chest.png", 128, 128, Color.GOLD)
	_create_placeholder("res://assets/encounters/fountain.png", 128, 128, Color.CYAN)

	# Combat icons (128x128)
	_create_placeholder("res://assets/combat/ai_enemy.png", 128, 128, Color.CRIMSON)
	_create_placeholder("res://assets/combat/player_ghost.png", 128, 128, Color.MEDIUM_PURPLE)

	print("Placeholder assets generated successfully!")
	print("Refresh the FileSystem dock in Godot to see the new files.")


func _create_placeholder(path: String, width: int, height: int, color: Color) -> void:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)

	# Add a simple border
	var border_color = color.darkened(0.3)
	for x in range(width):
		image.set_pixel(x, 0, border_color)
		image.set_pixel(x, height - 1, border_color)
	for y in range(height):
		image.set_pixel(0, y, border_color)
		image.set_pixel(width - 1, y, border_color)

	# Ensure directory exists
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)

	# Save the image
	var error = image.save_png(path)
	if error != OK:
		push_error("Failed to save placeholder: %s" % path)
	else:
		print("  Created: %s" % path)
