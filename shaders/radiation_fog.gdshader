shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;
void fragment() {
    float clouds = sin(UV.x * 48.0 + sin(UV.y * 27.0 + TIME * 0.4) * 3.0 + TIME * 0.8);
    float haze = 0.5 + 0.5 * clouds;
    ALBEDO = mix(vec3(0.83, 0.59, 0.37), vec3(1.0, 0.88, 0.66), haze);
    ALPHA = 0.18 + haze * 0.22;
}
