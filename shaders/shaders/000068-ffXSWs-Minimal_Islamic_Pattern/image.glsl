// Image (image) — Minimal Islamic Pattern by Shane
// https://www.shadertoy.com/view/ffXSWs

/*

    Minimal Islamic Pattern
    -----------------------

    See "Buffer A" for an explanation.

*/


// Standard 2D rotation formula.
//mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 2 out, 2 in...
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx)*vec3(.3031, .4030, .5973));
    p3 += dot(p3, p3.yzx + 42.1237);
    return fract((p3.xx+p3.yz)*p3.zy);
}

// This is an amalgamation of old blur and DOF functions with a heap of borrowed 
// lines from Dave Hoskins's much nicer Fibonacci based "Bokeh disc" function, which 
// you can find here: https://www.shadertoy.com/view/4d2Xzw
//
// If you're interested in bokeh, Dave's function above and some of Shadertoy user, 
// Hornet's, are probably the one's you should be looking at. Xor has some cool simple 
// ones on here too.
//
vec4 bokeh(sampler2D iCh, vec2 uv){


    // UV based DOF. Focused on the horizontal line, then blurring further away.
    //float r = smoothstep(0., 1., abs(uv.y - .57)/.57)*2.;
    // Focal point and circle of confusion.
    const float focD = 1.8, coc = .5;
    // Linear distance from either side of the focal point.
    float l = abs(texture(iCh, uv).w - focD) - coc;
    // Using it to calculate the DOF.
    float ra = clamp(l/coc, 0., 2.);
    //float ra = smoothstep(.1, .9, abs(uv.y - .5)*2.)*2.;
    //float ra = mix(clamp(l/coc, 0., 2.), smoothstep(.3, 1., abs(uv.y - .5)*2.), .25);
    ra = mix(ra, smoothstep(.2, 1., length(uv - .5)), .35);

    // Standard Fibonacci distribution calculations, compliments of Dave Hoskins.
    const int iter = 96;
    float rad = 1.6;//max(2.*ra, .5); // Bokeh radius.
    float r = 1.;
	vec4 tot = vec4(0), div = tot;
    vec2 vangle = vec2(0., rad*.01/sqrt(float(iter)));
    #define GA 2.3999632 // Golden angle.
    const mat2 rot = mat2(cos(GA), sin(GA), -sin(GA), cos(GA));

    // Aspect ratio.
    vec2 aspect = vec2(iResolution.y/iResolution.x, 1);
    
    
	for (int i = 0; i<iter; i++){
        
        #if 1
        
        // Dave Hoskin's Fibonacci based scattering. Cheaper and much nicer, so
        // it's set as the default.
        // The approx increase in the scale of sqrt(0, 1, 2, 3...).
        r += 1./r;
	    vangle = rot*vangle;
        vec4 col = texture(iCh, uv - (r - 1.)*vangle*aspect, iResolution.y/450.*1.5); 
        
        #else
        
        // A hash based random distribution, for anyone who wants to try it.
        //int ii = i%10; // For square bokeh.
        //int jj = i/10;
    
        // Random offset contained within a disk or radius n.
        float fi = float(i) + fract(iTime);
        //vec2 fi = vec2(ii, jj) - 5. + fract(iTime);
        vec2 rnd2 = hash22(fi + .1)*vec2(1, 6.2831);
        vec2 offs = 6.*sqrt(rnd2.x)*vec2(cos(rnd2.y), sin(rnd2.y));
        ////////
        /*
        // Polygons, if desired. Comment out the line above and comment in
        // the "rot2" formula above, if using it.
        const float N = 6.;
        float ra = rnd2.y;
        float a = (floor(ra*N) + .5)*6.2831859/N;
        vec2 offs  = mix(rot2(a)*vec2(0, 1), rot2(a + 6.2831859/N)*vec2(0, 1), fract(ra*N));
        offs *= 6.*sqrt(rnd2.x);
        */
        ////////
        offs *= rad;
        //offs = rad*(offs + (vec2(hash11B(fi), hash11B(fi + .21)) - .5));
        vec4 col = texture(iCh, uv - offs/iResolution.xy, iResolution.y/450.*1.5);  
  
        #endif
         
        // Thanks to Dave for figuring out how to tweak the colors to produce brighter 
        // contrast. It's common sense... once someone figures it out for you. :D 
        vec4 bokeh = pow(col, vec4(2));
		tot += bokeh*col*col;
		div += bokeh;
        
	}
    
    
    // Mixing the original value with the bokeh tweaked value according
    // to the depth of field.
    vec4 colOrig = texture(iCh, uv);
    // Not entirely correct, but no one will notice here. :)
	return mix(colOrig, colOrig*.25 + tot/div*4., ra);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Screen oordinates.
    vec2 uv = fragCoord/iResolution.xy;

    // Retrieving the stored color.
    //vec4 col = texture(iChannel0, uv);

    vec4 col = bokeh(iChannel0, uv);
    
 
    // Subtle vignette.
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);
    
    // Tanh sigmoid tone mapping -- Popularized by Xor. It's a great
    // all-rounder, if you just want to tone down the upper range. I'm 
    // not sure why I put "1.1" exposure in there... Probably left over 
    // from something else. :)
    col = tanh(col*1.1);

    // Rough gamma correction and screen presentation.
    fragColor = pow(max(col, 0.), vec4(1./2.2)); 
    
}
