// 第 18 章 · 森林味道：明显的三角树冠剪影 + 多层雾 + 阳光柱
float hash11(float n) { return fract(sin(n) * 43758.5453); }

// 经典「圣诞树」轮廓：三层倒三角 + 细树干
float sdTree(vec2 p)
{
    float d = 1e5;
    // 树干
    d = min(d, max(abs(p.x) - 0.03, max(p.y + 0.05, -p.y - 0.35)));
    // 三层冠
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        vec2 q = p - vec2(0.0, 0.05 + fi * 0.22);
        float halfW = 0.28 - fi * 0.05;
        // 倒三角：|x|/w + y
        float tri = max(abs(q.x) / halfW + q.y * 1.35, -q.y - 0.02);
        d = min(d, tri);
    }
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.12;

    vec3 sky = mix(vec3(0.95, 0.72, 0.48), vec3(0.45, 0.68, 0.90),
                   smoothstep(-0.15, 0.75, uv.y));
    vec2 sunP = vec2(0.62, 0.42);
    sky += vec3(1.0, 0.95, 0.75) * exp(-length(uv - sunP) * 7.0) * 0.65;

    vec3 col = sky;

    // 远山
    float hill = 0.10 * sin(uv.x * 1.7) + 0.05 * sin(uv.x * 4.3 + 1.2);
    col = mix(col, vec3(0.40, 0.48, 0.42),
              smoothstep(0.015, -0.01, uv.y + 0.02 - hill) * 0.65);

    // 三层树林
    for (int layer = 0; layer < 3; layer++) {
        float fl = float(layer);
        float scl = mix(1.35, 0.55, fl / 2.0);
        float yBase = mix(-0.52, -0.18, fl / 2.0);
        float fog = fl / 2.0 * 0.5;
        vec3 tcol = mix(vec3(0.06, 0.16, 0.08), vec3(0.22, 0.32, 0.18), fl / 2.0);

        float cell = 0.48 * scl;
        float worldX = uv.x + t * (0.03 + 0.02 * fl) + fl * 0.2;
        float id = floor(worldX / cell);
        float fx = fract(worldX / cell) - 0.5;
        float hMul = 0.75 + 0.5 * hash11(id * 3.1 + fl);

        vec2 tp = vec2(fx * 1.35, (uv.y - yBase) / (scl * hMul));
        // 轻微摆动
        tp.x += 0.02 * sin(iTime * 1.5 + id) * max(tp.y, 0.0);

        float d = sdTree(tp);
        float m = smoothstep(0.02, -0.005, d);
        col = mix(col, mix(tcol, sky, fog), m);
    }

    // 地面
    col = mix(col, vec3(0.14, 0.18, 0.10), smoothstep(0.02, -0.02, uv.y + 0.65));

    // 廉价光柱
    float shafts = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        vec2 s = uv - normalize(uv - sunP + 1e-3) * fi * 0.05;
        shafts += exp(-abs(s.x * 0.9 + 0.15 * sin(s.y * 4.0 + t)) * 14.0);
    }
    col += vec3(1.0, 0.9, 0.65) * shafts * 0.04 * smoothstep(-0.4, 0.3, uv.y);

    fragColor = vec4(pow(max(col, 0.0), vec3(0.95)), 1.0);
}
