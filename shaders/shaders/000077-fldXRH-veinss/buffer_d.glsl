// Buffer D (buffer) — veinss by lomateron
// https://www.shadertoy.com/view/fldXRH

#define A(u) texture(iChannel0,(u)/iResolution.xy)
#define B(u) texture(iChannel1,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    vec4 a = vec4(0);
    float z    = 6.;//kernel convolution size
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
      vec4 t = A(u+vec2(i,j)); t.z = 1.;
      vec4 m = B(u+vec2(i,j));
      vec2 c = (m.xy-vec2(i,j))*1.;
      float z = exp(-dot(c,c))*m.z*t.z;
      a.xy += z*m.xy;
      a.z  += z;
    }}
    float tz = 1./a.z; if(a.z==0.){tz = 0.;}
    a.xy *= tz;
    //a = A(u);
    if(iMouse.z>0.)
    {
        vec2 m = 22.*(u-iMouse.xy)/iResolution.y;
        a += vec4(m,0,0)*exp(-dot(m,m))*-.2;
    }
    if(iFrame==0)
    {
        vec2 m = 22.*(u-iResolution.xy*.5)/iResolution.y;
        a = vec4(m,1,1)*exp(-dot(m,m));
    }
    fragColor = a;
}