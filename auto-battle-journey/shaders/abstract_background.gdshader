shader_type canvas_item;

// Abstract procedural background based on #977D6C
// Creates organic texture with warm hue variations

uniform vec4 color_base : source_color = vec4(0.52, 0.43, 0.38, 1.0);          // #856D61 - darker base
uniform vec4 color_dark : source_color = vec4(0.28, 0.23, 0.20, 1.0);          // #473A33 - deep shadow
uniform vec4 color_light : source_color = vec4(0.68, 0.58, 0.50, 1.0);         // #AD9480 - muted highlight
uniform vec4 color_warm : source_color = vec4(0.60, 0.44, 0.32, 1.0);          // #997052 - warm mid
uniform vec4 color_cool : source_color = vec4(0.42, 0.40, 0.40, 1.0);          // #6B6666 - cool recess

uniform float scale : hint_range(1.0, 20.0) = 4.5;
uniform float detail : hint_range(1.0, 8.0) = 5.0;
uniform float contrast : hint_range(0.0, 1.0) = 0.6;
uniform float animation_speed : hint_range(0.0, 0.1) = 0.015;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;

// Hash functions for noise generation
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float hash1(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Value noise
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // Smoothstep

	float a = hash1(i);
	float b = hash1(i + vec2(1.0, 0.0));
	float c = hash1(i + vec2(0.0, 1.0));
	float d = hash1(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractional Brownian Motion
float fbm(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for (int i = 0; i < octaves; i++) {
		value += amplitude * value_noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

// Domain-warped FBM for more organic patterns
float warped_fbm(vec2 p, float t) {
	vec2 q = vec2(
		fbm(p + vec2(0.0, 0.0) + vec2(t * 0.3, t * 0.1), int(detail)),
		fbm(p + vec2(5.2, 1.3) + vec2(t * 0.1, t * 0.2), int(detail))
	);

	vec2 r = vec2(
		fbm(p + scale * q + vec2(1.7, 9.2) + vec2(t * 0.15, 0.0), int(detail)),
		fbm(p + scale * q + vec2(8.3, 2.8) + vec2(0.0, t * 0.12), int(detail))
	);

	return fbm(p + scale * r, int(detail));
}

// Cellular/voronoi-like texture for additional detail
float cellular(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float min_dist = 1.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 point = hash2(i + neighbor);
			vec2 diff = neighbor + point - f;
			float dist = length(diff);
			min_dist = min(min_dist, dist);
		}
	}
	return min_dist;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * animation_speed;

	// Scale UV for pattern size
	vec2 p = uv * scale;

	// Layer 1: Large-scale domain-warped noise (primary texture)
	float n1 = warped_fbm(p * 0.5, t);

	// Layer 2: Medium detail noise
	float n2 = fbm(p * 1.5 + vec2(t * 0.5, -t * 0.3), int(detail) - 1);

	// Layer 3: Fine cellular texture for crinkled paper feel
	float n3 = cellular(p * 3.5 + vec2(t * 0.2, t * 0.1));

	// Layer 4: Extra fine noise for paper grain
	float n4 = fbm(p * 6.0 + vec2(t * 0.1, -t * 0.05), 3);

	// Combine layers - heavier on texture
	float combined = n1 * 0.45 + n2 * 0.2 + n3 * 0.2 + n4 * 0.15;

	// Create color variation using the noise layers
	vec4 col = color_base;

	// Blend toward dark more aggressively - wider range
	col = mix(col, color_dark, smoothstep(0.45, 0.15, combined) * contrast);

	// Blend toward light only in peaks - narrower, subtler
	col = mix(col, color_light, smoothstep(0.6, 0.8, combined) * contrast * 0.4);

	// Add warm accent in mid-tones
	col = mix(col, color_warm, smoothstep(0.35, 0.6, n2) * 0.2);

	// Add cool tones in recesses
	col = mix(col, color_cool, smoothstep(0.5, 0.2, n1) * 0.12);

	// Subtle vignette for depth
	vec2 vig_uv = uv * 2.0 - 1.0;
	float vignette = 1.0 - dot(vig_uv * 0.5, vig_uv * 0.5);
	vignette = smoothstep(0.0, 1.0, vignette);
	col.rgb *= mix(1.0, vignette, vignette_strength);

	// Darken overall to sit properly as a background
	col.rgb *= 0.7;

	COLOR = col;
}
