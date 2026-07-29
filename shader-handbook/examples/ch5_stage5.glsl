// 第 5 章 · 阶梯实战 · 阶段 5：把噪声铺到地上 —— 云海成形
// 噪声本身一个字都没改。变的只有【喂给它什么坐标】：
// 屏幕下半部分不再是平铺的 uv，而是用 1/y 还原出的世界纵深。
// 于是同一片 fbm 变成了一层向地平线退去的云。
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

// 地平线放在偏上的位置：云海占画面 3/4，天空只留一条。
// 凡是会被多处引用的数字一律提成常量 —— 等下要反复调它。
const float HORIZON = 0.45;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // --- 天空：地平线暖、天顶冷。pow 让暖色只贴着地平线那一条 ---
    float sy  = clamp((uv.y - HORIZON) / (1.0 - HORIZON), 0.0, 1.0);
    vec3  col = mix(vec3(1.00, 0.60, 0.38), vec3(0.10, 0.16, 0.38), pow(sy, 0.60));

    // --- 云海。dy 是到地平线的屏幕距离，1/dy 就是世界纵深（第 0 章那招）---
    float dy    = HORIZON - uv.y;
    float depth = 1.0 / max(dy, 0.003);
    vec2  q     = vec2(uv.x * depth, depth) * 1.8;
    q += vec2(0.03, 0.45) * iTime;                  // 世界坐标持续增大 = 观察者向前飞

    vec2  w = vec2(fbm(q, 3), fbm(q + vec2(5.2, 1.3), 3)) - 0.5;
    float h = fbm(q + 1.4 * w, 6);                  // h 当云顶高度用

    // 高处是被照到的云顶，低处是云缝深处 —— 先只用两个颜色试水
    vec3 cloud = mix(vec3(0.17, 0.18, 0.31), vec3(0.93, 0.92, 0.96),
                     smoothstep(0.30, 0.70, h));

    col = mix(col, cloud, step(uv.y, HORIZON));

    fragColor = vec4(col, 1.0);
}
