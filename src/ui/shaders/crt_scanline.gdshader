shader_type canvas_item;

// Cyberpunk CRT Scanline and Chromatic Aberration Shader

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float scanline_count : hint_range(50.0, 800.0) = 480.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.015;
uniform float scanline_speed : hint_range(0.0, 5.0) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.0;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.20;
uniform float brightness : hint_range(0.5, 1.5) = 1.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Chromatic Aberration (RGB Shift)
    vec2 r_offset = vec2(chromatic_aberration, 0.0);
    vec2 b_offset = vec2(-chromatic_aberration, 0.0);
    
    float r = texture(SCREEN_TEXTURE, uv + r_offset).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv + b_offset).b;
    vec3 color = vec3(r, g, b);
    
    // Scanlines
    float scanline = sin((uv.y + TIME * scanline_speed * 0.05) * scanline_count * 3.14159);
    scanline = (scanline + 1.0) * 0.5;
    color -= scanline * scanline_intensity;
    
    // Vignette
    vec2 center_uv = uv * (1.0 - uv.yx);
    float vig = center_uv.x * center_uv.y * 15.0;
    vig = clamp(pow(vig, vignette_intensity), 0.0, 1.0);
    color = mix(color * vig, color, 1.0 - vignette_opacity);
    
    // Brightness boost
    color *= brightness;
    
    COLOR = vec4(color, 1.0);
}
