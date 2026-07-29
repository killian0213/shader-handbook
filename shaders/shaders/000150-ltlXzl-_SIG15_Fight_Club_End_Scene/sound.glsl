// Sound (sound) — [SIG15] Fight Club End Scene by movAX13h
// https://www.shadertoy.com/view/ltlXzl

// by srtuss

float n2f(float n)
{return 440.0*pow(2.0,n/12.0);}
float sine(float ph)
{return sin(ph*6.283185307179586476925286766559);}
float shns(float x)
{return fract(sin(floor(x * 4000.0)) * 29919.0) - 0.5;}
float hpns(float x, float h)
{return (shns(x + h) - shns(x - h));}
float adsr(float x, float a, float d)
{return smoothstep(0.0, a, x) * exp(max(x - a, 0.0) * -d);}
float adsr(float x, float a, float d, float g)
{return smoothstep(0.0, a, x) * smoothstep(a + d + g, a + g, x);}
float ade(float x, float a, float e, float g)
{return smoothstep(0.0, a, x) * exp(max(x - (a + g), 0.0) * -e);}
float pwm(float t, float v)
{
    float s = 0.001;
    t = fract(t);
    return smoothstep(v,  v + s, t) * smoothstep(1.0, 1.0 - s, t) - 0.5;
}

float nse(float x)
{
    float x2 = x;
    return texture(iChannel0, vec2(x2 / 256.0, x * 0.01), -100.0).x - 0.5;
}

vec2 expl(float x, vec2 pan, float seed)
{
    float dist = fract(seed * 27623.5978623) * 0.5;
    float dist2 = fract(seed * 2723.5978623);
    
    float ps = 0.2;
    float verb = adsr(x - 0.1, 0.1, 3.0);
    float xp = exp(-x / ps) * ps;
    ps = 0.9;
    float xp2 = mix(1.0, exp(-x / ps) * ps * 1.0, step(0.5, dist2));
    vec2 v = nse(xp * 100.0 + seed) * (adsr(x, 0.01, 4.0) + verb * 0.2) * 2.0 * pan.xy;
    v += nse(x * xp2 * 500.0 - seed) * (adsr(x, 0.1, 4.0) + verb * 0.2) * pan.yx;
    v += sin(v * (dist2 * 5.0)) * dist2 * 0.3;
    v += nse(x * 1340.0 + seed * 2.0) * (adsr(x, 0.1, 50.0) + verb * 0.3) * 0.5 * pan.xy;
    v = (smoothstep(-1.0 + dist, 1.0 - dist, v) - 0.5) * exp(-dist * 1.0);
    return v;
}

/*
t - time
pan - finetune direction of sound origin (1,1 = center)
pitch - change pitch/size of explosion (1 = default)
nr - number of subsequent explosions (sort of)
del - delay between subsequent explosions
vari - maximum random variation in delay (0 = no variation)
*/
vec2 explseq(float t, vec2 pan, float pitch, float nr, float del, float vari)
{
    float rp = del;
    vec2 v = vec2(0.0);
    float tb = t;
    float sd = floor(tb / rp);
    v += expl(max(fract(tb / rp) * rp, tb - nr * rp) * pitch - fract(sd * 19623.232) * vari, pan, sd) * step(0.0, tb);
    tb = (t - rp * 0.5);
    sd = floor(tb / rp);
    v += expl(max(fract(tb / rp) * rp, tb - nr * rp) * pitch - fract(sd * 290.1233) * vari, pan, -sd) * step(0.0, tb);
    return v;
}


float gts(float x, float tf)
{
    float ro = 1.0;
    return sine(x) * 0.2 + sine(x * 2.0) * 0.7 * exp(tf * -1.0 * ro) + sine(x * 3.002) * 0.4 * exp(tf * -2.0 * ro);
}

#define GTMUL adsr(tf, 0.01, 0.85, 0.12) * step(0.0, tt)

const float tbt = 60.0 / 160.0;
const float tbr = tbt * 4.0;

