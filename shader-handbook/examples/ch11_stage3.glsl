// 第 11 章 · 阶梯实战 · 阶段 3：余弦调色板
// mandel() 一个字没动。只是把灰度换成查表 —— 这一步的性价比高得离谱。

const int   MAX_ITER = 64;
const float BAILOUT  = 256.0;
const float TAU      = 6.2831853;

const vec2  CENTER = vec2(-0.7436, 0.0);
const float HALF_H = 1.35;

// iq 的余弦调色板：a + b·cos(TAU·(c·t + d))（第 4 章）。
// d 的三个分量决定 t=0 处的颜色，这里刻意让它落在余弦谷底 → 深蓝，
// 于是"远处 = 冷暗、靠近边界 = 暖亮"，视线自动被吸到分形上。
vec3 pal(float t)
{
    return vec3(0.42, 0.40, 0.42)
         + vec3(0.44, 0.42, 0.48)
         * cos(TAU * (vec3(1.00, 0.92, 0.78) * t + vec3(0.52, 0.42, 0.28)));
}

float mandel(vec2 c)
{
    vec2  z  = vec2(0.0);
    float n  = 0.0;
    float m2 = 0.0;
    for (int i = 0; i < MAX_ITER; i++)
    {
        z  = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        m2 = dot(z, z);
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

    float sn = mandel(c);

    // 【新增】查表。用 sqrt(sn) 而不是 sn：靠近边界时 sn 会无界地涨，
    // 直接线性喂给周期函数，边界附近的颜色一个像素就转好几圈 → 彩色噪点。
    // sqrt 把高端压住，让色环密度从中心到边界大致均匀。
    vec3 col = pal(sqrt(max(sn, 0.0)) * 0.28);

    // 【新增】哨兵 -1 → 集合内部仍然压成纯黑。下一阶段专门来救它。
    col *= step(0.0, sn);

    fragColor = vec4(col, 1.0);
}
