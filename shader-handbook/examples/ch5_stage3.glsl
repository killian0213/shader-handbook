// 第 5 章 · 阶梯实战 · 阶段 3：fbm —— 把同一个噪声叠六次
// 新增 mtx 和 fbm()。一层噪声只有一个尺度的细节；
// 六层"频率翻倍、振幅减半"叠起来，才有云雾那种"远看有形、近看有料"。
float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i + vec2(0.0, 0.0)), hash12(i + vec2(1.0, 0.0)), u.x),
               mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

// 每层顺带转一个小角度，打断"所有层的格子都对齐 x/y 轴"造成的十字纹。
// 这个矩阵是 (0.8, 0.6) 的旋转，行列式恰为 1，不会顺带缩放。
const mat2 mtx = mat2(0.80, 0.60, -0.60, 0.80);

// 标准 fbm（§5.7.1）。oct = 用几层。
float fbm(vec2 p, int oct)
{
    float f = 0.0;
    float a = 0.5;
    float w = 0.0;                      // 权重和，用来归一化
    for (int i = 0; i < 6; i++)
    {
        if (i >= oct) break;
        f += a * vnoise(p);
        w += a;
        p = mtx * p * 2.03;             // lacunarity 2.03，故意不是整数 2
        a *= 0.5;                       // gain 0.5
    }
    return f / max(w, 1e-4);            // 除以权重和 → 结果仍在 [0,1]，不会整体漂白
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // 基频从 8 降到 3：fbm 的最高层已经是 3×2.03⁵ ≈ 105 格，
    // 基频再高，顶层就细过一个像素，只会变成沙沙的噪点。
    vec2 p = 3.0 * fragCoord / iResolution.y;

    float n = fbm(p, 6);

    fragColor = vec4(vec3(n), 1.0);
}
