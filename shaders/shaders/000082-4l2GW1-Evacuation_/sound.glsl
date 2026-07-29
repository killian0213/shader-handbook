//  (sound) — Evacuation  by Xor
// https://www.shadertoy.com/view/4l2GW1

#define lights 16.0
#define pi atan(1.0)*8.0

vec2 mainSound( in int samp,float time)
{
    float light = fract(80.0*time)*(0.05*sin(time/lights*2.0*6.2831)+0.1);//Light buzz
    float alarm = sin(pi*fract(time)*(80.0+fract(time)*40.0))*2.0;
    return vec2(mix(light,alarm,clamp(time-10.0,0.0,1.0)) );
}