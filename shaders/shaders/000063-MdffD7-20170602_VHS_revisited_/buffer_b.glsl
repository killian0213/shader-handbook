// Buffer B (buffer) — 20170602_VHS (revisited) by FMS_Cat
// https://www.shadertoy.com/view/MdffD7

void mainImage( out vec4 fragColor, in vec2 fragCoord ) { fragColor = texture( iChannel0, fragCoord / iResolution.xy ); }