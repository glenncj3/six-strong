extends HBoxContainer
# CurrencyDisplay - Reusable component for displaying currency
# Auto-updates when PlayerAccount emits currency changed signals

@onready var gems_label: Label = $GemsLabel
@onready var reroll_tokens_label: Label = $RerollTokensLabel


func _ready() -> void:
	# Connect to PlayerAccount signals for auto-updates
	PlayerAccount.gems_changed.connect(_on_gems_changed)
	PlayerAccount.reroll_tokens_changed.connect(_on_reroll_tokens_changed)

	# Initialize display
	_update_display()


func _update_display() -> void:
	"""Update both currency labels."""
	gems_label.text = UIHelpers.format_currency(
		PlayerAccount.get_gems(),
		GameConstants.EMOJI_GEM
	)
	reroll_tokens_label.text = UIHelpers.format_currency(
		PlayerAccount.get_reroll_tokens(),
		GameConstants.EMOJI_REROLL
	)


func _on_gems_changed(new_amount: int) -> void:
	gems_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_GEM)


func _on_reroll_tokens_changed(new_amount: int) -> void:
	reroll_tokens_label.text = UIHelpers.format_currency(new_amount, GameConstants.EMOJI_REROLL)
