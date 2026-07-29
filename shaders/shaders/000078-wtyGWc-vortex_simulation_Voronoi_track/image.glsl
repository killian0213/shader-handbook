// Image (image) — vortex simulation+Voronoi track by FabriceNeyret2
// https://www.shadertoy.com/view/wtyGWc

// optimized version of transitional https://shadertoy.com/view/wtGGWc
//    Fork of vortex simulation  https://shadertoy.com/view/lsy3zR
//             inspired from http://evasion.imag.fr/~Fabrice.Neyret/demos/JS/Vort.html
//    + Voronoï particle tracking https://www.shadertoy.com/view/3ty3Dy


void mainImage( out vec4 O,  vec2 U )
{
    O = keyFlip(32)
     // ? T1(U).rrrr/(Nf*Nf)   // space key: draw Id/Voronoi ( closest )
        ? T1(U)/(Nf*Nf)        // space key: draw Id/Voronoi ( RGBA = 1st-4th closest )
        : T0(U);               // draw trace
}