// Image (image) — Extinguish [227] by Xor
// https://www.shadertoy.com/view/wfdXDj

/*
    "Extinguish" by @XorDev
    
    https://x.com/XorDev/status/1932461552868720941

    An experiment based on my "3D Fire":
    https://www.shadertoy.com/view/3XXSWS
*/
void mainImage(out vec4 O, vec2 I)
{
    //Animation time
    float t = iTime,
    //Raymarch iterator
    i,
    //Raymarch depth
    z,
    //Raymarch step size
    d;
    //Raymarch loop (50 iterations)
    for(O *= i; i++<5e1;
        //Sample glow attenuation
        O+=.001/d)
    {
        //Raymarch sample position
        vec3 p = z * normalize(vec3(I+I,0) - iResolution.xyy);
        //Shift camera back
        p.z += 6.;
        //Distortion (turbulence) loop
        for(d=1.; d<9.; d/=.8)
            //Add distortion waves
            p += cos(p.yzx*d-vec3(t+t,t,0))/d;
        //Compute distorted distance field of sphere
        z += d = .01+.1*length(p.xz);
    }
    //Tanh tonemapping
    //https://www.shadertoy.com/view/ms3BD7
    O = tanh(O);
}