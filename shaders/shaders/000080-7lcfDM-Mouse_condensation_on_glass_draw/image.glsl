// Image (image) — Mouse condensation on glass draw by supah
// https://www.shadertoy.com/view/7lcfDM

#define R iResolution.xy
#define T(c,u) texture(c,u)
vec2 r(vec2  p) {p = vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))); return fract(sin(p)*4375.5);}
void mainImage(out vec4 O,in vec2 I){
    vec2 u = I/R.xy;
    float m = clamp(T(iChannel0, u).r,0.,1.);
    O = mix(T(iChannel1,u+r(u)*.1)*.9,T(iChannel1,u)*1.1,m);
}