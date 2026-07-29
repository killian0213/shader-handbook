// 第 5 章 · 阶梯实战 · 阶段 6：用噪声驱动光和空气
// 三件新事：① ridged fbm 做山脊；② 沿光方向多采一次高度，换一个假法线；
// ③ 雾 + 八度频率限制，把地平线那条沙沙作响的噪点带干掉。
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

// oct 从 int 改成 float：最高那一层按小数部分淡入。
// 还用整数层数的话，远近之间会"跳档"，画面上能看见一条条档位分界线。
float fbm(vec2 p, float oct)
{
    float f = 0.0;
    float a = 0.5;
    float w = 0.0;
    for (int i = 0; i < 6; i++)
    {
        float k = clamp(oct - float(i), 0.0, 1.0);
        if (k <= 0.0) break;
        f += a * k * vnoise(p);
        w += a * k;
        p = mtx * p * 2.03;
        a *= 0.5;
    }
    return f / max(w, 1e-4);
}

// ridged fbm（§5.7.2）：1−|n| 把谷折成峰，再平方让棱线更利。
// 同一个循环、同一个噪声，只改了送进求和之前的那一步。
float ridged(vec2 p, int oct)
{
    float f = 0.0;
    float a = 0.5;
    float w = 0.0;
    for (int i = 0; i < 6; i++)
    {
        if (i >= oct) break;
        float n = 1.0 - abs(vnoise(p) * 2.0 - 1.0);
        f += a * n * n;
        w += a;
        p = mtx * p * 2.03;
        a *= 0.5;
    }
    return f / max(w, 1e-4);
}

const float HORIZON = 0.45;
const vec2  SUN     = vec2(-0.36, 0.58);

// 天空抽成函数，因为雾色必须去问它 —— 见下面的 fog
vec3 skyCol(vec2 uv)
{
    float sy = clamp((uv.y - HORIZON) / (1.0 - HORIZON), 0.0, 1.0);
    vec3  c  = mix(vec3(1.00, 0.60, 0.38), vec3(0.10, 0.16, 0.38), pow(sy, 0.60));
    // 太阳附近的大气散射：一大团很软的暖光，衰减系数小 → 铺得开
    c += vec3(1.00, 0.52, 0.24) * exp(-length(uv - SUN) * 3.0) * 0.60;
    return c;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    vec3 col = skyCol(uv);

    // 日面：一个小硬盘，其余亮度全交给上面的散射项
    float sd = length(uv - SUN);
    col = mix(col, vec3(1.00, 0.95, 0.84), smoothstep(0.052, 0.044, sd));

    // --- 山脊：ridged 当一维高度场，uv.y − h 就是剪影的有符号距离 ---
    float mh = HORIZON + 0.02 + 0.16 * ridged(vec2(uv.x * 1.1 + 7.0, 0.7), 4);
    float md = uv.y - mh;
    // 山体不是纯黑：越靠近地平线越接近霞色，这就是空气透视
    vec3 mcol = mix(vec3(0.52, 0.36, 0.42), vec3(0.13, 0.11, 0.22),
                    smoothstep(0.0, 0.13, uv.y - HORIZON));
    col = mix(col, mcol, smoothstep(0.004, -0.004, md));
    // 逆光轮廓：|md| 小的地方就是棱线，有距离场就有免费描光
    col += vec3(1.00, 0.66, 0.36) * smoothstep(0.010, 0.0, abs(md)) * 0.9;

    // --- 云海 ---
    float dy    = HORIZON - uv.y;
    float depth = 1.0 / max(dy, 0.003);
    vec2  q     = vec2(uv.x * depth, depth) * 1.8;
    q += vec2(0.03, 0.45) * iTime;

    // 频率限制：fp = 一个像素在 q 空间跨过的距离。
    // 每层频率翻倍，所以能用的层数 ≈ log2(0.5 / fp) —— 超出的层只会变成噪点。
    float fp  = 1.8 * depth * depth * 2.0 / iResolution.y;
    float det = clamp(log2(0.5 / fp), 1.0, 6.0);

    vec2  w  = vec2(fbm(q, 3.0), fbm(q + vec2(5.2, 1.3), 3.0)) - 0.5;
    vec2  qw = q + 1.4 * w;
    float h  = fbm(qw, det);

    // --- 假法线：沿光方向偏一点再采一次高度 ---
    // 那一侧更低 → 说明这块坡面朝着太阳 → 亮。一次额外采样，省掉整套梯度。
    float hl  = fbm(qw + vec2(-0.22, 0.10), det);
    float lit = clamp((h - hl) * 5.0 + 0.45, 0.0, 1.0);

    float body  = smoothstep(0.28, 0.66, h);
    vec3  cloud = mix(vec3(0.15, 0.16, 0.29), vec3(0.42, 0.43, 0.56), body);
    cloud += vec3(1.00, 0.63, 0.34) * pow(lit, 1.7) * (0.30 + 0.90 * body);

    // --- 雾：远处收敛到【地平线处的天空色】。
    //     随便挑一个雾色，地平线上就会横着一条接缝。 ---
    float fog = 1.0 - exp(-depth * 0.16);
    cloud = mix(cloud, skyCol(vec2(uv.x, HORIZON)), fog);

    col = mix(col, cloud, step(uv.y, HORIZON));

    fragColor = vec4(col, 1.0);
}
