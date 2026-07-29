// Sound (sound) — Remnant X by Dave_Hoskins
// https://www.shadertoy.com/view/4sjSW1

// Remnant X
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// by David Hoskins.

#define TAU  6.28318530718

float n1 = 0.0;
float n2 = 0.0;
float n3 = 0.0;
float n4 = 0.0;
float fb_lp = 0.0;
float fb_hp = 0.0;
float hp = 0.0;
float p4=1.0e-24;

float gTime;
float beat;


#define N(a, b) if(t > a){x = a; n = b;}
#define K(a) if(t > a) x = a;
#define BRING_IN

#define _sample (1.0 / iSampleRate)

// Low pass resonant filter...
float Filter(float inp, float cut_lp, float res_lp)
{
	fb_lp 	= res_lp+res_lp/(1.0-cut_lp + 1e-20);
	n1 		= n1+cut_lp*(inp-n1+fb_lp*(n1-n2))+p4;
	n2		= n2+cut_lp*(n1-n2);
    return n2;
}

//----------------------------------------------------------------------------------
float Tract(float x, float f, float bandwidth)
{
    float ret = sin(TAU * f * x) * exp(-bandwidth * 2.14159265359 * x);
    return ret;
}

//----------------------------------------------------------------------------------
float Hash(float p)
{
	vec2 p2 = fract(vec2(p * 5.3983, p * 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 3.4337) * .5;
}

//----------------------------------------------------------------------------------
float Noise(float time, float pitch)
{
    float ret = Hash(floor(time * pitch));
	return ret;
}

//----------------------------------------------------------------------------------
float noteMIDI(float n)
{
	return 440.0 * exp2((n - 69.0) / 12.0);
}

//----------------------------------------------------------------------------------
float Saw(float time, float pitch)
{
    float f1 = fract(time * pitch);
    float f2 = fract(time * pitch * .99);
    float f3 = fract(time * pitch * 2.01);
    float f4 = fract(time * pitch * 4.01);
    return (f1+f2*.7+f3*.4+f4*.3)*.8 - 1.0;
}


//----------------------------------------------------------------------------------
float Kick()
{
    #ifdef BRING_IN
    if (beat < 24.0) return 0.0;
    #endif
    float x = 0.0;
    float t = mod(beat, 8.0);
    
    K(0.0);
    K(0.5);
    K(4.0);
    K(6.0);
    K(7.5);
    
    t = t-x;
    float vol = exp(-t*.5);
    
    float kick = sin(t*220.0* exp(-t* .75));
    
    kick = (1.5 * kick - 0.5 * kick * kick * kick);
    
    
    return kick * vol * .4;// * smoothstep(0.0, .3, t);
}

//----------------------------------------------------------------------------------
vec2 Cymbals()
{
	#ifdef BRING_IN
    if (beat < 31.0) return vec2(0.0);
    #endif
    
    float x = 0.0;
    float n = 0.0;
    float t = mod(beat+.2, 8.0);

    N(0.0, .2);
    N(0.5, .5);
    N(2.5, .75);
    N(3.0, 1.0);
    N(4.0, .2);
    N(4.5, .7);
    N(6.5, 1.0);
    N(7.0, .6);
    N(7.75, .8);
    t = t-x;
    
    float vol = exp(-pow(abs(t), .4)*1.3) * .4 * n * smoothstep(0.0, .3, t);
	vec2 cym = vec2(Noise(t, 8000.0), Noise(t, 10000.0));
   
    return cym * vol;
}

//----------------------------------------------------------------------------------
float Snare()
{
    float x = 0.0;
    float n = 0.0;
    #ifdef BRING_IN
    if (beat < 40.0) return 0.0;
    #endif
    float t = mod(beat, 16.0);
    
    N(1.0, 1.0);
    N(3.0, 1.0);
    N(3.25, .5);
    N(5.0, 1.0);
    N(5.25, .5);
    N(7.0, 1.0);
    N(7.25, .5);
    N(7.5, 1.0);
    
    N(9.0, 1.0);
    N(11.0, 1.0);
    N(11.25, .5);
    N(13.0, 1.0);
    
    N(13.5, .25);
    N(13.75, .3);
    N(14.0, .35);
    N(14.25, .4);
    N(14.5, .5);
    N(14.75, .45);
    N(15.0,  .7);
    N(15.25, .6);
    N(15.5,  1.0);
    N(15.75, .8);

    t = t-x;
    
    float vol = exp(-pow(abs(t), .7) * 1.5) * n * .3;
    
    float sna = sin(t * 487.0 * exp(-t*.2)) * .65;
	sna += Noise(t+mod(gTime, .521), 1400.0 * exp(-t*.2));    
    
    return sna * vol;
}

//----------------------------------------------------------------------------------
float Bass()
{
    float n;
    float x = 0.0;
    float t = mod(beat, 16.0);
    
    N(0.0, 36.0);
    N(4.0, 35.0);
    N(6.0, 34.0);
    N(8.0, 33.0);

    float p = noteMIDI(float(n));
    t = t-x;
    float vol = exp(-t*.25) * smoothstep(0.0, .05, t) * .5;
    float saw = 0.0;
    float low = (cos(beat*.15)+1.0) *.45 + .05;
    float res = .7-(cos(t*2.)) *.2;

    for (int i = 0; i < 80; i++)
    {
        float s = Saw(gTime-(float(i)* _sample), p) * .7;
        s += Noise(gTime-(float(i) * _sample), p*16.0) *.3;
        saw = Filter(s, low, res);
    }
    return saw*vol;
}

//----------------------------------------------------------------------------------
float Lead()
{
    float n;
    float x = 0.0;
    
    #ifdef BRING_IN
	if (beat < 16.0) return 0.0;
    #endif

    float t = mod(beat+.15, 32.0);
    
    N(0.0, 58.0);
    N(.5, 60.0);
    N(2.0, 48.0);
    N(4.0, 59.0);
    N(6.0, 58.0);
    N(8.0, 57.0);
    
    N(16.0, 58.0);
    N(16.5, 60.0);
    N(18.0, 48.0);
    N(20.0, 59.0);
    N(22.0, 60.0);
    N(24.0, 64.0);

    N(31.0, 54.0);
    N(31.5, 56.0);

    float p = noteMIDI(float(n));
    t = t-x;
    float vib = sin(TAU*5.0*gTime) * smoothstep(0.3, 2.0, t) * .001;
    float vol = exp(-t*.3) * smoothstep(0.0, .4, t) * .05;
    float t1 = 500.0  + sin(gTime*TAU*.312)*400.0;
    float t2 = 1200.0 + sin(gTime*TAU*.13)*400.0;
    
    // Vocal tract simulating varying vowel sounds...
	float s = Tract(mod(gTime+vib, 1.0 / p), t1, 90.0);
   	s += Tract(mod(gTime+vib, 1.0 / p), t2, 120.0);
   	s += Tract(mod(gTime+vib, 1.0 / p), 2500.0, 160.0);
    // Octave down harmony...
  	s += Tract(mod(gTime+vib, 2.0 / p), t1, 90.0);
   	s += Tract(mod(gTime+vib, 2.0 / p), t2, 120.0);
   	s += Tract(mod(gTime+vib, 2.0 / p), 2500.0, 160.0);

    s+= (Noise(t, t1)+ Noise(t, t2))*.75;

    return s * vol;
}

//----------------------------------------------------------------------------------
vec2 mainSound( in int samp,float time)
{
	gTime = time;
	beat = time * 1.5;
    
   	vec2 audio = vec2(0.0, 0.0);
    
    float b1 = Bass();
    float b2 = -b1;
    float kick = Kick();
    float snare = Snare();
    vec2 cymb = Cymbals();
    float lead = Lead();
    
    audio = vec2(b1, b2);
    audio += vec2(kick);
    audio += vec2(snare);
    audio += cymb;
    audio += vec2(lead);

    vec2 sam  = clamp(audio * 1.5 * smoothstep(180.0, 172.0, time) * smoothstep(0.0, 1.0, time), -1.0, 1.0);
    // Loudness curve...
    sam = 1.5*sam-.5*sam*sam*sam;
    return sam;
    
    //return vec2(0.0); // Disabled.
}