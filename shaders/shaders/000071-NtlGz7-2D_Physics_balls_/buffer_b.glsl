// Buffer B (buffer) — 2D Physics (balls) by TDM
// https://www.shadertoy.com/view/NtlGz7

/*
 * Collision solver (1st iteration)
 */

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    int id = int(fragCoord.x);
    if(id >= NUM_OBJECTS) discard;
    vec2 ires = 1.0 / iChannelResolution[0].xy;
    
    // solve collisions    
    Body body = getBody(iChannel0, ires, id);
    solve(iChannel0,body,id,ires);
    
    // store
    fragColor = vec4(0.0);
    storeBody(id, body, fragColor, fragCoord);
}