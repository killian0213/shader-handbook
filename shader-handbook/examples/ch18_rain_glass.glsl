// 第 18 章 · 效果配方 · 雨打玻璃
// 心法：水珠 SDF 扭曲背景 UV + 拖尾 streak；背景用彩色渐变模拟窗外景。
// 语料对照：窗上水珠类（Rain on window / glass drops）

float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec2 hash22(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 34.345);
    return fract(vec2(p.x * p.y, p.x + p.y) * 345.456);
}

vec3 windowScene(vec2 uv)
{
    vec3 sky = mix(vec3(0.15, 0.22, 0.38), vec3(0.55, 0.65, 0.82), uv.y);
    float sun = exp(-length(uv - vec2(0.72, 0.78)) * 8.0);
    sky += vec3(1.0, 0.85, 0.5) * sun * 0.35;
    float bld = smoothstep(0.35, 0.0, abs(uv.x - 0.25) - 0.08) * smoothstep(0.0, 0.55, uv.y);
    sky = mix(sky, vec3(0.08, 0.09, 0.12), bld);
    return sky;
}

float drop(vec2 p, vec2 c, float r)
{
    vec2 q = p - c;
    float d = length(q) - r;
    float lens = 1.0 - smoothstep(0.0, r, length(q));
    return d - lens * 0.015;
}

vec2 dropNormal(vec2 p, vec2 c, float r)
{
    vec2 e = vec2(0.004, 0.0);
    float dx = drop(p + e.xy, c, r) - drop(p - e.xy, c, r);
    float dy = drop(p + e.yx, c, r) - drop(p - e.yx, c, r);
    return normalize(vec2(dx, dy));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float t = iTime;

    vec2 distort = vec2(0.0);
    float wet = 0.0;

    // 静态 + 缓慢新生水珠
    for (int i = 0; i < 28; i++) {
        float fi = float(i);
        vec2 seed = hash22(vec2(fi, fi * 1.7));
        vec2 c = seed * vec2(1.6, 0.9) - vec2(0.8, 0.45);
        float r = 0.015 + seed.x * 0.025;
        float age = fract(t * (0.08 + seed.y * 0.12) + seed.x * 10.0);
        c.y += age * 0.35;

        float d = drop(p, c, r);
        if (d < 0.02) {
            vec2 n = dropNormal(p, c, r);
            distort += n * smoothstep(0.02, -0.01, d) * 0.06;
            wet = max(wet, smoothstep(0.015, -0.005, d));
        }

        // 拖尾 streak
        vec2 trail = c + vec2(0.0, -0.08 * age);
        float td = length((p - trail) * vec2(1.0, 4.0)) - r * 0.35;
        wet = max(wet, smoothstep(0.01, 0.0, td) * 0.4);
    }

    vec2 bgUv = uv + distort;
    bgUv.y += wet * 0.008;
    vec3 col = windowScene(bgUv);

    // 玻璃高光与边缘
    col += vec3(0.9) * wet * 0.15;
    col = mix(col, vec3(0.85, 0.9, 1.0), wet * 0.08);
    col *= 0.92 + 0.08 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.2);

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
