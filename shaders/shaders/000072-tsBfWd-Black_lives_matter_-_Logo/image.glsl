// Image (image) — Black lives matter - Logo by iapafoto
// https://www.shadertoy.com/view/tsBfWd

// Created by sebastien durand - 2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------
// [iq] - Polygon-distance - https://www.shadertoy.com/view/wdBXRW
//-----------------------------------------------------

                                    int[]
                                   f=int[]  
                                  (8,40,62,
                                 70,78,84,   96,
                                106,27,134 ,32,95,5,
                               54,25,23,   40, 28,54,
                                   36,    55,45,41,
                            48,            31,42,    32,50,
                           27,52,36,56,      57,    90,53,95
                         ,57,96,54,136,58,         134,61,95,  
                         63,95,44,59,57,61,64   ,65,73,75,  87,64,
                        87,73,76,99,74,134,66  ,64,85,42  ,95, 54,
                      73,72,54,57,    73,27,      85    ,40,66,61
                    ,40,50 , 56            ,48,        50,58,57,
                    35,49,30,58,14,61,    14,72,25,    58,44,
                     30,20,41,5,44,4,55   ,12,46,27            );
                      float P(int t,int    n,vec2 p){     float d
                       =1e3,s=1.;for(int    i=t,j=n-2;i < n; j =i,
                         i+=2){vec2 a=vec2  (-f[j],f[j+1]),c=vec2
                           (-f[i],f[i+1]),e   =a-c,w = p-c,b=w-e*
                            clamp(dot(w,e)/    dot(e,e),0., 1.);
                             d=min(d,dot(b,b)); bvec3 x=bvec3(p.
                              y>=c.y,p.y<a.y,e.  x*w.y>e.y*w.x)
                                ;s=all(x)|| all(   not(x))?-s:
                                  s;}return s*sqrt  (d);}void 
                                   mainImage(out       vec4 O,
                                     vec2 u) {vec2   R=/****/
                                     iResolution .  xy, p=88.
                                     *(R-u-u)/R.y;  float d=
                                    abs(length (p)  -75.)-5.;
   	                                vec4 k=texture  (iChannel0
                                    ,.01*iTime +p/   200.);for
                                    (int i=0;i<8;i   ++)d=min(
                                    d,P(f[i],f[i+1   ],p+k.xy
                                    +vec2(-50,62))   );O=/**/
                                   smoothstep(0.,1.  ,d +1.2*
                                   k)*vec4(.94,.9,   .15,1);}

