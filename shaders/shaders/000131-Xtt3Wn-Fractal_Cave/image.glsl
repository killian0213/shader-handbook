// Image (image) — Fractal Cave by iq
// https://www.shadertoy.com/view/Xtt3Wn

// Copyright Inigo Quilez, 2016 - https://iquilezles.org/
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
//
// More info in this tutorial:
// https://iquilezles.org/articles/simplepathtracing
//
// You can buy a metal print of this shader here:
// https://www.redbubble.com/i/canvas-print/Cave-by-InigoQuilez/39845435.5Y5V7


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // get color
    vec3 col = texelFetch( iChannel0, ivec2(fragCoord), 0 ).xyz;
    col /= float(1+iFrame);
    col = pow( col, vec3(0.4545) );
    
    // color grading
    col = pow( col, vec3(0.8) ); col *= 1.6; col -= vec3(0.03,0.02,0.0);
    
    // vigneting
	vec2 p = fragCoord/iResolution.xy;
    col *= 0.5 + 0.5*pow( 16.0*p.x*p.y*(1.0-p.x)*(1.0-p.y), 0.1 );
    
    fragColor = vec4( col, 1.0 );
}