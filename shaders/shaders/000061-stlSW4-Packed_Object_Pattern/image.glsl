// Image (image) — Packed Object Pattern by Shane
// https://www.shadertoy.com/view/stlSW4

/*

    Packed Object Pattern
    ---------------------    
    
    This is yet another packed object pattern using a simple but highly
    inefficient dart throwing algorithm -- To be fair, it will get the
    job done, but will take at least 20 seconds to form, which in GPU 
    time is an eternity.
    
    There was no particular reason for putting this together other than 
    boredom and fun. I started with Oneshade's "Coral Growth" demonstration 
    as a base, then added bits here and there until not much of the 
    original code was left, but it's basically the same thing.
    
    My main motivation was prettying up some random vector objects, so I
    didn't bother much with the algorithm itself. Having said that, I at
    least attempted to hurry things along by modifying things to 
    effectively shoot more darts. However, there are way more efficient 
    partitioning based strategies for producing these patterns.
    
    I much prefer to use the cube map faces for pre-rendered textures,
    but I didn't here, plus I'm using all four channels, so changing 
    resolutions requires either hitting the back button or clicking the 
    mouse. By the way, there's a "SHAPE" define in the other tab that'll
    allow for the rendering of different objects for anyone interested.
    
    
    
    Other Examples:
    
    // I loosely based this example on the following:
    Expanding Coral Growth - Oneshade
    https://www.shadertoy.com/view/sl2GDd
    
    // One of Fabrice's early attempts.
    dart throwing / space filling 2b - Created by FabriceNeyret2 
    https://www.shadertoy.com/view/ltVBRt
    
    // This is a much more sophisticated approach. Fizzer uses his brain,
    // whereas I tend to hit things with a hammer and hope for the best. :D
    Dart-Throwing with Gap-Search - Fizzer
    https://www.shadertoy.com/view/3sSXW1 

*/


// I prefer the cleaner look, but some mild texturing is possible.
//#define TEXTURE

// Fake highlight shading. Things look cleaner without it.
#define HIGHLIGHTS


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){
    return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); 
}

/*
// IQ's line distace formula. 
float sdLine( in vec2 p, in vec2 a, in vec2 b ){

	p -= a, b -= a;
	return length(p - b*clamp(dot(p, b)/dot(b, b), 0., 1.));
}
*/

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    
   
    // UV coordinates.
    vec2 svUV = (fragCoord - iResolution.xy*.5)/iResolution.y;
    vec2 uv = rot2(-3.14159/3.5)*svUV - iTime/32.;
    float sf = 1./iResolution.y;

    // Some texture or buffer samples.
    vec4 buf = texture(iChannel0, fract(uv));
    vec4 bufSh = texture(iChannel0, fract(uv - vec2(-.005, -.015)));
    vec4 bufLt = texture(iChannel0, fract(uv + 2.25*vec2(-.005, -.015)));
    
    
    // Scene color -- Initiated to white.
    vec3 col = vec3(1);
    
    
    #ifdef TEXTURE
    vec3 tx2 = texture(iChannel1, uv).xyz; tx2 *= tx2;
    col = col*.6 + (col*1. + .1)*tx2;    
    #endif
    
    
    // Mild distance field based concentric background pattern.
    float pat = (abs(fract(-buf.x*65.) - .5)*2. - .2)/130.;
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, pat))*.25);
    // Line pattern.
    //float pat2 = (abs(fract((uv.x - uv.y)*65.) - .5)*2. - .35)/65.;
    //col = mix(col, vec3(0), (1. - smoothstep(0., sf, pat2))*.35);
    
    
    // Object coloring.
    vec3 cCol = vec3(1,  hash21(buf.yz)*.1, hash21(buf.yz + .09)*.1);
    #ifndef HIGHLIGHTS
    cCol += .15;
    #endif
     
    // Texturing the objects.
    #ifdef TEXTURE
    vec2 qq = (fract(uv - buf.yz) - .5);
    vec3 tx = texture(iChannel1, 
              (qq/2./buf.w)*(1. + dot(qq, qq)/buf.w)/1.5 + vec2(.2, 0)).xyz; 
    tx *= tx;
    tx = smoothstep(.0, .5, tx);
    cCol *= tx*1.5 + .1;
    //cCol = tx*.5;
    #endif
    
    // Outer and inner edge widths.
    float ew = .005;
    float ew2 = .008;
    
    // Bump. Not used.
    //float b = max(-bufLt.x/(buf.w - ew2), 0.);
 
 
    #ifdef HIGHLIGHTS
    // Fake mild diffuse and fake specular highlights.
    vec2 ep = buf.yz + normalize(vec2(.005, .015))*(buf.w*.35);
    float pl = length(fract(uv - ep) - .5) - (buf.w*.7*.85);
    //float pl = sHexS(fract(uv - ep) - .5, (buf.w*.4*.85), (buf.w*.4*.85)*.4);
    cCol = mix(cCol, mix(cCol, vec3(1), .75), (1. - smoothstep(0., sf*12., pl))*.1);
    ep = buf.yz + normalize(vec2(.005, .015))*(buf.w*.3);
    pl = length(fract(uv - ep) - .5) - (buf.w*.15*.85);
    //vec2 gg = abs(fract(uv - ep) - .5) - (buf.w*.15*.85);
    //pl = -pl + max(gg.x, gg.y)*16.;
    cCol = mix(cCol, mix(cCol, vec3(1), .75), (1. - smoothstep(0., sf*5., pl))*.35);
    #endif
 
    // Light edge color.
    vec3 cCol2 = mix(cCol, vec3(1), .9);


    /*
    ////
    // Polar lines on the outer rims. Interesting, but not this time. :)
    vec2 pp = fract(uv - buf.yz) - .5;
    float aa = atan(pp.x, pp.y)/6.2831;
    float lnNum = floor(48.*6.2831*buf.w);
    aa = (floor(aa*lnNum) + .5)/lnNum;
    vec2 aPnt3 = rot2(aa*6.2831)*vec2(0, 1);
    float pat3 = sdLine(pp, vec2(0), aPnt3) - .0025;
    if(lnNum>3.)cCol2 = mix(cCol2, vec3(0), (1. - smoothstep(0., sf, pat3))*.3);
    ////
    */
    

    // Rendering the various shadow, edge, color layers, etc.
    //
    // Shadow.
    col = mix(col, vec3(0),  (1. - smoothstep(0., sf*2., bufSh.x))*.4);
    // Edges.
    col = mix(col, vec3(0),  1. - smoothstep(sf, 0., -buf.x));
    col = mix(col, cCol2,  1. - smoothstep(sf, 0., -buf.x - ew));
    col = mix(col, vec3(0),  1. - smoothstep(sf, 0., -buf.x - ew2 - ew));
    #ifdef HIGHLIGHTS
    cCol += max(0.-(bufLt.x)/.25, 0.);
    //cCol += b*b;
    //cCol = mix(cCol, vec3(0), (1. - smoothstep(0., sf, pat2))*.35);
    #endif
    // The inner color layer.
    col = mix(col, cCol,  1. - smoothstep(sf, 0., -buf.x - ew2 - ew*2.));
    
    
    // Extra gradient based coloring.
    uv = fragCoord/iResolution.xy;
    col = mix(col, col.zyx, uv.y*.7 - .35);
    
    
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
    
}