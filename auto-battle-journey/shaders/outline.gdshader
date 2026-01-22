shader_type canvas_item;

// Glowing outline effect for selected elements
// Works with sprites and textures

uniform vec4 outline_color : source_color = vec4(0.85, 0.65, 0.13, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform float outline_glow : hint_range(0.0, 1.0) = 0.5;
uniform bool pulse_enabled = false;
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;

	// Sample surrounding pixels for outline
	float outline_alpha = 0.0;
	float samples = 0.0;

	// Sample in a circle around the pixel
	for (float angle = 0.0; angle < 6.28; angle += 0.785) { // 8 samples
		vec2 offset = vec2(cos(angle), sin(angle)) * pixel_size * outline_width;
		float sample_alpha = texture(TEXTURE, UV + offset).a;
		outline_alpha = max(outline_alpha, sample_alpha);
		samples += 1.0;
	}

	// Additional samples at cardinal directions for quality
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(pixel_size.x * outline_width, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(pixel_size.x * outline_width, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, pixel_size.y * outline_width)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(0.0, pixel_size.y * outline_width)).a);

	// Calculate outline (where surrounding pixels are opaque but this pixel is transparent)
	float outline = outline_alpha * (1.0 - base_color.a);

	// Add glow effect
	float glow_outline = 0.0;
	if (outline_glow > 0.0) {
		for (float i = 1.0; i <= 3.0; i += 1.0) {
			float glow_width = outline_width + i * 2.0;
			for (float angle = 0.0; angle < 6.28; angle += 0.785) {
				vec2 offset = vec2(cos(angle), sin(angle)) * pixel_size * glow_width;
				glow_outline = max(glow_outline, texture(TEXTURE, UV + offset).a);
			}
		}
		glow_outline *= (1.0 - base_color.a) * (1.0 - outline) * outline_glow * 0.5;
	}

	// Apply pulse if enabled
	float intensity = 1.0;
	if (pulse_enabled) {
		float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
		intensity = mix(0.7, 1.0, pulse);
	}

	// Combine
	vec4 final_color = base_color;
	if (outline > 0.0) {
		final_color = vec4(outline_color.rgb, outline * outline_color.a * intensity);
	} else if (glow_outline > 0.0) {
		final_color = vec4(outline_color.rgb, glow_outline * intensity);
	}

	// If base pixel is opaque, show base with slight edge highlight
	if (base_color.a > 0.0) {
		final_color = base_color;
	}

	COLOR = final_color;
}
