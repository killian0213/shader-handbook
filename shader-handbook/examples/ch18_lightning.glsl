// 第 18 章 · 效果配方 · 闪电
// 心法：hash 驱动分支折线 + 距离场辉光；背景为暗色风暴云 fbm。
// 语料对照：Lightning / storm 类作品

float hash11(float n) { return fract(sin(n) * 43758.5453); }

float vnoise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash11(dot(i, vec2(127.1, 311.7)));
    float b = hash11(dot(i + vec2(1, 0), vec2(127.1, 311.7)));
    float c = hash11(dot(i + vec2(0, 1), vec2(127.1, 311.7)));
    float d = hash11(dot(i + vec2(1, 1), vec2(127.1, 311.7)));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * vnoise(p);
        p = p * 2.1 + vec2(13.0);
        a *= 0.5;
    }
    return v;
}

float segDist(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float lightning(vec2 p, float seed, float t)
{
    float flash = step(0.55, hash11(seed + floor(t * 2.5)));
    if (flash < 0.5) return 0.0;

    vec2 pos = vec2(hash11(seed) * 0.6 - 0.3, 0.95);
    float d = 1e6;

    for (int i = 0; i < 8; i++) {
        float fi = float(i);
        vec2 next = pos + vec2((hash11(seed + fi * 7.3) - 0.5) * 0.18, -0.12 - hash11(seed + fi) * 0.08);
        d = min(d, segDist(p, pos, next));
        pos = next;

        // 分支
        if (hash11(seed + fi * 3.1) > 0.55) {
            vec2 br = pos + vec2((hash11(seed + fi * 11.0) - 0.5) * 0.25, -0.06);
            d = min(d, segDist(p, pos, br));
        }
    }

    float core = exp(-d * 120.0);
    float glow = exp(-d * 35.0) * 0.35;
    return (core + glow) * (0.6 + 0.4 * sin(t * 40.0 + seed));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime;

    // 风暴云
    float c1 = fbm(uv * 1.8 + vec2(t * 0.02, 0.0));
    float c2 = fbm(uv * 3.5 - vec2(t * 0.03, t * 0.01));
    vec3 col = mix(vec3(0.02, 0.025, 0.04), vec3(0.12, 0.14, 0.18), c1);
    col = mix(col, vec3(0.06, 0.07, 0.1), c2 * 0.5);

    float bolt = lightning(uv, 42.0, t) + lightning(uv, 17.0, t + 0.3) * 0.7;
    col += vec3(0.7, 0.85, 1.0) * bolt;
    col += vec3(1.0, 0.95, 0.85) * bolt * bolt * 0.8;

    // 云被闪电照亮
    col += vec3(0.15, 0.18, 0.25) * bolt * 0.4;

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
