// Image (image) — Realtime Extruded Quadtree by Shane
// https://www.shadertoy.com/view/slXGDN

/*


    Realtime Extruded Quadtree
    --------------------------
    
    FMS_Cat posted a beautifully rendered, static extruded quadtree example the 
    other day that appealed to me on many levels. Since I already had a realtime  
    quadtree example tucked away in my account, it inspired me to put on some
    finishing touches and post it. Designwise, I "borrowed" two aspects from 
    FMS_Cat's scene. One was the camera angle, and the other was the hollowing 
    out of random blocks. I added some moving objects to the hollowed blocks to 
    provide a personal touch and to further illustrate the idea that this is a 
    realtime example. 
    
    The quadtree code itself was based on a 2D quadtree demonstration I posted 
    on Shadertoy a few months ago, which ironically was much harder to produce 
    than this.
	
	Coding up an extruded quadtree in realtime is still a bit of an ask. 
    Thankfully, unlike my coding skills, machines have improved considerably 
    over the past few years, so it runs reasonably efficiently... Not fantastic, 
    but not too bad on decent machines. Apologies to anyone with a slower system,
    but even with cost cutting, there's a fair bit of processing going on.

    If you were to code an extruded tri-level quadtree using nested brute force 
    neighboring column repeat methods, you'd need a GPU-burning 64 taps, which 
    isn't satisfactory. However, using a mixture of simultaneous scaling and 
    repeat neighboring methods can get it right down to just 12, which 
    conceptually is about as good as you're going to get... Having said that, 
    there are some freakishly good coders on this site, so it wouldn't shock me 
    if someone got the number down. :)
    
    FMS_Cat's scene also included water, which would have been a great addition, 
    but I had to let it go, as it would have required extra passes -- Fake 
    environmental lighting was all I could afford this time around. However, I 
    have a regular extruded block example with water that I'll post later.
	
    

	Inspired by:
    
	// I love static renderings like this.
    "Wooden Structure" - FMS_Cat
	https://www.shadertoy.com/view/sdjXWy
    
    // I based the code on this particular example.
    Sorted Overlapping Quadtree - Shane
    https://www.shadertoy.com/view/wtjfDy


*/


// Just a very basic depth of field routine -- I find a lot of it is
// common sense. Basically, you store the scene distance from the camera 
// in the fourth channel, then use it to determine how blurry you want
// your image to be at that particular distance.
//
// For instance, in this case, I want pixels that are 3.5 units away from 
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
    const float focD = 3.5, coc = 1.;
    // Linear distance from either side of the focal point.
    float l = abs(focD - texture(iCh, uv).w);
    // Using it to calculate the DOF.
    vec2 dof = clamp((l - coc)/(1.*coc), 0., 1.)/vec2(800, 450); 
    
    // Combine samples. Samples with a larger DOF value are taken further 
    // away from the original point, and as such appear blurrier.
    vec3 acc = vec3(0);

    for(int i = 0; i<25; i++){
        // Accumulate samples.
        acc += texture(iCh, uv + (vec2(i/5, i%5) - 2.)*dof).xyz;
    }

    // Return the new variably blurred value.
    return acc /= 25.;
    // Visual debug representation of DOF value.
    //return vec3(length(dof)*450./2.5);
}


// This would normally be a very quick routine that displays
// the scene and gives it a distance of field effect, but I 
// wanted to put in a little loading bar graphic just to let
// people know that some precalculation is happening in the 
// background... and to give impatient people like me a visual 
// representation of the time it's going to take. :D
//
void mainImage( out vec4 fragColor, in vec2 fragCoord){
     
    
    // Apply some depth of field, then present to the screen.
    vec3 col = DpthFld(iChannel0, fragCoord/iResolution.xy);
    
    // Rough gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
}