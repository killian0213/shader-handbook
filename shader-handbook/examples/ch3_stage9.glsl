// 第 3 章 · 阶梯实战 · 阶段 9（HARD）：形态变形 SDF 图标
// 星形 ↔ 心形：mix(dA,dB,t) 与 smin 双轨；RGB 按距离差拆色做色散辉光。
const float TAU = 6.2831853;

const vec3 CY = vec3(0.36, 0.90, 1.00);
const vec3 AM = vec3(1.00, 0.74, 0.32);
const vec3 MG = vec3(1.00, 0.34, 0.72);

float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

float sdSegment(vec2 p, vec2 a, vec2 b, float w)
{
    vec2  pa = p - a;
    vec2  ba = b - a;
    float h  = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - w;
}

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

vec2 rotCW(vec2 p, float a)
{
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c) * p;
}

vec2 foldN(vec2 p, float n)
{
    float sector = TAU / n;
    float a = atan(p.x, p.y);
    a = mod(a + 0.5 * sector, sector) - 0.5 * sector;
    return length(p) * vec2(sin(a), cos(a));
}

// 五角星：折叠 + 内外半径差
float sdStar(vec2 p, float rOut, float rIn, float n)
{
    vec2 q = foldN(p, n);
    float d1 = length(q - vec2(0.0, rOut));
    float d2 = length(q - vec2(0.0, rIn));
    return min(d1, d2) - 0.02;
}

// 心形：两个圆 + 倒三角差集的经典近似
float sdHeart(vec2 p)
{
    p.y += 0.12;
    p.x = abs(p.x);
    float d1 = sdCircle(p - vec2(0.16, 0.22), 0.18);
    float d2 = sdCircle(p - vec2(0.0, 0.28), 0.18);
    float top = smin(d1, d2, 0.08);
    vec2  qp = rotCW(p, 3.14159);
    float bot = sdSegment(qp, vec2(-0.38, -0.08), vec2(0.38, -0.08), 0.02);
    bot = max(bot, qp.y + 0.05);
    return smin(top, bot, 0.06);
}

float fill(float d, float aa)
{
    return smoothstep(aa, -aa, d);
}

float stroke(float d, float w, float aa)
{
    return smoothstep(aa, -aa, abs(d) - w);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2  p  = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float aa = 2.0 / iResolution.y;

    vec2 q = p - vec2(0.0, -0.02);

    // 缓动循环 0→1→0
    float t = 0.5 + 0.5 * sin(iTime * 0.85);
    t = t * t * (3.0 - 2.0 * t);

    float dStar  = sdStar(q * 0.95, 0.42, 0.18, 5.0);
    float dHeart = sdHeart(q * 1.05);

    // 双轨变形：线性 mix + smin 混合，过渡更圆润
    float dMix  = mix(dStar, dHeart, t);
    float dSmin = smin(dStar, dHeart, 0.12 + 0.18 * (1.0 - abs(t - 0.5) * 2.0));
    float d = mix(dMix, dSmin, smoothstep(0.25, 0.75, t));

    vec3 col = mix(vec3(0.04, 0.05, 0.12), vec3(0.01, 0.015, 0.04),
                   smoothstep(0.08, 1.1, length(p)));

    // 色散：三通道用略微不同的距离偏移
    float dr = d + 0.004 * sin(iTime * 1.2);
    float dg = d;
    float db = d - 0.004 * sin(iTime * 1.2);

    col.r += CY.r * 0.007 / max(abs(dr), 0.005);
    col.g += AM.g * 0.006 / max(abs(dg), 0.005);
    col.b += MG.b * 0.008 / max(abs(db), 0.005);

    vec3 iconCol = mix(CY, MG, t);
    iconCol = mix(iconCol, AM, 0.35 + 0.25 * sin(iTime * 0.6));
    col = mix(col, iconCol * 0.35, fill(d, aa));
    col = mix(col, vec3(1.0), stroke(d, 0.005, aa));
    col = mix(col, iconCol, stroke(d, 0.002, aa));

    float pulse = 0.80 + 0.20 * sin(iTime * 2.5);
    col.r += CY.r * exp(-abs(dr) * 70.0) * 0.50 * pulse;
    col.g += AM.g * exp(-abs(dg) * 85.0) * 0.40;
    col.b += MG.b * exp(-abs(db) * 95.0) * 0.55 * pulse;

    col += iconCol * pow(0.014 / max(abs(d), 0.004), 1.5) * 0.18;

    vec2 uvq = fragCoord / iResolution.xy;
    col *= 0.52 + 0.48 * pow(16.0 * uvq.x * uvq.y * (1.0 - uvq.x) * (1.0 - uvq.y), 0.30);
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
