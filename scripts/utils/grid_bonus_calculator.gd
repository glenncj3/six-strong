class_name GridBonusCalculator
extends RefCounted
## Calculates stat_bonuses for characters on a CharacterGrid.
## Gathers bonuses from all sources: passive abilities, items, skills, etc.
## Any system that changes bonuses should call recalculate() on the grid's calculator.

var _grid  # CharacterGrid (untyped to avoid circular dependency)


func _init(grid) -> void:
	_grid = grid


func recalculate() -> void:
	"""Clear and recompute all stat_bonuses on every character in the grid."""
	# Clear all bonuses
	for ch in _grid.get_all_characters():
		ch.stat_bonuses.clear()

	var gd = _get_game_data()
	if gd == null:
		return

	_apply_passive_ability_bonuses(gd)
	# Future: _apply_item_bonuses(gd)
	# Future: _apply_skill_bonuses(gd)
	# Future: _apply_temporary_bonuses()


# =============================================================================
# PASSIVE ABILITY BONUSES
# =============================================================================

func _apply_passive_ability_bonuses(gd) -> void:
	for row in range(_grid.ROWS):
		for col in range(_grid.COLS):
			var ch = _grid.get_character_at(row, col)
			if ch == null:
				continue
			var char_master = gd.get_character_by_id(ch.base_character_id)
			if char_master.is_empty():
				continue
			var ability_entries = char_master.get("abilities", [])
			for entry in ability_entries:
				var parsed = parse_ability_entry(entry)
				var aid = parsed.get("id", "")
				if aid.is_empty():
					continue
				var ability = gd.get_ability(aid)
				if ability.is_empty() or ability.get("type", "") != "passive":
					continue
				var passive_id = ability.get("passive_effect", "")
				match passive_id:
					"buff_adjacent_attack":
						_apply_buff_adjacent(ch, ability, row, col, parsed)


func _apply_buff_adjacent(source: CharacterInstance, ability: Dictionary, src_row: int, src_col: int, params: Dictionary = {}) -> void:
	var buff_stat = ability.get("buff_stat", "attack_damage_bonus")
	var mod_type = ability.get("buff_modifier_type", "percent")
	var buff_value = float(params.get("buff_value", ability.get("default_buff_value", 0)))
	if buff_value == 0.0:
		return

	var adj_positions = [
		[src_row - 1, src_col],
		[src_row + 1, src_col],
		[src_row, src_col - 1],
		[src_row, src_col + 1],
	]
	for pos in adj_positions:
		var r = pos[0]
		var c = pos[1]
		if r < 0 or r >= _grid.ROWS or c < 0 or c >= _grid.COLS:
			continue
		var ally = _grid.get_character_at(r, c)
		if ally == null or ally == source:
			continue
		_add_bonus(ally, buff_stat, mod_type, buff_value)


# =============================================================================
# ABILITY ENTRY PARSING
# =============================================================================

# Normalizes an ability entry from a character's abilities array.
# Entries can be plain strings ("attack_enemy") or dicts with params
# ({"id": "buff_adjacent_attack", "buff_value": 5}). This is the expected
# pattern for configuring passive buff values per-character — the buff_value
# lives on the ability entry rather than as a character stat.
static func parse_ability_entry(entry) -> Dictionary:
	if entry is String:
		return {"id": entry}
	if entry is Dictionary:
		return entry
	return {}


# =============================================================================
# BONUS HELPERS
# =============================================================================

static func _add_bonus(character: CharacterInstance, stat: String, mod_type: String, value: float) -> void:
	"""Add a bonus to a character's stat_bonuses dict."""
	if not character.stat_bonuses.has(stat):
		character.stat_bonuses[stat] = {"flat": 0.0, "percent": 0.0}
	character.stat_bonuses[stat][mod_type] += value


func _get_game_data():
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("/root/GameData"):
		return tree.root.get_node("/root/GameData")
	return null
