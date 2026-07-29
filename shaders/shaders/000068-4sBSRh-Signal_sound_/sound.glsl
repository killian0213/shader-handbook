// Sound (sound) — Signal (sound) by srtuss
// https://www.shadertoy.com/view/4sBSRh

// srtuss, 2014

#define pi2 6.283185307179586476925286766559

float rnd(float x)
{
    return fract(sin(x * 143.5925) * 98723.8791);
}

float nse(float x)
{
   	float fl = floor(x);
    return mix(rnd(fl), rnd(fl + 1.0), smoothstep(0.0, 1.0, fract(x)));
}

float nses(float x)
{
    float e = 0.05;
   	float fl = floor(x);
    return mix(rnd(fl), rnd(fl + 1.0), smoothstep(0.5 - e, 0.5 + e, fract(x)));
}

float fbm(float x)
{
    return nse(x) * 0.5 + nse(x * 2.0) * 0.25 + nse(x * 4.0) * 0.125;
}

float s4(float t)
{
    #define NSPC 64
    float v = 0.0;
    for(int i = 0; i < NSPC; i ++)
    {
        float h = float(i + 1);
        float inten = 1.0 / h;
        float x = h - 8.0;//(sin(t * 0.5) * 3.0 + 8.0);
        inten *= exp(-x*x * 0.09);
        
        
        inten *= pow(fbm(h * 111.0 + nses(t * 3.0) * 10.0), 4.0);
        //inten *= pow(fbm(h * 111.0 + t * 10.0), 4.0);
        //h += rnd(h);
        v += inten * sin(h * t * 120.0 * 5.0 / 4.0 * pi2);
    }
    
    v *= 5.0;
    //v *= 100.0 / float(NSPC);
    
    return v;
}

float s3(float t)
{
    #define NSPC 64
    float v = 0.0;
    for(int i = 0; i < NSPC; i ++)
    {
        float h = float(i + 1);
        float inten = 1.0 / h;
        float x = h - (sin(t * 0.04) * 5.0 + 8.0);//8.0;//
        inten *= exp(-x*x * 0.09);
        
        
        inten *= pow(fbm(h * 111.0 + nses(t * 3.0) * 10.0), 4.0);
        //inten *= pow(fbm(h * 111.0 + t * 10.0), 4.0);
        h += rnd(h);
        v += inten * sin(h * t * 120.0 * 5.0 / 4.0 * pi2);
    }
    
    v *= 5.0;
    //v *= 100.0 / float(NSPC);
    
    return v;
}

float s2(float t)
{
    #define NSPC 64
    float v = 0.0;
    for(int i = 0; i < NSPC; i ++)
    {
        float h = float(i + 1);
        float inten = 1.0 / h;
        float x = h - (sin(t * 0.2) * 2.0 + 10.0);
        inten *= exp(-x*x * 0.09);
        
        
        
        inten *= pow(fbm(h * 111.0 + t * 10.0), 4.0);
        h += rnd(h);
        v += inten * sin(h * t * 120.0 * pi2);
    }
    
    v *= 5.0;
    //v *= 100.0 / float(NSPC);
    
    return v;
}

float s(float t)
{
    return (s2(t) + s2(t * 1.01)) * sin(t * 0.1) + s3(t * 2.252) * 0.4 * cos(t * 0.1) + s4(t * 0.25) * sin(t * 0.05);
}

vec2 echo(float t)
{
    vec2 v;
    
    float a = 0.7, et = 0.1, fb = 0.8;
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
    
    
    return vec2(echo(t) * exp(max(t - 55.0, 0.0) * -1.0));
}