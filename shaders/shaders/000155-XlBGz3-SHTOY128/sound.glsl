// Sound (sound) — SHTOY128 by and
// https://www.shadertoy.com/view/XlBGz3

// SHTOY128 - sound (AY-3-8910/AY-3-8912/YM2149 chip simulator)
// Created by Dmitry Andreev - and'2015
// Original theme composed by Ed Polinski - Agent-X (1992)
// http://zxtunes.com/author.php?id=745&play=478&ln=eng
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define MASTER_VOLUME   (0.7)
#define WARMUP_TIME     (1.0)
#define SPEED           (37.0)
#define INT_PER_STEP    (9.0)
#define STEP            (INT_PER_STEP * SPEED / 60.0)
#define DO_BANDLIMIT    (1)

//

#define N(s,x,p,o) n = t >= 0.0 && t < float(s) / STEP ? vec4(x,t,p,o) : n; t -= float(s) / STEP;
#define M(x,p,o) N(1,x,p,o)
#define R(s) N(s,0,0,0)

vec4 chan_A_subpat(int i, float t)
{
    vec4 n = vec4(0.0, 0.0, 0.0, 0.0);

    if (i == 0) {M(43,2,5)M(55,2,5)M(43,11,5)M(43,2,5)M(55,2,5)M(43,2,5)M(43,11,5)M(55,2,5)}
    if (i == 1) {M(36,2,5)M(48,2,5)M(36,11,5)M(36,2,5)M(48,2,5)M(36,2,5)M(36,11,5)M(48,2,5)}
    if (i == 2) {M(38,2,5)M(50,2,5)M(38,11,5)M(38,2,5)M(50,2,5)M(38,2,5)M(38,11,5)M(50,2,5)}

    return n;
}

vec4 chan_C_subpat(int i, float t)
{
    vec4 n = vec4(0.0, 0.0, 0.0, 0.0);

    if (i == 0) {M(52,15,1)M(81,7,2)M(64,16,2)M(52,15,2)M(83,7,3)M(52,15,3)M(64,16,3)M(81,7,2)}
    if (i == 1) {M(52,15,2)M(81,7,2)M(64,16,2)M(52,15,2)M(83,7,3)M(52,15,3)M(64,16,3)M(83,7,3)}
    if (i == 2) {M(52,15,3)M(79,7,2)M(64,16,2)M(52,15,2)M(81,7,3)M(52,15,3)M(64,16,3)M(74,7,1)}
    if (i == 3) {M(52,15,1)M(74,7,1)M(64,16,1)M(52,15,1)M(76,7,3)M(52,15,3)M(64,16,3)M(74,7,1)}

    return n;
}

vec4 chan_B_subpat(int i, float t)
{
    vec4 n = vec4(0.0, 0.0, 0.0, 0.0);

    if (i == 0)
    {
        N(1,79,4,4)N(2,81,4,4)N(5,83,4,4)N(1,79,4,4)N(2,81,4,4)N(3,83,4,4)N(2,84,4,4)
        N(1,83,4,4)N(2,81,4,4)N(5,72,4,4)N(1,86,4,1)N(1,86,4,1)N(1,86,4,1)N(2,88,4,3)
        N(1,88,4,3) N(1,86,4,1)N(1,86,4,1)N(1,79,4,4)N(2,81,4,4)N(5,83,4,4)N(1,79,4,4)
        N(2,81,4,4)N(3,83,4,4)N(2,84,4,4)N(1,83,4,4)N(2,81,4,4)N(5,72,4,4)
        N(1,86,4,1)N(1,86,4,1)N(1,86,4,1)N(2,88,4,3)N(1,88,4,3) N(1,90,4,3)N(1,90,4,3)
    }

    if (i == 1)
    {
        N(1,83,4,4)N(2,84,4,4)N(5,86,4,4)N(1,83,4,4)N(2,84,4,4)N(3,86,4,4)N(2,88,4,4)
        N(1,86,4,4)N(2,84,4,4)N(5,79,4,4)N(1,90,4,3)N(1,90,4,3)N(1,90,4,3)N(2,91,4,1)
        N(1,91,4,1) N(1,90,4,3)N(1,90,4,3)N(1,83,4,4)N(2,84,4,4)N(5,86,4,4)N(1,83,4,4)
        N(2,84,4,4)N(3,86,4,4)N(2,88,4,4)N(1,86,4,4)N(2,84,4,4)N(5,79,4,4)
        N(1,90,4,3)N(1,90,4,3)N(1,90,4,3)N(2,91,4,1)N(1,91,4,1) N(1,90,4,3)N(1,90,4,3)
    }

    if (i == 2)
    {
        N(1,74,5,9)N(1,81,5,9)R(1)N(5,83,5,9)N(1,81,5,9)N(1,81,5,9)N(1,79,5,9)N(1,74,5,9)
        R(1)N(1,79,5,9)R(1)N(1,76,5,9)N(1,77,5,9)R(1)N(1,76,5,9)R(1)N(1,74,5,9)N(1,72,5,9)
        R(1)N(2,69,5,9)N(2,88,7,5)N(2,86,7,5)N(1,74,2,8)N(1,76,2,8)N(1,74,2,8)N(1,74,5,9)
        N(1,81,5,9)R(1)N(5,83,5,9)N(1,81,5,9)N(1,81,5,9)N(1,79,5,9)N(1,74,5,9)R(1)
        N(1,79,5,9)R(1)N(1,76,5,9)N(1,77,5,9)R(1)N(1,76,5,9)R(1)N(1,79,5,9)N(1,79,5,9)R(1)
        N(2,78,5,9)N(2,79,7,5)N(2,81,7,5)N(1,74,2,8)N(1,76,2,8)N(1,78,2,8)
    }

    return n;
}

