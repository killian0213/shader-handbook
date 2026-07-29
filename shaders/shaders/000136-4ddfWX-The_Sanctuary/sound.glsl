// Sound (sound) — The Sanctuary by srtuss
// https://www.shadertoy.com/view/4ddfWX

// srtuss, 2018

#define PI 3.1415926535897932384626433832795

float tempo = 2.;

float hash(float x)
{
    return fract(sin(x) * 897612.531);
}
float hsh(float x)
{
    return fract(sin(x * 237.234234) * 982734.1235);
}
float rnd(float x, float mn, float mx)
{
    return mn + floor((mx - mn) * hash(floor(x)));
}

// perlin noise
float nse(float x)
{
    float y = floor(x);
    x -= y;
    x = x * x * (3. - 2. * x);
    return mix(hash(y), hash(y + 1.), x) - .5;
}

// FM-bell
vec2 inst0(float t, float f)
{
    vec2 v;
    v.x = sin(t * f * PI * 2. + sin(t * f * 80.) * exp(t * -50.)) * min(t * 800., 1.) * exp(t * -5.) * .25;
    v.y = cos(t * f * PI * 2. + sin(t * f * 80.) * exp(t * -50.)) * min(t * 800., 1.) * exp(t * -5.) * .25;
    return v;
}

// crude vowel-"A" instrument
float voc(float t, float f, float formant)
{
    float x = fract(t * f) / f;
    return (sin(x * 6. * formant) * .4 + sin(x * 12. * formant) + sin(x * 26. * formant) * .2) * min(x * 1000., 1.) * exp(x * -200.);
}

// a swarm of voc()'s
vec2 inst2(float t, float f)
{
    vec2 v = vec2(0., 0.);
    float formant = 300. * exp2(sin(t * .1));
    for(int i = 0; i < 16; ++i)
    {
        float h = float(i);
       	float m = voc(t + h / 3., f + pow(2.01, (h - 8.) * .2), formant);
        float pan = hash(h);
        v.x += m * pan;
        v.y += m * (1. - pan);
    }
    return v * .1;
}

float tri(float x)
{
    return abs(fract(x) * 2. - 1.);
}

// squarewave-ish instrument
vec2 inst4(float t, float f)
{
    vec2 v = vec2(0., 0.);
    for(int i = 0; i < 8; ++i)
    {
        float h = float(i) * 2. + 1.;
        float x = h;
       	float m = sin(t * f * 2. * PI * x) * (1. + nse(h * 41. + t * 10.)) / h;
        float pan = hash(h);
        v.x += m * pan;
        v.y += m * (1. - pan);
    }
    return v * .25;
}

// pentatonic scale
float penta(float x)
{
    x /= 5.;
    float y = floor(x);
    x = fract(x);
    x *= 5.;
    return step(1., x) * 2. + step(2., x) * 3. + step(3., x) * 2. + step(4., x) * 2. + y * 12.;
}

// 2 octaves of choir + playing harmonics, which gives some symphonic qualities
vec2 choir(float time, float n)
{
    vec2 v = inst2(time, 140. * pow(2., n / 12.));
    v += inst2(-time, 140. * pow(2., n / 12. - 1.));
    if(time > 128. / tempo)
    {
        v += inst4(time, 140. * 5. * pow(2., (n + 12.) / 12.)) * .2 * smoothstep(0., .1, nse(time * .44 + 10.));
        v += inst4(time, 140. * 4. * pow(2., (n + 12.) / 12.)) * .2 * smoothstep(0., .1, nse(time * .33));
        v += inst4(time, 140. * 3. * pow(2., (n + 12.) / 12.)) * .2 * smoothstep(0., .1, nse(time * .12));
        v += inst4(time, 140. * 5. / 2. * pow(2., (n + 12.) / 12.)) * .2 * smoothstep(0., .1, nse(time * .32 + 4.));
    }
    return v;
}

// a snaredrum with fake reverb tail
vec2 snare(float t)
{
    if(t < 0.)
        return vec2(0.);
    t *= 3.;
    float env = exp(t * -10.) + exp(t * -1.) * .07;
    vec2 w = vec2(hsh(t), hsh(t + .1)) * env * .4;
    w += sin(t * 400.) * exp(t * -10.) * min(1., t * 5000.) * .1;
    return w * (max(exp(-1. * fract(t * 20.)), min(t * 9., 1.)) + 3. * clamp(1. - abs(t - .4) * 10., 0., 1.));
}

// channel to be echo-ed
vec2 echomix(float time)
{
    vec2 v = vec2(0.);
    
    float x = mod(time, 8. / tempo);
    v += vec2(.5) * sin(pow(x, .9) * 300.) * min(1., x * 200.) * exp(x * -5.);
    
    float rate = tempo * 2.;
    if(time > 32. / tempo)
	    v += inst0(fract(time * rate) / rate, 140. * 2. * pow(2., penta(rnd(time * rate, 0., 10.)) / 12.)) * .4;
    return v;
}

// tempo-synced echo effect
vec2 echo(float t)
{
    vec2 s = vec2(0, 0);
    float k = 3. / 4. / tempo;
    float a = 1.;
    float damp = .5;
    vec2 sep = vec2(.3, 1.);
    s += echomix(t); a *= damp; sep = sep.yx;
    s += echomix(t - k).yx * a * sep; a *= damp; sep = sep.yx;
    s += echomix(t - k * 2.) * a * sep; a *= damp; sep = sep.yx;
    s += echomix(t - k * 3.).yx * a * sep;
    return s;
}

// putting everything together + postprocessing
vec2 mainSound( in int samp, float time )
{
    vec2 v = echo(time);
    
    float x;
    x = mod(time, 32. / tempo);
    v += choir(time, -5.) * clamp(x * tempo * .5, 0., 1.) * smoothstep(16. + 4., 15., x * tempo);
    v += choir(time, -7.) * (clamp((x * tempo - 16.) * .5, 0., 1.) * smoothstep(32. + 4., 31., x * tempo + 1.) + smoothstep(5., 0., x * tempo));
    
    if(time >= 128. / tempo)
    {
        v += snare(mod(time - 1. / tempo, 2. / tempo));
        x = mod(time, 16. / tempo);
        v += snare(x - tempo * (7. + 16.) / 16.);
    }
        
    vec2 ms = vec2(v.x + v.y, v.y - v.x);
    
    v = vec2(ms.x * .5 + ms.y, ms.x * .5 - ms.y);
    
    
    return v;
}