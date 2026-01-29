class_name CombatBoard
extends RefCounted
## Manages the two 2x3 grids of combat characters.

# Arrays of 6 elements (nullable). Index = row * GRID_COLS + column.
var player_characters: Array = []
var opponent_characters: Array = []


func _init() -> void:
	player_characters.resize(GameConstants.MAX_GRID_CHARACTERS)
	opponent_characters.resize(GameConstants.MAX_GRID_CHARACTERS)
	for i in range(GameConstants.MAX_GRID_CHARACTERS):
		player_characters[i] = null
		opponent_characters[i] = null


func get_character_at(p_team: int, p_row: int, p_col: int) -> CombatCharacter:
	var idx = p_row * GameConstants.GRID_COLS + p_col
	if idx < 0 or idx >= GameConstants.MAX_GRID_CHARACTERS:
		return null
	var arr = player_characters if p_team == GameConstants.TEAM_PLAYER else opponent_characters
	return arr[idx]


func set_character_at(p_team: int, p_row: int, p_col: int, character: CombatCharacter) -> void:
	var idx = p_row * GameConstants.GRID_COLS + p_col
	if idx < 0 or idx >= GameConstants.MAX_GRID_CHARACTERS:
		return
	var arr = player_characters if p_team == GameConstants.TEAM_PLAYER else opponent_characters
	arr[idx] = character


func get_all_living_characters() -> Array:
	var result: Array = []
	for ch in player_characters:
		if ch != null and ch.is_alive:
			result.append(ch)
	for ch in opponent_characters:
		if ch != null and ch.is_alive:
			result.append(ch)
	return result


func get_living_characters_on_team(p_team: int) -> Array:
	var arr = player_characters if p_team == GameConstants.TEAM_PLAYER else opponent_characters
	var result: Array = []
	for ch in arr:
		if ch != null and ch.is_alive:
			result.append(ch)
	return result


func get_living_characters(p_team: int, p_row: int) -> Array:
	var arr = player_characters if p_team == GameConstants.TEAM_PLAYER else opponent_characters
	var result: Array = []
	for col in range(GameConstants.GRID_COLS):
		var idx = p_row * GameConstants.GRID_COLS + col
		var ch = arr[idx]
		if ch != null and ch.is_alive:
			result.append(ch)
	return result


func get_adjacent_allies(character: CombatCharacter) -> Array:
	## Returns living allies orthogonally adjacent (same column different row, or same row ±1 column).
	## Excludes the character itself.
	var result: Array = []
	var adj_positions = [
		[character.row - 1, character.column],  # same column, other row
		[character.row + 1, character.column],
		[character.row, character.column - 1],  # same row, adjacent column
		[character.row, character.column + 1],
	]
	for pos in adj_positions:
		var r = pos[0]
		var c = pos[1]
		if r < 0 or r >= GameConstants.GRID_ROWS or c < 0 or c >= GameConstants.GRID_COLS:
			continue
		var ch = get_character_at(character.team, r, c)
		if ch != null and ch.is_alive and ch.id != character.id:
			result.append(ch)
	return result


func has_living_characters(p_team: int) -> bool:
	var arr = player_characters if p_team == GameConstants.TEAM_PLAYER else opponent_characters
	for ch in arr:
		if ch != null and ch.is_alive:
			return true
	return false
