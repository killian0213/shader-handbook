// Image (image) — Falling Sand CA Ultimate by gelami
// https://www.shadertoy.com/view/msBSWK

// Fork of "Falling Sand CA v2" by gelami. https://shadertoy.com/view/DsSSRd
// 2022-12-12 20:12:05

// Falling Sand CA Ultimate by gelami
// https://www.shadertoy.com/view/msBSWK

/*
 *  An improved falling sand cellular automaton simulation
 *  
 *  Cells are processed in 2x2 blocks to simplify the neighborhood checks
 *  and allows them to be processed in parallel without race conditions.
 *  The blocks are then offset using a cyclic Margolus neighborhood offset to prevent bias
 *  Has multiple types of materials that can interact with each other different
 *
 *  The biggest change from the previous iterations is the introduction of
 *  swaps instead of a 1D linear mapping of state in each block.
 *  Each cell in a 2x2 block can switch its position with another cell in the same block,
 *  Leading to a simpler model that can support multiple types of materials
 *  
 *  Controls:
 *  Mouse: Draw Material
 *  0 - 9: Select Material Type
 *  
 *  Arrow Keys: Move Camera
 *  Plus/Minus: Zoom in/out
 *  Left/Right Brackets: Change Mouse Radius
 *  
 *  Space: Clear
 *  R: Reset
 *
 *  1: Smoke
 *  2: Fire
 *  3: Lava
 *  4: Water
 *  5: Sand
 *  6: Stone
 *  7: Wood
 *  8: Grass
 *  9: Wall
 *  0: Eraser
 *  
 *  This is one of 4 shaders that explores falling sand cellular automata in the GPU
 * 
 *  Previous entries:
 *  Falling Sand CA v1 - gelami
 *  https://www.shadertoy.com/view/DsjSzc
 *  
 *  Falling Sand CA v2 - gelami
 *  https://www.shadertoy.com/view/DsSSRd
 *  
 */

// Pixel Art Filtering by Klems
// https://www.shadertoy.com/view/MllBWf
vec2 getCoordsAA(vec2 uv)
{
    float w = 1.0; // 1.5
    vec2 fl = floor(uv + 0.5);
    vec2 fr = fract(uv + 0.5);
    vec2 aa = fwidth(uv) * w * 0.5;
    fr = smoothstep(0.5 - aa, 0.5 + aa, fr);
    
    return fl + fr - 0.5;
}

vec4 sampleTexAA(sampler2D ch, vec2 uv, vec2 res)
{
    return texture(ch, getCoordsAA(uv) / res);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    initState(fragCoord, iFrame+4);
    vec4 scene = texelFetch(iChannel0, IRES-1, 0);
    vec4 mouse = texelFetch(iChannel0, IRES-ivec2(2, 1), 0);
    float scale = scene.x;
    vec2 center = scene.zw;
    float radius = mouse.x;
    float id = mouse.y;
    float px = 1.0 / scale;
    
    fragCoord -= RES * 0.5;
    fragCoord /= scale;
    fragCoord += center;
    
    fragColor = sampleTexAA(iChannel2, fragCoord, RES);
    
    vec2 mousePos = (iMouse.xy - RES * 0.5) / scale + center;
    float brush = smoothstep(0.0, px, abs(length(fragCoord - mousePos) - radius));
    
    float bleft = texelFetch(iChannel3, ivec2(KEY_BRACKET_LEFT, 0), 0).r;
    float bright = texelFetch(iChannel3, ivec2(KEY_BRACKET_RIGHT, 0), 0).r;
        
    if (iMouse.z > 0.0 || bleft > 0.0 || bright > 0.0)
        fragColor = mix(fragColor, vec4(0.8), 1.0-brush);
    
    //fragColor = vec4(texelFetch(iChannel0, ivec2(fragCoord), 0));
}