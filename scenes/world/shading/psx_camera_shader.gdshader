shader_type spatial;
render_mode cull_disabled, unshaded, fog_disabled;


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
// POST PROCESSING - RESOLUÇÃO / PIXELAMENTO
// ============================================================

global uniform vec2 resolution;
global uniform float color_depth;

uniform float dither_amount : hint_range(0.0, 1.0, 0.01) = 0.5;


// ============================================================
// PSX CAMERA - FOG
// ============================================================

uniform bool enable_fog = true;

uniform vec3 fog_color : source_color;

uniform vec3 noise_color : source_color;

uniform float fog_distance :
	hint_range(1, 6000) = 100;

uniform float fog_fade_range :
	hint_range(1, 6000) = 50;


// ============================================================
// PSX CAMERA - NOISE
// ============================================================

uniform bool enable_noise = true;

uniform float noise_time_fac :
	hint_range(0.1, 10) = 4;


// ============================================================
// PSX CAMERA - LIMITAÇÃO DE CORES
// ============================================================

uniform bool enable_color_limitation = true;

uniform int color_levels :
	hint_range(2, 256) = 32;


// ============================================================
// PSX CAMERA - DITHERING
// ============================================================

uniform bool enable_dithering = true;

uniform float dither_strength :
	hint_range(0.0, 1.0) = 0.3;


// ============================================================
// BAYER MATRIX
// ============================================================

const mat4 bayer_matrix = (1.0 / 16.0) * mat4(
	vec4(0.0, 8.0, 2.0, 10.0),
	vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0),
	vec4(15.0, 7.0, 13.0, 9.0)
) - 0.5;


// ============================================================
// PSX NOISE
// ============================================================

float hashOld12(vec2 p) {
	return fract(
		sin(dot(p, vec2(12.9898, 78.233)))
		* 43758.5453
		+ (TIME / noise_time_fac)
	);
}


// ============================================================
// COLOR MIX
// ============================================================

vec3 color_mix(vec3 a, vec3 b, float f) {

	f = clamp(abs(f), 0.0, 1.0);

	float invf = 1.0 - f;

	return (a * f) + (b * invf);
}


// ============================================================
// PSX QUANTIZATION
// ============================================================

vec3 quantize_color(vec3 color, int levels) {

	float quantizer = float(levels - 1);

	return floor(
		color * quantizer + 0.5
	) / quantizer;
}


// ============================================================
// PSX DITHER
// ============================================================

float dither(vec2 position, float brightness) {

	int x = int(mod(position.x, 4.0));
	int y = int(mod(position.y, 4.0));

	int index = x + y * 4;

	float dithering[16] = float[](
		0.0, 0.5, 0.125, 0.625,
		0.75, 0.25, 0.875, 0.375,
		0.1875, 0.6875, 0.0625, 0.5625,
		0.9375, 0.4375, 1.0, 0.8125
	);

	float threshold = dithering[index];

	return brightness < threshold ? 0.0 : 1.0;
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

	// ========================================================
	// PIXELAMENTO DO POST PROCESSING
	// ========================================================

	vec2 uv = floor(
		SCREEN_UV * resolution
	) / resolution;

	ivec2 int_uv = ivec2(
		uv * resolution
	);


	// ========================================================
	// IMAGEM ORIGINAL
	// ========================================================

	// A imagem usa o UV pixelizado.
	vec3 screen_color =
		texture(screen_texture, uv).rgb;


	// ========================================================
	// DEPTH
	// ========================================================

	// IMPORTANTE:
	// O depth continua usando SCREEN_UV original.
	// Não usar "uv" aqui.

	vec2 screen_coords =
		SCREEN_UV * 2.0 - 1.0;

	float depth =
		texture(depth_texture, SCREEN_UV).x;

	vec3 ndc =
		vec3(screen_coords, depth);

	vec4 view =
		INV_PROJECTION_MATRIX *
		vec4(ndc, 1.0);

	view.xyz /= view.w;

	float linear_depth =
		-view.z;


	// ========================================================
	// FOG MASK
	// ========================================================

	float depth_mask_inv =
		clamp(
			(
				linear_depth -
				(fog_distance - fog_fade_range)
			) / fog_fade_range,
			0.0,
			1.0
		);


	// ========================================================
	// COR FINAL INICIAL
	// ========================================================

	vec3 final_color =
		screen_color;


	// ========================================================
	// NOISE DO PSX CAMERA
	// ========================================================

	if (enable_noise) {

		vec3 twocolornoise =
			color_mix(
				fog_color,
				noise_color,
				hashOld12(screen_coords)
			);

		final_color =
			color_mix(
				twocolornoise,
				final_color,
				depth_mask_inv
			);
	}


	// ========================================================
	// FOG DO PSX CAMERA
	// ========================================================

	if (enable_fog) {

		final_color =
			color_mix(
				fog_color,
				final_color,
				depth_mask_inv
			);
	}


	// ========================================================
	// LIMITAÇÃO DE CORES DO PSX CAMERA
	// ========================================================

	if (enable_color_limitation) {

		final_color =
			quantize_color(
				final_color,
				color_levels
			);
	}


	// ========================================================
	// DITHERING DO PSX CAMERA
	// ========================================================

	if (enable_dithering) {

		float brightness =
			dot(
				final_color,
				vec3(0.3, 0.59, 0.11)
			);

		brightness +=
			dither_strength *
			(
				dither(
					FRAGCOORD.xy,
					brightness
				) - 0.5
			);

		final_color *=
			(
				1.0 +
				dither_strength *
				(
					dither(
						FRAGCOORD.xy,
						brightness
					) - 0.5
				)
			);
	}


	// ========================================================
	// PIXEL DITHERING DO POST PROCESSING
	// ========================================================

	vec3 dithered_color =
		final_color +
		bayer_matrix[
			int_uv.x % 4
		][
			int_uv.y % 4
		]
		/ color_depth
		* dither_amount;


	// ========================================================
	// QUANTIZAÇÃO DO POST PROCESSING
	// ========================================================

	vec3 quantized_color =
		round(
			dithered_color * color_depth
		) / color_depth;


	// ========================================================
	// RESULTADO
	// ========================================================

	ALBEDO = quantized_color;
}