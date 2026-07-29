// Image (image) — Swirl Spin by TekF
// https://www.shadertoy.com/view/XsyGzz

void mainImage( out vec4 f, in vec2 g )
{
    f = pow(texture(iChannel0, g / iResolution.xy),vec4(1.0/2.2));
}