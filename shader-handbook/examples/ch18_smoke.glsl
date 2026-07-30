// 第 18 章 · 效果配方 · 上升烟雾
// 2D 域扭曲 + 多层 alpha  slab，暗背景柔边体积感。

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
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = r * p;
        a *= 0.5;
    }
    return v;
}

float smokeLayer(vec2 uv, float t, float spd, float scl)
{
    vec2 q = uv;
    q.x += fbm(uv * 1.8 + vec2(t * spd, 0.0)) * 0.35;
    q.y += t * spd * 0.6;
    float n = fbm(q * scl);
    n = smoothstep(0.42, 0.72, n);
    float rise = smoothstep(-0.7, 0.5, uv.y);
    return n * rise;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.35;

    vec3 col = vec3(0.02, 0.025, 0.04);
    col += vec3(0.08, 0.06, 0.12) * exp(-length(uv - vec2(-0.3, -0.5)) * 1.2);

    float a1 = smokeLayer(uv, t, 0.25, 2.2) * 0.55;
    float a2 = smokeLayer(uv + vec2(0.15, -0.1), t * 1.1, 0.18, 2.8) * 0.45;
    float a3 = smokeLayer(uv + vec2(-0.1, 0.05), t * 0.9, 0.12, 3.5) * 0.35;
    float alpha = 1.0 - (1.0 - a1) * (1.0 - a2) * (1.0 - a3);

    vec3 smoke = mix(vec3(0.35, 0.38, 0.42), vec3(0.75, 0.78, 0.82), uv.y + 0.4);
    col = mix(col, smoke, clamp(alpha, 0.0, 1.0));

    // 微弱热源
    col += vec3(1.0, 0.45, 0.15) * exp(-length(uv - vec2(0.0, -0.65)) * 5.0) * 0.25;

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
