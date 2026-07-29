// Image (image) — Phosphor [318] by Xor
// https://www.shadertoy.com/view/WXV3zt

/*
    "Phosphor" by @XorDev

    https://x.com/XorDev/status/1940448131671580897
    
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
    //Raymarch iterator
    i;
    
    
    //Clear fragColor and raymarch 100 steps
    for(O*=i; i++<8e1;
        //Coloring and brightness
        O+=(cos(d/.1+vec4(0,2,4,0))+1.)/d*z)
    {
        //Sample point (from ray direction)
        vec3 p = z*normalize(vec3(I+I,0)-iResolution.xyy),
        //Rotation axis
        a = normalize(cos(vec3(4,2,0)+t-d*8.));
        //Move camera back 9 units
        p.z+=5.,
        //Rotated coordinates
        a = a*dot(a,p)-cross(a,p);
        
        //Turbulence loop
        for(d=1.;d++<9.;)
            a+=sin(a*d+t).yzx/d;
        
        //Distance to rings
        z+=d=.05*abs(length(p)-3.)+.04*abs(a.y);
    }
    //Tanh tonemap
    O = tanh(O/1e4);
}