vec4 chan_A_pat(float t)
{
    float subpat_len = 8.0 / STEP;
    t = mod(t, 64.0 / STEP);
    int p = int(t / subpat_len);

    int q = 0;
    if (p == 2 || p == 6) q = 1;
    if (p == 3 || p == 7) q = 2;

    t = mod(t, subpat_len);

    return chan_A_subpat(q, t);
}

vec4 chan_C_pat(float t)
{
    float subpat_len = 8.0 / STEP;
    int p = int(t / subpat_len);
    int q = p - (p / 4) * 4;

    t = mod(t, subpat_len);

    return chan_C_subpat(q, t);
}

vec4 chan_B_pat(float t)
{
    float subpat_len = 64.0 / STEP;
    int p = int(t / subpat_len);

    int q = 0;
    if (p == 1) q = 1;
    if (p == 2 || p == 3) q = 2;

    t = mod(t, subpat_len);

    return chan_B_subpat(q, t);
}

//

#define PHI_INC(cnt, val) cnt < 0.0 ? 0.0 : exp2(float(val) / 12.0) * clamp(cnt, 0.0, 1.0), cnt -= 1.0
#define PHI_REP(cnt, val) cnt < 0.0 ? 0.0 : exp2(float(val) / 12.0) * max(cnt, 0.0)

float arpeggio3(float p, int d0, int d1, int d2)
{
    float phi = 0.0;
    float mp = mod(p, 3.0);
    float cp = floor(p / 3.0);

    phi += PHI_INC(mp, d0);
    phi += PHI_INC(mp, d1);
    phi += PHI_INC(mp, d2);

    float f0 = exp2(float(d0) / 12.0);
    float f1 = exp2(float(d1) / 12.0);
    float f2 = exp2(float(d2) / 12.0);

    phi += (f0 + f1 + f2) * cp;

    return phi;
}

float ornament(int i, float t)
{
    float p = t * INT_PER_STEP * STEP;
    float phi = 0.0;

    if (i == 1) phi = arpeggio3(p, -8, -5,  0);
    if (i == 2) phi = arpeggio3(p, -7, -3,  0);
    if (i == 3) phi = arpeggio3(p, -9, -4,  0);
    if (i == 4) phi = arpeggio3(p,  0,  7, 12);

    if (i == 5)
    {
        phi += PHI_INC(p, 12);
        phi += PHI_INC(p, 12);
        phi += PHI_REP(p, 0);
    }

    if (i == 8)
    {
        phi += PHI_INC(p, 0);
        phi += PHI_INC(p, 24);
        phi += PHI_INC(p, 0);
        phi += PHI_INC(p, 12);
        phi += PHI_INC(p, 0); phi += PHI_INC(p, 0); phi += PHI_INC(p, 0); phi += PHI_INC(p, 12);
        phi += PHI_INC(p, 0); phi += PHI_INC(p, 0); phi += PHI_INC(p, 0); phi += PHI_INC(p, 12);
        phi += PHI_REP(p, 0);
    }

    if (i == 9)
    {
        phi += PHI_INC(p,-12);
        phi += PHI_INC(p, 0);
        phi += PHI_INC(p, 19);
        phi += PHI_REP(p, 0);
    }

    return phi / (INT_PER_STEP * STEP);
}

