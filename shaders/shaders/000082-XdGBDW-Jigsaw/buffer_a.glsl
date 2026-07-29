// Buffer A (buffer) — Jigsaw by Shane
// https://www.shadertoy.com/view/XdGBDW


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    // The 2D jigsaw piece function is by far the most expensive, but it's 
    // only called once per frame, then passed to the raymarching function
    // via the "Buf A" texture, which is a huge saving. Without this step,
    // attempting to raymarch this in realtime would stop a lot of systems 
    // in their tracks.
    //
    vec2 p = fragCoord.xy/iResolution.xy;
    
    // The camera movement is provided via texture scrolling. We're doing it
    // this way, because it'd be difficult to wrap this particular pattern. 
    // Not impossible, but compilicated. Therefore, the texture area has to 
    // span beyond the canvas borders to keep it withing the camera's field
    // of view. Otherwise, the effect wouldn't work.
    //
    fragColor = jigsaw4(vec3(p*4. - moveXY(iTime), 0));
    
}