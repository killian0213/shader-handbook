// Image (image) — Protostar 2 [326] by Xor
// https://www.shadertoy.com/view/w3G3RD

/*
    "Protostar 2" by @XorDev

    Practicing with whirling motion
    
    <512 playlist:
    https://www.shadertoy.com/playlist/N3SyzR
*/

void mainImage(out vec4 O, vec2 I)
{
    //Animation time
    float t = iTime,
    //Raymarch depth
    z,
    //Step distance
    d,
    //Signed distance
    s,
    //Raymarch iterator
    i;
    
    
    //Clear fragColor and raymarch 100 steps
    for(O*=i; i++<2e2;
        //Coloring and brightness
        O+=(cos(s/.6+vec4(0,1,2,0))+1.1)/d)
    {
        //Sample point (from ray direction)
        vec3 p = z*normalize(vec3(I+I,0)-iResolution.xyy),
        //Rotation axis
        a = normalize(cos(vec3(0,1,0)+t-.4*s));
        //Move camera back 9 units
        p.z+=9.,
        //Rotated coordinates
        a = a*dot(a,p)-cross(a,p);
        
        //Turbulence loop
        for(d=1.;d++<6.;)
            s=length(a+=cos(a*d+t).yzx/d);
        
        //Distance to rings
        z+=d=.1*(abs(sin(s-t))+abs(a.y)/d);
    }
    //Tanh tonemap
    O = tanh(O*O/2e7);
}