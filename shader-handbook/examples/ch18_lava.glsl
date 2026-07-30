// 第 18 章 · 效果配方 · 熔岩表面
// 域扭曲噪声模拟岩浆流动与冷却壳，非简单火柱。

float hash21(vec2 p)
{
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float noise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p)
{
    float v = 0.0, a = 0.5;
    mat2 r = mat2(1.6, 1.2, -1.2, 1.6);
    for (int i = 0; i < 6; i++) {
        v += a * noise(p);
        p = r * p;
        a *= 0.5;
    }
    return v;
}

float lava(vec2 p, float t)
{
    vec2 q = p;
    q += vec2(fbm(p + t * 0.15), fbm(p + vec2(5.2, 1.3) - t * 0.12)) * 0.55;
    q = p + vec2(fbm(q * 1.4 + t * 0.08), fbm(q * 1.4 - t * 0.06)) * 0.45;
    return fbm(q * 2.5);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.4;

    float n = lava(uv, t);
    float hot = smoothstep(0.48, 0.72, n);
    float crack = smoothstep(0.35, 0.42, abs(fbm(uv * 8.0 + t * 0.05) - 0.5));

    vec3 cold = vec3(0.08, 0.02, 0.01);
    vec3 warm = vec3(0.55, 0.08, 0.02);
    vec3 core = vec3(1.0, 0.55, 0.08);
    vec3 col = mix(cold, warm, smoothstep(0.35, 0.55, n));
    col = mix(col, core, hot);
    col = mix(col, cold * 0.5, crack * 0.7);

    // 表面高光
    float spec = pow(clamp(n, 0.0, 1.0), 4.0);
    col += vec3(1.0, 0.85, 0.4) * spec * 0.35;

    // 边缘暗化
    col *= 0.6 + 0.4 * smoothstep(1.2, 0.3, length(uv));

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
