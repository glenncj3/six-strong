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
	var spinning: bool = false
	var spins_remaining: int = 0
	var spin_button: Button
	var extra_spin_button: Button
	var result_label: Label
	var spins_label: Label
	var total_winnings: int = 0
	var winnings_label: Label

	# Resource cost config
	var extra_spin_cost: int = 0
	var extra_spin_resource: String = "gold"  # "gold" or "health"
	var extra_spin_purchased: bool = false


	func initialize(p_encounter_data: Dictionary, p_context: Dictionary) -> void:
		encounter_data = p_encounter_data
		context = p_context

		set_anchors_preset(Control.PRESET_FULL_RECT)
		add_theme_constant_override("separation", 16)
		alignment = BoxContainer.ALIGNMENT_CENTER

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

		# Spins remaining
		spins_label = UIHelpers.create_label(
			"Spins: %d" % spins_remaining,
			GameConstants.FONT_SIZE_BODY,
			GameConstants.COLOR_GOLD,
			true
		)
		spins_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(spins_label)

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

		add_child(UIHelpers.create_spacer(8))

		# Reel container
		var reel_center = CenterContainer.new()
		reel_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var reel_box = HBoxContainer.new()
		reel_box.add_theme_constant_override("separation", REEL_SPACING)

		for i in range(REEL_COUNT):
			var reel = _create_reel(i)
			reel_labels.append(reel)
			current_symbols.append(SYMBOLS[randi() % SYMBOLS.size()])
			reel_box.add_child(reel)

		reel_center.add_child(reel_box)
		add_child(reel_center)

		add_child(UIHelpers.create_spacer(8))

		# Result label
		result_label = UIHelpers.create_label(
			"",
			GameConstants.FONT_SIZE_REWARD,
			GameConstants.COLOR_SUCCESS,
			true
		)
		result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(result_label)

		# Winnings tracker
		winnings_label = UIHelpers.create_label(
			"",
			GameConstants.FONT_SIZE_BODY,
			GameConstants.COLOR_GOLD,
			true
		)
		winnings_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(winnings_label)

		add_child(UIHelpers.create_spacer(8))

		# Buttons
		var button_box = HBoxContainer.new()
		button_box.alignment = BoxContainer.ALIGNMENT_CENTER
		button_box.add_theme_constant_override("separation", 16)

		spin_button = UIHelpers.create_button("SPIN!", _on_spin_pressed, 150, 60)
		UIStyles.setup_success_button(spin_button)
		spin_button.add_theme_font_size_override("font_size", 24)
		button_box.add_child(spin_button)

		var resource_icon = "💰" if extra_spin_resource == "gold" else "❤️"
		extra_spin_button = UIHelpers.create_button(
			"+1 Spin (%s%d)" % [resource_icon, extra_spin_cost],
			_on_extra_spin_pressed,
			180,
			60
		)
		UIStyles.setup_button(extra_spin_button)
		button_box.add_child(extra_spin_button)

		add_child(button_box)


	func _create_reel(index: int) -> PanelContainer:
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
			spins_remaining += 1
			_update_spins_display()
			_update_button_states()
		else:
			result_label.add_theme_color_override("font_color", GameConstants.COLOR_DANGER)
			result_label.text = "Not enough %s!" % extra_spin_resource


	func _start_spin() -> void:
		spinning = true
		result_label.text = ""
		_update_button_states()

		# Animate each reel
		for i in range(REEL_COUNT):
			_animate_reel(i)


	func _animate_reel(reel_index: int) -> void:
		var panel: PanelContainer = reel_labels[reel_index]
		var label: Label = panel.get_meta("symbol_label")

		var stop_time = SPIN_DURATION + (reel_index * REEL_STOP_DELAY)
		var final_symbol = SYMBOLS[randi() % SYMBOLS.size()]
		current_symbols[reel_index] = final_symbol

		# Create spinning animation
		var elapsed := 0.0
		var spin_interval := 1.0 / SYMBOLS_PER_SECOND
		var next_change := 0.0

		# Use a timer-based approach for symbol cycling
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
		if reel_index == REEL_COUNT - 1:
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
			_update_winnings_display()

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
		spins_label.text = "Spins: %d" % spins_remaining

		# Animate the change
		var tween = create_tween()
		tween.tween_property(spins_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(spins_label, "scale", Vector2(1.0, 1.0), 0.1)


	func _update_winnings_display() -> void:
		if total_winnings > 0:
			winnings_label.text = "Total Winnings: +%d Gold" % total_winnings

			var tween = create_tween()
			tween.tween_property(winnings_label, "scale", Vector2(1.15, 1.15), 0.1)
			tween.tween_property(winnings_label, "scale", Vector2(1.0, 1.0), 0.1)


	func _update_button_states() -> void:
		spin_button.disabled = spinning or spins_remaining <= 0
		extra_spin_button.disabled = spinning or extra_spin_purchased

		if extra_spin_purchased:
			extra_spin_button.text = "Purchased"

		if spins_remaining <= 0 and not spinning:
			spin_button.text = "Done"


	func _check_completion() -> void:
		# Signal that the encounter can be completed
		var on_complete = context.get("on_encounter_complete", Callable())
		if on_complete.is_valid():
			on_complete.call()
