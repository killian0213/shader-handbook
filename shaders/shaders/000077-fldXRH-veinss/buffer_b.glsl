// Buffer B (buffer) — veinss by lomateron
// https://www.shadertoy.com/view/fldXRH

#define A(u) texture(iChannel0,(u)/iResolution.xy)
#define B(u) texture(iChannel1,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    vec4  r = A(u);
    vec4  a = B(u);
    float z = 6.;
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
        vec2  ij= vec2(i,j);
        vec2  c = ij*(3./z);
        float l = length(ij);
        ij /= l; if(l==0.){ij= vec2(0);}
        float e = exp(-dot(c,c));
        vec4 b = B(u+vec2(i,j));
        r.xy += +(b.x)    *ij*e*.1
                +(b.y-a.y)*ij*e*.5;
    }}

    fragColor = r;
}