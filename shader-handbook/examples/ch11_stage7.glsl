// 第 11 章 · 阶梯实战 · 阶段 7：打磨
// 数学一个字没改：还是同一个 z²+c、同一个平滑迭代数、同一个陷阱、同一个 DE。
// 变化全在最后二十行 —— 分层描边、内部透光、暗角、软膝、抖动。

const int   MAX_ITER = 260;
const float BAILOUT  = 256.0;
const float TAU      = 6.2831853;

const vec2  HOME    = vec2(-0.7436, 0.0);
const vec2  TARGET  = vec2(-0.743643887, 0.131825904);
const float HALF_H0 = 1.35;

vec3 pal(float t)
{
    return vec3(0.42, 0.40, 0.42)
         + vec3(0.44, 0.42, 0.48)
         * cos(TAU * (vec3(1.00, 0.92, 0.78) * t + vec3(0.52, 0.42, 0.28)));
}

// 软膝压缩：K 以下原样保留，K 以上平滑压回 1。
// 不用 1-exp(-c) 是因为它会把饱和色的低通道抬得比高通道多，整张图发灰发奶。
// 这里只有辉光会溢出 1，所以只压溢出的那一部分。
vec3 softKnee(vec3 c)
{
    const float K = 0.80;
    vec3 hi = max(c - K, 0.0);
    return min(c, vec3(K)) + (1.0 - K) * (1.0 - exp(-hi / (1.0 - K)));
}

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

    if (n >= float(lim)) return -1.0;
    return n - log2(log2(m2)) + 4.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float zt    = 0.5 - 0.5 * cos(iTime * 0.23);
    float halfH = HALF_H0 * exp(-zt * 7.6);
    vec2  center = mix(HOME, TARGET, smoothstep(0.0, 0.30, zt));
    vec2  c      = center + uv * halfH;

    int lim = int(min(float(MAX_ITER), 64.0 + 26.0 * log2(HALF_H0 / halfH)));

    vec2  trap;
    float de;
    float sn = mandel(c, lim, trap, de);

    float px = 2.0 * halfH / iResolution.y;
    float dp = de / px;
    float outside = 1.0 - step(sn, -0.5);

    // --- 内部：陷阱纹理 + 一层"从边界透进来的光"（新增第二项）---
    float tr    = sqrt(trap.x);
    vec3  inCol = pal(0.30 + 1.30 * tr) * (0.20 + 0.80 * smoothstep(0.0, 0.16, trap.y));
    inCol *= 0.42;
    // 内部越靠近边界越亮：|z| 最小值大的点离边界近，这是一个便宜的替代量
    inCol += pal(0.52) * smoothstep(0.30, 0.52, tr) * 0.22;

    // --- 外部：调色板 + 陷阱细纹 + 轻微去饱和的"距离雾"（新增第三项）---
    vec3 exCol = pal(sqrt(max(sn, 0.0)) * 0.28);
    exCol *= 0.75 + 0.40 * smoothstep(0.0, 0.30, trap.y);
    // 离边界远的地方压低饱和与亮度 → 纵深感，视线被推向边界
    float far = 1.0 - exp(-dp * 0.006);
    exCol = mix(exCol, vec3(dot(exCol, vec3(0.30, 0.59, 0.11))) * 0.55, far * 0.55);

    vec3 col = mix(inCol, exCol, outside);

    // --- 分层描边：一条 1.2 像素的硬芯 + 一条 5 像素的软晕 ---
    // 单独一条边太干，芯 + 晕两层叠起来才有"金属丝"的感觉
    float core = smoothstep(1.2, 0.0, dp) * outside;
    float halo = smoothstep(5.0, 0.6, dp) * outside;
    col = mix(col, pal(0.46), halo * 0.45);
    col = mix(col, vec3(1.00, 0.97, 0.90), core * 0.90);

    // --- 辉光：两个尺度。近处的紧、远处的散，加起来才像真的在发光 ---
    col += pal(0.55) * exp(-dp * 0.055) * 0.30 * outside;
    col += pal(0.14) * exp(-dp * 0.008) * 0.16 * outside;

    // --- 暗角：iq 的经典一行，四角压暗，视线自动收到中心 ---
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.55 + 0.45 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.28);

    // --- 只压过曝，不动正常颜色 ---
    col = softKnee(col);

    // --- 抖动：抹掉 8-bit 量化在大片平缓渐变上留下的色带 ---
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;

    fragColor = vec4(col, 1.0);
}
