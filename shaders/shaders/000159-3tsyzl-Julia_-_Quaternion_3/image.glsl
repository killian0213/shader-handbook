// Image (image) — Julia - Quaternion 3 by iq
// https://www.shadertoy.com/view/3tsyzl

// Copyright Inigo Quilez, 2020 - https://iquilezles.org/
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

// The Julia set of f(z) = z³ + c, as rendered for the Youtube
// video called "Geodes": https://www.youtube.com/watch?v=rQ2bnU4dkso
//
// I simplified a few things, reduced the number of GI bounces
// and did some temporal reprojection to keep it more or less
// real-time while looking similar to the one in the video.
//
// Explanations:
//  https://iquilezles.org/articles/distancefractals
//  https://iquilezles.org/articles/orbittraps3d
//
// Related shaders:
//
// Julia - Quaternion 1 : https://www.shadertoy.com/view/MsfGRr
// Julia - Quaternion 2 : https://www.shadertoy.com/view/lsl3W2
// Julia - Quaternion 3 : https://www.shadertoy.com/view/3tsyzl


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = fragCoord / iResolution.xy;

    vec3 col = texture( iChannel0, p ).xyz;

    // color grade
    col = col*2.0/(1.0+col);
    col = pow( col, vec3(0.4545) );
    col = pow(col,vec3(0.85,0.97,1.0));
    col = col*0.5 + 0.5*col*col*(3.0-2.0*col);

    // vignette
    col *= 0.5 + 0.5*pow( 16.0*p.x*p.y*(1.0-p.x)*(1.0-p.y), 0.1 );
    
    fragColor = vec4( col, 1.0 );
}