// Image (image) — Hyperloop [439 chars] by kishimisu
// https://www.shadertoy.com/view/4XVGWh

/* Hyperloop by @kishimisu (2024) - https://www.shadertoy.com/view/4XVGWh
   [442 chars -> 439 chars by Snoopeth]
   
   Playing with a different kind of space repetition using logarithmic scaling
   
   This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 
   International License (https://creativecommons.org/licenses/by-nc-sa/4.0/deed.en)
*/

// If you're getting a black image, try uncommenting this line:
// #define tanh(x) smoothstep(0., 1., x)

#define r *= mat2(cos(vec4(0,33,11,0) +//
#define l length(P

void mainImage(out vec4 O, vec2 F) {    

    vec3    H   = iResolution, 
            Y   , 
            P   ;
    float   E   = iTime,
            R   ,
            L   = .1, o;      
    for (   O   *= o; o++ < 50.; 
            O   += .02*(tanh(R*1e3)+2.-2.*tanh(l.xy*7.)))*(.8+cos(log(L*L)+o*.07-E+vec4(0,1,2,0)))/++R)
            P   *= L / l = vec3(F+F-H.xy, H.y)),
            
            P.z--,
            P.xz r .3)),
            P.zy r 1.)),
            P.yx r round((atan(P.y, P.x) + E*.2) * 1.91) / 1.91 - E*.2)),
            Y.x = pow(.67, floor(E - log(P.x)/.4) - E),
            L += R = min(min(
                       l.xy),
                       l-Y    ) - Y.x*.2  ),
                       l-Y*.67) - Y.x*.134) * .8;    
}