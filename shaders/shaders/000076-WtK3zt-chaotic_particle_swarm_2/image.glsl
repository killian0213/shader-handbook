// Image (image) — chaotic particle swarm 2 by FabriceNeyret2
// https://www.shadertoy.com/view/WtK3zt

// Commented refactored fork of unnick's shader https://shadertoy.com/view/ttK3Rc
// more refs: https://www.shadertoy.com/results?query=voronoi%20particle%20tracking&sort=newest
//            rory618's: https://www.shadertoy.com/user/rory618 [which one seminal ?]
//            wyatt's: https://www.shadertoy.com/results?query=wyatt [which one seminal ?] https://www.shadertoy.com/view/MlVfDR
//            https://www.shadertoy.com/view/4sK3WK
// another refactored/commented (very different) one: https://www.shadertoy.com/view/3ty3Dy

//[unnick said:]
//its still a mystery to me how to make particles interact with each other though
//ive seen some people use the gauss-seidel method to solve a poisson equation
//but idk how that works

//i use a divergence-free vector field together with the midpoint method to move particles

#define keyFlip(k) ( texelFetch( iChannel3, ivec2(k,2), 0 ).x > .5 )

void mainImage(out vec4 O,  vec2 _pos) 
{
    vec4 state = T(_pos); // we assume particle pos(x,y) is very close of storage(x,y)
    
    O = keyFlip(32)
        ? vec4( fract(state.xy/30.), state.z, 0) // displays particle-voronoi pos & id
        :   exp(-.2*l2( state.xy - _pos ) )      // draw gaussian spot
          * sqrt( sin((state.z + vec4(0,1,2,0)/3.) * tau) * .5 + .5); // hue
}
