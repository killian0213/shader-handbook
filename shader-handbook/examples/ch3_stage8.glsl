// 第 3 章 · 阶梯实战 · 阶段 8：洋葱环 + 描边叠层 —— 霓虹徽章
// abs(d)-t 逐层剥皮得到同心环；三种辉光衰减（k/d、exp、pow）分工发光。
const float TAU = 6.2831853;

const vec3 CY = vec3(0.36, 0.90, 1.00);
const vec3 AM = vec3(1.00, 0.74, 0.32);
const vec3 MG = vec3(1.00, 0.34, 0.72);

float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

float sdRing(vec2 p, float r, float w)
{
    return abs(length(p) - r) - w;
}

float sdBox(vec2 p, vec2 b, float r)
{
    vec2 d = abs(p) - b + r;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}

float fill(float d, float aa)
{
    return smoothstep(aa, -aa, d);
}

float stroke(float d, float w, float aa)
{
    return smoothstep(aa, -aa, abs(d) - w);
}

float sdSegment(vec2 p, vec2 a, vec2 b, float w)
{
    vec2  pa = p - a;
    vec2  ba = b - a;
    float h  = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - w;
}

// 洋葱剥皮：每层厚度 t，返回第 layer 个环带的距离
float onionRing(float d, float t, int layer)
{
    d = abs(d);
    for (int i = 0; i < layer; i++)
        d = abs(d - t) - t;
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2  p  = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float aa = 2.0 / iResolution.y;

    vec2 q = p - vec2(0.0, -0.04);

    vec3 col = mix(vec3(0.03, 0.05, 0.10), vec3(0.005, 0.008, 0.020),
                   smoothstep(0.05, 1.2, length(p)));

    float dOuter = sdCircle(q, 0.58);
    float dInner = sdBox(q, vec2(0.22, 0.22), 0.06);

    // 外壳圆 + 中心方：差集做徽章轮廓
    float dShell = max(dOuter, -dInner);

    // 三层洋葱环（从外到内）
    float t = 0.065;
    float r0 = onionRing(dShell, t, 0);
    float r1 = onionRing(dShell, t, 1);
    float r2 = onionRing(dShell, t, 2);

    // 辉光 ②：整体氛围 k/d
    col += CY * 0.008 / max(abs(dShell), 0.006);

    // 壳体填充
    col = mix(col, vec3(0.06, 0.10, 0.18), fill(dShell, aa));

    // 三层环描边，颜色递进
    col = mix(col, CY, stroke(r0, 0.004, aa));
    col = mix(col, AM, stroke(r1, 0.0035, aa));
    col = mix(col, MG, stroke(r2, 0.003, aa));

    // 中心十字 + 小环
    float cross = min(sdSegment(q, vec2(-0.14, 0.0), vec2(0.14, 0.0), 0.012),
                      sdSegment(q, vec2(0.0, -0.14), vec2(0.0, 0.14), 0.012));
    cross = min(cross, sdRing(q, 0.12, 0.008));
    col = mix(col, vec3(0.90, 0.95, 1.0), fill(cross, aa));

    // 辉光 ①：exp 贴身 —— 每层环不同色
    float pulse = 0.85 + 0.15 * sin(iTime * 2.0);
    col += CY * exp(-abs(r0) * 90.0) * 0.40;
    col += AM * exp(-abs(r1) * 110.0) * 0.35 * pulse;
    col += MG * exp(-abs(r2) * 130.0) * 0.45 * pulse;

    // 辉光 ③：pow 锐核 —— 中心点
    col += vec3(1.0, 0.95, 0.85) * pow(0.010 / max(length(q), 0.004), 1.8) * 0.15;

    vec2 uvq = fragCoord / iResolution.xy;
    col *= 0.50 + 0.50 * pow(16.0 * uvq.x * uvq.y * (1.0 - uvq.x) * (1.0 - uvq.y), 0.28);
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
