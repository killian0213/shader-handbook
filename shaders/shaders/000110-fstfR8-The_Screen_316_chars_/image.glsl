// Image (image) — The Screen [316 chars] by Xor
// https://www.shadertoy.com/view/fstfR8

/*
    "The Screen" by @XorDev
    
    Tweet: twitter.com/XorDev/status/1540071403185127426
    Twigl: t.co/l5PMGbxrjV
    
    Based loosely on "The Typist": shadertoy.com/view/sd3czM
    -11 chars by iq
    -2 chars by FabriceNeyret2
    
    <512 Chars playlist: shadertoy.com/playlist/N3SyzR
*/

void mainImage( out vec4 O, vec2 I)
{
    //Resolution for scaling
    vec2 r = iResolution.xy,
    //Rotated coordinates
    c = mat2(9,1,-1,9)*(I+I-r),
    //Iteration constant (starting at 0)
    i = r-r;
    
    //Intialize sample and color vector
    //Loop 200 times
    //Add cubed sample to output
    for(vec4 S,C = vec4(2,4,6, O-=O); i.x<2e2; O += S*S*S)
        
        //Compute sample point with bokeh offset
        I = c+sin(i+C.wx*5.5)*c.y/3e2*sqrt(i++),
        //Add perspective and scrolling
        I = I/(r*3.-I*.1).y+iTime,
        //LCD coloring
        S = sin(I.xxxy*4e1+C),
        S = max(  S.w * S* 
        //Random bar texturing
        max(cos((I.y+C/8e1)/texture(iChannel0,I/1e3-sin(I)/2e3).r),.03),.0);
    
    //Compute fourth root and darken for better coloring
    O = sqrt(sqrt(O)*.2);
}