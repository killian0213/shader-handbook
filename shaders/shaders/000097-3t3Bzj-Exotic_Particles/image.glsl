// Image (image) — Exotic Particles by Shane
// https://www.shadertoy.com/view/3t3Bzj

/*

    Exotic Particles
    ----------------
    
    Accumulating color values via transcental function-warping to create some 
    pretty, moving imagery that resembles colliding exotic particles in a 
    chamber... of paint... I actually have no idea what this looks like. :D
    
    Function-warping is nothing new, and this particular example is just a 
    slightly dressed up version of Jolle and Jarble's previous work, which in 
    turn was very loosely based on one of Lomateron's recent examples -- The 
    respective links are below.
    
    Anyway, I've commented the code. However, there's definitely nothing 
    difficult to grasp here. The simple color imagery was produced in 
    "Buffer A", which was blended with previous frames for a bit of temporal 
    blurring. The result (Image tab) was then used to take two 3x3 blurred 
    samples in order to add some highlights.
    
    
    
    
    Uses elements from the following shaders:
    
    Glass bubble lamp - Jarble: https://www.shadertoy.com/view/ttcfD7
    
    Glass bubble lamp fork - Jolle: https://www.shadertoy.com/view/WtdBDM
    
    Mount Mask - lomateron: https://www.shadertoy.com/view/WdsfRf
    
    
*/

// Things look cleaner without highlights, and in some ways I prefer it.
// However, it's less interesting... I think? :)
#define HIGHLIGHTS

// Serves no other purpose than to save having to write this out all the time. I'm using this 
// on a buffer texture, so no sRGB to linear operation needs to be performed. I'm also
// using (and prefer to use) aspect correct pixel coordinates, so it's necessary to stretch 
// out the X values before retrieving them. It's also possible to stretch out the UV coordinates
// first, then use a stretched sample spread, which is faster... Yeah, it's confusing, but it 
// doesn't matter, just so long as you have a method you're happy with. :)
//
vec4 tx(in vec2 p){ 
     p *= vec2(iResolution.y/iResolution.x, 1);
     return texture(iChannel0, p + .5/iResolution.y); 
}

// Blur function. Pretty standard.
vec4 bTx(in vec2 p){
    
    // Sample spread -- Measured in pixels.
    float px = 2.;
    
    // Result.
	vec4 c = vec4(0);
    
    // Standard equally weighted 3x3 blur.
    for(int i = 0; i<9; i++) c += tx(p + (vec2(i/3, i%3) - 1.)*px/iResolution.y);
 
    // Normalizing the return value.
    return c/9.;  
    
    /*
    // NxN blur.
    const int N = 5;
    for(int i = 0; i<N*N; i++) c += tx(p + (vec2(i/N, i%N) - float(N - 1)/2.)*px/iResolution.y);
    return c/float(N*N); 
    */
}
 
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    // Aspect correct pixel coordinates.
    vec2 uv = fragCoord/iResolution.y;
   
    // A 3x3 blurred texture sample. The generated warped imagery contains a few
    // high frequency speckles, so blurred samples mitigate that somewhat. Denoising
    // would be better, but this will do.
    vec4 col = bTx(uv);
    //vec4 col = tx(uv); // Standard single sample.
     
    #ifdef HIGHLIGHTS
    // Bump mapping via cheap, directional derivative-based highlighting.
    vec2 px = 4./iResolution.yy; // Sample spread.
    vec4 col2 = bTx(uv - px); // Seperate sample.
    float b = max(dot(col2 - col, vec4(.299, .587, .114, 0)), 0.)/length(px); // Bump.
    col += col2.yzxw*col2.yzxw*b/12.; // Add the colored highlights.
    #endif
    
    // Toning down the lower half slightly.
    col = mix(col, col.zyxw, max(.3 - uv.y, 0.));
    

    // Rough gamma correction.
    fragColor = sqrt(max(col, 0.));
}


