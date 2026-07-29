// Sound (sound) — Sphere Gears by iq
// https://www.shadertoy.com/view/tt2XzG

// Created by inigo quilez - iq/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


float base( in float time )
{
    float y = 0.0;

    {
    float f = 220.0;
    float im = 10.0 + 9.0*sin(0.25*6.2831*time);
    float v = 0.0;
    v += 1.0*sin( 6.2831*f*time*1.0 + 1.0*im*sin(0.25*6.2831*f*time) );
    v += 0.3*sin( 6.2831*f*time*0.5 + 8.0*im*sin(0.5*6.2831*f*time) );
    v *= exp(-2.0*fract(8.0*time));
    y += 0.3*v;
    }

    {
    float t = fract(time*2.0);
    float f = 220.0*exp(-5.0*t);
    float a = sin( 6.2831*f*t*0.5 );
    float v = 0.0;
    v += clamp(a*8.0,-1.0,1.0)*(exp(-10.0*t) + exp(-1.0*t));
    v += a*8.0*exp(-1.0*t);
    y += 0.4*v;
    }

    return y;
}

float sfx1( float time )
{
    float y = 0.0;
    
    float t = fract(0.5+time/10.0);

    {
    float v = -1.0+2.0*fract(111.731*fract(233.371*time));
    v *= smoothstep(0.09,0.11,t)-smoothstep(0.11,0.12,t) + smoothstep(0.87,0.88,t)-smoothstep(0.88,0.90,t);
    y += v;
    }
    
    {
    float v = -1.0+2.0*fract(111.731*fract(433.371*time));
    v *= smoothstep(0.15,0.17,t)*exp(-300.0*max(t-0.17,0.0)) + smoothstep(0.81,0.83,t)*exp(-250.0*max(t-0.83,0.0));
    y += v;
    }

    {
    float v = -1.0+2.0*fract(111.731*fract(433.371*time));
    v *= smoothstep(0.2,0.201,t)-smoothstep(0.201,0.22,t)+ smoothstep(0.75,0.77,t)-smoothstep(0.78,0.79,t);
    y += v;
    }

    return y;
}    
    
float sfx2( float time )
{
    float y = 0.0;
    
    float t = fract(0.5+time/10.0);
    
    {
    float v  = 0.5*(-1.0+2.0*fract(13.731*fract(1133.371*time)));
          v += 1.0*(-1.0+2.0*fract( 7.231*fract(971.8671*time)));
    v *= exp(-8.0*fract(0.5*12.0*time));
    v *= smoothstep(0.19,0.191,t)- smoothstep(0.75,0.77,t);
    y += 0.5*v;
    }

    return y;
}

vec2 mainSound( in int samp, float time )
{
    float y = 0.0;
    float s = 1.0;
    float o = 0.0;
    for( int i=0; i<5; i++ )
    {
        y += s*base( time-o );
        y += s*sfx1( time-o );
        s *= 0.2;
        o += 0.25;
    }
 
    y += sfx2(time);
    
    return vec2(y*0.15);
}