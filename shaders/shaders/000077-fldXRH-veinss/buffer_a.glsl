// Buffer A (buffer) — veinss by lomateron
// https://www.shadertoy.com/view/fldXRH

#define A(u) texture(iChannel0,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    vec4  r = vec4(0);
    vec4  a = A(u);
    float z = 6.;
    float t = 0.;
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
        vec2  ij= vec2(i,j);
        vec2  c = ij*(3./z);
        float l = length(ij);
        ij /= l; if(l==0.){ij= vec2(0);}
        float e = exp(-dot(c,c)); t+=e;
        vec4 b = A(u+vec2(i,j))-a;
        r.x += e*dot(b.xy,ij);
        r.y += abs(e*dot(b.xy,ij.yx*vec2(-1,1)));
    }}
    fragColor = r/t;
}