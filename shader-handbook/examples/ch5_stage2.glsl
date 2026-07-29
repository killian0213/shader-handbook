// 第 5 章 · 阶梯实战 · 阶段 2：把马赛克插值成 value noise
// 新增 vnoise()：同样是那些格点随机值，只是查询点会去问四个角，
// 再用三次曲线加权混合。格子从"块"变成"起伏"。
float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 值噪声（§5.3）：四角哈希 + 双线性插值，返回 [0,1]
float vnoise(vec2 p)
{
    vec2 i = floor(p);   // 我在第几号格子
    vec2 f = fract(p);   // 我在格子内部的哪儿

    // 三次插值曲线 f²(3−2f)：格点处导数为 0，所以跨格时斜率连续。
    // 把这行换成 vec2 u = f; 立刻能看到菱形块状感 —— 见正文。
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(hash12(i + vec2(0.0, 0.0)), hash12(i + vec2(1.0, 0.0)), u.x),
               mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // 频率从 40 降到 12：插值之后一个格子就是一团起伏，
    // 还留 40 格的话每团只有 20 像素宽，整屏会糊成一片均匀的灰。
    vec2 p = 12.0 * fragCoord / iResolution.y;

    float n = vnoise(p);

    fragColor = vec4(vec3(n), 1.0);
}
