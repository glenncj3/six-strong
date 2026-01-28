@tool
extends Control

const JSON_PATH := "res://data/characters/characters.json"
const STAT_KEYS := ["health", "mana", "defend_rate", "speed", "damage", "crit_chance"]
const TOP_KEYS := ["id", "name", "description", "image_path", "cost", "level_requirement"]
const OPTIONAL_KEYS := ["is_generic", "display_color"]
const ALL_CSV_COLUMNS := ["id", "name", "description", "image_path", "cost", "level_requirement",
	"health", "mana", "defend_rate", "speed", "damage", "crit_chance", "is_generic", "display_color", "tags"]

var file_dialog: FileDialog
var filepath_label: Label
var preview_label: RichTextLabel
var status_label: Label
var parsed_characters: Array = []
var csv_path: String = ""

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# File selection row
	var file_row = HBoxContainer.new()
	vbox.add_child(file_row)

	var select_btn = Button.new()
	select_btn.text = "Select CSV..."
	select_btn.pressed.connect(_on_select_csv)
	file_row.add_child(select_btn)

	filepath_label = Label.new()
	filepath_label.text = "No file selected"
	filepath_label.size_flags_horizontal = SIZE_EXPAND_FILL
	filepath_label.clip_text = true
	file_row.add_child(filepath_label)

	# Preview
	preview_label = RichTextLabel.new()
	preview_label.size_flags_vertical = SIZE_EXPAND_FILL
	preview_label.bbcode_enabled = true
	preview_label.text = "Select a CSV file to preview characters."
	vbox.add_child(preview_label)

	# Action buttons
	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	vbox.add_child(action_row)

	var import_btn = Button.new()
	import_btn.text = "Import to JSON (Replace)"
	import_btn.pressed.connect(_on_import_replace)
	action_row.add_child(import_btn)

	var merge_btn = Button.new()
	merge_btn.text = "Merge into JSON"
	merge_btn.pressed.connect(_on_import_merge)
	action_row.add_child(merge_btn)

	var export_btn = Button.new()
	export_btn.text = "Export JSON -> CSV"
	export_btn.pressed.connect(_on_export_csv)
	action_row.add_child(export_btn)

	# Status
	status_label = Label.new()
	status_label.text = ""
	vbox.add_child(status_label)

	# File dialog
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.csv ; CSV Files"])
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)

func _on_select_csv() -> void:
	file_dialog.popup_centered(Vector2i(600, 400))

func _on_file_selected(path: String) -> void:
	csv_path = path
	filepath_label.text = path
	_parse_csv(path)

# --- CSV Parsing ---

