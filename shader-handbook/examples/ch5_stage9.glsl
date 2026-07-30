// 第 5 章 · 阶梯实战 · 阶段 9（HARD）：风暴云景 —— 噪声即世界
// fbm + 域扭曲 + 调色板 + ridged 山脊 + 体积云；展示"噪声堆叠 = 场景"。
const float TAU = 6.2831853;

const float HORIZON = 0.38;
const vec2  SUN     = vec2(0.42, 0.52);

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
    return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
               mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

const mat2 mtx = mat2(0.80, 0.60, -0.60, 0.80);

float fbm(vec2 p, float oct)
{
    float f = 0.0, a = 0.5, w = 0.0;
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

float ridged(vec2 p, int oct)
{
    float f = 0.0, a = 0.5, w = 0.0;
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

vec3 pal(float t)
{
    return vec3(0.50, 0.50, 0.55)
         + vec3(0.35, 0.30, 0.40) * cos(TAU * (vec3(0.55) * t + vec3(0.0, 0.15, 0.35)));
}

vec3 stormSky(vec2 uv)
{
    float sy = clamp((uv.y - HORIZON) / (1.0 - HORIZON), 0.0, 1.0);
    vec3  base = mix(vec3(0.18, 0.14, 0.22), vec3(0.05, 0.08, 0.18), pow(sy, 0.5));

    // 高层云絮：屏幕空间 fbm
    vec2 sq = uv * vec2(2.5, 1.2) + vec2(iTime * 0.015, 0.0);
    float cloud = fbm(sq + vec2(fbm(sq, 3.0), 0.0) * 2.0, 4.0);
    base = mix(base, pal(cloud) * 0.55, smoothstep(0.45, 0.75, cloud) * 0.7);

    // 闪电闪光（偶发 sin 脉冲）
    float flash = pow(max(sin(iTime * 3.7 + sin(iTime * 0.9) * 5.0), 0.0), 12.0);
    base += vec3(0.6, 0.65, 0.85) * flash * 0.8;

    // 太阳透过 storm
    float sd = length(uv - SUN);
    base += vec3(0.9, 0.55, 0.25) * exp(-sd * 4.5) * 0.5;
    base = mix(base, vec3(1.0, 0.92, 0.75), smoothstep(0.045, 0.028, sd));

    return base;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    vec3 col = stormSky(uv);

    // 前景山脊：ridged 剪影
    float mh = HORIZON - 0.02 + 0.22 * ridged(vec2(uv.x * 1.3 + 4.0 + iTime * 0.01, 0.6), 5);
    float md = uv.y - mh;
    vec3 mcol = mix(vec3(0.08, 0.06, 0.10), vec3(0.22, 0.16, 0.20),
                    smoothstep(-0.05, 0.15, uv.y - HORIZON));
    col = mix(col, mcol, smoothstep(0.006, -0.006, md));
    col += vec3(0.45, 0.35, 0.55) * smoothstep(0.015, 0.0, abs(md)) * 0.6;

    // 低层风暴云：透视坐标 + 域扭曲
    if (uv.y < HORIZON)
    {
        float dy    = HORIZON - uv.y;
        float depth = 1.0 / max(dy, 0.004);
        vec2  q     = vec2(uv.x * depth, depth) * 1.6;
        q += vec2(iTime * 0.06, iTime * 0.02);

        float fp  = 1.6 * depth * depth * 2.0 / iResolution.y;
        float det = clamp(log2(0.5 / fp), 1.0, 6.0);

        vec2  w  = vec2(fbm(q, 3.0), fbm(q + vec2(4.1, 2.7), 3.0)) - 0.5;
        vec2  qw = q + 1.8 * w + vec2(fbm(q * 0.5, 2.0), 0.0);
        float h  = fbm(qw, det);

        float hl  = fbm(qw + vec2(-0.18, 0.12), det);
        float lit = clamp((h - hl) * 6.0 + 0.35, 0.0, 1.0);

        float body = smoothstep(0.22, 0.68, h);
        vec3  cloud = mix(vec3(0.06, 0.07, 0.12), pal(h) * 0.7, body);
        cloud += vec3(0.55, 0.45, 0.65) * pow(lit, 2.0) * body * 0.5;

        // 闪电照亮云底
        float flash = pow(max(sin(iTime * 3.7 + sin(iTime * 0.9) * 5.0), 0.0), 12.0);
        cloud += vec3(0.7, 0.75, 0.95) * flash * body * 0.4;

        float fog = 1.0 - exp(-depth * 0.14);
        cloud = mix(cloud, stormSky(vec2(uv.x, HORIZON)), fog);

        col = mix(col, cloud, step(uv.y, HORIZON));
    }

    // 雨丝（廉价线性噪声）
    vec2 rp = uv * vec2(80.0, 2.0) + vec2(iTime * 8.0, iTime * 20.0);
    float rain = smoothstep(0.92, 1.0, hash12(floor(rp)));
    col += vec3(0.5, 0.55, 0.65) * rain * 0.08 * step(uv.y, HORIZON + 0.05);

    col = pow(max(col, 0.0), vec3(1.0 / 2.2));

    vec2 qv = fragCoord / iResolution.xy;
    col *= 0.78 + 0.22 * pow(16.0 * qv.x * qv.y * (1.0 - qv.x) * (1.0 - qv.y), 0.32);
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
