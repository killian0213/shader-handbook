// Buffer B (buffer) — simple detailed fluid by lomateron
// https://www.shadertoy.com/view/sl3Szs

#define A(u) texture(iChannel0,(u)/iResolution.xy)
#define B(u) texture(iChannel1,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    vec4  o = vec4(0);
    float z = 4.;//kernel convolution size
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
      vec4  a = A(u+vec2(i,j));        //old velocity in a.xy, mass in a.z
      vec4  b = B(u+vec2(i,j));        //new velocity in b.xy, normalization of convolution in .z
      vec2  c = -b.xy-vec2(i,j);       //translate the gaussian 2Dimage
      float s = a.z*exp(-dot(c,c))*b.z;//calculate the normalized gaussian 2Dimage multiplied by mass
      vec2  e = c*(a.z-.8);            //fluid expands or atracts itself depending on mass
      o.xy += s*(b.xy+e);              //sum all translated velocities
      o.z  += s;                       //sum all translated masses
    }}
    float tz = 1./o.z;
    if(o.z==0.){tz = 0.;}              //avoid division by zero
    o.xy *= tz;                        //calculate the average velocity
    if(iMouse.z>0.)                    //mouse click adds velocity
    {
        vec2 m = 8.*(u-iMouse.xy)/iResolution.y;
        o += vec4(m,0,0)*.1*exp(-dot(m,m));
    }
    if(iFrame==0)
    {
        vec2 m = 3.*(u-iResolution.xy*.5)/iResolution.y;
        o = vec4(0,0,1,1)*exp(-dot(m,m));
    }
    fragColor = o;
}