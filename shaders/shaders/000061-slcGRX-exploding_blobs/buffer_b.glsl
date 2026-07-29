// Buffer B (buffer) — exploding blobs by lomateron
// https://www.shadertoy.com/view/slcGRX

#define A(u) texture(iChannel0,(u)/iResolution.xy)
#define B(u) texture(iChannel1,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    vec4  r = A(u);
    float z    = 8.;//kernel convolution size
    float blur = 3./z;
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
      vec4 b = B(u+vec2(i,j));
      vec2 c = (-vec2(i,j))*blur;
           c*= exp(-dot(c,c))*.06*r.z;
      r.xy += +b.z*c              *0. //enhance divergence
              +b.w*c.yx*vec2(-1,1)*1. //enhance curl 
              +abs(b.z)*(step(0.,b.w)*2.-1.)*c.yx*vec2(-1,1)*0.;
    }}

    fragColor = r;
}