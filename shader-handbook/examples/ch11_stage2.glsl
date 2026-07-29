// 第 11 章 · 阶梯实战 · 阶段 2：平滑迭代数
// 只改了 mandel() 的最后三行和一个常量，色带全部消失。
// 三处改动：BAILOUT 2 → 256、把 |z|² 存下来、用 log2(log2) 把整数补成实数。

const int   MAX_ITER = 64;
const float BAILOUT  = 256.0;        // 【改】从 2.0 提到 256.0，平滑公式才准

const vec2  CENTER = vec2(-0.7436, 0.0);
const float HALF_H = 1.35;

// 返回【平滑】迭代数。集合内部返回 -1.0 作为哨兵值（见下面的注释）。
float mandel(vec2 c)
{
    vec2  z  = vec2(0.0);
    float n  = 0.0;
    float m2 = 0.0;                  // 【新增】把逃逸那一刻的 |z|² 留住
    for (int i = 0; i < MAX_ITER; i++)
    {
        z  = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        m2 = dot(z, z);
        if (m2 > BAILOUT * BAILOUT) break;
        n += 1.0;
    }

    // 【新增】没逃逸的点必须在这里截住。它的 |z| 还在 2 以内，m2 可能小于 1，
    // log2(m2) 就是负数，再套一层 log2 直接得到 NaN。少了这一行，
    // 集合内部会变成一片随驱动而异的雪花/纯白/纯黑 —— 这个坑几乎人人踩一次。
    if (n >= float(MAX_ITER)) return -1.0;

    // 【新增】平滑迭代数：把"第几次逃逸"从整数补成实数。
    // |z| 是双指数增长的（|z_{n+1}| ≈ |z_n|²），所以 log2(log2|z|) 每迭代一次
    // 才增加 1 —— 它恰好度量了"这一步走了多远"的小数部分。
    // 末尾 +4.0：逃逸瞬间 m2 ≈ 256² = 65536，log2 得 16，再 log2 得 4，
    // 正好抵消，于是 sn 在逃逸阈值处平滑接上 n，不产生跳变。
    return n - log2(log2(m2)) + 4.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 c  = CENTER + uv * HALF_H;

    float sn  = mandel(c);
    // max(sn, 0.0) 一手包办两件事：哨兵 -1 变 0（内部纯黑），
    // 以及第 0 次就逃逸的远处点算出的轻微负值也归零
    vec3  col = vec3(max(sn, 0.0) / float(MAX_ITER));

    fragColor = vec4(col, 1.0);
}
