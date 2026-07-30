// 第 5 章 · 阶梯实战 · 阶段 8：域扭曲大理石 / 墨水
// fbm(p + fbm(p)) 经典配方；双色脉纹 + 慢流，教"坐标先于颜色"。
const float TAU = 6.2831853;

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

float fbm(vec2 p, int oct)
{
    float f = 0.0, a = 0.5, w = 0.0;
    for (int i = 0; i < 6; i++)
    {
        if (i >= oct) break;
        f += a * vnoise(p);
        w += a;
        p = mtx * p * 2.02;
        a *= 0.5;
    }
    return f / max(w, 1e-4);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p  = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 慢流 + 轻微旋转
    float ang = iTime * 0.03;
    float c = cos(ang), s = sin(ang);
    p = mat2(c, -s, s, c) * p;
    p += vec2(iTime * 0.04, iTime * 0.02);

    // 第一层 warp
    vec2 q = p * 1.4;
    q += vec2(fbm(q, 4), fbm(q + vec2(5.2, 1.3), 4)) * 1.6;

    // 第二层 warp（墨水感）
    vec2 r = q * 1.1 + vec2(1.7, 9.2);
    r += vec2(fbm(r, 5), fbm(r + vec2(3.7, 2.8), 5)) * 0.9;

    float n = fbm(r, 6);

    // 大理石脉纹：sin 放大对比
    float vein = sin(n * 12.0 + fbm(r * 2.0, 3) * 4.0);
    vein = smoothstep(-0.2, 0.6, vein);

    // 双色：深墨 + 暖白脉
    vec3 ink   = vec3(0.04, 0.05, 0.08);
    vec3 veinC = vec3(0.88, 0.84, 0.78);
    vec3 col   = mix(ink, veinC, vein);

    // 薄雾高光
    col += vec3(0.15, 0.18, 0.22) * pow(n, 3.0) * 0.4;

    // 边缘 vignette
    col *= 0.65 + 0.35 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.30);

    col = pow(max(col, 0.0), vec3(1.0 / 2.2));
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
