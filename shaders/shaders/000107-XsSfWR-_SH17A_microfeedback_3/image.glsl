// Image (image) — [SH17A] microfeedback 3 by victor_shepardson
// https://www.shadertoy.com/view/XsSfWR

void mainImage(out vec4 c, vec2 u)
{
    c = .5+.5*texelFetch(iChannel0, ivec2(u),0);
}