// Image (image) — Protein by iq
// https://www.shadertoy.com/view/M3BfW3

// Copyright Inigo Quilez, 2024 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work, neither as it is or altered
// here on Shadertoy or anywhere else, in any form, including physical and digital. You
// cannot use this Work in commercial or non-commercial products, websites or projects.
// You cannot sell this Work and you cannot mint an NFT of it or train a neural network
// with it without permission. I share this Work for educational purposes; you can link
// to it, through an URL, proper attribution and unmodified screenshot, as part of your
// educational material. If these conditions are too restrictive, please contact me and
// we'll definitely work it out.


// A protein-like structure made of 32,767 spheres, raytraced.
//
// It's similar to my Kindercrasher 4 kilobytes demo from 2008
// (https://www.pouet.net/prod.php?which=50526), but raytraced
// rather than rasterized and computing real ambient occlusion
// instead of Screen Space Ambient Occlusion. So, it's running
// in 16 years newer GPUs yet it's hundreds of times slower :)
//
// The code is mostly a copy of my previous BVH shader example
// here: https://www.shadertoy.com/view/lsBSWK


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // dof
    const float maxCoC = 0.015;       // max Circle of Confusion in screen space (0,1)
    const float focusPlane = 1.8;    // distance to the focus plane (spherical shell)
    const float focusRate  = 1.5;    // how quickly to defocuses
    const ivec2 kV = ivec2(32,13);
    float ran = texelFetch(iChannel1,ivec2(fragCoord)&1023,0).x;
    vec4  acc = vec4(0.0);
	for( int i=0; i<kV.x; i++ )
    {
        float rad = float(i)/float(kV.x-1);
        float ang = 6.283185*(float(kV.y)*rad + ran);
        vec2  off = maxCoC*sqrt(rad)*vec2(cos(ang),sin(ang));
        vec4  tmp = textureLod(iChannel0,(fragCoord+iResolution.y*off)/iResolution.xy,0.0); 
        
        float depth = tmp.w;
        vec3  color = tmp.xyz;
        float coc   = 0.0001 + maxCoC*min(1.0,focusRate*abs(depth-focusPlane)/depth);
        if( dot(off,off) < (coc*coc) )
        {
            acc += vec4(color,1.0)/(coc*coc);
        }
    }
    vec3 col = acc.xyz / acc.w;
    
    // gamma
    col = pow( col, vec3(0.4545) );
    
    // color grade
    col = pow( col, vec3(0.7,0.9,1.0) );

    // vignette     
    vec2 q = fragCoord/iResolution.xy;
    col *= 0.5 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );

    // clamp
    col = clamp( col, 0.0, 1.0 );

    // output
    fragColor = vec4( col, 1.0 );
}