extends PanelContainer
## GoldCostIcon - Reusable embossed gold coin with cost number
## Shows a circular gold coin with white outlined text

@onready var cost_label: Label = $CostLabel

var _styled: bool = false


func _ready() -> void:
	_setup_coin_style()


func _setup_coin_style() -> void:
	if _styled:
		return
	_styled = true

	var style = StyleBoxFlat.new()
	style.bg_color = Color("#D4A017")  # Main gold
	style.set_corner_radius_all(18)  # Circular
	style.border_color = Color("#8B6914")  # Darker gold border
	style.set_border_width_all(2)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 2
	style.shadow_offset = Vector2(1, 1)
	add_theme_stylebox_override("panel", style)


func set_cost(value: int) -> void:
	"""Set the cost value to display."""
	if cost_label:
		cost_label.text = str(value)
	else:
		# If called before ready, defer it
		call_deferred("set_cost", value)
