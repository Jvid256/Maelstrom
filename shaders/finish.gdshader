shader_type canvas_item;
// Screen finish (style anchor v0.2), over everything including the HUD:
// a cool-violet grade, a strong vignette, a slight chromatic fringe toward the edges
// and fine monochrome film grain.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec2 base_size = vec2(640.0, 360.0);
uniform vec3 grade = vec3(0.98, 0.93, 1.06);
uniform float vignette = 0.85;
uniform float fringe_px = 0.5;
uniform float grain = 0.03;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float edge = smoothstep(0.18, 0.5, length(c));
	vec2 shift = normalize(c + 1e-5) * fringe_px * edge / base_size;
	vec3 col;
	col.r = texture(screen_tex, uv + shift).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - shift).b;
	col *= grade;
	float v = 1.0 - pow(clamp(length(c * vec2(1.0, 0.92)) * 1.3, 0.0, 1.0), 2.2) * vignette;
	col *= v;
	// fine grain on the output pixels, re-rolled 12 times a second
	float n = hash(floor(FRAGCOORD.xy) + floor(TIME * 12.0) * vec2(17.0, 31.0)) - 0.5;
	col += n * grain * 2.0;
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
