shader_type spatial;

render_mode world_vertex_coords, specular_disabled, vertex_lighting, cull_disabled;

global uniform vec2 resolution;

uniform sampler2D color_texture : source_color, filter_nearest;

// =====================
// PS1
// =====================

uniform float vertex_wobble : hint_range(0.0,1.0,0.01) = 1.0;
uniform float affine_mapping : hint_range(0.0,1.0,0.01) = 1.0;

// =====================
// Vento
// =====================

uniform float wind_strength : hint_range(0.0,0.5,0.01) = 0.08;
uniform float wind_speed : hint_range(0.0,5.0,0.01) = 1.5;
uniform vec2 wind_direction = vec2(1.0,0.35);

varying vec2 original_uv;
varying float view_depth;

void vertex() {

    original_uv = UV;

    // ---------------------
    // ALTURA DA ÁRVORE
    // ---------------------

    // Ajuste estes valores conforme o tamanho da sua árvore.
    float height = smoothstep(0.3, 2.0, VERTEX.y);

    // ---------------------
    // VENTO
    // ---------------------

    float offset =
        NODE_POSITION_WORLD.x * 0.13 +
        NODE_POSITION_WORLD.z * 0.17;

    float wind =
        sin(TIME * wind_speed + offset) * 0.7 +
        sin(TIME * wind_speed * 2.3 + offset * 1.8) * 0.3;

    vec2 dir = normalize(wind_direction);

    float movement = wind * wind_strength * height;

    // Movimento lateral
    VERTEX.x += movement * dir.x;
    VERTEX.z += movement * dir.y;

    // Pequena inclinação
    VERTEX.x += movement * VERTEX.y * 0.02 * dir.x;
    VERTEX.z += movement * VERTEX.y * 0.02 * dir.y;

    // ---------------------
    // PS1
    // ---------------------

    vec4 view_position = VIEW_MATRIX * vec4(VERTEX,1.0);

    view_depth = view_position.z;

    UV *= view_depth;

    vec4 clip_position = PROJECTION_MATRIX * view_position;

    vec2 snapping = resolution * vertex_wobble;

    clip_position.xy =
        round(clip_position.xy * snapping) / snapping;

    POSITION = clip_position;
}

void fragment() {

    vec2 uv = mix(
        original_uv,
        UV / view_depth,
        affine_mapping
    );

    vec4 tex = texture(color_texture, uv);

    if(tex.a < 0.5)
        discard;

    ALBEDO = tex.rgb;
}