// 第 14 章 · 阶梯实战 · 阶段 9：生命游戏「外观」（单 Pass 假 CA）
// 用 floor(iTime) 驱动代数 + 局部 hash 规则，滚动演化出方块/闪烁器美学。
// 真·Conway Life = Buffer A→B 邻居计数 + texelFetch(nearest)；这里只有「味道」。
float hash11(float n) { return fract(sin(n) * 43758.5453); }

// 经典 Life 种子：滑翔机 + 闪烁器 + 方块（64×64 局部坐标）
float lifeSeed(vec2 c)
{
    c = mod(c, 64.0);
    float v = 0.0;

    // 方块 2×2
    if (all(greaterThanEqual(c, vec2(8.0, 8.0))) && all(lessThan(c, vec2(10.0, 10.0))))
        v = 1.0;

    // 闪烁器（垂直）
    if (abs(c.x - 20.0) < 0.5 && abs(c.y - 12.0) < 1.5) v = 1.0;

    // 滑翔机
    vec2 g = c - vec2(40.0, 40.0);
    if (g == vec2(0, 0) || g == vec2(1, 0) || g == vec2(2, 0) ||
        g == vec2(2, 1) || g == vec2(1, 2)) v = 1.0;

    // 随机噪点种子
    v = max(v, step(0.965, hash11(dot(c, vec2(127.1, 311.7)))));

    return v;
}

// 单 Pass 伪演化：代数 gen + 坐标 hash 模拟邻居投票（非真实 Life 规则）
float pseudoLife(vec2 id, float gen)
{
    float alive = lifeSeed(id + floor(gen * 0.15) * vec2(3.0, 1.0));

    float n = 0.0;
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++) {
            if (i == 0 && j == 0) continue;
            vec2 nb = id + vec2(float(i), float(j));
            float h = hash11(dot(nb, vec2(269.5, 183.3)) + gen * 17.0);
            n += mix(lifeSeed(nb), step(0.42, h), 0.55);
        }

    // 近似 B3/S23：活→2/3 续命，死→3 诞生；再加一点时间相位做闪烁器感
    float blink = 0.5 + 0.5 * sin(gen * 1.5708 + hash11(id.x + id.y * 13.0) * 6.28);
    if (alive > 0.5)
        return (n > 1.5 && n < 3.5) ? 1.0 : mix(0.0, 1.0, blink * step(n, 2.1));
    return step(2.5, n) * step(n, 3.5);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;

    // 720×405 友好：格点约 90×50
    vec2 grid = floor(vec2(uv.x * aspect, uv.y) * vec2(90.0, 50.0));
    float gen = floor(iTime * 2.5);

    float cell = pseudoLife(grid, gen);

    // 格线 + 活细胞亮绿，死细胞深青
    vec2 fc = fract(vec2(uv.x * aspect, uv.y) * vec2(90.0, 50.0));
    float gridLine = smoothstep(0.92, 1.0, max(fc.x, fc.y));
    vec3 dead  = vec3(0.04, 0.07, 0.09);
    vec3 alive = vec3(0.15, 0.95, 0.35);
    vec3 col = mix(dead, alive, cell);
    col = mix(col, col * 0.35, gridLine);

    // 轻微扫描线暗示「代数在走」
    col *= 0.92 + 0.08 * sin(gen * 0.5 + uv.y * 80.0);

    col = pow(col, vec3(0.9));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
