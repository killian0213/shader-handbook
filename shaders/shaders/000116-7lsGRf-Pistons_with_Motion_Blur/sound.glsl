// Sound (sound) — Pistons with Motion Blur by bad_dreams_
// https://www.shadertoy.com/view/7lsGRf

float hash11(float x) { return fract(sin(x * 3759.371 + 1546.3316) * 5752.1534); }

// Very noob attempt at sound effects.
vec2 mainSound(int samp, float time) {
    float camAngle = getCamAngle(0.0, time);
    float time2 = time * time;
    
    float initial = sin(camAngle);
    float shotRamp = clamp(time2 * 0.05 - 0.001, 0.0, 0.1);
    float extraRamp = clamp(time2 * 0.001 - 0.0001, 0.0, 0.05);
    float noise = hash11(time) * min(time2 * 0.1, 0.1);
    float shot = (1.0 - fract(initial)) * 2.0 - 1.0;
    float noiseRamp = time > 2.0 ? min(max(time * 0.25 - 2.0, 0.0), 1.0) : 0.0;
    
    float primary = shot * shotRamp * 1.0;
    float secondary = shot * hash11(time + 1.0) * extraRamp * 1.0;
    float tertiary = noise * shot * noiseRamp * 0.6;
    return vec2(primary + secondary + tertiary);
}