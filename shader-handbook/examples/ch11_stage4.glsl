// 第 11 章 · 阶梯实战 · 阶段 4：轨道陷阱（orbit trap）
// 前三阶段只用了"迭代了几次"这一个标量，所以集合内部只能是一块黑。
// 轨道陷阱多记两个数：整条轨道离原点最近多少、离两条坐标轴最近多少。
// 内部立刻长出纹理，外部也多了一层明暗。

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

// 【改】多一个 out 参数带出陷阱值：
//   trap.x = 轨道上 |z|² 的最小值      → 到原点最近多少
//   trap.y = 轨道上 min(|z.x|,|z.y|)   → 到"十字"（两条坐标轴）最近多少
float mandel(vec2 c, out vec2 trap)
{
    vec2  z  = vec2(0.0);
    float n  = 0.0;
    float m2 = 0.0;
    trap = vec2(1e10);               // 【新增】用 min 累积，所以初值必须够大
    for (int i = 0; i < MAX_ITER; i++)
    {
        z  = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        m2 = dot(z, z);
        // 【新增】陷阱在【循环内】用 min 累积。着色时用的是这个最小值，
        // 而不是循环结束时最后那个 z —— 用错的话颜色和形状会完全脱节。
        trap = min(trap, vec2(m2, min(abs(z.x), abs(z.y))));
        if (m2 > BAILOUT * BAILOUT) break;
        n += 1.0;
    }
    if (n >= float(MAX_ITER)) return -1.0;
    return n - log2(log2(m2)) + 4.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 c  = CENTER + uv * HALF_H;

    vec2  trap;
    float sn = mandel(c, trap);

    // 【新增】内部：轨道最接近原点的距离当调色板坐标。
    // 主心形里轨道收敛到一个不动点，|z*| 从 0 平滑长到 0.5；各个周期泡里
    // 轨道变成环，最小值跳一档 —— 于是每个泡自己一个颜色，结构全出来了。
    float tr    = sqrt(trap.x);
    vec3  inCol = pal(0.30 + 1.30 * tr) * (0.20 + 0.80 * smoothstep(0.0, 0.16, trap.y));
    inCol *= 0.55;                   // 内部压暗，主角还是边界

    // 【新增】外部：同一个十字陷阱当细纹调制，幅度很轻（0.75 → 1.15）
    vec3 exCol = pal(sqrt(max(sn, 0.0)) * 0.28);
    exCol *= 0.75 + 0.40 * smoothstep(0.0, 0.30, trap.y);

    vec3 col = mix(exCol, inCol, step(sn, -0.5));

    fragColor = vec4(col, 1.0);
}
