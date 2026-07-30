// 第 6 章 · 万花筒 ④：双层旋转玫瑰窗（压轴）
// 外层慢旋、内层反旋；镜数不同 → 拍频出「活」的万花。
// 再叠辉光与暗角——这才是「华丽」：内容密度 × 双重对称 × 后期。
const float TAU = 6.2831853;

float hash11(float n) { return fract(sin(n) * 43758.5453); }

vec2 kaleido(vec2 p, float n)
{
    float seg = TAU / n;
    float a = atan(p.y, p.x);
    float r = length(p);
    a = mod(a, seg);
    a = abs(a - 0.5 * seg);
    return r * vec2(cos(a), sin(a));
}

float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);
    float b = sqrt(max(r * r - d * d, 1e-6));
    return ((p.y - b) * d > p.x * b)
        ? length(p - vec2(0.0, b))
        : length(p - vec2(-d, 0.0)) - r;
}

vec3 pal(float t)
{
    return vec3(0.42, 0.28, 0.55)
         + vec3(0.55, 0.4, 0.35) * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

vec3 layer(vec2 uv, float nFold, float rot, float petalPhase)
{
    float c = cos(rot), s = sin(rot);
    vec2 p = mat2(c, -s, s, c) * uv;
    p = kaleido(p, nFold);

    // 一枚花瓣 + 弧饰，折叠后自动成环
    float dPetal = sdVesica(p - vec2(0.35, 0.15), 0.28, 0.16);
    float dArc = abs(length(p) - 0.55) - 0.02;
    float dDot = length(p - vec2(0.15, 0.05)) - 0.03;
    float d = min(dPetal, min(dArc, dDot));

    vec3 col = vec3(0.0);
    float m = smoothstep(0.012, -0.008, d);
    float glow = exp(-max(d, 0.0) * 14.0);
    vec3 tint = pal(petalPhase + length(p) * 0.8);
    col += tint * glow * 0.7;
    col = mix(col, tint * 1.2, m);
    col += vec3(1.0, 0.95, 0.85) * m * exp(-abs(d) * 80.0) * 0.5;
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 双层：镜数与转速都不同 → 干涉出「活」图案
    vec3 a = layer(uv, 8.0,  iTime * 0.15, 0.0);
    vec3 b = layer(uv * 1.15, 12.0, -iTime * 0.22, 0.35);

    vec3 col = a * 0.85 + b * 0.75;
    // 中心高光核
    col += vec3(1.0, 0.85, 0.7) * exp(-length(uv) * 6.0) * 0.25;

    // 星尘
    for (int i = 0; i < 16; i++) {
        float fi = float(i);
        float ang = fi * 1.7 + iTime * 0.3;
        vec2 sp = 0.75 * vec2(cos(ang), sin(ang * 1.3));
        col += pal(fi * 0.1) * exp(-length(uv - sp) * 70.0) * 0.45;
    }

    float tube = smoothstep(1.1, 0.85, length(uv));
    col *= tube;
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.55 + 0.45 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.35);
    col = pow(max(col, 0.0), vec3(0.9));

    fragColor = vec4(col, 1.0);
}
