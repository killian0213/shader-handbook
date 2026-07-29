// 第 14 章 · 阶梯实战 · 阶段 8：软体 Blob（Metaball）
// 几个隐式场 metaball 平滑并，外加噪声扰动，像熔岩灯。
// 真版 = 粒子/元球写 Buffer 做物理；这里解析场 + 时间驱动中心。
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
    for (int i = 0; i < 4; i++) {
        v += a * vnoise(p);
        p = p * 2.1 + vec2(17.0);
        a *= 0.5;
    }
    return v;
}

float meta(vec2 uv, vec2 cen, float r)
{
    vec2 d = uv - cen;
    return r * r / (dot(d, d) + 1e-4);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.55;

    vec2 c0 = vec2(0.35 * sin(t * 0.9),  0.40 * cos(t * 1.1));
    vec2 c1 = vec2(0.42 * sin(t * 1.2 + 1.0),  0.35 * cos(t * 0.85 + 2.0));
    vec2 c2 = vec2(0.28 * sin(t * 0.7 + 3.0), -0.38 * cos(t * 1.0 + 1.5));
    vec2 c3 = vec2(-0.32 * sin(t * 1.05 + 0.5), 0.25 * cos(t * 0.95 + 4.0));
    vec2 c4 = vec2(0.15 * sin(t * 1.3 + 2.5),  0.18 * cos(t * 1.15 + 0.8));

    float field = 0.0;
    field += meta(uv, c0, 0.12 + 0.02 * sin(t * 2.0));
    field += meta(uv, c1, 0.10 + 0.015 * cos(t * 1.7));
    field += meta(uv, c2, 0.11);
    field += meta(uv, c3, 0.09);
    field += meta(uv, c4, 0.08);

    float n = fbm(uv * 3.5 + t * 0.2);
    field *= 0.92 + 0.08 * n;

    float blob = smoothstep(0.95, 1.05, field);
    float edge = smoothstep(0.02, 0.0, abs(field - 1.0));

    float heat = fbm(uv * 2.0 - vec2(t * 0.15, t * 0.2));
    vec3 inner = mix(vec3(0.95, 0.25, 0.12), vec3(1.0, 0.75, 0.15), heat);
    inner = mix(inner, vec3(0.85, 0.15, 0.55), fbm(uv * 4.0 + t));

    vec3 bg = vec3(0.03, 0.025, 0.05);
    vec3 col = mix(bg, inner, blob);
    col += vec3(1.0, 0.9, 0.7) * edge * 0.45;
    col += vec3(0.4, 0.2, 0.6) * blob * (0.3 + 0.7 * heat) * 0.25;

    col = pow(col, vec3(0.92));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
