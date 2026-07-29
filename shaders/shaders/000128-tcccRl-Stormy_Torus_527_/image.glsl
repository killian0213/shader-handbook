// Image (image) — Stormy Torus [527] by Jaenam
// https://www.shadertoy.com/view/tcccRl

/*================================
=          Stormy Torus          =
=         Author: Jaenam         =
================================*/
// Date:    2025-11-24
// License: Creative Commons (CC BY-NC-SA 4.0)

// -10 @OldEclipse
// -12 @FabriceNeyret2
// -2 Me :D
// -9 @bug

void mainImage( out vec4 O, vec2 I )
{
    float i,d,w, t = iTime, m = 1.;
    vec3  p,k,r = iResolution,Z;
     
    for( O*= i ; 
         i++ < 1e2 && abs(p.x) < 6. ; 
         
         d += w = .01 + .07* abs( max( mix( sin( length( ceil(4.*k.z) + k) ) 
               , sin( length(p) - 1. ) 
               , smoothstep(5., 5.5, p.y)
               ), sqrt( dot(k,k) +16. -8.*length(k.xy) ) -1.5
                                    ) -i/150. ),
         O += max( 1.3/w * sin( vec4(1,2,3,1) + i*.5 ) , -length(k*k) )
       )

        for(
        
            k = vec3( (I+I-r.xy)/r.y *d, d - 10.),  
            k.xz *= mat2( cos(sin(t/2.)*.785 + vec4(0,33,11,0))),

            k.y < -6.3
              ? k.y = -k.y -9.,
                m = .5 : m,
        
            p = k*.5, w = .01 ; w < .2 ; w += w )
            p.yz += cos( p.xy*.01 ) 
                  - abs( dot( sin(.02*p.z +.03*p.y +t+t + .3*p/w ), w+ Z ));     
    
    O = tanh(O*O/1e6)*m;  
}


/* Twigl Version

https://x.com/Jaenam97/status/1992945636178575564?s=20

*/

/* Not so golfed version

void mainImage( out vec4 O, vec2 I )
{
    float i,d,w,s,n,t=iTime,m=1.;
    vec3 p,k,r = iResolution;
    mat2 R = mat2(cos(sin(t/2.)*.785 +vec4(0,33,11,0)));
    
    for(O*=i; i++<1e2; O += max(sin(vec4(1,2,3,1)+i*.5)*1.3/w,-length(k*k))){
    
        p = vec3((I+I-r.xy)/r.y*d, d-10.);
        
        if(abs(p.x)>6.) break;
        
        p.xz *= R;

        if(p.y < -6.3) {
            p.y = -p.y-9.;
            m = .5;
        }
        
        k=p;

        for(p*=.5,n = .01; n < .2; n += n)
            p.yz += cos(p.xy*.01) - abs(dot(sin(.02*p.z+.03*p.y+2.*t + .3*p/n), p-p+n));
            
        s = length(k.xy)-4.;
        w = mix(sin(length(ceil(k*4.).z+k)), sin(length(p)-1.), smoothstep(5., 5.5, p.y));
        
        d += w =.01+.07*abs(max(w,sqrt(s*s+k*k).z-1.5)-i/150.);
       
    }
    
    O = tanh(O*O/1e6)*m;  
}
*/
