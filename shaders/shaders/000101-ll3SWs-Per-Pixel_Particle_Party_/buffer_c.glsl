// Buf C (buffer) — Per-Pixel Particle Party! by huwb
// https://www.shadertoy.com/view/ll3SWs


// accumulation buffer for particle trails
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    fragColor.zw = vec2(0.);
    fragColor.xy = .75 * texture( iChannel1, uv ).xy;
    vec2 vel = texture(iChannel0,uv).xy;
    if( dot(vel,vel) != 0. ) fragColor += 1.;
}