func _parse_csv(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		_set_status("Error: Could not open file")
		return

	var content = file.get_as_text()
	file.close()

	var lines = content.strip_edges().split("\n")
	if lines.size() < 2:
		_set_status("Error: CSV must have a header row and at least one data row")
		return

	var headers = _parse_csv_line(lines[0])
	# Validate required columns
	for key in ["id", "name"]:
		if key not in headers:
			_set_status("Error: CSV missing required column: " + key)
			return

	parsed_characters.clear()
	var warnings: Array = []

	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			continue
		var values = _parse_csv_line(line)
		if values.size() != headers.size():
			warnings.append("Row %d: expected %d columns, got %d (skipped)" % [i + 1, headers.size(), values.size()])
			continue

		var row: Dictionary = {}
		for j in range(headers.size()):
			row[headers[j]] = values[j]

		var character = _row_to_character(row)
		if character.id.is_empty():
			warnings.append("Row %d: empty id (skipped)" % [i + 1])
			continue
		parsed_characters.append(character)

	# Update preview
	var text = "[b]Parsed %d characters[/b]\n" % parsed_characters.size()
	for w in warnings:
		text += "[color=yellow]Warning: %s[/color]\n" % w
	for c in parsed_characters:
		var tag_str = ", ".join(c.get("tags", [])) if c.get("tags", []).size() > 0 else "none"
		text += "\n[b]%s[/b] (%s) - HP:%s DMG:%s SPD:%s Tags:[i]%s[/i]" % [
			c.name, c.id,
			str(c.base_stats.health), str(c.base_stats.damage), str(c.base_stats.speed), tag_str]
	preview_label.text = text
	_set_status("Parsed %d characters with %d warnings" % [parsed_characters.size(), warnings.size()])

func _parse_csv_line(line: String) -> Array:
	# Handle quoted fields with commas
	var fields: Array = []
	var current := ""
	var in_quotes := false
	for ch in line:
		if ch == '"':
			in_quotes = not in_quotes
		elif ch == ',' and not in_quotes:
			fields.append(current.strip_edges())
			current = ""
		else:
			current += ch
	fields.append(current.strip_edges())
	return fields

func _row_to_character(row: Dictionary) -> Dictionary:
	var character: Dictionary = {}
	for key in TOP_KEYS:
		if key in row:
			character[key] = _convert_value(key, row[key])
		else:
			character[key] = _default_value(key)

	# Optional keys
	for key in OPTIONAL_KEYS:
		if key in row and not row[key].is_empty():
			character[key] = _convert_value(key, row[key])

	# Tags (pipe-separated in CSV, e.g. "fire|lightning")
	if "tags" in row and not row["tags"].is_empty():
		var raw_tags = row["tags"].split("|")
		var tags: Array = []
		for t in raw_tags:
			var trimmed = t.strip_edges()
			if not trimmed.is_empty():
				tags.append(trimmed)
		character["tags"] = tags
	else:
		character["tags"] = []

	# Stats
	var stats: Dictionary = {}
	for key in STAT_KEYS:
		if key in row and not row[key].is_empty():
			stats[key] = _convert_value(key, row[key])
		else:
			stats[key] = 0
	character["base_stats"] = stats
	return character

func _convert_value(key: String, value: String):
	if key in ["cost", "level_requirement", "health", "mana"]:
		return int(value) if not value.is_empty() else 0
	if key in ["defend_rate", "speed", "damage", "crit_chance"]:
		return float(value) if not value.is_empty() else 0.0
	if key == "is_generic":
		return value.to_lower() == "true"
	return value

func _default_value(key: String):
	if key in ["cost", "level_requirement"]:
		return 0
	return ""

# --- Import (Replace) ---

func _on_import_replace() -> void:
	if parsed_characters.is_empty():
		_set_status("No characters to import. Select and parse a CSV first.")
		return
	_write_json(parsed_characters)
	_set_status("Imported %d characters (replaced)" % parsed_characters.size())

# --- Import (Merge) ---

func _on_import_merge() -> void:
	if parsed_characters.is_empty():
		_set_status("No characters to merge. Select and parse a CSV first.")
		return

	var existing = _read_json()
	var by_id: Dictionary = {}
	for c in existing:
		by_id[c.id] = c
	for c in parsed_characters:
		by_id[c.id] = c

	_write_json(by_id.values())
	_set_status("Merged: %d total characters (%d from CSV)" % [by_id.size(), parsed_characters.size()])

# --- Export ---

func _on_export_csv() -> void:
	var characters = _read_json()
	if characters.is_empty():
		_set_status("No characters in JSON to export.")
		return

	# Show save dialog
	var save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.filters = PackedStringArray(["*.csv ; CSV Files"])
	save_dialog.file_selected.connect(func(path: String):
		_write_csv(path, characters)
		save_dialog.queue_free()
	)
	save_dialog.canceled.connect(func(): save_dialog.queue_free())
	add_child(save_dialog)
	save_dialog.popup_centered(Vector2i(600, 400))

func _write_csv(path: String, characters: Array) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		_set_status("Error: Could not write to " + path)
		return

	# Header
	file.store_line(",".join(ALL_CSV_COLUMNS))

	for c in characters:
		var fields: Array = []
		for key in TOP_KEYS:
			fields.append(_csv_escape(str(c.get(key, ""))))
		for key in STAT_KEYS:
			var stats = c.get("base_stats", {})
			fields.append(_csv_escape(str(stats.get(key, ""))))
		for key in OPTIONAL_KEYS:
			fields.append(_csv_escape(str(c.get(key, ""))))
		# Tags as pipe-separated
		var tags_val = c.get("tags", [])
		if tags_val is Array:
			fields.append(_csv_escape("|".join(tags_val)))
		else:
			fields.append("")
		file.store_line(",".join(fields))

	file.close()
	_set_status("Exported %d characters to %s" % [characters.size(), path])

func _csv_escape(value: String) -> String:
	if "," in value or '"' in value or "\n" in value:
		return '"' + value.replace('"', '""') + '"'
	return value

# --- JSON I/O ---

func _read_json() -> Array:
	var file = FileAccess.open(JSON_PATH, FileAccess.READ)
	if not file:
		return []
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return []
	var data = json.data
	if data is Dictionary and data.has("characters"):
		return data.characters
	return []

func _write_json(characters: Array) -> void:
	var data = {"characters": characters}
	var json_string = JSON.stringify(data, "  ")
	var file = FileAccess.open(JSON_PATH, FileAccess.WRITE)
	if not file:
		_set_status("Error: Could not write to " + JSON_PATH)
		return
	file.store_string(json_string)
	file.close()

func _set_status(msg: String) -> void:
	status_label.text = msg
	print("[CSV Import] ", msg)
