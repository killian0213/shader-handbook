// Image (image) — Crowdy waves 2 by FabriceNeyret2
// https://www.shadertoy.com/view/3ty3Dy

// Commented refactored fork of "Crowdy waves" by rory618. https://shadertoy.com/view/ttyGWw
// All-in-one-buffer variant of the Voronoi particle tracking method: https://www.shadertoy.com/view/wlcXRS

// more refs: https://www.shadertoy.com/results?query=voronoi%20particle%20tracking&sort=newest
//            rory618's: https://www.shadertoy.com/user/rory618 [which one seminal ?]
//            wyatt's: https://www.shadertoy.com/results?query=wyatt [which one seminal ?] https://www.shadertoy.com/view/MlVfDR
//            https://www.shadertoy.com/view/4sK3WK
// Another refactored/commented (very different) one: https://www.shadertoy.com/view/WtK3zt

void mainImage( out vec4 O, vec2 I )
{
    O = keyFlip(32)
        ? T1(I)/(R.x*R.y)*N    // space key: draw Id/Voronoi
        : T2(I);               // draw trace
}