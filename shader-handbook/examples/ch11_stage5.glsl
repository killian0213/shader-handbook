// 第 11 章 · 阶梯实战 · 阶段 5：距离估计（DE）→ 描边与发光
// 循环里再同步推一个导数 z'，就能算出"这个像素离集合边界有多远"。
// 有了真正的距离，描边和辉光都变成免费的，而且宽度可以精确按【像素】给。

const int   MAX_ITER = 64;
const float BAILOUT  = 256.0;
const float TAU      = 6.2831853;

const vec2  CENTER = vec2(-0.7436, 0.0);
const float HALF_H = 1.35;

vec3 pal(float t)
{
    return vec3(0.42, 0.40, 0.42)
         + vec3(0.44, 0.42, 0.48)
         * cos(TAU * (vec3(1.00, 0.92, 0.78) * t + vec3(0.52, 0.42, 0.28)));
}

// 【改】再多带出一个 de：到 Mandelbrot 集边界的距离估计
float mandel(vec2 c, out vec2 trap, out float de)
{
    vec2  z  = vec2(0.0);
    vec2  dz = vec2(0.0);            // 【新增】z 对 c 的导数，也是复数
    float n  = 0.0;
    float m2 = 0.0;
    trap = vec2(1e10);
    for (int i = 0; i < MAX_ITER; i++)
    {
        // 【新增】z' ← 2·z·z' + 1。必须【先】更新 dz、【后】更新 z，
        // 因为链式法则里用的是这一步之前的 z。顺序写反 → 距离整体偏大，
        // 描边会离边界浮开一点点，很难一眼看出来。
        dz = 2.0 * vec2(z.x * dz.x - z.y * dz.y,
                        z.x * dz.y + z.y * dz.x) + vec2(1.0, 0.0);
        z  = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        m2 = dot(z, z);
        trap = min(trap, vec2(m2, min(abs(z.x), abs(z.y))));
        if (m2 > BAILOUT * BAILOUT) break;
        n += 1.0;
    }
    // 【新增】d ≈ |z|·log|z| / |z'|（Green 势除以它的梯度，见 11.3）。
    // 写成 |z|² 的形式可以省掉一次 sqrt：0.5·sqrt(m2/|dz|²)·log(m2)
    de = 0.5 * sqrt(m2 / max(dot(dz, dz), 1e-20)) * log(m2);

    if (n >= float(MAX_ITER)) return -1.0;
    return n - log2(log2(m2)) + 4.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 c  = CENTER + uv * HALF_H;

    vec2  trap;
    float de;
    float sn = mandel(c, trap, de);

    float tr    = sqrt(trap.x);
    vec3  inCol = pal(0.30 + 1.30 * tr) * (0.20 + 0.80 * smoothstep(0.0, 0.16, trap.y));
    inCol *= 0.55;

    vec3 exCol = pal(sqrt(max(sn, 0.0)) * 0.28);
    exCol *= 0.75 + 0.40 * smoothstep(0.0, 0.30, trap.y);

    float outside = 1.0 - step(sn, -0.5);
    vec3  col     = mix(inCol, exCol, outside);

    // 【新增】把距离换算成【像素】单位。px 是一个像素在复平面上的边长；
    // dp 就是"离边界几个像素"。这一步让描边宽度与分辨率、缩放全都无关 ——
    // 这是解析抗锯齿，比超采样便宜得多，而且永远不会糊。
    float px = 2.0 * HALF_H / iResolution.y;
    float dp = de / px;

    // 【新增】描边：贴着边界的 2 个像素
    float rim = smoothstep(2.2, 0.0, dp) * outside;
    col = mix(col, vec3(1.00, 0.96, 0.86), rim * 0.85);

    // 【新增】辉光：光是【加】上去的。exp 的系数按像素给，
    // 0.03 → 大约 33 像素外衰减到 1/e，肉眼看是"边界在发光"
    col += pal(0.55) * exp(-dp * 0.030) * 0.35 * outside;

    fragColor = vec4(col, 1.0);
}
