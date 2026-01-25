shader_type canvas_item;

// Animated diagonal shine sweep effect
// Great for buttons, cards, and reward items

uniform float shine_width : hint_range(0.05, 0.5) = 0.15;
uniform float shine_angle : hint_range(-1.57, 1.57) = 0.785; // 45 degrees
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);
uniform float shine_speed : hint_range(0.5, 5.0) = 1.5;
uniform float shine_interval : hint_range(1.0, 10.0) = 3.0; // Time between shines
uniform bool auto_animate = true;
uniform float manual_progress : hint_range(-0.5, 1.5) = 0.0; // For manual control

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);

	// Calculate shine position
	float progress;
	if (auto_animate) {
		// Animate with interval
		float cycle_time = mod(TIME * shine_speed, shine_interval);
		progress = cycle_time / (shine_interval * 0.3); // Shine takes 30% of interval
		progress = progress * 2.0 - 0.5; // Range: -0.5 to 1.5
	} else {
		progress = manual_progress;
	}

	// Rotate UV for angled shine
	float cos_angle = cos(shine_angle);
	float sin_angle = sin(shine_angle);
	vec2 rotated_uv = vec2(
		UV.x * cos_angle - UV.y * sin_angle,
		UV.x * sin_angle + UV.y * cos_angle
	);

	// Calculate shine intensity
	float dist_from_shine = abs(rotated_uv.x - progress);
	float shine_intensity = 1.0 - smoothstep(0.0, shine_width, dist_from_shine);

	// Only show shine when in range
	if (progress < -0.3 || progress > 1.3) {
		shine_intensity = 0.0;
	}

	// Blend shine with base
	vec4 final_color = base_color;
	final_color.rgb = mix(base_color.rgb, shine_color.rgb, shine_intensity * shine_color.a);
	final_color.a = base_color.a;

	COLOR = final_color;
}
