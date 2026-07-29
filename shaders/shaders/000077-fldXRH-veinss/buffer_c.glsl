// Buffer C (buffer) — veinss by lomateron
// https://www.shadertoy.com/view/fldXRH

#define A(u) texture(iChannel0,(u)/iResolution.xy)
#define B(u) texture(iChannel1,(u)/iResolution.xy)
#define C(u) texture(iChannel2,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    vec4 t = A(u);
    vec2 m = +t.xy
             +B(u).xy*(t.z-.5)*0.
             +t.z*vec2(0,.0)
             -C(u).x*t.xy*.0;
    float s = 0.;
    float z    = 6.;//kernel convolution size
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
      vec2 c = (m+vec2(i,j))*1.;
      s += exp(-dot(c,c));
    }}
    if(s==0.){s = 1.;}
    s = 1./s;
    
    fragColor = vec4(m,s,0);
}