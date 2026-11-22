shader_type canvas_item;
// Palette swap, erosion and fog for map tiles, following style anchor v0.2.
// Stable tiles draw as-is. Unstable tiles map each pixel's brightness onto the
// shared purple ramp ("shift" steps darker), optionally tinted toward the heart.
// Fog is flat tinted bands with a 1 px checker only at band edges.

uniform bool unstable = false;
uniform int shift = -1;
uniform float deep : hint_range(0.0, 1.0) = 0.0;
uniform float fog : hint_range(0.0, 1.0) = 0.0;
uniform float erode : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
// No sun: land sits at a low ambient; the light pass adds the pillar's pool on top.
uniform float ambient = 0.58;
// Up to three pools of light, in map pixels: the pillar, the anchor mast, Pallas. Radius 0 = off.
uniform vec2 light_pos1 = vec2(264.0, 160.0);
uniform float light_radius1 = 95.0;
uniform vec4 light_tint1 : source_color = vec4(0.902, 0.984, 1.0, 1.0);
uniform vec2 light_pos2 = vec2(0.0, 0.0);
uniform float light_radius2 = 0.0;
uniform vec4 light_tint2 : source_color = vec4(0.94, 0.75, 0.38, 1.0);
uniform vec2 light_pos3 = vec2(0.0, 0.0);
uniform float light_radius3 = 0.0;
uniform vec4 light_tint3 : source_color = vec4(0.94, 0.69, 0.31, 1.0);
uniform float light_strength = 1.15;
// Small lights: lamps, shrines, forges, lit windows. Positions in map pixels; radius 0 = off.
const int MAX_SMALL = 24;
uniform int small_count = 0;
uniform vec2 small_pos[24];
uniform float small_radius[24];
uniform vec4 small_tint[24] : source_color;
uniform vec4 wash : source_color = vec4(0.129, 0.094, 0.173, 1.0);

uniform vec4 ramp0 : source_color = vec4(0.055, 0.043, 0.078, 1.0);
uniform vec4 ramp1 : source_color = vec4(0.090, 0.071, 0.122, 1.0);
uniform vec4 ramp2 : source_color = vec4(0.129, 0.102, 0.173, 1.0);
uniform vec4 ramp3 : source_color = vec4(0.180, 0.141, 0.235, 1.0);
uniform vec4 ramp4 : source_color = vec4(0.239, 0.188, 0.314, 1.0);
uniform vec4 ramp5 : source_color = vec4(0.306, 0.247, 0.392, 1.0);
uniform vec4 deep_color : source_color = vec4(0.290, 0.165, 0.369, 1.0);
uniform vec4 fog_light : source_color = vec4(0.110, 0.086, 0.149, 1.0);
uniform vec4 fog_thick : source_color = vec4(0.145, 0.110, 0.192, 1.0);
uniform vec4 outline_unstable : source_color = vec4(0.043, 0.035, 0.063, 1.0);

varying vec2 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.13) * 43758.5453);
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int b[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(b[y * 4 + x]) + 0.5) / 16.0;
}

