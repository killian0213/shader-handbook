// 第 5 章 · 阶梯实战 · 阶段 4：域扭曲 —— 用噪声去挪噪声的坐标
// 新增的只有三行，但它是"从棉花团变成流体"的那一步（§5.8）。
// 顺手接上 iTime：动画就是往场函数里塞一个含时间的项。
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

const mat2 mtx = mat2(0.80, 0.60, -0.60, 0.80);

float fbm(vec2 p, int oct)
{
    float f = 0.0;
    float a = 0.5;
    float w = 0.0;
    for (int i = 0; i < 6; i++)
    {
        if (i >= oct) break;
        f += a * vnoise(p);
        w += a;
        p = mtx * p * 2.03;
        a *= 0.5;
    }
    return f / max(w, 1e-4);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = 3.0 * fragCoord / iResolution.y;
    p += vec2(0.04, 0.10) * iTime;                  // 整片缓慢平移

    // 位移场：两个【互不相关】的 fbm。第二个必须加偏移，
    // 否则 w.x == w.y，坐标只会沿对角线被拉，看不出旋涡。
    // 只用 3 层：位移场要的是大尺度趋势，细节交给主噪声。
    vec2 w = vec2(fbm(p, 3), fbm(p + vec2(5.2, 1.3), 3)) - 0.5;

    // 振幅 1.4：从 0.2 开始试，一点点加到图案开始"拧"但还没撕碎
    float n = fbm(p + 1.4 * w, 6);

    fragColor = vec4(vec3(n), 1.0);
}
