// Image (image) — Cubescape Pixel by iq
// https://www.shadertoy.com/view/43GyzW

// Copyright Inigo Quilez, 2025 - https://iquilezles.org/
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

// Made about two years ago as a variation of https://www.shadertoy.com/view/Msl3Rr
// but published now. You might need to restart the shader to get the sound to work.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    int kPixelSize = int(2.0 + iResolution.y/360.0);

    ivec2 p = ivec2(fragCoord)/kPixelSize;
    
    vec4 col = texelFetch( iChannel0, p, 0 );

    // borders
    float da00 = texelFetch( iChannel0, p+ivec2(0,0), 0 ).w;
    float da10 = texelFetch( iChannel0, p+ivec2(1,0), 0 ).w;
    float da01 = texelFetch( iChannel0, p+ivec2(0,1), 0 ).w;
    float da11 = texelFetch( iChannel0, p+ivec2(1,1), 0 ).w;
    float fa00 = mod(da00,6.0), id00 = floor(da00/6.0);
    float fa10 = mod(da10,6.0), id10 = floor(da10/6.0);
    if( abs(da01-da00)>0.5 || 
        abs(id10-id00)>0.5 ||
       (abs(fa10-fa00)>0.5 && abs(da11-da10)<0.5) ) col.xyz *= 0.4;

    // vignette
	vec2 q = fragCoord/iResolution.xy;
    col *= 0.1 + 0.8*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );

    fragColor = vec4( col.xyz, 1.0 );
}
