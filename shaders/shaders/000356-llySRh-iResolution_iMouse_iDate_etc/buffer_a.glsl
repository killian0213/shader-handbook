// Buffer A (buffer) — iResolution, iMouse, iDate, etc by FabriceNeyret2
// https://www.shadertoy.com/view/llySRh

// === standard  Main() ==========================

//#define R    iResolution.xy
#define T(U) texelFetch( iChannel0, ivec2(U), 0 )

void mainImage( out vec4 O, vec2 u )
{
    vec2 R = iResolution.xy,
         U = ( 2.*u - R ) / R.y;

    O = T(u);
}