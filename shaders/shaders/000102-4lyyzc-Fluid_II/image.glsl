// Image (image) — Fluid II by wyatt
// https://www.shadertoy.com/view/4lyyzc

vec2 R;
vec4 T ( vec2 U ) {return texture(iChannel0,U/R);}
void mainImage( out vec4 C, in vec2 U )
{
    R = iResolution.xy;
    vec4 
        a = T(U+vec2(1,0)),
        b = T(U-vec2(1,0)),
        c = T(U+vec2(0,1)),
        d = T(U-vec2(0,1));
        
    vec4 g = vec4(a.zw-b.zw,c.zw-d.zw);
    vec2 dz = g.xz;
    vec2 dw = g.yw;
   	vec4 v = T(U);
    C.xyz = max(vec3(0),sin(1.5+5.*v.z+3.*(v.w)*v.w*vec3(1,2,3)));
    vec3 n = normalize(vec3(dz,.05));
    vec4 tx = texture(iChannel1,reflect(vec3(0,0,1),n));
    float p = 1e6*dot(dz,dz);
    p = atan(p*p)*.63661977237;
    float w = atan(3.*v.w)*.63661977237;
    C *= (0.7+0.3*tx);
}
