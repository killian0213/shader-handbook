// Image (image) — 20170602_VHS (revisited) by FMS_Cat
// https://www.shadertoy.com/view/MdffD7

#define VHSRES vec2(320.0,240.0)

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 uv = fragCoord.xy / iResolution.xy / iResolution.xy * VHSRES;
  fragColor = texture( iChannel0, uv );
}