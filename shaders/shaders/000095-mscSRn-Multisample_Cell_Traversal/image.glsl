// Image (image) — Multisample Cell Traversal by Shane
// https://www.shadertoy.com/view/mscSRn

/*

    Multisample Cell Traversal
    --------------------------

    See "Buffer A" for an explanation.

*/



void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Coordinates.
    vec2 uv = fragCoord/iResolution.xy;
    
    // Retrieving the stored color.
    vec4 col = texture(iChannel0, uv);
    
    /*
    // Chromatic aberration.
    // Pixel spread. Aesthetically, it's difficult to decide how you want to deal
    // with different resolutions. You'll either want a specific pixel shift or a
    // percentage shift based on physical screen distances.
    float px = min(2./450., 2./iResolution.y);//max(2./450., 2./mix(450., maxRes, .333));//
    vec4 r = texture(iChannel0, uv - vec2(px, 0)); // Red shifted to the right.
    vec4 g = texture(iChannel0, uv); // Green in the middle.
    vec4 b = texture(iChannel0, uv - vec2(-px, 0)); // Blue shifted to the left.
    vec4 col = vec4(r.x, g.y, b.z, 1); // Plain old primary RGB.
    //vec4 col = vec4(g.x, b.y, r.z, 1); // Alternate secondary RGB, or whatever you call it. :)
    */
    
        // Hardware bloom that I made up on the spot. It's
    // not as nice as software bloom, but it's way cheaper
    // and definitely easier to implement.
    float a = 0., w = 1.;
    vec4 col2 = vec4(0);
    for (int i = 0; i<6; i++){
        vec2 jit = (texture(iChannel1, uv + float(i)/6. + fract(iTime)).xy - .5)/iResolution.y;
        col2 += texture(iChannel0, uv + jit, float(i)/2.)*w;
        a += w;
        //w *= .7071;
    }
    col2 /= a;
    
    col += smoothstep(0., 1., col2)*2.;

    
    // Subtle vignette.
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./32.);
    
  
    // Rough gamma correction and screen presentation.
    fragColor = pow(max(col, 0.), vec4(1./2.2));
    
}