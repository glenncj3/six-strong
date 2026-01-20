extends Control
# Main Menu - entry point with navigation and currency display

@onready var gems_label = $CurrencyDisplay/HBoxContainer/GemsLabel
@onready var reroll_tokens_label = $CurrencyDisplay/HBoxContainer/RerollTokensLabel
@onready var play_button = $MarginContainer/VBoxContainer/ButtonContainer/PlayButton
@onready var collection_button = $MarginContainer/VBoxContainer/ButtonContainer/CollectionButton
@onready var quit_button = $MarginContainer/VBoxContainer/ButtonContainer/QuitButton


func _ready() -> void:
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

	# Focus play button
	play_button.grab_focus()


func _update_currency_display() -> void:
	gems_label.text = "💎 %d" % PlayerAccount.get_gems()
	reroll_tokens_label.text = "🎫 %d" % PlayerAccount.get_reroll_tokens()


func _on_gems_changed(new_amount: int) -> void:
	gems_label.text = "💎 %d" % new_amount


func _on_reroll_tokens_changed(new_amount: int) -> void:
	reroll_tokens_label.text = "🎫 %d" % new_amount


func _on_play_pressed() -> void:
	# Check if there's an active run to resume
	if RunManager.has_active_run():
		print("MainMenu: Resuming active run...")
		RunManager.load_run_state()
		# TODO: Navigate to run_view scene (Phase 4)
		print("MainMenu: Would navigate to run_view here")
	else:
		print("MainMenu: Starting new run (draft)...")
		get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/draft.tscn")


func _on_collection_pressed() -> void:
	print("MainMenu: Opening collection...")
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/collection.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _input(event: InputEvent) -> void:
	# Debug: Press T to add reroll token
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			PlayerAccount.add_reroll_token()
			print("MainMenu: Added reroll token (Debug)")
