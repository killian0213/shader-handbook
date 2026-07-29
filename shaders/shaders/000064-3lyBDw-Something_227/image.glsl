// Image (image) — Something  227 by gaz
// https://www.shadertoy.com/view/3lyBDw

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(t)(cos((vec3(0,2,-2)/3.+t)*6.24)*.5+.5)
#define D(a)length(vec2(fract(log(length(a.xy))-iTime*.5)-.5,a.z))/3.-.005*pow(l,.03)
void mainImage(out vec4 O, vec2 C)
{
    O=vec4(0);
    vec3 p,r=iResolution;
    for(float g,e,i=0.,l;
        ++i<99.;
        e<.005?O.xyz+=mix(vec3(1),H(l),.7)/i:p
        )
    {
        p=R(g*normalize(vec3((C-.5*r.xy)/r.y,1.))-vec3(0,0,6),
            normalize(vec3(1,2,0)),
            iTime*.2
        );
        l=length(p);
        g+=e=min(min(D(p),D(p.zxy)),D(p.yzx));    
    }
}