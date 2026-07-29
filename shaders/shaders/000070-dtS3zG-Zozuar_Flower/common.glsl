// Common (common) — Zozuar Flower by mla
// https://www.shadertoy.com/view/dtS3zG

const float PI = 3.14159265;

vec3 hsv(float h, float s, float v) {
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  // x²(3-2x) = 3x²-2x³, f'(x) = 6x-6x² = 6x(1-x)
  // f'(x) = 1-x², f = 0.5*(3.0*x-x³)
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing       
  return v * mix( vec3(1.0), rgb, s);
}

mat2 rotate2D(float t) {
  return mat2(cos(t),sin(t),-sin(t),cos(t));
}