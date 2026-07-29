// Buffer B (buffer) — Multiscale Turing Patterns by cornusammonis
// https://www.shadertoy.com/view/MdGGzR

#define G(ic,x) texture(ic, x)
#define iC0 iChannel0
#define iC1 iChannel1
#define o0 9.0
#define o1 27.0
#define stddev 2.5

float gaussian(float x, float s) {
    return exp(-x*x/(s*s));
}

vec4 gaussian(vec4 x, float s) {
    return exp(-x*x/(s*s));
}

vec2 wrap(vec2 x) {
    return mod(mod(x, 1.0) + 1.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec2 ix = vec2(1.0 / iResolution.x, 0.0);
    vec2 iy = vec2(0.0, 1.0 / iResolution.y);
    vec4 i0 = vec4(-4.0, -3.0, -2.0, -1.0);
    vec4 i1 = vec4(1.0, 2.0, 3.0, 4.0);
    vec4 g0 = gaussian(i0, stddev);
    vec4 g1 = g0.wzyx;
    float g = gaussian(0.0, stddev);
    float sum = 2.0 * dot(g0, vec4(1.0)) + g;
    g0 /= sum;
    g1 /= sum;
    g /= sum;

    // 2 complete blur passes
    vec4 leftX0  = g0 * vec4(G(iC0, wrap(uv + o0 * ix * i0.x)).w, G(iC0, wrap(uv + o0 * ix * i0.y)).w, G(iC0, wrap(uv + o0 * ix * i0.z)).w, G(iC0, wrap(uv + o0 * ix * i0.w)).w);
    vec4 rightX0 = g1 * vec4(G(iC0, wrap(uv + o0 * ix * i1.x)).w, G(iC0, wrap(uv + o0 * ix * i1.y)).w, G(iC0, wrap(uv + o0 * ix * i1.z)).w, G(iC0, wrap(uv + o0 * ix * i1.w)).w); 
    float centerX0 = g * G(iC0, uv).w;
    float sumX0 = centerX0 + dot(leftX0, vec4(1.0)) + dot(rightX0, vec4(1.0));

    vec4 leftY0  = g0 * vec4(G(iC1, wrap(uv + o0 * iy * i0.x)).x, G(iC1, wrap(uv + o0 * iy * i0.y)).x, G(iC1, wrap(uv + o0 * iy * i0.z)).x, G(iC1, wrap(uv + o0 * iy * i0.w)).x);
    vec4 rightY0 = g1 * vec4(G(iC1, wrap(uv + o0 * iy * i1.x)).x, G(iC1, wrap(uv + o0 * iy * i1.y)).x, G(iC1, wrap(uv + o0 * iy * i1.z)).x, G(iC1, wrap(uv + o0 * iy * i1.w)).x); 
    float centerY0 = g * G(iC1, uv).x;
    float sumY0 = centerY0 + dot(leftY0, vec4(1.0)) + dot(rightY0, vec4(1.0));

    vec4 leftX1  = g0 * vec4(G(iC1, wrap(uv + o1 * ix * i0.x)).y, G(iC1, wrap(uv + o1 * ix * i0.y)).y, G(iC1, wrap(uv + o1 * ix * i0.z)).y, G(iC1, wrap(uv + o1 * ix * i0.w)).y);
    vec4 rightX1 = g1 * vec4(G(iC1, wrap(uv + o1 * ix * i1.x)).y, G(iC1, wrap(uv + o1 * ix * i1.y)).y, G(iC1, wrap(uv + o1 * ix * i1.z)).y, G(iC1, wrap(uv + o1 * ix * i1.w)).y); 
    float centerX1 = g * G(iC1, uv).y;
    float sumX1 = centerX1 + dot(leftX1, vec4(1.0)) + dot(rightX1, vec4(1.0));

    vec4 leftY1  = g0 * vec4(G(iC1, wrap(uv + o1 * iy * i0.x)).z, G(iC1, wrap(uv + o1 * iy * i0.y)).z, G(iC1, wrap(uv + o1 * iy * i0.z)).z, G(iC1, wrap(uv + o1 * iy * i0.w)).z);
    vec4 rightY1 = g1 * vec4(G(iC1, wrap(uv + o1 * iy * i1.x)).z, G(iC1, wrap(uv + o1 * iy * i1.y)).z, G(iC1, wrap(uv + o1 * iy * i1.z)).z, G(iC1, wrap(uv + o1 * iy * i1.w)).z); 
    float centerY1 = g * G(iC1, uv).z;
    float sumY1 = centerY1 + dot(leftY1, vec4(1.0)) + dot(rightY1, vec4(1.0));
    
    fragColor = vec4(sumX0, sumY0, sumX1, sumY1);
}