// Common (common) — Analytic Direct Lighting by fad
// https://www.shadertoy.com/view/dlcXR4

const int numPoints = 26;
const int N = numPoints / 2;

#define CONTROL_RADIUS (max(iResolution.x, iResolution.y) * 0.05)
const float PI = 3.14159265;

#ifndef HW_PERFORMANCE
uniform sampler2D iChannel0;
uniform vec4 iResolution;
#endif

vec4 getPointData(int i) {
    return texelFetch(iChannel0, ivec2(i % int(iResolution.x), i / int(iResolution.x)), 0);
}

vec2 getPoint(int i) {
    return texelFetch(iChannel0, ivec2(i % int(iResolution.x), i / int(iResolution.x)), 0).xy;
}