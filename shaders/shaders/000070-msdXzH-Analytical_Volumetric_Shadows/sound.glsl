// Sound (sound) — Analytical Volumetric Shadows by me_123
// https://www.shadertoy.com/view/msdXzH

float hash11(uint q)
{// by David Hoskins.
	uvec2 n = q * uvec2(1597334673U, 3812015801U);
	q = (n.x ^ n.y) * 1597334673U;
	return float(q) * (1.0 / float(0xffffffffU));
}
float noise(in float x) {
    return mix(hash11(uint(floor(x))),hash11(1u+uint(floor(x))),0.5*(1.-cos(3.14159*fract(x))));
}
float fbm(in float x) {
    float v = 0.0;
    for (int i = 0; i < 5; i += 1) {
        v += noise(x*float(1<<i))*pow(2., -float(i));
    }
    return v*0.5 - 0.5;
}

float s(in float x) {
    return sin(fract(x)*3.141592*2.);
}
float smoothfract(in float x, in float s) {
    float f = fract(x)-s;
    return cos((f < 0.0 ? -f/s : f/(1.-s))*3.141592)*0.5+0.5;
}
float synth(in float time, in float freq, in float lucid) {
    float v = 0.0;
    for (float i = 1.0; i < 10.; i++) {
        v += s(time*freq/i + s(time*i*freq*lucid)*smoothfract(time/i, 0.1))*(s(time/i*5.)*0.25+0.5);
    }
    v *= smoothfract(time*0.01*freq, 0.1)*0.5;
    float k = smoothfract(time*freq*0.25, 0.5);
    v += smoothfract(time*freq, k*0.5+0.2)*(1.-k);
    v += smoothfract(time*freq*0.5, 0.1)*k;
    return v*0.2;
}
float n(in float x) {
    return 440.*pow(2., x/12.);
}
float drum(in float time, in float dur) {
    return exp(-time*dur*2.0)*s(exp(-time*dur-0.5)*100.)*mix(1.0, fbm(exp(-time*5.*dur)*100.), exp(-time*5.*dur));
}
float layer(in float time) {
    float k = synth(time, n(0.0), 0.03)*smoothfract(time, 0.1);
    k += synth(time, n(2.0), 0.1)*smoothfract(time/3., 0.1);
    k += synth(time, n(5.0), 0.02)*smoothfract(time*2., 0.1);
    k += synth(time, n(9.0)*0.5, 0.1);
    k += drum(fract(time*2.), 5.0);
    k += drum(fract(time*3.)/3., 2.0);
    k += drum(fract(time*6.)/2., 10.0)*0.1;
    return k;
}
vec2 mainSound( int samp, float time )
{
    float k = 0.0;
    k += layer(time);
    k += layer(time*0.5)*2.0;
    return vec2(sin(k*0.5));
}