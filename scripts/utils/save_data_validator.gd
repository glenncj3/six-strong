class_name SaveDataValidator
extends RefCounted
## Validates save data against a schema to ensure data integrity.
## Helps prevent crashes from corrupt, outdated, or tampered save files.
##
## Usage:
##   var schema = {
##       "run_id": {"type": "string", "required": true},
##       "round": {"type": "int", "required": true, "min": 0},
##       "team": {"type": "array", "required": true, "min_length": 1}
##   }
##   var result = SaveDataValidator.validate(save_data, schema)
##   if not result.is_valid:
##       push_error("Validation failed: %s" % result.errors)

## Validation result class
class ValidationResult:
	var is_valid: bool = true
	var errors: Array[String] = []
	var warnings: Array[String] = []

	func add_error(message: String) -> void:
		errors.append(message)
		is_valid = false

	func add_warning(message: String) -> void:
		warnings.append(message)


## Validate data against a schema
## Returns ValidationResult with is_valid flag and error/warning lists
static func validate(data: Dictionary, schema: Dictionary) -> ValidationResult:
	var result = ValidationResult.new()

	if data == null:
		result.add_error("Data is null")
		return result

	for field_name in schema:
		var field_schema = schema[field_name]
		_validate_field(data, field_name, field_schema, result)

	return result


## Validate data and return the data if valid, null otherwise
## Also populates defaults for missing optional fields
static func validate_and_fix(data: Dictionary, schema: Dictionary) -> Dictionary:
	if data == null:
		return {}

	var result = validate(data, schema)

	# Log errors
	if not result.is_valid:
		push_error("SaveDataValidator: %d validation errors" % result.errors.size())
		for error in result.errors:
			push_error("  - %s" % error)

	# Log warnings
	for warning in result.warnings:
		push_warning("SaveDataValidator: %s" % warning)

	# Apply defaults for missing optional fields
	var fixed_data = data.duplicate(true)
	for field_name in schema:
		var field_schema = schema[field_name]
		if not fixed_data.has(field_name) and field_schema.has("default"):
			fixed_data[field_name] = field_schema["default"]

	return fixed_data if result.is_valid else {}


## Validate a single field
static func _validate_field(data: Dictionary, field_name: String, field_schema: Dictionary, result: ValidationResult) -> void:
	var is_required = field_schema.get("required", false)
	var field_type = field_schema.get("type", "any")

	# Check if field exists
	if not data.has(field_name):
		if is_required:
			result.add_error("Missing required field: '%s'" % field_name)
		elif field_schema.has("default"):
			result.add_warning("Missing optional field '%s', using default" % field_name)
		return

	var value = data[field_name]

	# Type validation
	match field_type:
		"string":
			if not value is String:
				result.add_error("Field '%s' should be string, got %s" % [field_name, typeof(value)])
		"int":
			if not (value is int or value is float):
				result.add_error("Field '%s' should be int, got %s" % [field_name, typeof(value)])
			else:
				_validate_numeric_constraints(field_name, int(value), field_schema, result)
		"float":
			if not (value is int or value is float):
				result.add_error("Field '%s' should be float, got %s" % [field_name, typeof(value)])
			else:
				_validate_numeric_constraints(field_name, float(value), field_schema, result)
		"bool":
			if not value is bool:
				result.add_error("Field '%s' should be bool, got %s" % [field_name, typeof(value)])
		"array":
			if not value is Array:
				result.add_error("Field '%s' should be array, got %s" % [field_name, typeof(value)])
			else:
				_validate_array_constraints(field_name, value, field_schema, result)
		"dict":
			if not value is Dictionary:
				result.add_error("Field '%s' should be dictionary, got %s" % [field_name, typeof(value)])
		"any":
			pass  # No type checking

	# Enum validation
	if field_schema.has("enum"):
		var allowed = field_schema["enum"]
		if value not in allowed:
			result.add_error("Field '%s' value '%s' not in allowed values: %s" % [field_name, value, allowed])


static func _validate_numeric_constraints(field_name: String, value: float, field_schema: Dictionary, result: ValidationResult) -> void:
	if field_schema.has("min") and value < field_schema["min"]:
		result.add_error("Field '%s' value %d is below minimum %d" % [field_name, value, field_schema["min"]])
	if field_schema.has("max") and value > field_schema["max"]:
		result.add_error("Field '%s' value %d exceeds maximum %d" % [field_name, value, field_schema["max"]])


static func _validate_array_constraints(field_name: String, value: Array, field_schema: Dictionary, result: ValidationResult) -> void:
	if field_schema.has("min_length") and value.size() < field_schema["min_length"]:
		result.add_error("Field '%s' array has %d items, needs at least %d" % [field_name, value.size(), field_schema["min_length"]])
	if field_schema.has("max_length") and value.size() > field_schema["max_length"]:
		result.add_error("Field '%s' array has %d items, maximum is %d" % [field_name, value.size(), field_schema["max_length"]])


# =============================================================================
# PREDEFINED SCHEMAS
# =============================================================================

## Schema for active run save data
## Field names must match RunState.to_dict() output
static func get_run_state_schema() -> Dictionary:
	return {
		"run_id": {"type": "string", "required": true},
		"current_round": {"type": "int", "required": true, "min": 1},  # Runs start at round 1
		"current_phase": {"type": "string", "required": true, "enum": ["encounter", "combat"]},
		"encounters_this_round": {"type": "int", "required": false, "default": 0, "min": 0},
		"reputation": {"type": "int", "required": true, "min": 0},
		"wins": {"type": "int", "required": true, "min": 0},
		"losses": {"type": "int", "required": true, "min": 0},
		"starting_gold": {"type": "int", "required": false, "default": 0, "min": 0},
		"current_gold": {"type": "int", "required": true, "min": 0},
		"grid": {"type": "dict", "required": true},  # CharacterGrid serialization
		"encounter_history": {"type": "array", "required": false, "default": []},
	}


## Schema for player account save data
static func get_player_account_schema() -> Dictionary:
	return {
		"player_id": {"type": "string", "required": false, "default": ""},
		"currencies": {"type": "dict", "required": true},
		"characters": {"type": "array", "required": false, "default": []},
		"unlocked_character_ids": {"type": "array", "required": true},
	}


## Schema for character data in team array
static func get_character_instance_schema() -> Dictionary:
	return {
		"base_character_id": {"type": "string", "required": true},
		"level": {"type": "int", "required": false, "default": 1, "min": 1},
		"experience": {"type": "int", "required": false, "default": 0, "min": 0},
		"equipped_items": {"type": "array", "required": false, "default": []},
		"learned_skills": {"type": "array", "required": false, "default": []},
	}
