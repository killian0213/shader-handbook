// Image (image) — Noise Layer Raymarch Traversal by Shane
// https://www.shadertoy.com/view/3XSSzw

/*

    Noise Layer Raymarch Traversal
    ------------------------------

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
    const float focD = 2.5, coc = .5;
    // Linear distance from either side of the focal point.
    //float l = abs(texture(iCh, uv).w - focD) - coc;
    float l = texture(iCh, uv).w;
    // Using it to calculate the DOF.
    float dof = clamp(l/coc, 0., 2.)*2.; 
    //float dof = smoothstep(.5, 1., abs(uv.x*2. + uv.y - 1.5)*1.)*2.;
  
    
    // Combine samples. Samples with a larger DOF value are taken further 
    // away from the original point, and as such appear blurrier.
    vec3 acc = vec3(0);
    
    // DOF spread.
    vec2 iRes = vec2(iResolution.x/iResolution.y, 1)*450.;


    for(int i = 0; i<25; i++){
        // Accumulate samples.
        acc += texture(iCh, uv + (vec2(i/5, i%5) - 2.)/iRes*dof).xyz;
        //acc.x *= dof/2.;
    }

    // Return the new variably blurred value.
    return acc /= 25.;
    // Visual debug representation of DOF value.
    //return vec3(length(dof)*450./2.5);
}
 
*/

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's float to float hash. I've added an extra sine wrapping modulo to
// cater for my annoying AMD based system, which can't wrap sine with a 
// proper degree of accuracy.
float hash11B(float x){ return fract(sin(mod(x, 6.2831853))*43758.5453); }

// This is an amalgamation of old blur and DOF functions with a heap of borrowed 
// lines from Dave Hoskins's much nicer Fibonacci based "Bokeh disc" function, which 
// you can find here: https://www.shadertoy.com/view/4d2Xzw
//
// If you're interested in bokeh, Dave's function above, and some of Shadertoy user, 
// Hornet's, are probably the ones you should be looking at. Xor has some cool simple 
// ones on here too.
//
vec4 bokeh(sampler2D iCh, vec2 uv){


    // UV based DOF. Focused on the horizontal line, then blurring further away.
    //float r = smoothstep(0., 1., abs(uv.y - .57)/.57)*2.;
    // Focal point and circle of confusion.
    const float focD = 2., coc = .75;
    // Linear distance from either side of the focal point.
    float l = texture(iCh, uv).w;//abs(texture(iCh, uv).w - focD) - coc;
    // Using it to calculate the DOF.
    float ra = l;//clamp(l/coc, 0., 2.);
    //float ra = smoothstep(.5, 1., abs(uv.x*2. + uv.y - 1.5)*1.)*2.;
    //float ra = mix(clamp(l/coc, 0., 2.), smoothstep(.3, 1., abs(uv.y - .5)*2.), .25);
    //float ra = (smoothstep(.2, 1., length(uv - .5)));

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
    // Trying to reduce the sample spread at larger resolutions.
    //if(iResolution.y>450.) aspect *= mix(iResolution.y, 450., .5)/iResolution.y;
    
    
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
        vec2 rnd2 = vec2(hash11B(fi), hash11B(fi + .1)*6.2831);
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
	return mix(colOrig, tot/div*2., ra);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Screen oordinates.
    vec2 uv = fragCoord/iResolution.xy;


    // Retrieving the stored color.
    //vec4 col = texture(iChannel0, uv);

    // Rough bokeh algorithm.
    vec4 col = bokeh(iChannel0, uv);
    
    // Depth of field.
    //vec4 col = DpthFld(iChannel0, uv).xyzz;

    /* 
    // Hardware bloom that I made up on the spot. It's
    // not as nice as software bloom, but it's way cheaper
    // and definitely easier to implement.
    float a = 0., w = 1.;
    vec4 col2 = vec4(0);
    for (int i = 0; i<6; i++){
        vec2 jit = (texture(iChannel1, uv + float(i)/6. + 
                    fract(iTime)).xy - .5)/iResolution.y;
        col2 += texture(iChannel0, uv + jit*4., float(i)/2.)*w;
        a += w;
        //w *= .7071;
    }
    col2 /= a;
    
    col += smoothstep(.2, 1., col2);
    */
     
    // Subtle tone-mapping.
    //col /= (2. + col)/2.5;
    
    
    // Vignette and very rough Reinhard tone mapping.
    col *= smoothstep(1.5, .5, length(2.*uv - 1.)*.7);
 
    // Rough gamma correction and screen presentation.
    fragColor = pow(max(col, 0.), vec4(1./2.2)); 
    
}
