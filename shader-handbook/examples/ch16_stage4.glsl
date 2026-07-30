// 第 16 章 · 交互模拟 · 阶段 4：音频反应隧道 / 能量球（HARD · Showcase）
// 假频谱驱动隧道半径、配色与 ~0.5s 节拍脉冲；无 iChannel0 也能「听感」同步。
//
// 真版：FFT bins → 低频控 pulse，中频控 twist，高频控 sparkle。
const float TAU = 6.2831853;
const int FFT_BINS = 16;

float hash11(float n) { return fract(sin(n) * 43758.5453); }

float fakeBin(int i, float t)
{
    float fi = float(i);
    float v = sin(t * (1.8 + fi * 0.42) + fi * 1.1) * 0.5 + 0.5;
    v *= exp(-fi * 0.08);
    return v;
}

float beatPulse(float t)
{
    float bpm = 120.0;
    float beat = mod(t * bpm / 60.0, 1.0);
    return smoothstep(0.92, 0.0, beat) + smoothstep(0.45, 0.0, abs(beat - 0.5)) * 0.5;
}

float lowEnergy(float t)
{
    float s = 0.0;
    for (int i = 0; i < 4; i++)
        s += fakeBin(i, t);
    return s / 4.0;
}

float hiEnergy(float t)
{
    float s = 0.0;
    for (int i = 8; i < FFT_BINS; i++)
        s += fakeBin(i, t);
    return s / float(FFT_BINS - 8);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float t = iTime;

    float low  = lowEnergy(t);
    float hi   = hiEnergy(t);
    float beat = beatPulse(t);
    float pulse = 0.65 + 0.35 * beat + low * 0.25;

    // 极坐标隧道
    float a = atan(p.y, p.x);
    float r = length(p);

    float twist = a + r * (3.5 + low * 2.0) - t * (1.2 + hi * 0.8);
    float radius = 0.22 + 0.06 * sin(twist * 2.0) * pulse;
    radius += 0.03 * sin(t * 8.0 + a * 6.0) * hi;

    float tunnel = smoothstep(radius + 0.015, radius - 0.015, abs(sin(twist * 4.0 + t * 2.0)));
    tunnel *= exp(-r * 1.1) * pulse;

    vec3 cA = vec3(0.1, 0.5 + low * 0.5, 1.0);
    vec3 cB = vec3(1.0, 0.2 + hi * 0.6, 0.55 + beat * 0.3);
    vec3 col = mix(cA, cB, 0.5 + 0.5 * sin(twist + t * 0.5));
    col *= tunnel;

    // 中心能量球
    float orbR = 0.12 + low * 0.06 + beat * 0.04;
    float orb = smoothstep(orbR + 0.02, orbR - 0.02, r);
    vec3 orbCol = mix(vec3(1.0, 0.85, 0.4), vec3(0.3, 0.95, 1.0), hi);
    col = mix(col, orbCol * (1.2 + beat), orb);
    col += orbCol * exp(-r * 12.0) * (0.4 + beat * 0.6);

    // 节拍闪白
    col += vec3(1.0) * beat * exp(-r * 3.0) * 0.15;

    // 高频 sparkle
    col += vec3(0.9, 0.95, 1.0) * hi * step(0.97, hash11(r * 100.0 + floor(t * 30.0))) * tunnel;

    vec3 bg = vec3(0.01, 0.015, 0.04);
    col = mix(bg, col, smoothstep(0.0, 0.05, tunnel + orb));

    col = col / (col + vec3(0.5));
    col *= 0.65 + 0.35 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.25);
    col = pow(col, vec3(0.92));

    fragColor = vec4(col, 1.0);
}
