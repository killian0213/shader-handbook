// Common (common) — The Typist by Xor
// https://www.shadertoy.com/view/sd3czM

/*
    Originally, this was two-pass effect, but I found a way to simplify it to one.
    I'm keeping the original code here for posterity:
*/

/*
#define T texture(iChannel0, I

///BUFFER A
//iChannel0: Font texture (Linear)
//iChannel1: Bluenoise texture (Nearest)
void mainImage(out vec4 O, vec2 I)
{
    //Time shortened 
    float t = iTime*.03,
    //Resolution scale factor
    r = .2/iResolution.y;
    //Rotate coordinates with perspective and scrolling
    I = (I*mat2(9,-1,1,9)*r-2.)/9./(1.-I.y*r)+t;
    //Sample bluenoise texture (one-pixel per letter)
    O = texture(iChannel1,I/64.);
    //Pixel coordinates
    vec2 p = I*16e2,
    //Chromatic aberration delta
    d = vec2(2e-3,0);
    //Add random offset
    I += ceil(O.rg*16.+t/.2)/16.;// - O.b*O.a*(I-t)/9.
    //Sample letters with aberration
    O = (vec4(T-d).r,T).r,T+d.yx))+.001) *
    //Apply LCD color effect
    max(sin(p.x+vec4(0,2,4,6))*sin(p.y),0.);
    //Make sure the alpha is 1 for bokeh pass!
    O.a = 1.; O*=O*O;
}

///IMAGE
//iChannel0: Buffer A texture
void mainImage(out vec4 O, vec2 I)
{
    //Resolution for texel calculation
    vec2 r = iResolution.xy,
    //Sample point starting at vec2(scale, 0)
    p = vec2(dot(I+I-r,vec2(1,-5)/5e3), O-=O);
    
    //"i" approximating the sqrt of the number of iterations.
    //So i < 16 means roughly 256 texture samples.
    for(float i=1.; i<16.; i+=1./i)
        //Rotate sample point by golden angle (for even spacing).
        p *= mat2(0,.061,1.413, 0)-.737,
        //Add samples exponentially (a bit like a "smooth maximum").
        O += T/r+p*i/r);
    //Convert back to linear color (making brighter pixel stand out)
    //Average by total sample weight via alpha channel.
    O = pow(O/O.a,.15-O+O)/.8;
}
*/