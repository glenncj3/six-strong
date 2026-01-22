shader_type canvas_item;

// Multi-stop gradient overlay for panels
// Can be vertical, horizontal, or radial

uniform vec4 color_top : source_color = vec4(0.2, 0.2, 0.3, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.1, 0.1, 0.15, 1.0);
uniform vec4 color_mid : source_color = vec4(0.15, 0.15, 0.22, 1.0);
uniform bool use_mid_color = true;
uniform float mid_position : hint_range(0.0, 1.0) = 0.5;

// Gradient direction: 0 = vertical, 1 = horizontal, 2 = radial
uniform int gradient_type : hint_range(0, 2) = 0;

// For radial gradient
uniform vec2 radial_center = vec2(0.5, 0.5);
uniform float radial_scale : hint_range(0.1, 2.0) = 1.0;

void fragment() {
	float t;

	if (gradient_type == 0) {
		// Vertical gradient (top to bottom)
		t = UV.y;
	} else if (gradient_type == 1) {
		// Horizontal gradient (left to right)
		t = UV.x;
	} else {
		// Radial gradient (center to edge)
		t = distance(UV, radial_center) * radial_scale;
		t = clamp(t, 0.0, 1.0);
	}

	vec4 final_color;

	if (use_mid_color) {
		// Three-stop gradient
		if (t < mid_position) {
			float local_t = t / mid_position;
			final_color = mix(color_top, color_mid, local_t);
		} else {
			float local_t = (t - mid_position) / (1.0 - mid_position);
			final_color = mix(color_mid, color_bottom, local_t);
		}
	} else {
		// Two-stop gradient
		final_color = mix(color_top, color_bottom, t);
	}

	// Preserve original alpha if needed
	COLOR = final_color;
}
