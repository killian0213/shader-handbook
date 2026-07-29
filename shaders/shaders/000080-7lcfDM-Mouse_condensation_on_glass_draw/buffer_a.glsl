// Buffer A (buffer) — Mouse condensation on glass draw by supah
// https://www.shadertoy.com/view/7lcfDM

#define R iResolution.xy
#define M iMouse
void mainImage(out vec4 O,in vec2 I){
    vec2 u = (I-.5*R)/R.y,
         m = (M.xy-.5*R)/R.y;
    float r = M.z>1.?.03:-1.,
          d = smoothstep(100./R.y,0.,length(u-m)-r);
	O = vec4(d+texture(iChannel0,I/R)*0.97);
}