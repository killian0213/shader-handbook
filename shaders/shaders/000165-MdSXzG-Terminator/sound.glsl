// Sound (sound) — Terminator by and
// https://www.shadertoy.com/view/MdSXzG

// Terminator - sound (FM synthesis + MIDI)
// Created by Dmitry Andreev - and'2014
// Original theme composed by Brad Fiedel
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define DO_DELAY        (1)
#define DO_UNISON       (1)
#define MASTER_VOLUME   (0.70)
#define BPM             (86.0)
#define STEP            (4.0 * BPM / 60.0)

// Sound track data

#define N(x, s) if (t < float(s) / STEP) { return vec2(x, t); } t -= float(s) / STEP;

vec2 rhythm_pat(float t)
{
    N(1,1) N(1,2) N(1,2) N(1,1) N(1,2) N(2,2) N(3,2)

    return vec2(0.0);
}

vec2 lead_pat(float t)
{
    N(74,1) N(76,2) N(77,15) N(76,4) N(72,2) N(65,24)
    N(74,1) N(76,2) N(77,15) N(76,4) N(72,2) N(81,12) N(79,12)
    N(74,1) N(76,2) N(77,15) N(76,4) N(72,2) N(67,24)
    N(65,22)N(62,2) N(65,12) N(64,12)

    return vec2(0.0);
}

vec2 pad_pat(float t)
{
    N(74,24) N(70,24) N(74,24) N(72,24) N(70,24) N(72,24) N(70,24) N(72,24)

    return vec2(0.0);
}

// Synth utilities

float note2Freq(float note)
{
    if (note == 0.0) return 0.0;

    return 16.35 * pow(1.059463, note);
}

float env_ad(float t, float attack, float decay)
{
    float env = (1.0 - exp(-t * attack)) * exp(-t * decay);

    float t_max = log((attack + decay) / decay) / attack;
    float env_max = (1.0 - exp(-t_max * attack)) * exp(-t_max * decay);

    return env / env_max;
}

float loop(float t, float steps)
{
    return mod(t, steps / STEP);
}

#if DO_UNISON
#define UNISON(count,w,wfunc,t,f0,df,dp,v0,dv) U1(count)U2(dp)U3(df)U4(wfunc,t,f0)U5(dv)U6(w,v0)
    #define U1(count) { const int c = (count); for (int i = 0; i < c; i++) {
    #define U2(dp)          float up = (dp) * float(i) / float(c);
    #define U3(df)          float uf = 1.0 + (df) * float(i) / float(c);
    #define U4(wfunc,t,f0)  vec2  x  = vec2(wfunc((t), (f0) * uf, up)) / float(c);
    #define U5(dv)          float a  = (dv) * ((float(i) / float(c - 1)) * 2.0 - 1.0);
    #define U6(w,v0)        w += x * vec2((v0) + a, (v0) - a); } }
#else
#define UNISON(count,w,wfunc,t,f0,df,dp,v0,dv) w += (v0) * wfunc((t), (f0), 0.0);
#endif

// Waveforms

float sine(float x)
{
    return sin(6.2831 * x);
}

float tsaw(float x, float q)
{
    // (saw) 0.0 <= q <= 0.5 (tri)

    float f = fract(x) - q;
    f /= (f >= 0.0 ? 1.0 : 0.0) - q;

    return f * 2.0 - 1.0;
}

// Instruments

float wave_pad(float t, float f0, float p0)
{
    float op1 = tsaw(p0 + t * f0 * 0.5000, 0.02);
    float op2 = tsaw(p0 + t * f0 * 0.5086, 0.02);

    return op1 - op2;
}

vec2 ins_pad(float t, float f0)
{
    vec2 w = vec2(0.0);

    UNISON(3, w, wave_pad, t, f0, 0.003, 0.1, 0.6, 0.4);

    return w;
}

float wave_bass(float t, float f0, float p0)
{
    float op4 = tsaw(p0 + t * f0 * 10.000, 0.01) * (exp(-t * 10.0) + 0.01);
    float op3 = tsaw(p0 + t * f0 * 1.0012 + op4 * 0.17, 0.2);
    float op2 = tsaw(p0 + t * f0 * 0.5008 + op4 * 0.09, 0.2);
    float op1 = sine(p0 + t * f0 * 1.0000 + op4 * 0.16);

    op1 *= env_ad(t, 30.0, 3.0);
    op2 *= env_ad(t, 10.0, 5.0);
    op3 *= env_ad(t, 10.0, 5.0);

    return op1 * 0.92 + op2 * 0.54 + op3 * 0.42;
}

vec2 ins_bass(float t, float f0)
{
    vec2 w = vec2(0.0);

    UNISON(5, w, wave_bass, t, f0, 0.002, 0.01, 1.0, 0.0);

    return w;
}

float wave_lead(float t, float f0, float p0)
{
    float op4 = tsaw(p0 + t * f0 * 10.000, 0.3) * (exp(-t * 10.0) + 0.01);
    float op3 = tsaw(p0 + t * f0 * 1.0012 + op4 * 0.22, 0.01);
    float op2 = tsaw(p0 + t * f0 * 0.5008 + op4 * 0.22, 0.02);
    float op1 = tsaw(p0 + t * f0 * 1.0000 + op4 * 0.22, 0.03);

    op1 *= env_ad(t, 4.0, 0.2);
    op2 *= env_ad(t, 6.0, 0.5);
    op3 *= env_ad(t, 6.0, 1.0);

    return op1 * 0.75 + op2 * 0.4 + op3 * 0.26;
}

