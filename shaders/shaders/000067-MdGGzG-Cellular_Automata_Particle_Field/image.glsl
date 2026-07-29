// Image (image) — Cellular Automata Particle Field by alleycatsphinx
// https://www.shadertoy.com/view/MdGGzG

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texture(iChannel0, fragCoord.xy/iResolution.xy);
}	