// Image (image) — Some boxes by iq
// https://www.shadertoy.com/view/Xd2fzR

// Copyright Inigo Quilez, 2018 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work in any form,
// including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it.
// I share this Work for educational purposes, and you can link to it,
// through an URL, proper attribution and unmodified screenshot, as part
// of your educational material. If these conditions are too restrictive
// please contact me and we'll definitely work it out.


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // source
    vec3 col = texelFetch( iChannel0, ivec2(fragCoord), 0 ).xyz;
    
    // gain
    col *= 1.7/(1.0+col);
    
    // burn the highlights
    float g = dot(col,vec3(0.3333));
    col = mix( col, vec3(g), min(g*0.2,1.0) );
    
    // gamma
    col = pow( col, vec3(0.4545) );

    // instafilter
    col = 1.15*pow( col, vec3(0.9,0.95,1.0) ) + vec3(-0.04,-0.04,0.0);

    // vignete     
	vec2 q = fragCoord / iResolution.xy;
    col *= 0.5 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
    
    // output
    fragColor = vec4( col, 1.0 );
}