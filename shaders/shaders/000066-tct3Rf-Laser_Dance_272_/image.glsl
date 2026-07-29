// Image (image) — Laser Dance [272] by Xor
// https://www.shadertoy.com/view/tct3Rf

/*
    "Laser Dance" by @XorDev
    
    https://x.com/XorDev/status/1923037860485075114
*/
void mainImage(out vec4 O, vec2 I)
{
    //Raymarch iterator, step distance, depth
    float i, d, z;
    
    //Clear fragcolor and raymarch 100 steps
    for(O *= i; i++ < 1e2;
    //Pick colors and attenuate
    O += (cos(z + vec4(0,2,3,0)) + 1.5) / d / z)
    {
        //Raymarch sample point
        vec3 p = z * normalize(vec3(I+I,0) - iResolution.xyy) + .8;
        //Reflection distance
        d = max(-p.y, 0.);
        //Reflect y-axis
        p.y += d+d - 1.;
        //Step forward slowly with a bias for soft reflections
        z += d = .3 * (.01 + .1*d + 
        //Lazer distance field
        length(min( p = cos(p + iTime) + cos(p / .6).yzx, p.zxy)) 
        / (1.+d+d+d*d));
    }
    //Tanh tonemapping
    O = tanh(O / 7e2);
}