float riff(float time)
{
    float v = 0.0;
    
    time = mod(time, tbr * 4.0);
    
    float tf, tt;
    // G#5
    tt = time;
    tf = max(mod(tt, tbt * 2.0), max(tt - tbr * 1.5, 0.0));
    v += gts(time * n2f(-5.0), tf) * GTMUL;
    
    // D#5 short
    tt = time - tbr * 1.001;
    tf = max(mod(tt, tbt * 2.0), max(tt - tbr * 1.5, 0.0));
    v += gts(time * n2f(-6.0), tf) * GTMUL * 0.5;
    
    // D#5
    tt = time - tbr * 2.0;
    tf = max(mod(tt, tbt * 2.0), max(tt - tbr * 0.5, 0.0));
    v += gts(time * n2f(-6.0), tf) * GTMUL;
    
    // E5
    tt = time - tbt;
    tf = max(mod(tt, tbt * 2.0), max(tt - tbr * 2.5, 0.0));
    v += gts(time * n2f(-1.0), tf) * GTMUL;
    
    
    // E5
    tt = time - tbr * 3.0;
    tf = max(mod(tt, tbt * 1.0), max(tt - tbr * 0.5, 0.0));
    v += gts(time * n2f(-5.0), tf) * GTMUL;
    
    // D#5
    tt = time - tbr * 3.0 - tbt * 1.5;
    tf = tt;
    v += gts(time * n2f(-6.0), tf) * GTMUL;
    
    // A4 short
    tt = time - tbr * 3.02;
    tf = max(mod(tt, tbt * 2.0), max(tt - tbr * 0.5, 0.0));
    v += gts(time * n2f(-12.0), tf) * GTMUL * 0.5;
    
    v = sin(v * (1.1 + 0.4 * sin(time * 4.0)));
    
    v = smoothstep(-0.25, 0.25, v);
    
    return v;
}

float sub(float t)
{
    t = mod(t, tbr * 4.0);

    float f = n2f(-5.0);
    f = mix(f, n2f(-8.0), step(tbr, t));
    f = mix(f, n2f(-1.0), step(tbr * 2., t));
    f = mix(f, n2f(0.0), step(tbr * 3., t));
    
    float ph = t * f * 0.25;
    return (sine(ph) + sine(ph * 1.03) * 0.3) * adsr(mod(t, tbr), 0.1, 0.1, tbr * 0.85);
}

float riffhp(float t)
{
    float h = 0.0001 + sin(t) * 0.00005;
    return riff(t + h) - riff(t - h);
}

float echos(float t)
{
    return riffhp(t);
}

vec2 echochn(float t)
{
    vec2 v = vec2(0.0);
    float to = 0.0;
    float ea = 1.0;
    vec2 pan = vec2(1.0, 0.5);
    vec2 of = vec2(0.002, 0.0);
    float deltime = (60.0 / 160.0) * 4.0 / 3.0;
    for(int i = 0; i < 10; i++)
    {
    	v += vec2(echos(t - to + of.x), echos(t - to + of.y)) * pan * ea;
        ea *= 0.2;
        to += deltime;
        of = of.yx;
        pan = pan.yx;
    }
    return v;
}

vec2 mainSound( in int samp,float time)
{
    float t = time - 16.5;
    vec2 v = 	explseq(t - 1.0, vec2(1.8, 0.4), 0.6, -1.0, 0.5,   0.1) * 1.0;
    	 v += 	explseq(t - 2.0, vec2(0.2, 1.0), 0.5,  1.0, 0.654, 0.2)  * 0.6;
    	 v += 	explseq(t - 2.5, vec2(1.0, 1.0), 0.6, 0.5, 0.7,   0.1)  * 0.3;
    	 v += 	explseq(t - 3.0, vec2(1.0, 0.0), 0.6,  0.8, 0.4,   0.1)  * 0.2;
    
    	 v += 	explseq(t - 4.0, vec2(0.8, 0.6), 0.7, 1.0, 0.5,   0.3)  * 0.8;
    	 v += 	explseq(t - 4.0, vec2(0.1, 1.0), 0.65, 0.5, 0.45, 0.1)  * 0.4;
    	 v += 	explseq(t - 5.5, vec2(0.5, 0.5), 0.5, 0.9, 0.4,   0.2)  * 0.3;

    	 v += 	explseq(t - 13.4, vec2(0.8, 0.9), 0.5,-1.0, 0.5,   0.1)  * 0.8;
    	 v += 	explseq(t - 14.4, vec2(0.8, 1.0), 0.4, 0.6, 0.7,   0.2) * 0.5;
    	 v += 	explseq(t - 14.9, vec2(0.7, 1.0), 0.5, 0.4, 0.8,   0.1)  * 0.3;
    	 v += 	explseq(t - 16.3, vec2(1.0, 1.0), 0.35, 0.6, 0.7,   0.2) * 0.6;

    t = time - 15.0;
    vec2 m = echochn(t);
    m += vec2(sub(t) * 0.5);
    m *= 0.2;
    
    v += m*smoothstep(-0.1, 2.0, t)*smoothstep(30.0, 10.0, t);
    
    return vec2(v);
}