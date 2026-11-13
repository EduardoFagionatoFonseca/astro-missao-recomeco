shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float intensity = 0.0;
uniform float radiation = 0.0;

void fragment() {
    vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
    if (radiation > 0.001) {
        vec2 blur = SCREEN_PIXEL_SIZE * radiation * 2.5;
        vec3 softened = scene * 0.24;
        softened += texture(screen_texture, SCREEN_UV + vec2(blur.x, 0.0)).rgb * 0.15;
        softened += texture(screen_texture, SCREEN_UV - vec2(blur.x, 0.0)).rgb * 0.15;
        softened += texture(screen_texture, SCREEN_UV + vec2(0.0, blur.y)).rgb * 0.15;
        softened += texture(screen_texture, SCREEN_UV - vec2(0.0, blur.y)).rgb * 0.15;
        softened += texture(screen_texture, SCREEN_UV + blur).rgb * 0.08;
        softened += texture(screen_texture, SCREEN_UV - blur).rgb * 0.08;
        scene = mix(scene, softened, radiation * 0.75);
    }
    vec2 p = (UV - vec2(0.5)) * vec2(1.1, 1.0);
    float edge = smoothstep(0.18, 0.66, length(p));
    scene = mix(scene, vec3(0.005, 0.008, 0.015), edge * intensity);
    float spread = smoothstep(0.65 - radiation * 0.30, 0.82 - radiation * 0.10, length(p));
    scene = mix(scene, vec3(0.98, 0.36, 0.08), spread * radiation * 0.48);
    COLOR = vec4(scene, 1.0);
}
