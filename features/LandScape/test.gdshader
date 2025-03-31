shader_type spatial;

uniform sampler2D fog_texture;
uniform vec4 fog_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 uv = UV;
    
    // To disable interpolation
    ivec2 tex_size = textureSize(fog_texture, 0);
    vec2 pixel_uv = floor(uv * vec2(tex_size)) / vec2(tex_size);

    // To read transparency without blurring
    float fog_alpha = texture(fog_texture, pixel_uv).a;

    ALBEDO = fog_color.rgb;
    ALPHA = fog_alpha;
}