vec2 ins_lead(float t, float f0)
{
    vec2 w = vec2(0.0);

    UNISON(5, w, wave_lead, t, f0, 0.01, 0.3, 0.6, 0.4);

    return w;
}

vec2 ins_drum(float t, float f0)
{
    float f1 = f0 * (exp(-t * 8.0) * 1.5 + 0.5);

    // Hihat
    float op5 = sine(t * f0 * 2.8020             ) * exp(-t * 1.0);
    float op4 = sine(t * f0 * 2.5000 + op5 * 1.12);
    float op3 = sine(t * f0 * 15.000 + op4 * 0.92) * exp(-t * 14.0);

    // Hihat rebounce
    op3 *= t < 0.02 ? (exp(-t * 40.0) * 0.8 + 0.2) : 1.0;

    // Drum
    float op2 = sine(t * f0 * 2.0000             ) * exp(-t * 40.0);
    float op1 = sine(t * f1 * 1.0000 + op2 * 0.20) * pow(clamp(1.2 - t * 2.0, 0.0, 1.0), 0.5);

    return vec2(op1 + op3 * 0.2);
}

vec2 ins_snare(float t, float f0)
{
    float op3 = sine(t * f0 * 2.8020) * exp(-t * 1.0);
    float op2 = sine(t * f0 * 2.5000 + op3 * 1.00);
    float op1 = sine(t * f0 * 18.000 + op2 * 0.72);

    return vec2(op1 * exp(-t * 5.5));
}

float wave_bell(float t, float f0)
{
    float op3 = sine(f0 * t * 6.0000             ) * exp(-t * 5.0);
    float op2 = sine(f0 * t * 7.2364 + op3 * 0.20);
    float op1 = sine(f0 * t * 2.0000 + op2 * 0.13) * exp(-t * 2.0);

    return op1;
}

//

struct Mixer
{
    vec2  lead;
    vec2  lead2;
    vec2  lead3;
    vec2  pad;
    vec2  bass;
    vec2  drum;
    vec2  snare;
    vec2  bell;
};

vec2 synthWave(float t, Mixer m)
{
    vec2 w = vec2(0.0);
    vec2 n = vec2(0.0);
    float fq = 0.0;

    // Lead
    n = lead_pat(loop(t, 192.0));
    fq = note2Freq(n.x) * 0.25;
    w += m.lead  * ins_lead(n.y, fq);
    w += m.lead2 * ins_lead(n.y, fq * 0.5);

    n = lead_pat(loop(t - 12.0 / STEP, 192.0));
    fq = note2Freq(n.x) * 0.5;
    w += m.lead3 * ins_pad(n.y, fq) * exp(-n.y * 3.0);

    // String pad
    n = pad_pat(loop(t, 192.0));
    fq = note2Freq(n.x) / 8.0;
    w += m.pad * ins_pad(n.y, fq);

    n = rhythm_pat(loop(t, 12.0));

    // Compress dynamic range
    w *= 1.0 - exp(-n.y * 8.0) * 0.7;

    // Bass
    w += m.bass * ins_bass(n.y, fq * 0.5);
    w += m.bass * ins_bass(n.y, fq * 1.0) * 0.3;

    // Drum
    if (n.x >= 1.0) w += m.drum * ins_drum(n.y, n.x == 2.0 ? 116.5 : 130.8);

    // Snare
    if (n.x >= 2.0) w += m.snare * ins_snare(n.y, 116.75) * (n.x == 3.0 ? 0.7 : 1.0);

    // Bell
    w += m.bell * vec2(wave_bell(loop(t, 12.0), 175.0));

    return w;
}

vec2 mainSound( in int samp,float t)
{
    Mixer m;
    m.lead  = vec2(1.0, 0.7) * 1.2;
    m.lead2 = vec2(0.7, 1.0) * 0.7;
    m.lead3 = vec2(0.4, 0.9) * 0.5;
    m.pad   = vec2(1.0, 1.0) * 0.7;
    m.bass  = vec2(0.8, 1.0) * 0.28;
    m.drum  = vec2(1.0, 0.9) * 0.34;
    m.snare = vec2(0.9, 1.0) * 0.16;
    m.bell  = vec2(1.0, 0.8) * 0.14;

    vec2 w = synthWave(t, m);

    #if DO_DELAY
        m.lead  = vec2(0.3, 0.4) * 1.2;
        m.lead2 = vec2(1.0, 0.5) * 0.35;
        m.lead3 = vec2(0.8, 0.2) * 0.4;
        m.pad   = vec2(0.8, 0.5) * 0.2;
        m.bass  = vec2(0.3, 0.2) * 0.25;
        m.drum  = vec2(0.3, 0.4) * 0.4;
        m.snare = vec2(1.0, 0.5) * 0.1;
        m.bell  = vec2(0.8, 1.0) * 0.1;

        w += synthWave(t - (3.0 / STEP), m);
    #endif

    // Fade-in / fade-out
    w *= pow(clamp(t * 0.2, 0.0, 1.0), 2.0);
    w *= pow(clamp((60.0 - t) * 0.2, 0.0, 1.0), 2.0);

    w = clamp(w * MASTER_VOLUME, -1.0, 1.0);

    return w;
}