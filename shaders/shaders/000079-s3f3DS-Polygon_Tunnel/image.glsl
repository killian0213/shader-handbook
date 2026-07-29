// Image (image) — Polygon Tunnel by Shane
// https://www.shadertoy.com/view/s3f3DS

/*

    Polygon Tunnel
    --------------
    
    See "Buffer A" for an explanation.

*/


 
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
    const float focD = 3., coc = 1.;
    // Linear distance from either side of the focal point.
    float l = abs(texture(iCh, uv).w - focD) - coc;
    // Using it to calculate the DOF.
    float dof = clamp(l/coc, 0., 1.); 
    // Adding a bit of faux DOF to the top and bottom of the screen.
    dof = mix(dof*2., smoothstep(.2, .6, abs(uv.y - .5))*2., .5);

    
    // Combine samples. Samples with a larger DOF value are taken further 
    // away from the original point, and as such appear blurrier.
    vec3 acc = vec3(0);
    
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

    vec4 col = DpthFld(iChannel0, uv).xyzz;

    // Retrieving the stored color.
    //vec4 col = texture(iChannel0, uv);


    // Subtle vignette.
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./32.);
    
    // Tanh sigmoid tone mapping -- Popularized by Xor. It's a great
    // all-rounder, if you just want to tone down the upper range. I'm 
    // not sure why I put "1.1" exposure in there... Probably left over 
    // from something else. :)
    //col = tanh(col*1.1);

    // Rough gamma correction and screen presentation.
    fragColor = pow(max(col, 0.), vec4(1)/2.2); 
    
}
