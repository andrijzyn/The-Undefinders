shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_prepass_alpha;

uniform float ghost_alpha : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D albedo_texture;
uniform vec3 albedo_color : source_color  = vec3(1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = albedo_color * tex_color.rgb;
    ALPHA = ghost_alpha * tex_color.a;
}