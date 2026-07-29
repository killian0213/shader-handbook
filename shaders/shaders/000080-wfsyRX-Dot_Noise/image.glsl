// Image (image) — Dot Noise by Xor
// https://www.shadertoy.com/view/wfsyRX

/*
    "Dot Noise" by @XorDev

    Expanding on my Irregular Gyroid experiments:
    https://www.shadertoy.com/view/XcBBRz
    
    I am trying to create a cheap noise-like function and I found that
    I can get pretty good results with a modified gyroid, using the
    golden angle for rotation and the golden ratio for scaling
    
    It's much cheaper than 3D simplex noise with only two sine waves,
    one dot-product, and a couple of matrix multiplications.
    For a lighter version you can do just one matrix or replace with
    .yzx swizzling, but they do produce more visible patterns.
    
    This is not a perfect solution and it still has noticable patterns
    at a large scale, but it works surprisingly well for the size and
    can be layered like fractal noise for better scalability.

    The function outputs range from -3.0 to +3.0, but weighted to 0.0.
*/
float dot_noise(vec3 p)
{
    //The golden ratio:
    //https://mini.gmshaders.com/p/phi
    const float PHI = 1.618033988;
    //Rotating the golden angle on the vec3(1, phi, phi*phi) axis
    const mat3 GOLD = mat3(
    -0.571464913, +0.814921382, +0.096597072,
    -0.278044873, -0.303026659, +0.911518454,
    +0.772087367, +0.494042493, +0.399753815);
    
    //Gyroid with irrational orientations and scales
    return dot(cos(GOLD * p), sin(PHI * p * GOLD));
    //Ranges from [-3 to +3]
}
//Distance field for demo.
float dist(vec3 p)
{
    //Rotate axis with depth
    vec2 twist = cos(p.z*0.1+vec2(0,11));
    //Scale down to avoid overstepping
    return (dot_noise(p)+6.0 - abs(dot(p.xy,twist))) * 0.3;
    //Fractal noise example:
    //return (dot_noise(p/8.0)*8.0+dot_noise(p.zxy/4.0)*4.0+dot_noise(p.yzx/2.0)*2.0+dot_noise(p)+32.0-abs(p.y))*0.2;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Ray direction
    vec3 d = normalize(vec3(2.0*fragCoord,0) - iResolution.xyy);
    
    //Camera moving forward
    vec3 p = vec3(0,0,-5.0*iTime);
    
    vec3 l = vec3(0.0);
    //Raymarch loop with 80 iterations
    for(float i = 0.0; i<80.0; i++)
    {
        //Get step distance
        float s = dist(p);
        //Step forward
        p += d * s,
        //Add light falloff
        l += exp(cos(p.y*.2+vec3(6,1,2))*.5)*5e-6 / (5e-4 + s*s);
    }
    
    // Hacky diffuse directional derivative light by Shane
    vec3 ld = normalize(vec3(0, 1, 1));
    float n = 0.5 + smoothstep(0.0, 0.1, dist(p + ld*0.1) - dist(p));
    //Color and tonemap with tanh
    fragColor = vec4(tanh(n * l*l), 1.0);
}