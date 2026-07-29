// Image (image) — Sphere FBM Terrain by iq
// https://www.shadertoy.com/view/3dGSWR

// Copyright Inigo Quilez, 2019 - https://iquilezles.org/
// I am the sole copyright owner of this Work. You cannot
// host, display, distribute or share this Work neither as
// is or altered, in any form including physical and
// digital. You cannot use this Work in any commercial or
// non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it. You
// cannot use this Work to train AI models. I share this
// Work for educational purposes, you can link to it as
// an URL, proper attribution and unmodified screenshot,
// as part of your educational material. If these
// conditions are too restrictive please contact me.

// This is an experiment on creating a terrain using only sphere
// SDFs, without using noise, displacement or heightmaps. Instead
// the terrain is a true volumetric SDF; no approximations and no
// reduced marching steps needed, even for concave areas.
//
// The article that explains this technique can be found here:
//
//     https://iquilezles.org/articles/fbmsdf
//
// A video render can be found here:
//
//     https://www.youtube.com/watch?v=mCdlfdpN-AM
//
// A subtractive synthesis example of this technique, here: 
//
//     https://www.shadertoy.com/view/Ws3XWl


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col = texelFetch( iChannel0, ivec2(fragCoord), 0 ).xyz;

    // grading
    col = max(col*1.4-0.17,0.0);
    col.y *= 1.04;
    col.z += 0.01;

    // vignette
    vec2 p = fragCoord/iResolution.xy;
    col *= 0.5 + 0.5*pow( 16.0*p.x*p.y*(1.0-p.x)*(1.0-p.y), 0.1 );
         
    // cheap dithering
    col += sin(fragCoord.x*114.0)*sin(fragCoord.y*211.1)/512.0;
    
    fragColor = vec4( col, 1.0 );
}
