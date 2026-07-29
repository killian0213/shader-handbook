// Image (image) — Vortex [265] by Xor
// https://www.shadertoy.com/view/wctXWN

/*
    "Vortex" by @XorDev
    
    https://x.com/XorDev/status/1930594981963505793

    An experiment based on my "3D Fire":
    https://www.shadertoy.com/view/3XXSWS
*/
void mainImage(out vec4 O, vec2 I)
{
    //Raymarch iterator
    float i,
    //Raymarch depth
    z = fract(dot(I,sin(I))),
    //Raymarch step size
    d;
    //Raymarch loop (100 iterations)
    for(O *= i; i++<1e2;
        //Sample coloring and glow attenuation
        O+=(sin(z+vec4(6,2,4,0))+1.5)/d)
    {
        //Raymarch sample position
        vec3 p = z * normalize(vec3(I+I,0) - iResolution.xyy);
        //Shift camera back
        p.z += 6.;
        //Distortion (turbulence) loop
        for(d=1.; d<9.; d/=.8)
            //Add distortion waves
            p += cos(p.yzx*d-iTime)/d;
        //Compute distorted distance field of hollow sphere
        z += d = .002+abs(length(p)-.5)/4e1;
    }
    //Tanh tonemapping
    //https://www.shadertoy.com/view/ms3BD7
    O = tanh(O/7e3);
}