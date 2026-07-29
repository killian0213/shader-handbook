// Buffer A (buffer) — Fast Separable Blur by iq
// https://www.shadertoy.com/view/Xd33Rf

// Created by inigo quilez - iq/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord/iResolution.xy;
    
    p.x += 0.1*sin(6.0*p.y + 0.5*iTime);
    p.y += 0.5*sin(4.0*p.x + 0.5*iTime);
    
    vec3 col = texture( iChannel0, p ).zyx * 1.5;

    fragColor = vec4( col, 1.0 );
}

