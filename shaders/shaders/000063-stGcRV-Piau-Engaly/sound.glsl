// Sound (sound) — Piau-Engaly by athibaul
// https://www.shadertoy.com/view/stGcRV

vec2 noise(float x)
{
    float xi = floor(x), xf = fract(x);
    xf = smoothstep(0.,1.,xf);
    return mix(hash21(xi), hash21(xi+1.), xf)*2.-1.;
}

vec2 mainSound( int samp, float t )
{
    vec2 sig = vec2(0.);
    sig += 0.01 * noise(300.*mod(t,16.2)) * (1. + 0.5*noise(t-100.));
    sig += 0.01 * noise(1000.*mod(t,10.)) * (1. + 0.5*noise(0.62*t));
    sig += 0.005 * noise(2000.*mod(t,11.)) * (1. + 0.5*noise(0.25*t));
    sig += 0.002 * noise(4000.*mod(t,12.)) * (1. + 0.5*noise(0.1*t));
    sig += 0.001 * noise(8000.*mod(t,13.)) * (1. + 0.5*noise(0.141*t));
    return sig * smoothstep(0.,4.,t);
}