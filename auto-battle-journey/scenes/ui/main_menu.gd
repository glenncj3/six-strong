extends Control
# Main Menu - entry point with navigation and currency display
# Refactored to use SceneManager with fantasy aesthetic

const DebugMenuScene = preload("res://scenes/ui/debug_menu.tscn")

@onready var background = $Background
@onready var title_label = $MarginContainer/VBoxContainer/Title
@onready var subtitle_label = $MarginContainer/VBoxContainer/Subtitle
@onready var gems_label = $CurrencyDisplay/HBoxContainer/GemsLabel
@onready var reroll_tokens_label = $CurrencyDisplay/HBoxContainer/RerollTokensLabel
@onready var play_button = $MarginContainer/VBoxContainer/ButtonContainer/PlayButton
@onready var collection_button = $MarginContainer/VBoxContainer/ButtonContainer/CollectionButton
@onready var quit_button = $MarginContainer/VBoxContainer/ButtonContainer/QuitButton


func _ready() -> void:
	# Apply visual styling
	_apply_visual_styling()

	# Update currency display
	_update_currency_display()

	# Connect signals
	PlayerAccount.gems_changed.connect(_on_gems_changed)
	PlayerAccount.reroll_tokens_changed.connect(_on_reroll_tokens_changed)

	# Connect buttons
	play_button.pressed.connect(_on_play_pressed)
	collection_button.pressed.connect(_on_collection_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Check for active run to resume
	if RunManager.has_active_run():
		play_button.text = "RESUME RUN"
	else:
		play_button.text = "PLAY"



func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling to the menu."""
	# Background
	background.color = GameConstants.COLOR_BG_DARK

	# Title styling
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)
	subtitle_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)

	# Currency labels
	gems_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	reroll_tokens_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Style buttons with fantasy aesthetic
	UIStyles.apply_button_styles(play_button)
	UIStyles.apply_button_styles(collection_button)
	UIStyles.apply_button_styles(quit_button)


func _update_currency_display() -> void:
	gems_label.text = UIHelpers.format_currency(PlayerAccount.get_gems(), GameConstants.EMOJI_GEM)
	reroll_tokens_label.text = UIHelpers.format_currency(PlayerAccount.get_reroll_tokens(), GameConstants.EMOJI_REROLL)


func _on_gems_changed(new_amount: int) -> void:
	gems_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_GEM)


func _on_reroll_tokens_changed(new_amount: int) -> void:
	reroll_tokens_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_REROLL)


func _on_play_pressed() -> void:
	# Check if there's an active run to resume
	if RunManager.has_active_run():
		print("MainMenu: Resuming active run...")
		RunManager.load_run_state()
		SceneManager.go_to("run_view")
	else:
		print("MainMenu: Starting new run (draft)...")
		SceneManager.go_to_draft()


func _on_collection_pressed() -> void:
	print("MainMenu: Opening collection...")
	SceneManager.go_to_collection()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _input(event: InputEvent) -> void:
	# Debug controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				PlayerAccount.add_reroll_token()
				_update_currency_display()
				print("MainMenu: Added reroll token (Debug)")
			KEY_D:
				_open_debug_menu()


func _open_debug_menu() -> void:
	"""Open the debug menu overlay."""
	var debug_menu = DebugMenuScene.instantiate()
	add_child(debug_menu)
	print("MainMenu: Opened debug menu")
