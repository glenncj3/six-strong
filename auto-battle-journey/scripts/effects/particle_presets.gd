class_name ParticlePresets
extends RefCounted
## Factory for common particle effects.
## Creates pre-configured GPUParticles2D nodes for various visual effects.

# =============================================================================
# BURST EFFECTS (one-shot)
# =============================================================================

static func create_sparkle_burst(color: Color = Color.WHITE, amount: int = 12) -> CPUParticles2D:
	"""Create a sparkle burst effect (for selections, rewards)."""
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = amount
	particles.lifetime = 0.8

	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2(0, 300)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = color

	# Fade out
	var gradient = Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 1.0))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	particles.color_ramp = gradient_tex

	particles.finished.connect(particles.queue_free)

	return particles


static func create_gold_burst(amount: int = 8) -> CPUParticles2D:
	"""Create gold coin burst effect."""
	return create_sparkle_burst(GameConstants.COLOR_GOLD, amount)


static func create_rarity_burst(rarity: String) -> CPUParticles2D:
	"""Create a burst matching rarity color."""
	var color = UIStyles.get_rarity_color(rarity)
	var amount = 8
	match rarity.to_lower():
		"epic":
			amount = 12
		"legendary":
			amount = 16
	return create_sparkle_burst(color, amount)


# =============================================================================
# CONTINUOUS EFFECTS
# =============================================================================

static func create_ambient_sparkle(color: Color = Color.WHITE, rate: int = 5) -> CPUParticles2D:
	"""Create continuous ambient sparkle effect."""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = rate * 2
	particles.lifetime = 1.5

	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.gravity = Vector2(0, -30)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color

	# Fade in and out
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(color.r, color.g, color.b, 0.0))
	gradient.add_point(0.2, Color(color.r, color.g, color.b, 1.0))
	gradient.add_point(0.8, Color(color.r, color.g, color.b, 1.0))
	gradient.add_point(1.0, Color(color.r, color.g, color.b, 0.0))
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	particles.color_ramp = gradient_tex

	return particles


static func create_legendary_aura() -> CPUParticles2D:
	"""Create legendary item golden aura effect."""
	var particles = create_ambient_sparkle(GameConstants.GLOW_COLOR_LEGENDARY, 8)
	particles.spread = 180.0
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 30.0
	particles.gravity = Vector2(0, -20)
	particles.amount = 16
	particles.lifetime = 2.0
	return particles


static func create_epic_wisps() -> CPUParticles2D:
	"""Create epic item purple wisp effect."""
	var particles = create_ambient_sparkle(GameConstants.GLOW_COLOR_EPIC, 4)
	particles.spread = 90.0
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 25.0
	particles.amount = 8
	particles.lifetime = 2.5
	return particles


# =============================================================================
# UTILITY
# =============================================================================

static func spawn_at(parent: Node, particles: CPUParticles2D, pos: Vector2) -> void:
	"""Spawn particles at a position and start emitting."""
	particles.position = pos
	parent.add_child(particles)
	particles.emitting = true


static func spawn_burst_at(parent: Node, pos: Vector2, color: Color = Color.WHITE) -> void:
	"""Quick spawn a sparkle burst at position."""
	var particles = create_sparkle_burst(color)
	spawn_at(parent, particles, pos)