vec3 ramp(int i) {
	if (i <= 0) return ramp0.rgb;
	if (i == 1) return ramp1.rgb;
	if (i == 2) return ramp2.rgb;
	if (i == 3) return ramp3.rgb;
	if (i == 4) return ramp4.rgb;
	return ramp5.rgb;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.5) {
		discard;
	}
	// Loose pieces crumble: pixels near the silhouette edge drop out.
	if (erode > 0.0) {
		vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
		float edge = 0.0;
		for (int k = 1; k <= 3; k++) {
			float d = float(k);
			edge += step(texture(TEXTURE, UV + vec2(d, 0.0) * TEXTURE_PIXEL_SIZE).a, 0.5);
			edge += step(texture(TEXTURE, UV - vec2(d, 0.0) * TEXTURE_PIXEL_SIZE).a, 0.5);
			edge += step(texture(TEXTURE, UV + vec2(0.0, d) * TEXTURE_PIXEL_SIZE).a, 0.5);
			edge += step(texture(TEXTURE, UV - vec2(0.0, d) * TEXTURE_PIXEL_SIZE).a, 0.5);
		}
		float blocky = hash(floor(px / 2.0));
		if (edge > 0.0 && blocky < erode * (0.25 + edge * 0.08)) {
			discard;
		}
	}
	vec3 col = c.rgb;
	float mx = max(col.r, max(col.g, col.b));
	float mn = min(col.r, min(col.g, col.b));
	// lit windows, the pillar crystal and other light sources keep their brightness
	float emissive = smoothstep(0.30, 0.55, (mx - mn) * mx * 2.2) * step(0.55, mx);
	if (unstable) {
		float l = dot(col, vec3(0.299, 0.587, 0.114));
		if (l < 0.07) {
			col = outline_unstable.rgb;
		} else {
			// loose pieces: the world's own colors, darker and washed into the haze;
			// features one more step down so they read as silhouettes
			col = mix(col * (shift <= -2 ? 0.55 : 0.75), wash.rgb, 0.3);
			if (deep > 0.0) {
				col = mix(col, deep_color.rgb, deep * 0.3);
			}
		}
		emissive = 0.0;
	}
	// light: low ambient everywhere, plus the pillar's pool in 6 stepped, dithered bands
	vec2 wp = floor(world_pos);
	float f = 0.0;
	vec3 tint = vec3(0.0);
	if (light_radius1 > 0.0) {
		float f1 = light_strength * pow(clamp(1.0 - length((wp - light_pos1) * vec2(1.0, 1.3)) / light_radius1, 0.0, 1.0), 1.6);
		f += f1;
		tint += light_tint1.rgb * f1;
	}
	if (light_radius2 > 0.0) {
		float f2 = light_strength * pow(clamp(1.0 - length((wp - light_pos2) * vec2(1.0, 1.3)) / light_radius2, 0.0, 1.0), 1.6);
		f += f2;
		tint += light_tint2.rgb * f2;
	}
	if (light_radius3 > 0.0) {
		float f3 = light_strength * pow(clamp(1.0 - length((wp - light_pos3) * vec2(1.0, 1.3)) / light_radius3, 0.0, 1.0), 1.6);
		f += f3;
		tint += light_tint3.rgb * f3;
	}
	for (int i = 0; i < MAX_SMALL; i++) {
		if (i >= small_count) break;
		if (small_radius[i] <= 0.0) continue;
		float fs = light_strength * 1.1 * pow(clamp(1.0 - length((wp - small_pos[i]) * vec2(1.0, 1.3)) / small_radius[i], 0.0, 1.0), 1.4);
		f += fs;
		tint += small_tint[i].rgb * fs;
	}
	float L = floor(clamp(ambient + f, 0.0, 1.6) * 6.0 + bayer4(wp)) / 6.0;
	vec3 lit = col * (vec3(L * 0.75) + tint * 0.5);
	col = mix(lit, col, emissive);
	if (fog > 0.0) {
		vec2 p = floor(world_pos);
		float n = 0.5 + 0.25 * sin(p.x / 13.0 + sin(p.y / 9.0) * 1.3) + 0.25 * cos(p.y / 11.0 - p.x / 23.0);
		float th1 = 1.0 - fog * 1.25;
		float th2 = 1.0 - fog * 0.55;
		bool chk = mod(p.x + p.y, 2.0) < 1.0;
		int lvl = 0;
		if (n > th1 || (abs(n - th1) < 0.03 && chk)) lvl = 1;
		if (n > th2 || (abs(n - th2) < 0.03 && chk)) lvl = 2;
		if (lvl == 1) {
			col = mix(col, fog_light.rgb, 0.5);
		} else if (lvl == 2) {
			col = mix(col, fog_thick.rgb, 0.72);
		}
	}
	COLOR = vec4(col, 1.0);
}
