extends Control
# Main Menu - entry point with navigation and currency display
# Refactored to use SceneManager with fantasy aesthetic
# Now includes entrance animations and enhanced button effects

const DebugMenuScene = preload("res://scenes/ui/debug_menu.tscn")
const AmbientParticlesScene = preload("res://scenes/effects/ambient_particles.tscn")

@onready var background = $Background
@onready var title_label = $MarginContainer/VBoxContainer/Title
@onready var gems_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/GemsLabel
@onready var reroll_tokens_label = $HeaderBar/MarginContainer/HBoxContainer/CenterSection/RerollTokensLabel
@onready var play_button = $MarginContainer/VBoxContainer/ButtonContainer/PlayButton
@onready var collection_button = $MarginContainer/VBoxContainer/ButtonContainer/CollectionButton
@onready var quit_button = $MarginContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var reset_button = $MarginContainer/VBoxContainer/ButtonContainer/ResetButton
@onready var header_bar = $HeaderBar
@onready var button_container = $MarginContainer/VBoxContainer/ButtonContainer


func _ready() -> void:
	# Apply visual styling
	_apply_visual_styling()

	# Apply button interaction effects
	_apply_button_effects()

	# Update currency display
	_update_currency_display()

	# Connect signals
	PlayerAccount.gems_changed.connect(_on_gems_changed)
	PlayerAccount.reroll_tokens_changed.connect(_on_reroll_tokens_changed)

	# Connect buttons
	play_button.pressed.connect(_on_play_pressed)
	collection_button.pressed.connect(_on_collection_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	# Check for active run to resume
	if RunManager.has_active_run():
		play_button.text = "RESUME RUN"
	else:
		play_button.text = "PLAY"

	# Play entrance animations
	_play_entrance_animations()

	# Add ambient effects
	_setup_ambient_effects()


func _exit_tree() -> void:
	# Disconnect from autoload signals to prevent memory leaks
	if PlayerAccount.gems_changed.is_connected(_on_gems_changed):
		PlayerAccount.gems_changed.disconnect(_on_gems_changed)
	if PlayerAccount.reroll_tokens_changed.is_connected(_on_reroll_tokens_changed):
		PlayerAccount.reroll_tokens_changed.disconnect(_on_reroll_tokens_changed)



func _apply_visual_styling() -> void:
	"""Apply fantasy aesthetic styling to the menu."""
	# Title styling
	title_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_GOLD)

	# Currency labels
	gems_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
	reroll_tokens_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)

	# Style buttons with fantasy aesthetic
	UIStyles.apply_button_styles(play_button)
	UIStyles.apply_button_styles(collection_button)
	UIStyles.apply_button_styles(quit_button)
	UIStyles.apply_button_styles(reset_button)


func _apply_button_effects() -> void:
	"""Apply hover/press scale effects to buttons."""
	ButtonEffects.apply_effects(play_button)
	ButtonEffects.apply_effects(collection_button)
	ButtonEffects.apply_effects(quit_button)


func _play_entrance_animations() -> void:
	"""Play entrance animations for menu elements."""
	# Title - fade in
	AnimationManager.fade_in(title_label, GameConstants.ANIM_DURATION_NORMAL, 0.0)

	# Buttons - cascade fade in (safe for container layouts)
	var buttons = [play_button, collection_button, quit_button]
	var base_delay = 0.15
	for i in range(buttons.size()):
		var delay = base_delay + (i * 0.08)
		AnimationManager.fade_in(buttons[i], GameConstants.ANIM_DURATION_NORMAL, delay)


func _setup_ambient_effects() -> void:
	"""Add ambient visual effects."""
	# Add particles as Node2D child - renders after background in tree order
	var particles = AmbientParticlesScene.instantiate()
	background.add_sibling(particles)  # Add right after background node

	# More visible pulse on play button
	AnimationManager.pulse(play_button, 0.7, 1.0, 1.5)


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
		if RunManager.load_run_state():
			SceneManager.go_to("run_view")
		else:
			# Load failed - save is corrupted, clear it and start fresh
			push_warning("MainMenu: Failed to load run state, clearing corrupted save")
			RunManager.clear_run_state()
			play_button.text = "PLAY"
			_show_load_error_dialog()
	else:
		SceneManager.go_to("draft")


func _show_load_error_dialog() -> void:
	"""Show error dialog when save load fails."""
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Your saved run could not be loaded.\n\nThe save file may be corrupted. Starting a new game."
	dialog.ok_button_text = "OK"
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()


func _on_collection_pressed() -> void:
	SceneManager.go_to("legacy_collection", false)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_reset_pressed() -> void:
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Reset all progress?\n\nThis will delete your save data and start fresh."
	dialog.ok_button_text = "Reset"
	dialog.cancel_button_text = "Cancel"
	dialog.confirmed.connect(_confirm_reset.bind(dialog))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()


func _confirm_reset(dialog: ConfirmationDialog) -> void:
	dialog.queue_free()
	PlayerAccount.reset_account()
	RunManager.clear_run_state()
	_update_currency_display()
	play_button.text = "PLAY"


func _input(event: InputEvent) -> void:
	# Debug controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				PlayerAccount.add_reroll_token()
				_update_currency_display()
			KEY_D:
				_open_debug_menu()


func _open_debug_menu() -> void:
	"""Open the debug menu overlay."""
	var debug_menu = DebugMenuScene.instantiate()
	add_child(debug_menu)
