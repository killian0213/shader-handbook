// 第 5 章 · 阶梯实战 · 阶段 1：把 hash 直接画出来
// 整章的地基就这一个函数。画面很丑，但它证明了一件事：
// 只靠坐标就能造出"随机"，而且同一个格子每帧都是同一个值。

// Dave_Hoskins 的无 sin 哈希（§5.2.4）。输入任意 vec2，输出 [0,1)。
// 常数 .1031 / 33.33 是统计挑出来的，别随手改成 .1 —— 会立刻出现周期条纹。
float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);   // 让三个分量互相污染
    return fract((p3.x + p3.y) * p3.z);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // 纵向固定 40 格，横向按宽高比自然伸展（除以 .y 而不是 .xy，格子才是正方形）
    vec2 p = 40.0 * fragCoord / iResolution.y;

    // floor(p) = 格子编号。整格共用一个随机值 → 马赛克
    float h = hash12(floor(p));

    fragColor = vec4(vec3(h), 1.0);
}
