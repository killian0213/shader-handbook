// Image (image) — Color Grid 1 by iq
// https://www.shadertoy.com/view/4dBSRK

// Copyright Inigo Quilez, 2014 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2  px = 4.0*(-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y;
    
    float id = 0.5 + 0.5*cos(iTime + sin(dot(floor(px+0.5),vec2(113.1,17.81)))*43758.545);
    
    vec3  co = 0.5 + 0.5*cos(iTime + 2.0*id + vec3(0.0,1.0,2.0) );
    
    vec2  pa = smoothstep( 0.0, 0.2, id*(0.5 + 0.5*cos(6.2831*px)) );
    
    fragColor = vec4( co*pa.x*pa.y, 1.0 );
}