// Buffer B (buffer) — IRIDESCENCE: DIFFRACTION GRATING by alro
// https://www.shadertoy.com/view/7dVGzz

// Tangent field generation
void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    vec2 uv = fragCoord.xy / iResolution.xy;
    uv = 0.5 - uv;
    uv = normalize(uv);
    fragColor = vec4(-uv.y, uv.x, 0.0, 1.0);
}