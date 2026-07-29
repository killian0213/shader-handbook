// Image (image) — Multisample Raycaster by Shane
// https://www.shadertoy.com/view/Nd3yRX

/*

    Multisample Raycaster
    ---------------------

    See "Buffer A" for an explanation.

*/


// The following is based on John Hable's Uncharted 2 tone mapping, which
// I feel does a really good job at toning down the high color frequencies
// whilst leaving the essence of the gamma corrected linear image intact.
//
// To arrive at this non-tweakable overly simplified formula, I've plugged
// in the most basic settings that work with scenes like this, then cut things
// right back. Anyway, if you want to read about the extended formula, here
// it is.
//
// http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/
// A nice rounded article to read. 
// https://64.github.io/tonemapping/#uncharted-2
vec4 uTone(vec4 x){
    return ((x*(x*.6 + .1) + .004)/(x*(x*.6 + 1.)  + .06) - .0667)*1.933526;    
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // The other buffer has a maximum Y-resolution of 540 set, which 
    // means any pixels outside that are not rendered. On a 1980x1080
    // fullscreen resolution, this means roughly a quarter of the pixels
    // are rendered, which is a huge saving. Of course, this also means
    // that the scene needs to be upscaled, which will make things less
    // crisp, but you can't have everything. :)
    //
    // By the way, this tip came from Shadertoy user, spalmer, who has
    // a heap of interesting work for anyone interested:
    // https://www.shadertoy.com/user/spalmer
    //
    float maxRes = iResolution.y;//540.;
    vec2 uv = fragCoord/iResolution.xy;
    // If the resolution exceeds the maximum, upscale.
    if(iResolution.y>maxRes) uv = (fragCoord/iResolution.xy - .5)*maxRes/iResolution.y + .5;
    
    // Retrieving the stored color.
    vec4 col = texture(iChannel0, uv);
    
    /////////
    // Hardware bloom that I made up on the spot. It's
    // not as nice as software bloom, but it's way cheaper
    // and definitely easier to implement.
    float a = 1., w = 1.;
    vec4 col2 = vec4(0);
    for (int i = 0; i<6; i++){
        vec2 jit = (texture(iChannel1, uv + 
                            float(i)/6. + fract(iTime)).xy - .5)/iResolution.y;
        col2 += texture(iChannel0, uv + jit, float(i)/2.)*w;
        a += w;
        //w *= .7071;
    }
    col2 /= a;
    
    col += smoothstep(.3, 1., col2);
    //////////
    
    // Toning down the high frequency values. A simple Reinhard toner would 
    // get the job done, but I've dropped in a heavily modified and trimmed 
    // down Uncharted 2 tone mapping formula.
    // mapping functio.
    col = uTone(col); 
    
    // Subtle vignette.
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./32.);
    
  
    // Rough gamma correction and screen presentation.
    fragColor = pow(max(col, 0.), vec4(1./2.2));
    
}