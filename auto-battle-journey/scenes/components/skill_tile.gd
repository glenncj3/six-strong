extends ClickablePanelBase
## SkillTile - Clickable square tile for skill selection
## Shows skill icon and name in a compact square format (matches character tile style)

signal tile_clicked(skill_data: Dictionary)

const TILE_BORDER_WIDTH := 4

@onready var content_margin: MarginContainer = $ContentMargin
@onready var icon: TextureRect = $ContentMargin/Icon
@onready var border_overlay: Panel = $BorderOverlay
@onready var name_label: Label = $ContentMargin/NameMargin/NameLabel
@onready var gold_cost_icon: PanelContainer = $ContentMargin/CostMargin/GoldCostIcon

var skill_data: Dictionary = {}
var cost: int = 0


func _init_default_styles() -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = GameConstants.COLOR_AMETHYST
	normal.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	var hover = normal.duplicate()
	hover.bg_color = GameConstants.COLOR_AMETHYST.lightened(0.15)
	var pressed = normal.duplicate()
	pressed.bg_color = GameConstants.COLOR_AMETHYST.darkened(0.1)
	setup_styles({"normal": normal, "hover": hover, "pressed": pressed})


func _on_ready() -> void:
	UIHelpers.set_children_mouse_filter_ignore(self)
	UIStyles.set_margin_all(content_margin, TILE_BORDER_WIDTH)
	_setup_border_overlay()


func _setup_border_overlay() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(TILE_BORDER_WIDTH)
	style.border_color = GameConstants.COLOR_BORDER_GOLD
	style.set_corner_radius_all(UIStyles.CORNER_RADIUS_MEDIUM)
	border_overlay.add_theme_stylebox_override("panel", style)


func _handle_click() -> void:
	if not skill_data.is_empty():
		tile_clicked.emit(skill_data)


func setup(p_skill_data: Dictionary, tile_size: float) -> void:
	"""Configure the tile with skill data."""
	skill_data = p_skill_data
	custom_minimum_size = Vector2(tile_size, tile_size)

	if skill_data.is_empty():
		push_error("SkillTile: Empty skill data provided")
		return

	UIHelpers.set_texture_safe(icon, skill_data.get("image_path", ""))
	name_label.text = skill_data.get("name", "Unknown")
	cost = skill_data.get("cost", 0)
	gold_cost_icon.set_cost(cost)
