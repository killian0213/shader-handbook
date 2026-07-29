// Image (image) — Bits [246] by Xor
// https://www.shadertoy.com/view/wfK3Rm

/*
    "Bits" by @XorDev
    
    Tweet:
    https://x.com/XorDev/status/1925548343054496239
*/
void mainImage(out vec4 O, vec2 I)
{
    //Raymarch iterator, step distance and z-depth
    float i, d, z;
    //Clear fragColor and raymarch 100 steps
    for(O *= i; i++<1e2;
        //Pick color and glow
        O += (cos(z+vec4(6,1,2,3))+1.)/d)
    {
        //Raymarch sample point
        vec3 p = z * normalize(vec3(I+I,0)-iResolution.xyy);
        //Scroll forward
        p.z -= iTime;
        //Turbulence
        //https://mini.gmshaders.com/p/turbulence
        //Rounded for blocky effect
        for(d = .4; d < 3e1; d += d)
            p += cos(round(p*d)-z*.1).yzx/d;
        //Distance to depth columns
        z += d = length(sin(p.xy))*.1;
    }
    //Tanh tonemapping
    //https://www.shadertoy.com/view/ms3BD7
    O = tanh(O/5e3);
}