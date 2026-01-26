class_name SlotMachineEncounterUI
extends RefCounted
## UI creation for slot machine encounters.
## Player spins 3 reels to match fantasy symbols for rewards.
## Starts with free spins, can pay resource for more.


static func create_ui(encounter_data: Dictionary, context: Dictionary) -> Control:
	"""Create slot machine encounter UI."""
	var game = SlotMachineController.new()
	game.initialize(encounter_data, context)
	return game


static func get_reward_preview(encounter_data: Dictionary) -> String:
	"""Get reward preview for slot machine encounter."""
	var data = encounter_data.get("data", {})
	var jackpot = data.get("jackpot_reward", 100)
	var free_spins = data.get("free_spins", 2)
	return "%d spins, up to %d Gold" % [free_spins, jackpot]


## Inner class that handles all game state and logic as a proper node
class SlotMachineController extends VBoxContainer:
	# Reel configuration
	const REEL_COUNT := 3
	const REEL_WIDTH := 140
	const REEL_HEIGHT := 180
	const SYMBOL_SIZE := 100
	const REEL_SPACING := 20

	# Symbols with fantasy theme
	const SYMBOLS := ["sword", "shield", "potion", "gold", "gem"]
	const SYMBOL_EMOJIS := {
		"sword": "⚔️",
		"shield": "🛡️",
		"potion": "🧪",
		"gold": "💰",
		"gem": "💎"
	}
	const SYMBOL_COLORS := {
		"sword": Color("#C0C0C0"),  # Silver
		"shield": Color("#8B4513"),  # Brown
		"potion": Color("#FF69B4"),  # Pink
		"gold": Color("#FFD700"),    # Gold
		"gem": Color("#9932CC")      # Purple
	}

	# Spin timing
	const SPIN_DURATION := 2.0
	const REEL_STOP_DELAY := 0.4  # Delay between each reel stopping
	const SYMBOLS_PER_SECOND := 8.0

	var encounter_data: Dictionary
	var context: Dictionary
	var reel_labels: Array = []  # The Label nodes showing symbols
	var current_symbols: Array = []  # Current symbol on each reel
	var locked_reels: Array = []  # Whether each reel is locked
	var lock_buttons: Array = []  # Lock button for each reel
	var spinning: bool = false
	var reels_still_spinning: int = 0
	var spins_remaining: int = 0
	var spin_button: Button
	var extra_spin_button: Button
	var result_label: Label
	var total_winnings: int = 0

	# Resource cost config
	var extra_spin_cost: int = 0
	var extra_spin_resource: String = "gold"  # "gold" or "health"
	var extra_spin_purchased: bool = false


	func initialize(p_encounter_data: Dictionary, p_context: Dictionary) -> void:
		encounter_data = p_encounter_data
		context = p_context

		set_anchors_preset(Control.PRESET_FULL_RECT)
		add_theme_constant_override("separation", 10)
		alignment = BoxContainer.ALIGNMENT_BEGIN

		var data = encounter_data.get("data", {})
		spins_remaining = data.get("free_spins", 2)
		extra_spin_cost = data.get("extra_spin_cost", 15)
		extra_spin_resource = data.get("extra_spin_resource", "gold")

		_build_ui()
		_update_button_states()


	func _build_ui() -> void:
		var data = encounter_data.get("data", {})
		var jackpot = data.get("jackpot_reward", 100)
		var triple = data.get("triple_reward", 50)
		var pair = data.get("pair_reward", 15)

		# Result label (shown in empty space at top, below encounter title)
		result_label = UIHelpers.create_label(
			"",
			GameConstants.FONT_SIZE_REWARD,
			GameConstants.COLOR_SUCCESS,
			true
		)
		result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(result_label)

		# Payout info
		var payout_text = "💎x3: %d | 3 match: %d | 2 match: %d" % [jackpot, triple, pair]
		var payout_label = UIHelpers.create_label(
			payout_text,
			GameConstants.FONT_SIZE_SMALL,
			GameConstants.COLOR_TEXT_MUTED,
			true
		)
		payout_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(payout_label)

		# Reel container
		var reel_center = CenterContainer.new()
		reel_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var reel_box = HBoxContainer.new()
		reel_box.add_theme_constant_override("separation", REEL_SPACING)

		for i in range(REEL_COUNT):
			var reel_column = VBoxContainer.new()
			reel_column.add_theme_constant_override("separation", 8)

			var reel = _create_reel(i)
			reel_labels.append(reel)
			current_symbols.append(SYMBOLS[randi() % SYMBOLS.size()])
			locked_reels.append(false)
			reel_column.add_child(reel)

			# Lock button below each reel
			var lock_btn = Button.new()
			lock_btn.custom_minimum_size = Vector2(50, 50)
			lock_btn.text = "🔓"
			lock_btn.add_theme_font_size_override("font_size", 24)
			lock_btn.tooltip_text = "Lock this reel"
			lock_btn.pressed.connect(_on_lock_pressed.bind(i))
			lock_buttons.append(lock_btn)

			var lock_center = CenterContainer.new()
			lock_center.add_child(lock_btn)
			reel_column.add_child(lock_center)

			reel_box.add_child(reel_column)

		reel_center.add_child(reel_box)
		add_child(reel_center)

		add_child(UIHelpers.create_spacer(20))

		# Buttons
		var button_box = HBoxContainer.new()
		button_box.alignment = BoxContainer.ALIGNMENT_CENTER
		button_box.add_theme_constant_override("separation", 16)

		spin_button = UIHelpers.create_button("Spins: %d" % spins_remaining, _on_spin_pressed, 160, 50)
		UIStyles.setup_success_button(spin_button)
		spin_button.add_theme_font_size_override("font_size", 20)
		button_box.add_child(spin_button)

		extra_spin_button = UIHelpers.create_button(
			"Bonus Spin: %dg" % extra_spin_cost,
			_on_extra_spin_pressed,
			160,
			50
		)
		UIStyles.setup_button(extra_spin_button)
		button_box.add_child(extra_spin_button)

		add_child(button_box)


	func _create_reel(_index: int) -> PanelContainer:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(REEL_WIDTH, REEL_HEIGHT)

		# Style the reel background
		var style = StyleBoxFlat.new()
		style.bg_color = GameConstants.COLOR_PANEL_DARK
		style.set_corner_radius_all(8)
		style.set_border_width_all(3)
		style.border_color = GameConstants.COLOR_BORDER_GOLD
		panel.add_theme_stylebox_override("panel", style)

		# Symbol label
		var center = CenterContainer.new()
		var label = Label.new()
		label.text = "?"
		label.add_theme_font_size_override("font_size", 64)
		label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_LIGHT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		center.add_child(label)
		panel.add_child(center)

		# Store reference to the label for animation
		panel.set_meta("symbol_label", label)

		return panel


	func _on_lock_pressed(reel_index: int) -> void:
		if spinning:
			return

		locked_reels[reel_index] = not locked_reels[reel_index]
		var btn: Button = lock_buttons[reel_index]
		var panel: PanelContainer = reel_labels[reel_index]

		if locked_reels[reel_index]:
			btn.text = "🔒"
			btn.tooltip_text = "Unlock this reel"
			# Dim the locked reel slightly
			var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
			style.border_color = GameConstants.COLOR_TEXT_MUTED
			panel.add_theme_stylebox_override("panel", style)
		else:
			btn.text = "🔓"
			btn.tooltip_text = "Lock this reel"
			# Restore normal border
			var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
			style.border_color = GameConstants.COLOR_BORDER_GOLD
			panel.add_theme_stylebox_override("panel", style)


	func _on_spin_pressed() -> void:
		if spinning or spins_remaining <= 0:
			return

		spins_remaining -= 1
		_update_spins_display()
		_start_spin()


	func _on_extra_spin_pressed() -> void:
		if spinning or extra_spin_purchased:
			return

		# Check if player can afford it
		var can_afford = false
		if extra_spin_resource == "gold":
			var on_gold_spend = context.get("on_gold_spend", Callable())
			if on_gold_spend.is_valid():
				can_afford = on_gold_spend.call(extra_spin_cost)
			else:
				can_afford = RunManager.spend_gold(extra_spin_cost)
		else:
			# Health cost - deduct from a random team member
			var team = RunManager.get_team()
			if team.size() > 0:
				var char_instance = team[randi() % team.size()]
				if char_instance.current_health > extra_spin_cost:
					char_instance.current_health -= extra_spin_cost
					can_afford = true

		if can_afford:
			extra_spin_purchased = true
			_update_button_states()
			_start_spin()
		else:
			result_label.add_theme_color_override("font_color", GameConstants.COLOR_DANGER)
			result_label.text = "Not enough %s!" % extra_spin_resource


	func _start_spin() -> void:
		spinning = true
		result_label.text = ""
		_update_button_states()

		# Track how many reels are actually spinning
		reels_still_spinning = 0

		# Animate each unlocked reel
		for i in range(REEL_COUNT):
			if not locked_reels[i]:
				reels_still_spinning += 1

		var spin_order := 0
		for i in range(REEL_COUNT):
			if not locked_reels[i]:
				_animate_reel(i, spin_order)
				spin_order += 1

		# If all reels are locked, just evaluate immediately
		if reels_still_spinning == 0:
			var eval_tween = create_tween()
			eval_tween.tween_interval(0.1)
			eval_tween.tween_callback(_evaluate_spin)


	func _animate_reel(reel_index: int, spin_order: int = 0) -> void:
		var panel: PanelContainer = reel_labels[reel_index]
		var label: Label = panel.get_meta("symbol_label")

		var stop_time = SPIN_DURATION + (spin_order * REEL_STOP_DELAY)
		var final_symbol = SYMBOLS[randi() % SYMBOLS.size()]
		current_symbols[reel_index] = final_symbol

		# Create spinning animation
		var spin_interval := 1.0 / SYMBOLS_PER_SECOND

		# Use a tween-based approach for symbol cycling
		var tween = create_tween()
		tween.set_loops(int(stop_time / spin_interval))

		# Each loop iteration changes the symbol
		tween.tween_callback(func():
			var random_symbol = SYMBOLS[randi() % SYMBOLS.size()]
			label.text = SYMBOL_EMOJIS[random_symbol]
			label.add_theme_color_override("font_color", SYMBOL_COLORS[random_symbol])

			# Subtle bounce effect
			var bounce_tween = create_tween()
			bounce_tween.tween_property(label, "scale", Vector2(1.1, 0.9), 0.05)
			bounce_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.05)
		).set_delay(spin_interval)

		# Final stop with the determined symbol
		var stop_tween = create_tween()
		stop_tween.tween_interval(stop_time)
		stop_tween.tween_callback(func():
			_stop_reel(reel_index, final_symbol)
		)


	func _stop_reel(reel_index: int, symbol: String) -> void:
		var panel: PanelContainer = reel_labels[reel_index]
		var label: Label = panel.get_meta("symbol_label")

		# Set final symbol
		label.text = SYMBOL_EMOJIS[symbol]
		label.add_theme_color_override("font_color", SYMBOL_COLORS[symbol])

		# Landing animation - bounce and flash
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)

		# Scale pop
		label.pivot_offset = label.size / 2
		tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15)

		# Flash the border
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
		panel.add_theme_stylebox_override("panel", style)

		var flash_tween = create_tween()
		flash_tween.tween_property(style, "border_color", Color.WHITE, 0.1)
		flash_tween.tween_property(style, "border_color", GameConstants.COLOR_BORDER_GOLD, 0.2)

		# Check if all reels have stopped
		reels_still_spinning -= 1
		if reels_still_spinning <= 0:
			# Small delay then evaluate
			var eval_tween = create_tween()
			eval_tween.tween_interval(0.3)
			eval_tween.tween_callback(_evaluate_spin)


	func _evaluate_spin() -> void:
		spinning = false

		var data = encounter_data.get("data", {})
		var jackpot = data.get("jackpot_reward", 100)
		var triple = data.get("triple_reward", 50)
		var pair = data.get("pair_reward", 15)

		# Count symbols
		var counts := {}
		for symbol in current_symbols:
			counts[symbol] = counts.get(symbol, 0) + 1

		var reward := 0
		var message := ""

		# Check for jackpot (3 gems)
		if counts.get("gem", 0) == 3:
			reward = jackpot
			message = "JACKPOT! +%d Gold!" % reward
			_play_jackpot_effect()
		# Check for triple
		elif counts.values().max() == 3:
			reward = triple
			var winning_symbol = ""
			for symbol in counts:
				if counts[symbol] == 3:
					winning_symbol = SYMBOL_EMOJIS[symbol]
					break
			message = "TRIPLE %s! +%d Gold!" % [winning_symbol, reward]
			_play_win_effect()
		# Check for pair
		elif counts.values().max() == 2:
			reward = pair
			var winning_symbol = ""
			for symbol in counts:
				if counts[symbol] == 2:
					winning_symbol = SYMBOL_EMOJIS[symbol]
					break
			message = "PAIR %s! +%d Gold!" % [winning_symbol, reward]
			_play_small_win_effect()
		else:
			message = "No match..."
			result_label.add_theme_color_override("font_color", GameConstants.COLOR_TEXT_MUTED)

		# Award gold
		if reward > 0:
			total_winnings += reward
			var on_gold_reward = context.get("on_gold_reward", Callable())
			if on_gold_reward.is_valid():
				on_gold_reward.call(reward)
			else:
				RunManager.add_gold(reward)

			result_label.add_theme_color_override("font_color", GameConstants.COLOR_SUCCESS)
			message += " (Total: +%d)" % total_winnings

		result_label.text = message
		_update_button_states()

		# Check if encounter is complete
		if spins_remaining <= 0:
			_check_completion()


	func _play_jackpot_effect() -> void:
		# Screen shake and flash all reels gold
		for panel in reel_labels:
			var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
			style.bg_color = GameConstants.COLOR_GOLD
			panel.add_theme_stylebox_override("panel", style)

			var tween = create_tween()
			tween.set_loops(3)
			tween.tween_property(style, "bg_color", Color.WHITE, 0.1)
			tween.tween_property(style, "bg_color", GameConstants.COLOR_GOLD, 0.1)
			tween.chain().tween_property(style, "bg_color", GameConstants.COLOR_PANEL_DARK, 0.3)


	func _play_win_effect() -> void:
		# Flash winning reels
		for i in range(REEL_COUNT):
			var panel: PanelContainer = reel_labels[i]
			var tween = create_tween()
			tween.tween_property(panel, "modulate", Color(1.5, 1.5, 1.5), 0.1)
			tween.tween_property(panel, "modulate", Color.WHITE, 0.2)


	func _play_small_win_effect() -> void:
		# Subtle pulse
		for panel in reel_labels:
			var label: Label = panel.get_meta("symbol_label")
			var tween = create_tween()
			tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.1)
			tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)


	func _update_spins_display() -> void:
		spin_button.text = "Spins: %d" % spins_remaining

		# Animate the change
		var tween = create_tween()
		spin_button.pivot_offset = spin_button.size / 2
		tween.tween_property(spin_button, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(spin_button, "scale", Vector2(1.0, 1.0), 0.1)


	func _update_button_states() -> void:
		spin_button.disabled = spinning or spins_remaining <= 0
		extra_spin_button.disabled = spinning or extra_spin_purchased

		# Disable lock buttons while spinning
		for btn in lock_buttons:
			btn.disabled = spinning

		if extra_spin_purchased:
			extra_spin_button.text = "Purchased"

		if spins_remaining <= 0 and not spinning:
			spin_button.text = "Done"
		elif not spinning:
			spin_button.text = "Spins: %d" % spins_remaining


	func _check_completion() -> void:
		# Signal that the encounter can be completed
		var on_complete = context.get("on_encounter_complete", Callable())
		if on_complete.is_valid():
			on_complete.call()
