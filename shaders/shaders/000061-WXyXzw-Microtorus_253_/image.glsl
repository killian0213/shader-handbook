// Image (image) — Microtorus [253] by Xor
// https://www.shadertoy.com/view/WXyXzw

/*
    Playing with iq's tiny torus shader
*/
void mainImage(out vec4 o, vec2 f)
{
    //Camera depth
    float z = 5.,
    //Raymarch step distance
    d,
    //Raymarch iterator
    i;
    
    //Center and scale uvs
    f = f/iResolution.y/.1-z;
    
    //3D sample point
    vec3 p;
    //Raymarch loop (100 steps)
    for(o*=i; i++<1e2;
        //Sample coloring (attenuate with distance)
        o += (sin(p.y+z+vec4(0,1,2,3))+1.)/d)
        
        //Raymarch sample point
        p = vec3(f,z),
        //Rotated about y-axis
        p.xz *= mat2(cos(iTime+vec4(0,33,11,0))),
        //Outer ring radius
        d = length(p.xy)-3.,
        //Step the distance to torus
        z -= d = .1+.2*abs(sqrt(d*d+p*p).z-1.5);
    //Tanh tonemap
    //https://mini.gmshaders.com/p/func-tanh
    o=tanh(o*o/1e5);
}