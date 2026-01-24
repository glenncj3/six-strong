class_name UIHelpers
extends RefCounted
## UIHelpers - Facade for backwards compatibility.
##
## This class delegates to specialized UI helper classes:
## - UIContainerHelpers: Container management, mouse filters, texture loading
## - UIFormattingHelpers: Text/number formatting
## - UIPanelFactory: Option panels, shop rows
##
## New code should use the specialized classes directly for clarity.
## This facade exists for backwards compatibility with existing code.


## Type of option panel to create (re-exported from UIPanelFactory)
enum OptionPanelType { COMBAT, ENCOUNTER }


# =============================================================================
# UIContainerHelpers DELEGATES
# =============================================================================

static func set_children_mouse_filter_ignore(parent: Control, recursive: bool = true) -> void:
	UIContainerHelpers.set_children_mouse_filter_ignore(parent, recursive)


static func create_vbox_container(separation: int = GameConstants.CONTENT_SEPARATION, full_rect: bool = true) -> VBoxContainer:
	return UIContainerHelpers.create_vbox_container(separation, full_rect)


static func create_spacer(height: int = 20) -> Control:
	return UIContainerHelpers.create_spacer(height)


static func create_label(
	text: String,
	font_size: int = GameConstants.FONT_SIZE_BODY,
	color: Color = Color.WHITE,
	centered: bool = false
) -> Label:
	return UIContainerHelpers.create_label(text, font_size, color, centered)


static func clear_children(container: Node) -> void:
	UIContainerHelpers.clear_children(container)


static func clear_children_immediate(container: Node) -> void:
	UIContainerHelpers.clear_children_immediate(container)


static func get_child_count_of_type(container: Node, type: Variant) -> int:
	return UIContainerHelpers.get_child_count_of_type(container, type)


static func create_empty_placeholder(text: String, color: Color = Color(0.7, 0.7, 0.7)) -> Label:
	return UIContainerHelpers.create_empty_placeholder(text, color)


static func add_empty_placeholder(container: Node, text: String) -> void:
	UIContainerHelpers.add_empty_placeholder(container, text)


static func load_texture_safe(path: String) -> Texture2D:
	return UIContainerHelpers.load_texture_safe(path)


static func set_texture_safe(texture_rect: TextureRect, path: String) -> bool:
	return UIContainerHelpers.set_texture_safe(texture_rect, path)


static func set_button_enabled(button: Button, enabled: bool, disabled_text: String = "") -> void:
	UIContainerHelpers.set_button_enabled(button, enabled, disabled_text)


# =============================================================================
# UIFormattingHelpers DELEGATES
# =============================================================================

static func format_currency(amount: int, symbol: String = "") -> String:
	return UIFormattingHelpers.format_currency(amount, symbol)


static func format_stat(stat_name: String, value: int) -> String:
	return UIFormattingHelpers.format_stat(stat_name, value)


static func get_difficulty_color(difficulty: String) -> Color:
	return UIFormattingHelpers.get_difficulty_color(difficulty)


# =============================================================================
# UIPanelFactory DELEGATES
# =============================================================================

static func create_team_selector(team: Array) -> OptionButton:
	return UIPanelFactory.create_team_selector(team)


static func create_shop_row(
	data: Dictionary,
	cost: int,
	team: Array,
	buy_callback: Callable,
	content_type: String = "item"
) -> Control:
	return UIPanelFactory.create_shop_row(data, cost, team, buy_callback, content_type)



static func create_option_panel(data: Dictionary, panel_type: OptionPanelType, on_select: Callable) -> ClickableOptionPanel:
	# Map UIHelpers.OptionPanelType to UIPanelFactory.OptionPanelType
	var factory_type = UIPanelFactory.OptionPanelType.COMBAT if panel_type == OptionPanelType.COMBAT else UIPanelFactory.OptionPanelType.ENCOUNTER
	return UIPanelFactory.create_option_panel(data, factory_type, on_select)


static func create_combat_option_panel(combat_data: Dictionary, on_select: Callable) -> ClickableOptionPanel:
	return UIPanelFactory.create_combat_option_panel(combat_data, on_select)


static func create_encounter_option_panel(encounter_data: Dictionary, on_select: Callable) -> ClickableOptionPanel:
	return UIPanelFactory.create_encounter_option_panel(encounter_data, on_select)
