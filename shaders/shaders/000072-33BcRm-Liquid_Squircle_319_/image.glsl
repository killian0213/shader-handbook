// Image (image) — Liquid Squircle [319] by Jaenam
// https://www.shadertoy.com/view/33BcRm

/*================================
=        Liquid Squircle         =
=        Author: Jaenam          =
================================*/
// Date:    2025-10-17
// License: Creative Commons (CC BY-NC-SA 4.0)

void mainImage( out vec4 O, vec2 I )
{
    float i,d,s,t = iTime/2.;
    vec3 p, r = iResolution;
    mat2 R = mat2(cos(t+vec4(0,33,11,0)));
    
    for(O*=i; i++<1e2; O+=max(1.3*sin(vec4(3,2,1,1)+i*.3)/s,-length(p*p*p)))
    
        p = vec3((I+I - r.xy)/r.y*d*R, d-4.), p.xz*=R,
        d+=s=.012+.07*abs(max(sin(length(p*p)/.4),clamp(length(p*p)-4.,0.,2.))-i/1e2);  
   
    O=tanh(O*O/2e6);
     
}

/* Twigl version:

https://x.com/Jaenam97/status/1979203052507664513

*/