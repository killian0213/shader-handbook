// Image (image) — Lichtenberg figure by rory618
// https://www.shadertoy.com/view/3sl3WH

void mainImage( out vec4 o, in vec2 i )
{
    o = texture(iChannel0, i/iResolution.xy)/vec4(iFrame);
    o = log(o*1000.+1.)/7.;
}