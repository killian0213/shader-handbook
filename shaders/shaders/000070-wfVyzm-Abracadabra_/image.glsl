// Image (image) — Abracadabra 🪄👻 by Jaenam
// https://www.shadertoy.com/view/wfVyzm

/*================================
=          Abracadabra           =
=         Author: Jaenam         =
================================*/
// Date:    2025-12-02
// License: Creative Commons (CC BY-NC-SA 4.0)

//Twigl version: https://x.com/Jaenam97/status/1995858045285343420?s=20

// Motion Blur learnt from @FabriceNeyret2
#define t ( iTime + fract(1e4*sin(dot(I,vec2(137,-13))))* iTimeDelta )//
#define S smoothstep//

void mainImage( out vec4 O, vec2 I )
{   
   
    float i,d,s,m,l,
    x = abs(mod(t/4., 2.) - 1.),
    a = x < .5  ? -(exp2(12.*x - 6.) * sin((20.*x - 11.125) * 1.396)) / 2.
                          : (exp2(-12.*x + 6.) * sin((20.*x - 11.125) * 1.396)) / 2. + 1.;                
    vec3 p,k,r = iResolution;

    for(O*=i; i++<1e2; O += max(sin(vec4(1,2,3,1)+i*.5)*1.3/s,-length(k*k))){

        k = vec3((I+I-r.xy)/r.y*d, d-9.);
        
        if(abs(k.x)>6.) break;
        
        l = length(.2*k.xy-vec2(sin(t)/9.,.6+sin(t+t)/9.));

        k.y < -5. ? k.y = -k.y-10., m = .5 : m = 1.;
        
        k.xz *= mat2(cos(a*6.28 + k.y * .3 * S(.2, .5, x) * S(.7, .5, x)+ vec4(0,33,11,0)));
        
        for(p=k*.5,s = .01; s < 1.; s += s)
            p.y += .95+abs(dot(sin(p.x + 2.*t+p/s),  .2+p-p )) * s;
        
        l = mix(sin(length(k*k.x)),mix(sin(length(p)),l,.5-l),S(5.5, 6., p.y));

        p = abs(k);
        d += s =.012+.09*abs(max(sin(length(k)+l),
                                max(max(max(p.x, p.y), p.z), dot(p, vec3(.577)) * mix(.5, .9, a))-3.)-i/1e2);
    }
 
    O = tanh(O*O/1e6)*m;  
}
