shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float softness : hint_range(0.0, 0.2) = 0.02;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	float max_dist = 0.707; // sqrt(0.5^2 + 0.5^2)
	float normalized_dist = dist / max_dist;

	float threshold = progress * 1.2; // Overshoot to ensure full coverage
	float alpha = smoothstep(threshold - softness, threshold, normalized_dist);

	COLOR = vec4(color.rgb, 1.0 - alpha);
}
