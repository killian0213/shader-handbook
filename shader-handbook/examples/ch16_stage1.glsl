// 第 16 章 · 交互模拟 · 阶段 1：假 FFT 频谱柱
// Web 预览无真实音频：用 layered sin(iTime*freq + phase) 驱动 32 根柱，
// 营造「音频可视化」Reactive 观感。
//
// 真版做法：Shadertoy 上 texture(iChannel0, vec2(bin, 0.5)).x 采样音频频谱纹理。
const int BARS = 32;
const float TAU = 6.2831853;

float hash11(float n) { return fract(sin(n) * 43758.5453); }

// 模拟第 i 个频段的「能量」
float fakeFFT(int i, float t)
{
    float fi = float(i);
    float base = sin(t * (2.0 + fi * 0.35) + fi * 0.7) * 0.5 + 0.5;
    float hi   = sin(t * (5.5 + fi * 0.8) + hash11(fi) * TAU) * 0.5 + 0.5;
    float beat = smoothstep(0.85, 1.0, sin(t * 3.2) * 0.5 + 0.5);
    float freqFalloff = exp(-fi * 0.045);
    return (base * 0.55 + hi * 0.35 + beat * 0.25) * freqFalloff + 0.08;
}

vec3 barColor(float h, float t)
{
    return mix(vec3(0.15, 0.85, 1.0), vec3(1.0, 0.35, 0.75), h)
         + vec3(0.2, 0.1, 0.0) * sin(t * 4.0 + h * 6.0) * 0.15;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    float t = iTime;

    vec3 bg = mix(vec3(0.02, 0.025, 0.05), vec3(0.04, 0.03, 0.08), uv.y);
    vec3 col = bg;

    float barW = 0.022;
    float gap  = 0.004;
    float totalW = float(BARS) * (barW + gap);
    float x0 = 0.5 - totalW * 0.5;

    for (int i = 0; i < BARS; i++) {
        float fi = float(i);
        float energy = fakeFFT(i, t);
        float bx = x0 + fi * (barW + gap);
        float by = 0.12;

        if (uv.x >= bx && uv.x < bx + barW && uv.y >= by && uv.y < by + energy * 0.72) {
            float h = (uv.y - by) / max(energy * 0.72, 0.001);
            vec3 bc = barColor(h, t + fi * 0.2);
            col = mix(col, bc, 0.95);

            // 柱顶高光
            if (uv.y > by + energy * 0.72 - 0.008)
                col += vec3(1.0, 0.95, 0.9) * 0.35;
        }

        // 柱底反射（假镜面）
        float reflY = by - (uv.y - by - energy * 0.72);
        if (uv.x >= bx && uv.x < bx + barW && reflY >= by && reflY < by + energy * 0.25) {
            float fade = 1.0 - (reflY - by) / (energy * 0.25 + 0.001);
            col += barColor(0.5, t) * fade * 0.12;
        }
    }

    // 底栏 HUD
    float hud = smoothstep(0.02, 0.0, abs(uv.y - 0.10));
    col = mix(col, vec3(0.08, 0.12, 0.18), hud * 0.5);

    col = pow(col, vec3(0.95));
    fragColor = vec4(col, 1.0);
}
