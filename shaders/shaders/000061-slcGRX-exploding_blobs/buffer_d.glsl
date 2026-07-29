// Buffer D (buffer) — exploding blobs by lomateron
// https://www.shadertoy.com/view/slcGRX

#define A(u) texture(iChannel0,(u)/iResolution.xy)
#define B(u) texture(iChannel1,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    float tz = 0.;
    vec4 a = vec4(0);
    float z    = 8.;//kernel convolution size
    float blur = 4./z;
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
      vec4 t = A(u+vec2(i,j));
      vec4 m = B(u+vec2(i,j));
      vec2 c = (m.xy-vec2(i,j))*blur;
      float z = t.z*exp(-dot(c,c));
      a.xy += z*m.xy;
      a.z  += z*m.z;
      tz   += z;
    }}
    if(tz==0.){tz = 1.;}
    a.xy /= tz;
    if(iMouse.z>0.)
    {
        vec2 m = 16.*(u-iMouse.xy)/iResolution.y;
        a += vec4(1,0,1,1)*.1*exp(-dot(m,m));
    }
    if(iFrame==0)
    {
        vec2 m = 4.*(u-iResolution.xy*.5)/iResolution.y;
        a = vec4(1,0,1,1)*exp(-dot(m,m));
    }
    fragColor = a;
}