vec2 xsample(int i, float t)
{
    float p = t * INT_PER_STEP * STEP;
    int   ip = int(p);
    vec2  s = vec2(0.0, 0.0);

    if (i == 2)
    {
        s.x = clamp(15.0 - p, 0.0, 15.0);
        s.y = ip == 0 ? 1.0 : 0.0;
    }
    
    if (i == 11)
    {
        s.x = clamp(15.0 - p, 0.0, 15.0);
    }

    if (i == 4)
    {
        s.x = clamp(16.0 - p, 9.0, 15.0);
    }

    if (i == 5)
    {
        s.x = clamp(14.5 - p * 0.5, 12.0, 14.0);
        s.x = mix(s.x,
            clamp(s.x + sin(p * 3.1415 * 0.4) * 0.4, 0.0, 15.0),
            clamp(p - 17.0, 0.0, 1.0));

        s.y = ip == 0 ? 1.0 : 0.0;
    }

    if (i == 7)
    {
        s.x = clamp(16.0 - p * 0.85, 0.0, 15.0);
        if (p > 11.0) s.x = clamp(10.0 - abs(14.0 - p), 0.0, 15.0);
        s.y = ip == 0 ? 1.0 : 0.0;
    }

    if (i == 15)
    {
        s.x = clamp(17.0 - p * 2.2, 0.0, 15.0);
        s.x = p > 5.0 ? 0.0 : s.x;
    }

    if (i == 16)
    {
        s.x = clamp(15.5 - p * 0.5, 0.0, 15.0);
        s.x = p > 10.0 ? 0.0 : s.x;
        s.y = 1.0;
    }

    return s;
}

//

vec2 hash22(vec2 p)
{
    p  = fract(p * vec2(5.3983, 5.4427));
    p += dot(vec2(p.y, p.x), p + vec2(21.5351, 14.3137));
    return fract(vec2(p.x * p.y * 95.4337, p.x * p.y * 97.597));
}

vec2 noise(float t)
{
    return hash22(vec2(t, t * 1.423)) * 2.0 - 1.0;
}

vec2 lpnoise(float t, float fq)
{
    t *= fq;

    float tt = fract(t);
    float tn = t - tt;
    tt = smoothstep(0.0, 1.0, tt);

    vec2 n0 = noise(floor(tn + 0.0) / fq);
    vec2 n1 = noise(floor(tn + 1.0) / fq);

    return mix(n0, n1, tt);
}

//

float getVolumeAY(float v_0_15)
{
    float vol = exp2(-(31.0 - (v_0_15 * 31.0 / 15.0)) * 0.215) - 0.011;

    return clamp(vol, 0.0, 1.0);
}

float synthAY(float phi, float f0, float v, float n, float ns)
{
    float vol = 0.5 * getVolumeAY(v);
    float y = fract(phi * f0);

    #if DO_BANDLIMIT
        float q = 0.75 * min(iSampleRate, 44100.0) / f0;
        y = abs(y * 2.0 - 1.0) * 2.0 - 1.0;
        y = y >= 0.0 ? 1.0 - pow(1.0 - y, q) : pow(1.0 + y, q) - 1.0;
        y = y * 0.5 + 0.5;
    #else
        y = y > 0.5 ? 1.0 : 0.0;
    #endif

    return vol * (y * 2.0 - 1.0) * (n * y > 0.0 ? ns : 1.0);
}

float synthTrack(vec4 note, float ns)
{
    float phi = ornament(int(note.w), note.y);
    vec2  smp = xsample(int(note.z), note.y);
    float f0  = 0.45 * 16.35 * exp2(note.x / 12.0);

    return synthAY(phi, f0, smp.x, smp.y, ns);
}
    
vec2 mainSound( in int samp,float time)
{
    time = max(0.0, time - WARMUP_TIME);
    float k = 44100.0 / iSampleRate;

    float n = lpnoise(time, 0.75 * 44100.0 * k).x;
    float a = synthTrack(chan_A_pat(time), n);
    float b = synthTrack(chan_B_pat(time), n);
    float c = synthTrack(chan_C_pat(time), n);

    vec2 w = vec2(0.86, 0.50) * a + vec2(0.62, 0.64) * b + vec2(0.62, 0.92) * c;

    // fade-out
    float fd = clamp(58.0 - time - WARMUP_TIME, 0.0, 1.0);
    w *= getVolumeAY(fd * 15.0);

    // cursor click when entering the editor
    if (time + WARMUP_TIME > 59.75)
    {
        float t = time + WARMUP_TIME - 59.75;
        t *= k;
        float v = exp2(-t * 400.0);
        if (t > 0.0035) v *= -2.0;
        
        w += vec2(v, v);
    }

    if (time == 0.0) w = vec2(0.0, 0.0);

    return w * MASTER_VOLUME;
}