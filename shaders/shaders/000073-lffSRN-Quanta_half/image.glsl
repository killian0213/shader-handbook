// Image (image) — Quanta half by liamegan
// https://www.shadertoy.com/view/lffSRN

  void mainImage( out vec4 c, in vec2 f ) {
    c = texture(iChannel0,f/iResolution.xy);
  }