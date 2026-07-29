// Image (image) — Launch [326] by Xor
// https://www.shadertoy.com/view/wX3XW2

/*
    "LAUNCH" by @XorDev

    https://x.com/XorDev/status/1949897576435581439
    
    <512 playlist:
    https://www.shadertoy.com/playlist/N3SyzR

    Twigl code:
    for(float i,z,d,f;i++<1e2;o+=vec4(3,1,d,z/f)/z)
    {vec3 v=vec3(0,-2,7),p=z*normalize(FC.rgb*2.-r.xyx)+v,
    a=p;a.y*=.3;for(d=1.;d++<9.;)a-=.1*sin((a.zxy+t*v+d)*d)*p.y/d;
    z+=d=min(max(-p.y,length(a)-2.),
    f=.2+abs(length(a.xz-cos(a.zx*6.))+max(p.y/.1,-.6)))/8.;}
    o=tanh(o*o.a/1e3);
*/

void mainImage(out vec4 O, vec2 I)
{
    //Raymarch depth
    float z,
    //Step distance
    d,
    //Fire distance
    f,
    //Raymarch iterator
    i;
    
    
    //Clear fragColor and raymarch 80 steps
    for(O*=i; i++<1e2;
        //Coloring and brightness
        O+=vec4(3,1,d,z/f)/z)
    {
        //Offset vector
        vec3 v = vec3(0,-2,7),
        //Sample position with camera offset
        p = z*normalize(vec3(I+I,0)-iResolution.xyy)+v,
        //Fire wave coordinates
        w = p;
        //Stretch vertically
        w.y *= .3;
        
        //Turbulence loop
        for(d=1.;d++<9.;)
            w-=.1*sin((w.zxy+iTime*v+d)*d)*p.y/d;
        
        //Distance to rocket cylinder
        z += d = min(max(-p.y,length(w)-2.),
            //Modulated fire streams
            f=.2+abs(length(w.xz-cos(w.zx*6.))+max(p.y/.1,-.6)))/8.;
    }
    //Tanh tonemap
    O = tanh(O*O.a/1e3);
}