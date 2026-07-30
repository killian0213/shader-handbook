// 第 4 章 · 阶梯实战 · 阶段 8：调色板探索器
// 鼠标 X 驱动 pal(t) 相位；fbm 场着色成色带，肉眼看见"系数→颜色"的映射。
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

float fbm(vec2 p)
{
    float f = 0.0, a = 0.5, w = 0.0;
    for (int i = 0; i < 5; i++)
    {
        f += a * vnoise(p);
        w += a;
        p = mtx * p * 2.02;
        a *= 0.5;
    }
    return f / w;
}

// IQ 余弦调色板：a + b·cos(2π(c·t + d))
vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
    return a + b * cos(TAU * (c * t + d));
}

// 默认 cosmic 系数
vec3 palCosmic(float t)
{
    return pal(t, vec3(0.50, 0.50, 0.50), vec3(0.50, 0.50, 0.50),
               vec3(1.00, 1.00, 1.00), vec3(0.00, 0.33, 0.67));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p  = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 鼠标 X → 相位偏移；无鼠标时用时间慢扫
    float mx = iMouse.x / max(iResolution.x, 1.0);
    float phase = (iMouse.z > 0.5) ? mx : fract(iTime * 0.08);

    // 顶部色带：直接展示 pal(t) 在 t∈[0,1] 上的输出
    float bandY = uv.y;
    vec3 bandCol = vec3(0.0);
    if (bandY > 0.88)
    {
        float t = uv.x;
        bandCol = palCosmic(t + phase);
        // 竖线标记当前相位
        float marker = smoothstep(0.004, 0.0, abs(uv.x - phase));
        bandCol = mix(bandCol * 0.35, bandCol, 1.0 - marker * 0.5);
        bandCol += vec3(1.0) * marker;
    }

    // 主体：fbm 场 → pal
    float n = fbm(p * 1.6 + vec2(phase * 3.0, iTime * 0.05));
    n = fbm(p * 2.4 + vec2(n, n) * 1.2 + phase);
    float t = fract(n * 0.85 + phase * 0.5);
    vec3 col = palCosmic(t) * (0.35 + 0.65 * n);

    // 底部标签感色块：a / b / c 分量可视化
    if (uv.y < 0.10)
    {
        vec3 a = vec3(0.50);
        vec3 b = vec3(0.50);
        vec3 c = vec3(1.00);
        float seg = uv.x * 3.0;
        if (seg < 1.0)
            col = mix(a, a + b, seg);
        else if (seg < 2.0)
            col = mix(a + b, a + b * cos(TAU * c * 0.5), seg - 1.0);
        else
            col = palCosmic(fract((seg - 2.0) + phase));
        col *= 0.7;
    }
    else if (bandY > 0.88)
        col = bandCol;
    else
    {
        // 横线分隔感
        float grid = smoothstep(0.002, 0.0, abs(fract(uv.y * 8.0 + phase) - 0.5) - 0.48);
        col = mix(col, col * 1.15, grid * 0.15);
    }

    // 左侧相位指示条
    float bar = smoothstep(0.02, 0.0, abs(uv.x - 0.025));
    if (uv.x < 0.05 && uv.y > 0.12 && uv.y < 0.86)
        col = mix(col, palCosmic((uv.y - 0.12) / 0.74 + phase), bar);

    col = pow(max(col, 0.0), vec3(1.0 / 2.2));
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
