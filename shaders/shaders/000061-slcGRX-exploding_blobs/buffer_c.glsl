// Buffer C (buffer) — exploding blobs by lomateron
// https://www.shadertoy.com/view/slcGRX

#define A(u) texture(iChannel0,(u)/iResolution.xy)
#define B(u) texture(iChannel1,(u)/iResolution.xy)
#define C(u) texture(iChannel2,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    vec4 t = A(u);
    vec2 m = +t.xy
             +B(u).xy*(t.z-.5)
             +t.z*vec2(0,.0)
             -C(u).x*t.xy*.0;
    float s = 0.;
    float z    = 8.;//kernel convolution size
    float blur = 4./z;
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
      vec2 c = (m+vec2(i,j))*blur;
      s += exp(-dot(c,c));
    }}
    if(s==0.){s = 1.;}
    s = 1./s;
    
    fragColor = vec4(m,s,0);
}