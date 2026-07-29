// Buf B (buffer) — Perceptual Depth Poisson Solver by cornusammonis
// https://www.shadertoy.com/view/MlByW3

// This computes the laplacian of the input


float laplacian(sampler2D sampler, vec2 fragCoord) {
    vec2 vUv = fragCoord.xy / iResolution.xy;
    vec2 texel = 1. / iResolution.xy;
    
    // 3x3 neighborhood coordinates
    float step_x = texel.x;
    float step_y = texel.y;
    vec2 n  = vec2(0.0, step_y);
    vec2 ne = vec2(step_x, step_y);
    vec2 e  = vec2(step_x, 0.0);
    vec2 se = vec2(step_x, -step_y);
    vec2 s  = vec2(0.0, -step_y);
    vec2 sw = vec2(-step_x, -step_y);
    vec2 w  = vec2(-step_x, 0.0);
    vec2 nw = vec2(-step_x, step_y);

    vec4 uv =    texture(iChannel0, fract(vUv));
    vec4 uv_n =  texture(iChannel0, fract(vUv+n));
    vec4 uv_e =  texture(iChannel0, fract(vUv+e));
    vec4 uv_s =  texture(iChannel0, fract(vUv+s));
    vec4 uv_w =  texture(iChannel0, fract(vUv+w));
    vec4 uv_nw = texture(iChannel0, fract(vUv+nw));
    vec4 uv_sw = texture(iChannel0, fract(vUv+sw));
    vec4 uv_ne = texture(iChannel0, fract(vUv+ne));
    vec4 uv_se = texture(iChannel0, fract(vUv+se));
    
    vec2 diff = vec2(
        0.5 * (uv_e.x - uv_w.x) + 0.25 * (uv_ne.x - uv_nw.x + uv_se.x - uv_sw.x),
        0.5 * (uv_n.y - uv_s.y) + 0.25 * (uv_ne.y + uv_nw.y - uv_se.y - uv_sw.y)
    );
    
    return diff.x + diff.y;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(laplacian(iChannel0, fragCoord),0,0,0);
}