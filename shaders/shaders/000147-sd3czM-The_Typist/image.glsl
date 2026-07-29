// Image (image) — The Typist by Xor
// https://www.shadertoy.com/view/sd3czM

/*
    "The Typist" by @XorDev
    -20 Thanks to FabriceNeyret2
*/

#define T texture(iChannel0, p

void mainImage(out vec4 O, vec2 I)
{
    //Resolution for scaling/texel math
    vec2 r = iResolution.xy,
    //Pixel coordinates for DOF sample
    p,
    //Bokeh radius in pixels
    b = (I+I-r)*mat2(1,-5,0,0)/5e3,
    //Chromatic aberration delta (and clear color)
    d = vec2(2e-3,O-=O);
 
    //"i" approximating the sqrt of the number of iterations
    //So i < 16 means roughly 256 texture samples
    for(float i=1.,t = iTime*.03; i<16.; i+=1./i)
    
        //Rotate sample point by golden angle (for even spacing)
        b *= mat2(0,.061,1.413, 0) - .737,
        //Bokeh sample coordinates
        p = I + b*i,
        //Apply perspective, rotation and scrolling
        p = ( p*mat2(9,-1,1,9) - r.y/.1 )/9./(5.*r-p).y + t,
        //Randomize symbols
        p += ceil( texture(iChannel1,p/64.).rg*16. + t/.2 )/16.,
        //Sample font with aberration
        O += pow(( vec4( T-d).r , T).r, T+d.yx) ) + .001 ) *
        //LCD color effect
        max(  sin(p*=16e2).y * sin(p.x+vec4(0,2,4,6)), 0.),
        //Cube for better gamma
        3.+O-O);
    
    //Adjust gamma and brightness
    O = pow(O,.15+O-O)*.6;
}
