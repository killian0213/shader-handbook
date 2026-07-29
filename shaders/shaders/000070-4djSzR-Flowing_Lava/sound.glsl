// Sound (sound) — Flowing Lava by fizzer
// https://www.shadertoy.com/view/4djSzR

float bubbles(float time, float period, float len, float ff)
{
    float c=floor(time/period)*period;
    float t=(time-c)-(0.5+0.5*sin(c*12.0))*0.8*period;
    return step(-0.2,cos(c*199.0*len))*sin(ff*(5000.0+cos(c*70.0)*2000.0)*(t+0.1)*t)*(smoothstep(0.0,0.07*len,t)-smoothstep(0.1*len,0.2*len,t));
}

vec2 mainSound( in int samp,float time)
{
    return vec2(bubbles(time, 2.0, 1.2, 1.0)*0.9+0.1*bubbles(time, 0.5, 0.5, 2.0)+0.2*bubbles(time, 0.2, 0.2, 2.0))*0.75;
}