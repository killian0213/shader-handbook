// Image (image) — 3D Turing Texture by Shane
// https://www.shadertoy.com/view/NsSSDW

/*

    3D Turing Texture
    -----------------

    Constructing and applying a repeat 3D Turing pattern: Diffusion patterns are 
    nothing new, but I couldn't find any 3D wrappable ones, so I've put this up 
    as a reference. It's based on something I did years ago.
    
    There are a couple of things I needed to overcome before presenting it in
    shader form. The main one was that diffusion patterns take a while to create, 
    and people get bored very quickly... OK, I mean, I get bored very quickly. :D
    To get around this, I skipped over the usual dual concentration approach, and
    took a custom filtered approach, which forms patterns much faster. Unfortunately, 
    the initial precalculation can be a little intensive, so I hid it behind an 
    oldschool waiting screen -- similar to the ones that people used to use in old 
    demos.
    
    It was also necessary to render the Turing pattern efficiently in realtime,
    which meant it had to be relatively fast and smooth. Smooth rendering usually 
    requires eight texel reads per pass, which is a little slow. One unfiltered 
    texture read is fast, but not visually acceptable. I got around the problem by 
    storing four neighbor values in adjoining buffer channels, which meant only two 
    texel reads per pass. The problem with the dual concentrated solution diffusion 
    appraoch is that twice as many storage slots are required, which in turn requires 
    twice the reads at half the resolution. However, the filtered noise approach 
    that I've used bypasses that -- By the way, I have yet another filtering method 
    that is much nicer that I'll demonstrate in due course.
    
    The structure itself is just a few layers of transcendentals combined to make
    something that looks geometric and natural at the same time. By warping the 
    structure, you can make it look more organic, but I wanted to keep it simple.
 
    Anyway, the pattern here is only bump mapped, but it is fast enough to be used
    via the distance function. I've applied a basic depth of field effect to round 
    things out. I have a few more traditional looking 3D Turing pattern surfaces 
    that I'll release a little later on.
    
    
    
    // Other examples:
    
    // I love this one.
    3D diffusion limited aggregation - Mattz
    https://www.shadertoy.com/view/XtSfRz
    
    // 2D, but really nice. Wyatt has heaps of diffusion (2D and 3D) related 
    // examples on here that are worth looking through.
    Symbiosis - Wyatt
    https://www.shadertoy.com/view/WssXW2
    
    
*/


// Just a very basic depth of field routine -- I find a lot of it is
// common sense. Basically, you store the scene distance from the camera 
// in the fourth channel, then use it to determine how blurry you want
// your image to be at that particular distance.
//
// For instance, in this case, I want pixels that are 12 units away from 
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
    const float focD = 12., coc = 5.;
    // Linear distance from either side of the focal point.
    float l = abs(focD - texture(iCh, uv).w);
    // Using it to calculate the DOF.
    vec2 dof = clamp((l - coc)/(2.*coc), 0., 1.)/vec2(800, 450)*2.5; 
    
    // Combine samples. Samples with a larger DOF value are taken further 
    // away from the original point, and appear blurrier.
    vec3 acc = vec3(0);

    for(int i = 0; i<49; i++){
        // Accumulate samples.
        acc += texture(iCh, uv + (vec2(i/7, i%7) - 3.)*dof).xyz;
    }

    // Return the new variably blurred value.
    return acc /= 49.;
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

    
    
    int tFrame = iFrame - frame0;
    if(tFrame<300){
    
        // Precalculating and producing the Turing pattern can take 
        // a few seconds, so rather than present a stuttering mess to 
        // the user, I put together an oldschool demoscene waiting
        // screen graphic... I was in a hurry, so the logic could be
        // better, but it does the job.
        
        
        vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
        float sf = 1./iResolution.y;
        
        float l = float(tFrame - 1)/300.*300./299.;
        //l = floor(l*31.999)/31.;
        float x = uv.x;//floor(uv.x*15.999)/15.;
        
        float back = max(abs(uv.x) - .25, abs(uv.y) - .02);
        vec3 col = mix(vec3(0), vec3(1), 1. - smoothstep(0., sf, back - .01));
        col = mix(col, vec3(0), 1. - smoothstep(0., sf*2., back - .005));
        
        uv = uv + vec2(.25*(1. - l), 0);
        float bar = max(abs(uv.x) - .25*l, abs(uv.y) - .02);
        
        vec3 bCol = .5 + .5*cos(6.2831*x*.5 + vec3(0, 1, 2) + 4.);
        bCol *= max((uv.y + .01)/.015, 0.) + .25;
        
        col = mix(col, bCol, 1. - smoothstep(0., sf, bar));
        
        fragColor = vec4(sqrt(max(col, 0.)), 1);
        
        // I prefer "if-else" statements, but sometimes GPUs will calculate the
        // whole statement, which can be expensive. Hence the less readable "return"
        // approach.
        return;
    }
    
    // If we're not precalculating (above), apply some depth of field, then present
    // to the screen.
    vec3 col = DpthFld(iChannel0, fragCoord/iResolution.xy);
    
	fragColor = vec4(sqrt(max(col, 0.)), 1);
}