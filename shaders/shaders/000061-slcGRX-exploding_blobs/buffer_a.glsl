// Buffer A (buffer) — exploding blobs by lomateron
// https://www.shadertoy.com/view/slcGRX

#define A(u) texture(iChannel0,(u)/iResolution.xy)
void mainImage( out vec4 fragColor, in vec2 u )
{
    vec4  r = vec4(0);
    vec4  a = A(u);
    float z    = 8.;//kernel convolution size
    float blur = 3./z;
    for(float i=-z; i<=z; ++i){
    for(float j=-z; j<=z; ++j){
        vec2  c = vec2(i,j)*blur; //c = c.yx*vec2(-1,1);
              c*= exp(-dot(c,c));
        vec4  a2= A(u+vec2(i,j));
        vec4  b = a2-a;
        r.xy += c*b.z;
        r.z  += dot(c,b.xy           )*a2.z;
        r.w  += dot(c,b.yx*vec2(-1,1))*a2.z;
    }}
    fragColor = r;
}