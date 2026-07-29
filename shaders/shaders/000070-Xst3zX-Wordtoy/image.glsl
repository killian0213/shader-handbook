// Image (image) — Wordtoy by poljere
// https://www.shadertoy.com/view/Xst3zX

// Created by Pol Jeremias - poljere/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

/////////////////////////////////////////////////////////////
// POST PROCESS
//
// This pass adds post processing effects on top of the rest.
/////////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iChannelResolution[0].xy;
    vec3 col = vec3(0.01, 0.05,0.01) + 0.1*sin(iTime * 2.0 + fragCoord.y * 2.0);

    float amount = 0.002 * length(uv - vec2(0.5,0.5));
    col.r += texture( iChannel0, vec2(uv.x+amount,uv.y) ).r;
    col.g += texture( iChannel0, uv ).g;
    col.b += texture( iChannel0, vec2(uv.x-amount,uv.y) ).b;
    
    fragColor = vec4(col, 1.0);
}