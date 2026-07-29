// Buffer B (buffer) — Sunrise on saturn by mrange
// https://www.shadertoy.com/view/DldXDX

#define TIME        iTime
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)

#define ROT(a)          mat2(cos(a), sin(a), -sin(a), cos(a))

const mat2 brot = ROT(2.399);
// License: Unknown, author: Dave Hoskins, found: Forgot where
vec3 dblur(vec2 q,float rad) {
  vec3 acc=vec3(0);
  const float m = 0.0025;
  vec2 pixel=vec2(m*RESOLUTION.y/RESOLUTION.x,m);
  vec2 angle=vec2(0,rad);
  rad=1.;
  const int iter = 30;
  for (int j=0; j<iter; ++j) {  
    rad += 1./rad;
    angle*=brot;
    vec4 col=texture(iChannel1,q+pixel*(rad-1.)*angle);
    acc+=clamp(col.xyz, 0.0, 10.0);
  }
  return acc*(1.0/float(iter));
}

// License: Unknown, author: Matt Taylor (https://github.com/64), found: https://64.github.io/tonemapping/
vec3 aces_approx(vec3 v) {
  v = max(v, 0.0);
  v *= 0.6f;
  float a = 2.51f;
  float b = 0.03f;
  float c = 2.43f;
  float d = 0.59f;
  float e = 0.14f;
  return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0f, 1.0f);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec3 col = texture(iChannel0, q).xyz;
  
  col -= 0.005*vec3(0.0, 1.0, 2.0).zyx;
  col = aces_approx(col);
  col += 0.5*dblur(q, 1.0);
  fragColor = vec4(col, 1.0);
}
