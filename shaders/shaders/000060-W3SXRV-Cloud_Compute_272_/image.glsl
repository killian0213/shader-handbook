// Image (image) — Cloud Compute [272] by Xor
// https://www.shadertoy.com/view/W3SXRV

/*
    "Cloud Compute" by @XorDev
    
    Based on my tweet shader:
    https://x.com/XorDev/status/1918680610127659112
*/
void mainImage(out vec4 O, vec2 I)
{
    float t = iTime, i, z, d;
    for(O *= i; i++<8e1;)
    {
        vec3 p = z * normalize( vec3(I+I, 0) - iResolution.xxy );
        p.xz -= t;
        p.y = 4.-abs(p.y);
        
        for(d=.7; d<2e1; d+=d)
            p += cos(round(p.yzx*d)-.2*t)/d;
            
        z += d = .01+abs(p.y)/15.;
        O += (cos(vec4(0,1,2,0)-p.y*2.)+1.1)/z/d;
    }
    
    O = tanh(O/8e2);
}