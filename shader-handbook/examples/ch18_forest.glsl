// 第 18 章 · 森林味道：尖朝上的三角树冠 + 多层 + 雾 + 光柱
float hash11(float n) { return fract(sin(n) * 43758.5453); }

// p 局部：树脚在 (0,0)，向上为正 y
float sdTree(vec2 p)
{
    // 树干：细长盒
    float trunk = max(abs(p.x) - 0.028, max(-p.y, p.y - 0.22));

    // 三层尖朝上的三角冠（tip 在上）
    float crown = 1e5;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        // 每层底部中心
        float baseY = 0.18 + fi * 0.20;
        float tipY  = baseY + 0.28 - fi * 0.02;
        float halfW = 0.30 - fi * 0.06;
        // 把点变到「底边中心为原点、尖在 +y」的局部
        vec2 q = p - vec2(0.0, baseY);
        float h = tipY - baseY;
        // 向上三角：底部宽、顶部尖
        // 在高度 u∈[0,h] 处半宽 = halfW * (1 - u/h)
        float u = clamp(q.y, 0.0, h);
        float w = halfW * (1.0 - u / h);
        float dTri = max(max(-q.y, q.y - h), abs(q.x) - w);
        crown = min(crown, dTri);
    }
    return min(trunk, crown);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.1;

    vec3 sky = mix(vec3(0.98, 0.78, 0.52), vec3(0.40, 0.65, 0.92),
                   smoothstep(-0.2, 0.8, uv.y));
    vec2 sunP = vec2(0.55, 0.38);
    sky += vec3(1.0, 0.95, 0.75) * exp(-length(uv - sunP) * 8.0) * 0.7;

    vec3 col = sky;

    float hill = 0.12 * sin(uv.x * 1.8 + 0.5) + 0.05 * sin(uv.x * 4.0);
    col = mix(col, vec3(0.42, 0.48, 0.40),
              smoothstep(0.02, -0.01, uv.y + 0.05 - hill) * 0.7);

    for (int layer = 0; layer < 3; layer++) {
        float fl = float(layer);
        float scl = mix(1.25, 0.5, fl / 2.0);
        float y0 = mix(-0.72, -0.28, fl / 2.0);
        float fog = 0.15 + 0.4 * (fl / 2.0);
        vec3 tcol = mix(vec3(0.05, 0.18, 0.07), vec3(0.20, 0.34, 0.16), fl / 2.0);

        float cell = 0.42 * scl + 0.05;
        float worldX = uv.x + t * (0.04 + 0.02 * fl) + fl * 0.31;
        float id = floor(worldX / cell);
        float fx = fract(worldX / cell) - 0.5;
        float hMul = 0.8 + 0.55 * hash11(id + fl * 17.0);

        // 本地：脚在 y=0
        vec2 tp;
        tp.x = fx / (0.45);
        tp.y = (uv.y - y0) / (scl * hMul);
        tp.x += 0.03 * sin(iTime * 1.3 + id) * clamp(tp.y, 0.0, 1.0);

        float d = sdTree(tp);
        float m = smoothstep(0.015, -0.008, d);
        col = mix(col, mix(tcol, sky * 0.85, fog), m);
    }

    col = mix(col, vec3(0.12, 0.16, 0.08), smoothstep(0.02, -0.02, uv.y + 0.78));

    // 光柱
    float shafts = 0.0;
    vec2 dir = normalize(sunP - vec2(0.0, -0.5));
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        vec2 s = uv + dir * fi * 0.04;
        shafts += exp(-abs(s.x - 0.2 * sin(s.y * 3.0 + t)) * 10.0);
    }
    col += vec3(1.0, 0.92, 0.7) * shafts * 0.035 * smoothstep(-0.5, 0.2, uv.y);

    fragColor = vec4(pow(max(col, 0.0), vec3(0.95)), 1.0);
}
