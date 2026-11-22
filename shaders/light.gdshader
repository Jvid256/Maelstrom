shader_type canvas_item;
// Haze pass (style anchor v0.2). Runs over the map only, under the HUD.
// The purple apocalyptic haze lifts the shadows toward violet; highlights stay clean.
// (The light itself is in tile.gdshader: low ambient plus the pillar's stepped pool.)

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 haze_color : source_color = vec4(0.243, 0.133, 0.337, 1.0);
uniform float haze_strength = 0.32;

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	float haze = pow(1.0 - clamp(lum / 0.78, 0.0, 1.0), 1.5) * haze_strength;
	col = mix(col, haze_color.rgb, haze);
	COLOR = vec4(col, 1.0);
}
