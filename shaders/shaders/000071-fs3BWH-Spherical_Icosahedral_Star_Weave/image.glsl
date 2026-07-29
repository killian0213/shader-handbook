// Image (image) — Spherical Icosahedral Star Weave by Shane
// https://www.shadertoy.com/view/fs3BWH

/*

    Spherical Icosahedral Star Weave
    --------------------------------
    
    See "Buffer A" for an explanation.
    
*/

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Rendering the buffer.
    //
    // See Buffer A for an explanation.
    
    // Retrieving the stored color.
    vec4 col = texture(iChannel0, fragCoord/iResolution.xy);

    // Rough gamma correction and screen presentation.
    // "col" should already be above zero, but we're capping it anyway.
    fragColor = sqrt(max(col, 0.));
    
}