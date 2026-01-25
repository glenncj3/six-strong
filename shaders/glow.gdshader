shader_type canvas_item;

// Outer glow effect for buttons, cards, icons
// Apply to a ColorRect or TextureRect behind the element

uniform vec4 glow_color : source_color = vec4(0.85, 0.65, 0.13, 1.0); // Gold by default
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float glow_size : hint_range(0.0, 0.5) = 0.15;
uniform float glow_softness : hint_range(0.0, 1.0) = 0.5;
uniform bool pulse_enabled = false;
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	// Calculate distance from edge (0 at edge, 1 at center)
	vec2 uv_centered = UV - 0.5;
	vec2 abs_uv = abs(uv_centered) * 2.0;

	// Distance from edge (rectangular)
	float edge_dist_x = 1.0 - abs_uv.x;
	float edge_dist_y = 1.0 - abs_uv.y;
	float edge_dist = min(edge_dist_x, edge_dist_y);

	// Normalize to glow size
	float glow_factor = smoothstep(0.0, glow_size, edge_dist);

	// Apply softness
	glow_factor = pow(glow_factor, glow_softness);

	// Invert so glow is at edges
	glow_factor = 1.0 - glow_factor;

	// Apply pulse if enabled
	float intensity = glow_intensity;
	if (pulse_enabled) {
		float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
		intensity *= mix(pulse_min, 1.0, pulse);
	}

	// Output glow color with calculated alpha
	COLOR = vec4(glow_color.rgb, glow_factor * intensity * glow_color.a);
}
