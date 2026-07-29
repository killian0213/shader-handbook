// Sound (sound) — Mechanical by iq
// https://www.shadertoy.com/view/XslXW2

// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec2 mainSound( in int samp, float time )
{
    time -= 0.16;

    float si = mod( floor(time*0.25), 2.0 );

    float y = 0.0;

    
    y += 0.3*sin( 6.2831*440.0*time +  8.0*sin(0.87*6.2831*440.0*time) ) * exp(  -8.0*fract(time) );
    y += 0.3*sin( 6.2831*440.0*time + 16.0*sin(0.87*6.2831*440.0*time) ) * exp( -10.0*fract(time) );
    y += 0.1*sin( 6.2831*440.0*time + 32.0*sin(0.87*6.2831*440.0*time) ) * exp( -12.0*fract(time) );
    y += 0.4*si*smoothstep(-0.2,0.2,sin( 6.2831*880.0*time + 16.0*sin(1.25*6.2831*880.0*time) ) * exp( -20.0*fract(4.0*time) ));

    y += 0.6*(-1.0+2.0*fract(55.0*time)) * exp( -4.0*(fract(time+0.5)) );
    y += 0.2*sin( 6.2831*1.0*time )*sin( 6.2831*440.0*time ) * exp( -1.0*(1.0-fract(time)) );

    y += 0.9*(1.0-si)*smoothstep( -0.05, 0.05, sin( 150.0*exp(-40.0*fract(time+0.5) ) ) );
    y += 0.5*(-1.0 + 2.0*fract(sin(100.0*time)*43758.5453123)*exp(-20.0*fract(time)));
    y += 1.2*(1.0-si)*sin( 100.0*exp(-15.0*fract(time) ) );
    
    y *= 0.5;
    y *= smoothstep( 0.0, 2.0, time );
    
    return vec2(y, y);
}