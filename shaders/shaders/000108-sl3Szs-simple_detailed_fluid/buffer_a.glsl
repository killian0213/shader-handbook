// Buffer A (buffer) — simple detailed fluid by lomateron
// https://www.shadertoy.com/view/sl3Szs

#define A(u) texture(iChannel0,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    vec2 v = u/iResolution.xy;
    vec4 a = A(u);
    vec2 m = +a.xy                      //fluid velocity
             -vec2(0,1)*.01             //gravity
             +float(v.x<.05)*vec2(1,0)  //wall
             +float(v.y<.05)*vec2(0,1)  //wall
             -float(v.x>.95)*vec2(1,0)  //wall
             -float(v.y>.95)*vec2(0,1); //wall
    float s = 0.;
    float z = 4.;//kernel convolution size
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
      vec2 c = -m+vec2(i,j);//translate the gaussian 2Dimage using the velocity
      s += exp(-dot(c,c));  //calculate the gaussian 2Dimage
    }}
    if(s==0.){s = 1.;}      //avoid division by zero
              s = 1./s;
    fragColor = vec4(m,s,0);//velocity in .xy
                            //convolution normalization in .z
}