// Image (image) — Recursion! by AntoineC
// https://www.shadertoy.com/view/wst3W2

void mainImage(out vec4 o, vec2 u) {o=texture(iChannel0,u/iResolution.xy).rgbb;}