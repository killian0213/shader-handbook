// Image (image) — Leizex (made in 2008) by iq
// https://www.shadertoy.com/view/XtycD1

// Copyright Inigo Quilez, 2018 - https://iquilezles.org/
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


// This is "Leizex", a procedural graphics I made in 2008, which was my 3rd ever
// raymarched SDF image (I was still investigating and learning the technique).
//
// I just copy pasted the code here to Shadertoy from my original C version I
// made at the time and made it more GLSL native. It has pretty much worked out
// of the box. And I could read it easily, I'm glad to see that after 10 years
// my coding habits haven't changed that much really, including vaiable names!
//
// Link to the original piece: https://iquilezles.org/demoscene/



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float x = fragCoord.x/iResolution.x;
    float f = clamp( 4.0*abs(x-0.5)-1.0, 0.0, 1.0 );

    // blur edges (could be optimized by making it separable,
    // sampling in-between texels and reading from mip 1 or 2)
    vec3 col = vec3(0.0);
    for( int m=-4; m<=4; m++ )
    for( int n=-4; n<=4; n++ )
    {
        vec2 uv = (fragCoord + f*2.0*vec2(float(m),float(n)) )/iResolution.xy;
        col += textureLod(iChannel0, uv, 0.0 ).xyz;
    }
    col /= 81.0;
    
    // vignette
    col *= 1.0-0.1*f;
    fragColor = vec4(col,1.0);
}