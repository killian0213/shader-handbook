// Common (common) — vt220 coding at night edition by sprash3
// https://www.shadertoy.com/view/XdtfzX

#define PHOSPHOR_COL vec4(0.2, 1.0, 0.2, 0.)

precision highp float;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
