// Buffer A (buffer) — Waveform Music [445] by Xor
// https://www.shadertoy.com/view/wfcGR2

void mainImage(out vec4 O, vec2 I)
{
    vec2 r = iResolution.xy;
    O = (I.y-=r.y/6e2)>1.?texture(iChannel0,I/r):texture(iChannel1,I/r);
}