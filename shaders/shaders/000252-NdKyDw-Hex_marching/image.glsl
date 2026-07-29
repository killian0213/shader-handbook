// Image (image) — Hex marching by mrange
// https://www.shadertoy.com/view/NdKyDw

// License CC0: Hex Marching
//  Results from saturday afternoon tinkering
#define TIME iTime
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/iResolution.xy;

  vec4 pcol = texture(iChannel0, q);
  vec3 col = pcol.xyz;
  col = clamp(col, 0.0, 1.0);
  col *= smoothstep(0.0, 2.0, TIME);
  col = sqrt(col);
  fragColor = vec4(col, 1.0);
}