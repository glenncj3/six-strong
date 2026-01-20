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
	print("MainMenu: Play button pressed")
	# TODO: Check for active run and resume, or start draft
	# For now, just print
	pass


func _on_collection_pressed() -> void:
	print("MainMenu: Opening collection...")
	get_tree().get_root().get_node("Main").change_scene("res://scenes/ui/collection.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
