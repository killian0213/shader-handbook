// Sound (sound) — Industry II (sound) by srtuss
// https://www.shadertoy.com/view/Xd2GW3

// srtuss, 2014

float hash(float x)
{
    return (fract(cos(x * 115.5782) * 1000.0 + sin(x * 0.5782) * 333.333) - 0.5) * 1.0;
}

float nse(float t)
{
    float fl = floor(t);
    return mix(hash(fl), hash(fl + 1.0), smoothstep(0.0, 1.0, fract(t)));
}

float quan(float x, float v)
{
    return floor(x * v) / v;
}

#define pi2 6.283185307179586476925286766559

float engine1(float t)
{
    return nse(fract(t * 40.0) * 60.0);
}



float f1(float t, float ts, float tl, float k)
{
	float o1 = clamp(t - ts, 0.0, tl);
	float o2 = max(t - (ts + tl), 0.0);

	return o1 * o1 * k / (2.0 * tl) + o2 * k;
}

float phase(float t)
{
    // phase result
    float p;
    
    float tb = 0.0, td = 1.0;
    float fl = 4.0, fn = 10.6;
    
    p = fl * t;
    p += f1(t, tb, 0.4, fn - fl); fl = fn; tb += 2.0;
    fn = (13.0);
    p += f1(t, tb, 0.05, fn - fl); fl = fn; tb += 0.05;
    fn = (0.001);
    p += f1(t, tb, 0.8, fn - fl); fl = fn; tb += 0.3;
    
    
    
    return p;
}


float wf2(float x)
{
    return nse(fract((sin(x * 300.0) * 0.001 + x) * 100.0) * 26.0);
}

float s(float t)
{
    float h = 0.7;
    float tt = mod(t, 4.0);
    float v = (nse(tt * 40000.0 - h) - nse(tt * 40000.0 + h));
    v = v * 0.5 * exp(-10.0 * max(tt - 2.0, 0.0)) * exp(-40.0 * max(1.0 - tt, 0.0));
    
    h = 0.005;
    v += (((engine1(t - h) + engine1(t + h))) * 0.4 + sin(t * 40.0 * pi2) * 0.2) * smoothstep(-0.1, 0.1, sin(t * 10.0)) * 0.5;
    
    h = 0.1;
    v += (nse(t * 1000.0 - h) + nse(t * 1000.0 + h)) * sin(t * 20.0);
    
    
    tt = mod(t, 7.0);
    v += wf2(phase(tt) * 1.0) * exp(-1.0 * max(tt - 2.0, 0.0)) * exp(-1.0 * max(1.0 - tt, 0.0)) * 0.5;
    
    
    //tt = mod(t + 3.0, 3.0);
    //tt = pow(tt, 0.8) * 0.1 + tt;
    //v += clamp(-1.0, 1.0, 4.0 * sin((tt + sin(tt * tt * 100.0) * 0.01) * 3000.0) * exp(max(tt, 0.0) * -10.0)) * 0.5;
    
    // thump
    tt = mod(t + .1, 1.25);
    float phs = (pow(tt, 0.5) + t) * 1.1;
    v += clamp(-1.0, 1.0, (nse(phs * 200.0) + sin(phs * 200.0) * 0.5) * exp(max(0.04 - tt, 0.0) * -100.0) * exp(max(tt, 0.0) * -4.0) * 8.0) * 0.8;
    
    return v;
}

vec2 echo(float t)
{
    vec2 v;
    
    float a = 0.5, et = 0.1, fb = 0.6;
    v = vec2(s(t));
    v = v.yx + s(t - et) * a * vec2(1.0, 0.5); a *= fb; et += 0.2;
    v = v.yx + s(t - et) * a * vec2(0.5, 1.0); a *= -fb; et += 0.2;
    v = v    + s(t - et) * a * vec2(1.0, 0.5); a *= fb; et += 0.3;
    v = v.yx + s(t - et) * a * vec2(1.0, 0.5); a *= -fb; et += 0.2;
    v = v    + s(t - et) * a * vec2(0.5, 1.0); a *= fb; et += 0.3;
    v = v    + s(t - et) * a * vec2(1.0, 0.5); a *= -fb; et += 0.3;
    v = v.yx + s(t - et) * a * vec2(0.5, 1.0); a *= fb; et += 0.2;
    v = v.yx + s(t - et) * a * vec2(1.0, 0.5); a *= -fb; et += 0.3;
    v = v    + s(t - et) * a * vec2(1.0, 0.5); a *= fb; et += 0.4;
    v = v.yx + s(t - et) * a * vec2(0.5, 1.0); a *= -fb; et += 0.3;
    v = v.yx + s(t - et) * a * vec2(1.0, 0.5); a *= fb; et += 0.2;
    
    return v;
}


vec2 mainSound( in int samp,float t)
{
    vec2 v = vec2(0.0);
    v = echo(t) * 0.35;
    
    //v = vec2();
    
    return vec2(v);
}