// 第 18 章 · 森林味道：醒目尖朝上三角树 + 多层雾 + 光柱
float hash11(float n) { return fract(sin(n) * 43758.5453); }

// 实心等腰三角：尖在 tip、底边中心在 base、半宽 halfW（2D 覆盖函数，<0 在内）
float sdTriUp(vec2 p, vec2 base, float h, float halfW)
{
    vec2 q = p - base;
    // 高度 [0,h]，半宽从 halfW 收到 0
    float t = clamp(q.y / max(h, 1e-4), 0.0, 1.0);
    float w = mix(halfW, 0.0, t);
    // 盒状近似 SDF（分类够稳，抗锯齿靠 smoothstep）
    float d = max(max(-q.y, q.y - h), abs(q.x) - w);
    return d;
}

// 一棵树：粗干 + 三层大三角冠（尖朝上）
float sdTree(vec2 p)
{
    // 树干：脚在 y=0
    float trunk = max(abs(p.x) - 0.045, max(-p.y - 0.02, p.y - 0.28));

    // 底层最宽，上层最尖、最高
    float c0 = sdTriUp(p, vec2(0.0, 0.22), 0.42, 0.38);
    float c1 = sdTriUp(p, vec2(0.0, 0.42), 0.40, 0.28);
    float c2 = sdTriUp(p, vec2(0.0, 0.62), 0.38, 0.18);
    float crown = min(c0, min(c1, c2));
    return min(trunk, crown);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.08;

    // 天空 + 太阳
    vec3 sky = mix(vec3(0.98, 0.72, 0.48), vec3(0.35, 0.62, 0.95),
                   smoothstep(-0.15, 0.85, uv.y));
    vec2 sunP = vec2(0.62, 0.42);
    sky += vec3(1.0, 0.95, 0.7) * exp(-length(uv - sunP) * 7.0) * 0.85;

    vec3 col = sky;

    // 远山
    float hill = 0.10 * sin(uv.x * 1.6 + 0.4) + 0.04 * sin(uv.x * 3.7);
    float hm = smoothstep(0.03, -0.02, uv.y + 0.02 - hill);
    col = mix(col, vec3(0.45, 0.50, 0.38), hm * 0.75);

    // 三层树：近大远小、近深远淡
    for (int layer = 0; layer < 3; layer++) {
        float fl = float(layer);
        float scl = mix(1.15, 0.55, fl / 2.0);   // 世界高度缩放
        float y0  = mix(-0.78, -0.32, fl / 2.0); // 树脚 y
        float fog = 0.08 + 0.38 * (fl / 2.0);
        vec3 tcol = mix(vec3(0.04, 0.16, 0.06), vec3(0.18, 0.32, 0.14), fl / 2.0);

        float cell = mix(0.55, 0.38, fl / 2.0);
        float worldX = uv.x + t * (0.05 + 0.03 * fl) + fl * 0.27;
        float id = floor(worldX / cell);
        float fx = fract(worldX / cell) - 0.5;

        // 跳过太靠边的格子，减少贴边裁切
        if (abs(fx) < 0.48) {
            float hMul = 0.75 + 0.55 * hash11(id * 1.7 + fl * 19.0);
            float xOff = (hash11(id + 3.1) - 0.5) * 0.12;

            // 本地坐标：脚 (0,0)，x 用 cell 归一，y 用树高缩放
            vec2 tp;
            tp.x = (fx - xOff) * 2.15;                 // 让半宽 ~0.38 占满格
            tp.y = (uv.y - y0) / max(scl * hMul, 1e-3);
            // 轻摇：越高晃越大
            tp.x += 0.04 * sin(iTime * 1.4 + id) * clamp(tp.y, 0.0, 1.2);

            float d = sdTree(tp);
            float m = smoothstep(0.02, -0.01, d);
            col = mix(col, mix(tcol, sky * 0.9, fog), m);
        }
    }

    // 前景地
    col = mix(col, vec3(0.10, 0.14, 0.07), smoothstep(0.03, -0.02, uv.y + 0.82));

    // 廉价光柱
    float shafts = 0.0;
    vec2 dir = normalize(sunP - vec2(0.0, -0.55));
    for (int i = 0; i < 7; i++) {
        float fi = float(i);
        vec2 s = uv + dir * fi * 0.045;
        shafts += exp(-abs(s.x - 0.18 * sin(s.y * 2.8 + t * 2.0)) * 9.0);
    }
    col += vec3(1.0, 0.92, 0.7) * shafts * 0.04 * smoothstep(-0.55, 0.25, uv.y);

    fragColor = vec4(pow(max(col, 0.0), vec3(0.95)), 1.0);
}
