// Image (image) — Ether [299] by Xor
// https://www.shadertoy.com/view/t3XXWj

/*
    "Ether" by @XorDev
    
    Experimenting with more 3D turbulence
*/
void mainImage(out vec4 O, vec2 I)
{
    //Time for animation
    float t = iTime,
    //Raymarch loop iterator
    i,
    //Raymarched depth
    z,
    //Raymarch step size and "Turbulence" frequency
    //https://www.shadertoy.com/view/WclSWn
    d;

    //Raymarching loop with 50 iterations
    for (O *= i; i++ < 80.;
        //Add color and glow attenuation
        O += max(sin(z*.4+t + vec4(6, 2, 4, 0)) + .7, .2) / d)
    {
        //Compute raymarch sample point
        vec3 p = z * normalize(vec3(I+I,0)-iResolution.xxy);
        p.z -= 5.*t;
        //Turbulence loop (increase frequency)
        for (d = 1.; d < 15.; d /= .6)
            //Add a turbulence wave
            p += .6*cos(p.yzx* d - vec3(t*.6, 0, t) ) / d;
        //Sample gyroid distance
        z += d = .01 + abs(p.y*.3+ dot(cos(p), sin(p.yzx*.6)) + 2.) / 3.;
    }
    //Tanh tonemapping
    //https://www.shadertoy.com/view/ms3BD7
    O = tanh(O / 2e3);
}