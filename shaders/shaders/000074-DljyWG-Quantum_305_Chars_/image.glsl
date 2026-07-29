// Image (image) — Quantum [305 Chars] by Xor
// https://www.shadertoy.com/view/DljyWG

/*
    "Quantum" by @XorDev
    
    I was inspired by the works of @HAL09999.
    Can you guys help me get this under 300 chars?
    
    
    Tweet: twitter.com/XorDev/status/1691936068491161779
    Twigl: twigl.app/?ol=true&ss=-Nc-PLP4WFAyiuC4HlEz
    
    <512 Chars playlist: shadertoy.com/playlist/N3SyzR
*/
//-7 Thanks to Fabrice
void mainImage(out vec4 O, vec2 I)
{
    vec3  p,q,r=iResolution;
    float i=1.,j=i,z;
    for(O *= z;  i>0.;  i-=.02 )
        z = p.z = sqrt( max( z = i - dot( p = (vec3(I+I,0)-r)/r.y, p ) , -z/1e5 )  ),
        p /= 2. + z,
        p.xz *= mat2(cos(iTime+vec4(0,11,33,0))),
        j = cos( j * dot( cos(q+=p), sin(q.yzx) ) /.3 ),
        O += i * pow(z,.4) 
               * pow( j+1. , 8. )
               * ( sin(i*3e1 +vec4(0,1,2,3) ) + 1. ) / 2e3;
    O*=O;
}



//Original [313 chars]
/*/
void mainImage(out vec4 O, vec2 I)
{
    vec3 p,q,r=iResolution;
    O *= 0.;
    for(float i=1.,j,z;i>0.;i-=.02)
        z=p.z+=sqrt(max(z=i-dot(p=vec3(I+I-r.xy,0)/r.y,p),-z/1e5)),p/=2.+p.z,p.xz*=mat2(cos(iTime+vec4(0,11,33,0))),
        O+=pow(z,.4)*i*pow(cos(j=cos(j)*dot(cos(q+=p),sin(q.yzx))/.3)*.5+.5,8.)*(sin(i*3e1+vec4(0,1,2,3))+1.)/8.;
    O*=O;
}
*/