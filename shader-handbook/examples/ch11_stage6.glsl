// 第 11 章 · 阶梯实战 · 阶段 6：缓慢缩放 + 自适应迭代上限
// 一个固定的 MAX_ITER 只够看全景。往里放大之后，边界附近需要几百次迭代才分得开，
// 上限不跟着涨，细节就会"化开"成一坨。这一阶段就是把上限接到缩放倍数上。

const int   MAX_ITER = 260;          // 【改】只当硬天花板，别再直接用它当上限
const float BAILOUT  = 256.0;
const float TAU      = 6.2831853;

const vec2  HOME   = vec2(-0.7436, 0.0);
const vec2  TARGET = vec2(-0.743643887, 0.131825904);   // 海马谷里的 Misiurewicz 点
const float HALF_H0 = 1.35;

vec3 pal(float t)
{
    return vec3(0.42, 0.40, 0.42)
         + vec3(0.44, 0.42, 0.48)
         * cos(TAU * (vec3(1.00, 0.92, 0.78) * t + vec3(0.52, 0.42, 0.28)));
}

// 【改】迭代上限改成参数 lim。硬循环界仍写 MAX_ITER，
// 让编译器知道最坏情况，真正的退出靠 i >= lim。
float mandel(vec2 c, int lim, out vec2 trap, out float de)
{
    vec2  z  = vec2(0.0);
    vec2  dz = vec2(0.0);
    float n  = 0.0;
    float m2 = 0.0;
    trap = vec2(1e10);
    for (int i = 0; i < MAX_ITER; i++)
    {
        if (i >= lim) break;
        dz = 2.0 * vec2(z.x * dz.x - z.y * dz.y,
                        z.x * dz.y + z.y * dz.x) + vec2(1.0, 0.0);
        z  = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        m2 = dot(z, z);
        trap = min(trap, vec2(m2, min(abs(z.x), abs(z.y))));
        if (m2 > BAILOUT * BAILOUT) break;
        n += 1.0;
    }
    de = 0.5 * sqrt(m2 / max(dot(dz, dz), 1e-20)) * log(m2);

    if (n >= float(lim)) return -1.0;   // 【改】和动态上限比，不再和 MAX_ITER 比
    return n - log2(log2(m2)) + 4.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 【新增】来回呼吸式缩放：zt 在 0↔1 之间余弦往返，周期约 27 秒。
    // 不用单向 exp(-t) 是因为它迟早会撞上 float 精度墙；往返永远回得来。
    float zt    = 0.5 - 0.5 * cos(iTime * 0.23);
    float halfH = HALF_H0 * exp(-zt * 7.6);        // 指数缩放才是"匀速放大"

    // 【新增】一边放大一边把镜头推到目标点上（前 30% 行程内完成）
    vec2 center = mix(HOME, TARGET, smoothstep(0.0, 0.30, zt));
    vec2 c      = center + uv * halfH;

    // 【新增】视野每缩小一半，就多给 26 次迭代。这一行是本阶段的全部重点。
    int lim = int(min(float(MAX_ITER), 64.0 + 26.0 * log2(HALF_H0 / halfH)));

    vec2  trap;
    float de;
    float sn = mandel(c, lim, trap, de);

    float tr    = sqrt(trap.x);
    vec3  inCol = pal(0.30 + 1.30 * tr) * (0.20 + 0.80 * smoothstep(0.0, 0.16, trap.y));
    inCol *= 0.55;

    vec3 exCol = pal(sqrt(max(sn, 0.0)) * 0.28);
    exCol *= 0.75 + 0.40 * smoothstep(0.0, 0.30, trap.y);

    float outside = 1.0 - step(sn, -0.5);
    vec3  col     = mix(inCol, exCol, outside);

    // 【改】px 现在跟着 halfH 变。因为描边宽度是按像素给的，
    // 放大过程中描边始终是 2 像素粗，不会随缩放变胖变瘦
    float px = 2.0 * halfH / iResolution.y;
    float dp = de / px;

    float rim = smoothstep(2.2, 0.0, dp) * outside;
    col = mix(col, vec3(1.00, 0.96, 0.86), rim * 0.85);
    col += pal(0.55) * exp(-dp * 0.030) * 0.35 * outside;

    fragColor = vec4(col, 1.0);
}
