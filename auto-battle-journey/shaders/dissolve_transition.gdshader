shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float noise = random(UV * 20.0);
	float threshold = progress;

	if (noise < threshold - edge_width) {
		COLOR = color;
	} else if (noise < threshold) {
		// Edge glow
		float edge = (threshold - noise) / edge_width;
		COLOR = mix(vec4(0.85, 0.65, 0.13, 1.0), color, edge);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
