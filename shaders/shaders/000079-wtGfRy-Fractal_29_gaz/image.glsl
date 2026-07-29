// Image (image) — Fractal 29_gaz by gaz
// https://www.shadertoy.com/view/wtGfRy

#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
void mainImage(out vec4 O, vec2 C)
{
    O=vec4(0);
    vec3 p,r=iResolution,
    d=normalize(vec3((C-.5*r.xy)/r.y,1));  
    for(float i=0.,g=0.,e,s;
        ++i<99.;
        O.xyz+=5e-5*abs(cos(vec3(3,2,1)+log(s*9.)))/dot(p,p)/e
    )
    {
        p=g*d;
        p.z+=iTime*.3;
        p=R(p,normalize(vec3(1,2,3)),.5);   
        s=2.5;
        p=abs(mod(p-1.,2.)-1.)-1.;
        for(int j=0;j++<10;)
            p=1.-abs(p-1.),
            s*=e=-1.8/dot(p,p),
            p=p*e-.7;
            g+=e=abs(p.z)/s+.001;           
     }
}