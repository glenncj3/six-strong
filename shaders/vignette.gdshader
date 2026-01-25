shader_type canvas_item;

// Soft edge darkening effect for panels and cards
// Creates depth by darkening the edges

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_softness : hint_range(0.1, 2.0) = 0.8;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec2 vignette_center = vec2(0.5, 0.5);
uniform float vignette_roundness : hint_range(0.0, 1.0) = 1.0; // 0 = rectangular, 1 = circular

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);

	// Calculate distance from center
	vec2 uv_centered = UV - vignette_center;

	float dist;
	if (vignette_roundness > 0.99) {
		// Circular vignette
		dist = length(uv_centered) * 2.0;
	} else if (vignette_roundness < 0.01) {
		// Rectangular vignette
		vec2 abs_uv = abs(uv_centered) * 2.0;
		dist = max(abs_uv.x, abs_uv.y);
	} else {
		// Blend between circular and rectangular
		vec2 abs_uv = abs(uv_centered) * 2.0;
		float rect_dist = max(abs_uv.x, abs_uv.y);
		float circ_dist = length(uv_centered) * 2.0;
		dist = mix(rect_dist, circ_dist, vignette_roundness);
	}

	// Apply softness
	float vignette = smoothstep(1.0 - vignette_softness, 1.0, dist);
	vignette *= vignette_intensity;

	// Blend vignette color
	vec4 final_color = base_color;
	final_color.rgb = mix(base_color.rgb, vignette_color.rgb, vignette);

	COLOR = final_color;
}
