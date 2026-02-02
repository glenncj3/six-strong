extends SceneTree
## Validates that characters have nonzero values for stats their abilities require.
## For example, a character with attack_enemy must have damage > 0.
##
## Run with: godot --headless --path "C:\Users\glenn\Dev\six-strong" --script res://tests/unit/test_character_ability_stats.gd

var tests_passed: int = 0
var tests_failed: int = 0

# Ability data keyed by id, loaded from abilities.json
var _abilities: Dictionary = {}


func _init():
	call_deferred("_run_tests")


func _run_tests():
	print("\n=== Character Ability Stat Validation ===\n")

	_load_abilities()
	_test_all_characters()

	print("\n=== Results: %d passed, %d failed ===" % [tests_passed, tests_failed])

	if tests_failed > 0:
		print("SOME TESTS FAILED")
	else:
		print("ALL TESTS PASSED")


func _load_abilities():
	var file = FileAccess.open("res://data/abilities/abilities.json", FileAccess.READ)
	if file == null:
		push_error("Cannot open abilities.json")
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	for ability in data.get("abilities", []):
		_abilities[ability["id"]] = ability


func _get_required_stats(ability: Dictionary) -> Array:
	"""Return an array of [stat_name, reason] pairs that must be nonzero."""
	var required: Array = []

	# attack abilities need damage
	if ability.has("damage_multiplier"):
		required.append(["damage", "ability has damage_multiplier"])

	# stacks_from: poison_value, burn_value, shield_value
	if ability.has("stacks_from"):
		var stat = ability["stacks_from"]
		required.append([stat, "ability stacks_from references %s" % stat])

	# duration_from: haste_value, slow_value, freeze_value
	if ability.has("duration_from"):
		var stat = ability["duration_from"]
		required.append([stat, "ability duration_from references %s" % stat])

	# heal_from: heal_value
	if ability.has("heal_from"):
		var stat = ability["heal_from"]
		required.append([stat, "ability heal_from references %s" % stat])

	return required


func _test_all_characters():
	var file = FileAccess.open("res://data/characters/characters.json", FileAccess.READ)
	if file == null:
		_fail("Cannot open characters.json")
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	var characters = data.get("characters", [])

	for character in characters:
		var char_name = character.get("name", "Unknown").strip_edges()
		var char_id = character.get("id", "???")
		var base_stats = character.get("base_stats", {})
		var ability_ids = character.get("abilities", [])

		for ability_entry in ability_ids:
			# Abilities can be strings or dicts with an "id" key
			var ability_id: String
			if ability_entry is String:
				ability_id = ability_entry
			elif ability_entry is Dictionary:
				ability_id = ability_entry.get("id", "")
			else:
				continue

			if not _abilities.has(ability_id):
				_fail("%s (%s): references unknown ability '%s'" % [char_name, char_id, ability_id])
				continue

			var ability = _abilities[ability_id]
			var required_stats = _get_required_stats(ability)

			for req in required_stats:
				var stat_name: String = req[0]
				var reason: String = req[1]
				var stat_value = base_stats.get(stat_name, 0)

				if stat_value == null or stat_value == 0 or stat_value == 0.0:
					_fail("%s (%s): has ability '%s' but %s is 0 (%s)" % [char_name, char_id, ability_id, stat_name, reason])
				else:
					_pass("%s (%s): %s = %s for ability '%s'" % [char_name, char_id, stat_name, str(stat_value), ability_id])


func _pass(msg: String):
	tests_passed += 1
	print("  PASS: %s" % msg)


func _fail(msg: String):
	tests_failed += 1
	print("  FAIL: %s" % msg)
