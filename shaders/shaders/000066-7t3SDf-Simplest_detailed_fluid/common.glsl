// Common (common) — Simplest detailed fluid by davidar
// https://www.shadertoy.com/view/7t3SDf

#define M void mainImage(out vec4 r, vec2 u)
#define A(i) texelFetch(iChannel0,ivec2(i+u),0)