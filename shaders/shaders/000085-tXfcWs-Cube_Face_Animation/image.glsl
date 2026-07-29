// Image (image) — Cube Face Animation by Shane
// https://www.shadertoy.com/view/tXfcWs

/*

    Cube Face Animation
    -------------------

    See "Buffer A".

*/

  

// Just a very basic depth of field routine -- I find a lot of it is
// common sense. Basically, you store the scene distance from the camera 
// in the fourth channel, then use it to determine how blurry you want
// your image to be at that particular distance.
//
// For instance, in this case, I want pixels that are 6.25 units away from 
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
    #ifdef ISOMETRIC
    const float focD = 4., coc = .5;
    #else
    const float focD = 1.5, coc = .5;
    #endif
    // Linear distance from either side of the focal point.
    float l = abs(texture(iCh, uv).w - focD) - coc;
    // Using it to calculate the DOF.
    float dof = clamp(l/coc, 0., 2.)*2.; 
    dof = mix(dof, smoothstep(-.25,.25, abs(uv.y - .5)*abs(uv.y - .5) - .2)*4., .5);
    
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


void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Screen oordinates.
    vec2 uv = fragCoord/iResolution.xy;


    // Retrieving the stored color.
    //vec4 col = texture(iChannel0, uv);

    // Depth of field.
    vec4 col = DpthFld(iChannel0, uv).xyzz;
    
      
    // Hardware bloom that I made up on the spot. It's
    // not as nice as software bloom, but it's way cheaper
    // and definitely easier to implement.
    float a = 1., w = 1.;
    vec4 col2 = vec4(0);
    for (int i = 0; i<6; i++){
        vec2 jit = (texture(iChannel1, uv + float(i)/6. + 
                             fract(iTime)).xy - .5)/iResolution.y;
        col2 += texture(iChannel0, uv + jit*1., float(i)/2.)*w;
        a += w;
        //w *= .7071;
    }
    col2 /= a;
    
    col += smoothstep(.0, 1., col2);
    
    
    //col = mix(col.yzxw, col, smoothstep(0., .8, uv.y));
  
    // Very rough Reinhard-based tone mapping.
    //col /= (1.5 + col)/2.;
    
    // Subtle vignette.
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);

    // Rough gamma correction and screen presentation.
    fragColor = pow(max(col, 0.), vec4(1./2.2)); 
    
}

