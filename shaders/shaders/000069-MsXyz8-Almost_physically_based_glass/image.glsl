// Image (image) — Almost physically based glass by keim
// https://www.shadertoy.com/view/MsXyz8

const float BLUR = 0.012;
const vec3  GAMMA = vec3(1./2.2);

vec4 gamma(in vec4 i) { return vec4(pow(i.xyz, GAMMA), i.w); }
vec4 img(vec2 d) { return textureLod(iChannel0, d/iResolution.xy, 0.); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec4 col = img(fragCoord);
  vec2 b = vec2(col.w * BLUR * iResolution.x, 0);
  fragColor = gamma((col + img(fragCoord+b.xy) 
                         + img(fragCoord-b.xy)
                         + img(fragCoord+b.yx)
                         + img(fragCoord-b.yx))/5.);
}
