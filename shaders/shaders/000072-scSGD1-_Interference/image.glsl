// Image (image) —  Interference by kishimisu
// https://www.shadertoy.com/view/scSGD1

/* Interference by @kishimisu (2026) - https://www.shadertoy.com/view/scSGD1

   Playing with logarithmic space repetition
   to create a "closer and closer" effect
*/

#define R(a) *= mat2(cos(a + vec4(0,33,11,0)))//
#define L(x) length(x)

void mainImage(out vec4 O, vec2 F) {

    float a, r, t = iTime;
    
    for (O *= a; a < 40.; a++) {
        vec3 i = iResolution, f,
             p = r * normalize(vec3((F+F-i.xy)/i.y, 1));
             
        p.z -= 3.;
        p.xz R(.3);
        p.zy R(sin(t/4.)*.3 + .9);
        p.xy R(t/4.);
        p.x = abs(p.x) - 1.;
        
        O += (.01 + .02*smoothstep(.9, 1., cos(L(p.xy+p.z)*2.-t)))*
             (1. + cos(L(p.xy)*2. + a*.2 + vec4(0,1,2,0)))/L(p.xy);
             
        p.yx R(atan(p.y, p.x));
        p.zx R(atan(max(p.z, 0.), p.x));
        
        f.x = pow(.67, floor(t - log(p.x)/.4) - t);
        r += min(L(p.xy), min(
             abs(L(p - f) - f.x*.2), 
             abs(L(p - f*.67) - f.x*.134)
        )) + .01;
    }
    
    O = tanh(O);
}