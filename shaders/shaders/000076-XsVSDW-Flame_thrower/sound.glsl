// Sound (sound) — Flame thrower by TambakoJaguar
// https://www.shadertoy.com/view/XsVSDW

const float f = 16000.;
const float d = 222.5;

float rand2(vec2 co)
{
    float r1 = fract(sin(dot(co.xy ,vec2(16.9898,78.233))) * 23758.5453);
    return fract(sin(dot(vec2(r1, co.xy*1.562) ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(float x)
{
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    vec2 n = vec2(p, p+1000.);
    return mix(rand2(n), rand2(n + 1.0),f);
}

vec2 getSound(float t)
{
    float flameVar = sin(t*0.55) + 0.56*sin(t*0.134) + 0.22*sin(t*0.095);
    float d2 = d*(1. - 0.02*flameVar);
    
    float t2 = f*(mod(t, 3.254) + mod(t, 1.8456));
    float l = noise(t2) - 0.8*noise(t2 + d2*0.5) + 0.5*noise(t2 - d2);
    float r = noise(t2 + 1000.) - 0.8*noise(t2 + d2 + 3000.) + 0.5*noise(t2 + d2*0.5 + 3000.);
    
    return (0.8 + 0.3*flameVar)*(1. + 0.3*noise(t*16.))*vec2(l, r);
} 

vec2 mainSound( in int samp, float time )
{
    vec2 s = 0.5*getSound(time);
    return s;
}