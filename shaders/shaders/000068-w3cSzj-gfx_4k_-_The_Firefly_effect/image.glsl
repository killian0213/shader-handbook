// Image (image) — gfx 4k - The Firefly effect by iapafoto
// https://www.shadertoy.com/view/w3cSzj

//#define COMPOSITION_HELPER

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 R = iResolution.xy, q = fragCoord / R;
    vec3 col = texture( iChannel0, q).xyz; 

    // gamma
    col = pow( col, vec3(.4545) );
    // vignetting
    col *= .1+.9*sqrt(16.*q.x*q.y*(1.-q.x)*(1.-q.y));
    
    #ifdef COMPOSITION_HELPER
        col = mix(vec3(0), col, .5+.5*smoothstep(0., 2., abs(fragCoord.x-R.x*.33)) );
        col = mix(vec3(0), col, .5+.5*smoothstep(0., 2., abs(fragCoord.x-R.x*.66)) );
        col = mix(vec3(0), col, .5+.5*smoothstep(0., 2., abs(fragCoord.y-R.y*.33)) );
        col = mix(vec3(0), col, .5+.5*smoothstep(0., 2., abs(fragCoord.y-R.y*.66)) );
    #endif // COMPOSITION_HELPER
    fragColor = vec4(col,1.);
}