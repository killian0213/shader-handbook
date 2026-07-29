// Buffer B (buffer) — 20260117_Subway Incident by 0b5vr
// https://www.shadertoy.com/view/lcV3RW

// Accumulation Pass

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 uv = fragCoord.xy / iResolution.xy;

  // accumulate using backbuffer
  fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);

  if ( iFrame > 1 && iMouse.w < 0.5 ) {
    fragColor += texelFetch(iChannel1, ivec2(fragCoord), 0);
  }
}
