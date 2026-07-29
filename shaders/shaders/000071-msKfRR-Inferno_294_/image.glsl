// Image (image) — Inferno [294] by Xor
// https://www.shadertoy.com/view/msKfRR

/*
    "Inferno" by @XorDev

    A variant of Quantum (shadertoy.com/view/DljyWG), created for my new shader merch shop!
    https://xordev.square.site
    
    <300 chars playlist: shadertoy.com/playlist/fXlGDN
    -10 thanks to FabriceNeyret2

*/
void mainImage(out vec4 O, vec2 I)
{
    O*=0.;
    vec3 p, q, r = iResolution;
    
    for(float i=1.,z; i>0.; i-=.02)
        z=p.z = sqrt(max(z= i - dot( p = vec3(I+I-r.xy,0)/r.y, p ) , -z/1e4)),
        p.xz *= mat2(cos(iTime*.2+vec4(0,11,33,0))),
        O += sqrt(z)
             * pow( cos( dot( cos(q+=p/2.),sin(q.yzx)) /.3) *.5 +.5, 8.)
             * ( i* sin( i*20.+vec4(6,5,4,3)) + i ) / 7.;
    O*=O;
}
//Original [258]
/*
void mainImage(out vec4 O, vec2 I)
{
    O*=0.;
    vec3 p,q,r=iResolution;
    for(float i=1.,j,z;i>0.;i-=.02)
    z=p.z+=sqrt(max(z=i-dot(p=vec3(I+I-r.xy,0)/r.y,p),-z/1e4)),
    O+=sqrt(z)*i*pow(cos(j=dot(cos(q+=p/2.),sin(q.yzx))/.3)*.5+.5,8.)
    *(sin(i*2e1+vec4(6,5,4,3))+1.)/7.;
    O*=O;
}
*/