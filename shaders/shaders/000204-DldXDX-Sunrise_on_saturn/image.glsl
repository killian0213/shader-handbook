// Image (image) — Sunrise on saturn by mrange
// https://www.shadertoy.com/view/DldXDX

// CC0: Sunrise on saturn
// Was tinkering with trying to recreate a sweet sci fi image
// Stopped working and forgot to share at the time.
// I strongly doubt there's mist like blur in space but it looked
// nice on original image so tried to recreate it.

#define TIME        iTime
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec3 col = vec3(0.0);
  col = texture(iChannel0, q).xyz;
  col = sqrt(col);

  fragColor = vec4(col, 1.0);
}
