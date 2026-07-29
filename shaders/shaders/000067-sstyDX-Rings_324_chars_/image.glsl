// Image (image) — Rings [324 chars] by Xor
// https://www.shadertoy.com/view/sstyDX

/*
    "Rings [324 chars]" by @XorDev
    Tweet: https://twitter.com/XorDev/status/1532211104583131136
    Twigl: https://t.co/eyzpt9hV4A
    
    Also see "Mars": https://www.shadertoy.com/view/sdcyWN

    Bokeh based on: shadertoy.com/view/fljyWd
    -3 thanks to iq
    
    <512 Chars playlist: shadertoy.com/playlist/N3SyzR
*/

#define S texture(iChannel0

void mainImage(out vec4 O, vec2 I)
{
    vec2 r = iResolution.xy,     //Resolution for texel calculations
    i = r/r,                     //Iteration variable
    d = (I.x-I-I+r*.2).yy/2e3,   //Depth of field vector
    p,                           //Sample point
    l;                           //Sample point length
    
    //Clear color
    for(O-=O;    
    //Iterate approximately 16*16 times
    i.x<16.;    
    //Approximately i = sqrt of the number of iterations
    i+=1./i)
        
        //Compute sample length and point with skewing
        l = length(p=(I+d*i)*mat2(2,1,-2,4)/r.y-vec2(-.1,.6)) / vec2(3,8),
        //Rotate DOF sample vector
        d *= -mat2(73,67,-67,73)/99.,
        //Add rings (radial and cartesian noise)
        O += pow(S,l)*S,p*mat2(cos(iTime*.1+vec4(0,33,11,0))))/l.x*.4,vec4(5,8,9,0));
    //Take fifth root for boosted contrast
    O=pow(O,.2+O-O);
}