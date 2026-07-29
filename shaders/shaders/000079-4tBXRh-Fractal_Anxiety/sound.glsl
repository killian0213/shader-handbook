// Sound (sound) — Fractal Anxiety by Kali
// https://www.shadertoy.com/view/4tBXRh

vec2 mainSound( in int samp,float time)
{
    float t=1.+abs(.01-mod(time,.02))+abs(sin(time*3.4356));
    float t2=500.+sin(time*.54321)*200.;
    float s=abs(sin(t*t2))*abs(sin(time*20.));
    float c=abs(cos(time*.6341));
    s=clamp(s,0.,.25+c)/(1.+c);
    return vec2(s)*min(1.,time*.2);
}