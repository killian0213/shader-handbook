// Image (image) — Pseudo Realtime Path Tracing by Shane
// https://www.shadertoy.com/view/ssycDR

/*

    Pseudo Realtime Path Tracing
    ----------------------------
    
    See "Buffer A" for an explanation.
    
*/

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // The other buffer has a maximum Y-resolution of 540 set, which 
    // means any pixels outside that are not rendered. On a 1980x1080
    // fullscreen resolution, this means roughly a quarter of the pixels
    // are rendered, which is a huge saving. Of course, this also means
    // that the scene needs to be upscaled, which will make things less
    // crisp, but you can't have everything. :)
    //
    // By the way, this tip came from Shadertoy user, Spalmer, who has
    // a heap of interesting work for anyone interested:
    // https://www.shadertoy.com/user/spalmer
    //
    float maxRes = 540.;
    vec2 uv = fragCoord/iResolution.xy;
    // If the resolution exceeds the maximum, upscale.
    if(iResolution.y>maxRes) uv = (uv - .5)*maxRes/iResolution.y + .5;
    
    // Retrieving the stored color.
    vec4 col = texture(iChannel0, uv);
     
    #define HARDWARE_BLOOM
    #ifdef HARDWARE_BLOOM
    // Hardware bloom that I made up on the spot. It's
    // not as nice as software bloom, but it's way cheaper
    // and definitely easier to implement.
    float a = 1., w = 1.;
    vec4 colBloom = vec4(0);
    for (int i = 0; i<8; i++){
        vec2 jit = (texture(iChannel1, uv + vec2(i*57, i*27)/128. + 
                             fract(iTime)).xy - .5)/iResolution.y;
        colBloom += texture(iChannel0, uv + jit*16., float(i)/2.)*w;
        a += w;
        w *= .7071;
    }
    colBloom /= a;
    
    col += smoothstep(vec4(.05), vec4(1), colBloom)*2.;
    #endif
 

    // I should probably tone map here, but the lighting isn't exactly
    // realistic, plus I like the contrast here.
    #ifdef HARDWARE_BLOOM
    col = tanh(col); // Cheap sigmoid-based toning.
    #endif

    // Rough gamma correction and screen presentation.
    fragColor = pow(col, vec4(1./2.2));
    
}