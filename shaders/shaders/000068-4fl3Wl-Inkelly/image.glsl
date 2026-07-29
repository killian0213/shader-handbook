// Image (image) — Inkelly by leon
// https://www.shadertoy.com/view/4fl3Wl

// Inkelly
// leon denise 2023-12-27

// other variations
// https://www.shadertoy.com/view/4cs3Rs
// https://www.shadertoy.com/view/4cX3WS

// render pass

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    float d = length(uv-.5);
    
    // blue noise
    vec4 blu = texture(iChannel1, fragCoord/iChannelResolution[1].xy);
    
    // background
    d += blu.x*.2;
    vec3 color = vec3(1)*smoothstep(2., 0., d);
    
    // edge
    float feather = .02;
    vec3 ep = vec3(1./iChannelResolution[0].xy,0);
    #define T(u) smoothstep(0., feather, texture(iChannel0, uv+u).r)
    float mr = T(.0);
    float edge = abs(T(ep.xz)-mr)+abs(T(-ep.xz)-mr)+abs(T(ep.zy)-mr)+abs(T(-ep.zy)-mr);
    color *= vec3(1.-clamp(edge/2., 0., 1.));
    
    fragColor = vec4(color,1.0);
}