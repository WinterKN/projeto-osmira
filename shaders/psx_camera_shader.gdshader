shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;


// ============================================================
// TEXTURAS
// ============================================================

uniform sampler2D depth_texture : source_color, hint_depth_texture;

uniform sampler2D screen_texture :
	source_color,
	hint_screen_texture,
	repeat_disable,
	filter_nearest;


// ============================================================
// POST PROCESSING - RESOLUÇÃO / PROFUNDIDADE DE COR
// ============================================================

global uniform vec2 resolution;
global uniform float color_depth;


// ============================================================
// FOG
// ============================================================

uniform bool enable_fog = true;

uniform vec3 fog_color : source_color = vec3(0.27, 0.30, 0.27);
uniform vec3 noise_color : source_color = vec3(0.38, 0.37, 0.31);

uniform float fog_distance : hint_range(1.0, 6000.0, 1.0) = 120.0;
uniform float fog_fade_range : hint_range(1.0, 6000.0, 1.0) = 70.0;
uniform float fog_opacity : hint_range(0.0, 1.0, 0.01) = 0.78;


// ============================================================
// NOISE ATMOSFÉRICO
// ============================================================

uniform bool enable_noise = true;

uniform float noise_strength : hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float noise_time_fac : hint_range(0.1, 20.0, 0.1) = 6.0;


// ============================================================
// LIMITAÇÃO DE CORES
// ============================================================

uniform bool enable_color_limitation = true;

uniform int color_levels : hint_range(2, 256) = 48;


// ============================================================
// DITHERING
// ============================================================

uniform bool enable_dithering = true;

uniform float dither_strength : hint_range(0.0, 1.0, 0.01) = 0.08;


// ============================================================
// AJUSTES FINAIS DE COR
// ============================================================

uniform vec3 color_tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float saturation : hint_range(0.0, 2.0, 0.01) = 0.95;
uniform float contrast : hint_range(0.5, 2.0, 0.01) = 1.05;


// ============================================================
// HASH / NOISE
// ============================================================

float hash12(vec2 p) {
	return fract(
		sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123
	);
}


// ============================================================
// QUANTIZAÇÃO
// ============================================================

vec3 quantize_color(vec3 color, int levels) {
	float lv = float(max(levels, 2) - 1);
	return floor(color * lv + 0.5) / lv;
}


// ============================================================
// AJUSTE DE SATURAÇÃO / CONTRASTE
// ============================================================

vec3 apply_color_adjustments(vec3 color, float sat, float con) {
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, sat);
	color = (color - 0.5) * con + 0.5;
	return color;
}


// ============================================================
// BAYER 4x4
// ============================================================

float get_bayer_4x4(ivec2 pos) {
	int x = int(mod(float(pos.x), 4.0));
	int y = int(mod(float(pos.y), 4.0));
	int index = x + y * 4;

	float bayer[16] = float[](
		0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
		12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
		3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
		15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
	);

	return bayer[index] - 0.5;
}


// ============================================================
// VERTEX
// ============================================================

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}


// ============================================================
// FRAGMENT
// ============================================================

void fragment() {

	// --------------------------------------------------------
	// SEGURANÇA
	// --------------------------------------------------------

	vec2 safe_resolution = max(resolution, vec2(1.0));
	float safe_color_depth = max(color_depth, 2.0);


	// --------------------------------------------------------
	// UV PIXELIZADO
	// --------------------------------------------------------

	vec2 uv = floor(SCREEN_UV * safe_resolution) / safe_resolution;
	ivec2 pixel_pos = ivec2(SCREEN_UV * safe_resolution);


	// --------------------------------------------------------
	// COR ORIGINAL DA TELA
	// --------------------------------------------------------

	vec3 screen_color = texture(screen_texture, uv).rgb;
	vec3 final_color = screen_color;


	// --------------------------------------------------------
	// DEPTH LINEAR
	// --------------------------------------------------------

	vec2 screen_coords = SCREEN_UV * 2.0 - 1.0;
	float depth = texture(depth_texture, SCREEN_UV).x;

	vec3 ndc = vec3(screen_coords, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;

	float linear_depth = -view.z;


	// --------------------------------------------------------
	// FOG FACTOR
	// --------------------------------------------------------

	float fog_start = max(fog_distance - fog_fade_range, 0.0);

	float fog_factor = smoothstep(
		fog_start,
		fog_distance,
		linear_depth
	);

	fog_factor *= fog_opacity;


	// --------------------------------------------------------
	// COR DA FOG COM NOISE
	// --------------------------------------------------------

	vec3 fog_final_color = fog_color;

	if (enable_noise) {
		vec2 noise_uv = floor(uv * safe_resolution);
		noise_uv += vec2(TIME * (1.0 / noise_time_fac), TIME * (0.73 / noise_time_fac));

		float noise_value = hash12(noise_uv);

		fog_final_color = mix(
			fog_color,
			noise_color,
			noise_value * noise_strength
		);
	}


	// --------------------------------------------------------
	// APLICAR FOG
	// --------------------------------------------------------

	if (enable_fog) {
		final_color = mix(
			final_color,
			fog_final_color,
			fog_factor
		);
	}


	// --------------------------------------------------------
	// AJUSTES FINAIS DE COR
	// --------------------------------------------------------

	final_color *= color_tint;
	final_color = apply_color_adjustments(
		final_color,
		saturation,
		contrast
	);


	// --------------------------------------------------------
	// DITHERING
	// --------------------------------------------------------

	if (enable_dithering) {
		final_color +=
			(get_bayer_4x4(pixel_pos) / safe_color_depth) *
			dither_strength;
	}


	// --------------------------------------------------------
	// LIMITAÇÃO DE CORES
	// --------------------------------------------------------

	if (enable_color_limitation) {
		final_color = quantize_color(
			final_color,
			color_levels
		);
	}


	// --------------------------------------------------------
	// RESULTADO
	// --------------------------------------------------------

	ALBEDO = clamp(final_color, vec3(0.0), vec3(1.0));
}