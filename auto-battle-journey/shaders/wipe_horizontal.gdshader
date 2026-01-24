shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float softness : hint_range(0.0, 0.2) = 0.02;

void fragment() {
	float threshold = progress * 1.1; // Slight overshoot
	float alpha = smoothstep(threshold - softness, threshold, 1.0 - UV.x);

	COLOR = vec4(color.rgb, alpha);
}
