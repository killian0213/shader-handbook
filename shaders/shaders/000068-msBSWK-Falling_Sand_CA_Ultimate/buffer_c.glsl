// Buffer C (buffer) — Falling Sand CA Ultimate by gelami
// https://www.shadertoy.com/view/msBSWK


#define BUFFER_OFFSET 2

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    initState(fragCoord, iFrame+2);
    ivec2 p = ivec2(floor(fragCoord));
    
    if (p == IRES-1 || p == IRES-ivec2(2, 1) || iFrame < 2)
    {
        fragColor = sampleTex0(p);
        return;
    }
    
    fragColor = simulate(iChannel0, p, IRES, iFrame, BUFFER_OFFSET);
}