// Image (image) — Apollonian Construction by Shane
// https://www.shadertoy.com/view/DsK3zh

/*

    Apollonian Construction
    -----------------------

    Rendering the buffer.
 
    See Buffer A for an explanation.
    
*/

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// This is an amalgamation of old blur and DOF functions with a couple of borrowed 
// lines from Dave Hoskins's much nicer Fibonacci based "Bokeh disc" function, which 
// you can find here: https://www.shadertoy.com/view/4d2Xzw
//
// This function is only really suitable for this example. If you're interested in 
// bokeh, Dave's function above and some of Shadertoy user, Hornet's, are probably
// the one's you should be looking at. Xor has some cool simple ones on here that I'm
// yet to dig into, but they might worth a look also.
vec4 bloom(sampler2D iCh, vec2 uv){

	vec4 tot = vec4(0);
    
    // UV based DOF. Focused on the horizontal line, then blurring further away.
    //float r = smoothstep(0., 1., abs(uv.y - .57)/.57)*2.;
    // Focal point and circle of confusion.
    const float focD = 2.5, coc = 1.;
    // Linear distance from either side of the focal point.
    float l = abs(texture(iCh, uv).w - focD - coc) - coc;
    // Using it to calculate the DOF.
    float r = clamp(l/coc, 0., 1.);
    
    const int n = 4;
    for (int j = -n; j<=n; j++){
        for (int i = -n; i<=n; i++){
           
            // Random offset contained within a disk or radius n.
            vec2 rnd2 = vec2(hash21(vec2(i, j)), hash21(vec2(i, j) + .1)*6.2831);
            vec2 offs = float(n)*rnd2.x*vec2(cos(rnd2.y), sin(rnd2.y));
            
            vec4 c = texture(iCh, uv + offs/vec2(800, 450)*r, r*iResolution.y/450.*.7); 
            tot += mix(c, pow(c, vec4(1.25))*3.4, rnd2.x*rnd2.x); //ow(c, vec4(1.5))*4.
            
        }
    }
    
	return tot/float((n*2 + 1)*(n*2 + 1));
}



void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Rendering the buffer.
    vec2 uv = fragCoord/iResolution.xy;
    
    // Retrieving the stored color.
    vec4 col = texture(iChannel0, uv);
   
    // Custom DOF bloom-like function.
    col = bloom(iChannel0, uv);
    
    

    // Rough gamma correction and screen presentation.
    // "col" should already be above zero, but we're capping it anyway.
    fragColor = pow(max(col, 0.), vec4(1./2.2));
    
}

