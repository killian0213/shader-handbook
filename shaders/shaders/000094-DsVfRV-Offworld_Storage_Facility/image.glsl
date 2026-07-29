// Image (image) — Offworld Storage Facility by Shane
// https://www.shadertoy.com/view/DsVfRV

/*

    Offworld Storage Facility
    -------------------------

    See "Buffer A" for an explanation.

*/


/*

// Just a very basic depth of field routine -- I find a lot of it is
// common sense. Basically, you store the scene distance from the camera 
// in the fourth channel, then use it to determine how blurry you want
// your image to be at that particular distance.
//
// For instance, in this case, I want pixels that are 2.25 units away from 
// the camera to be in focus (not blurred) and for things to get more 
// blurry as you move away from that point -- aptly named the focal point 
// for non camera people. :)
//
// I based this on old code of mine, but adopted things that I found in 
// IQ and Nesvi7's examples, which you can find here:
//
// Ladybug - IQ
// https://www.shadertoy.com/view/4tByz3
//
// Cube surface II - Nesvi7
// https://www.shadertoy.com/view/Mty3DV
//
vec3 DpthFld(sampler2D iCh, vec2 uv){
	
    // Focal point and circle of confusion.
    const float focD = 3., coc = 2.5;
    // Linear distance from either side of the focal point.
    float l = abs(texture(iCh, uv).w - focD - coc) - coc;
    // Using it to calculate the DOF.
    float dof = clamp(l/coc, 0., 2.); 
    
    // Combine samples. Samples with a larger DOF value are taken further 
    // away from the original point, and as such appear blurrier.
    vec3 acc = vec3(0);

    for(int i = 0; i<25; i++){
        // Accumulate samples.
        acc += texture(iCh, uv + (vec2(i/5, i%5) - 2.)/vec2(800, 450)*dof).xyz;
        //acc.x *= dof/2.;
    }

    // Return the new variably blurred value.
    return acc /= 25.;
    // Visual debug representation of DOF value.
    //return vec3(length(dof)*450./2.5);
}

*/


// IQ's float to float hash. I've added an extra sine wrapping modulo to
// cater for my annoying AMD based system, which can't wrap sine with a 
// proper degree of accuracy.
float hash11B(float x){ return fract(sin(mod(x, 6.2831853))*43758.5453); }

// This is an amalgamation of old blur and DOF functions with a heap of borrowed 
// lines from Dave Hoskins's much nicer Fibonacci based "Bokeh disc" function, which 
// you can find here: https://www.shadertoy.com/view/4d2Xzw
//
// If you're interested in bokeh, Dave's function above and some of Shadertoy user, 
// Hornet's, are probably the one's you should be looking at. Xor has some cool simple 
// ones on here too.
//
vec4 bloom(sampler2D iCh, vec2 uv){


    // UV based DOF. Focused on the horizontal line, then blurring further away.
    //float r = smoothstep(0., 1., abs(uv.y - .57)/.57)*2.;
    // Focal point and circle of confusion.
    const float focD = 3., coc = 2.5;
    // Linear distance from either side of the focal point.
    float l = abs(texture(iCh, uv).w - focD - coc) - coc;
    // Using it to calculate the DOF.
    float ra = clamp(l/coc, 0., 2.);
    //float ra = smoothstep(.1, .9, abs(uv.y - .5)*2.)*2.;
    //float ra = mix(clamp(l/coc, 0., 2.), smoothstep(.3, 1., abs(uv.y - .5)*2.), .25);
    //float ra = (smoothstep(.2, 1., length(uv - .5)));

 

    // Standard Fibonacci distribution calculations, compliments of Dave Hoskins.
    const int iter = 96;
    float rad = 2.5;//max(2.*ra, .5); // Bokeh radius.
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
        vec4 col = texture(iCh, uv - (r - 1.)*vangle*aspect, iResolution.y/450.*1.); 
        
        #else
        
        // A hash based random distribution, for anyone who wants to try it.
        //int ii = i%10; // For square bokeh.
        //int jj = i/10;
    
        // Random offset contained within a disk or radius n.
        float fi = float(i) + fract(iTime);
        //vec2 fi = vec2(ii, jj) - 5. + fract(iTime);
        vec2 rnd2 = vec2(hash11B(fi), hash11B(fi + .1)*6.2831);
        vec2 offs = 6.*sqrt(rnd2.x)*vec2(cos(rnd2.y), sin(rnd2.y));
        offs *= rad;
        //offs = rad*(offs + (vec2(hash11B(fi), hash11B(fi + .21)) - .5));
        vec4 col = texture(iCh, uv - offs/iResolution.xy, iResolution.y/450.*1.);  
  
        #endif
         
        // Thanks to Dave for figuring out how to tweak the colors to produce brighter 
        // contrast. It's common sense... once someone figures it out for you. :D 
        //
        // Linear falloff -- Not always necessary, but I need things to fade out
        // toward the edges. Nonlinear falloff is possible too.
        col *= 1. - float(i)/float(iter); 
        vec4 bokeh = col*col;
		tot += bokeh*bokeh;
		div += bokeh;
        
	}
    
    
    // Mixing the original value with the bokeh tweaked value according
    // to the depth of field and a hand tweaked brightness factor.
    vec4 colOrig = texture(iCh, uv);
	return colOrig + tot/div*2.*ra; //mix(colOrig, colOrig + tot/div*2., ra);///
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Screen oordinates.
    vec2 uv = fragCoord/iResolution.xy;

    // Uncomment the "DpthFld" function first.
    //vec4 col = DpthFld(iChannel0, uv).xyzz;

    
    // A bloom function. A lot of it comes from Dave Hoskins's bokeh function.
    // See the function above for a link to the original.
    vec4 col = bloom(iChannel0, uv);
    
    // Retrieving the stored color only.
    //vec4 col = texture(iChannel0, uv);


    // Subtle vignette.
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./32.);

    // Rough gamma correction and screen presentation.
    fragColor = pow(max(col, 0.), vec4(1./2.2)); 
    
}
