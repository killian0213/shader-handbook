// 第 3 章 · 阶梯实战 · 阶段 6：打磨
// 几何一个都没加，三个配色常量也一个没动。变化全在光：
// 三种辉光衰减分工 + 表圈定向明暗 + 暗角 + 软膝压缩 + 抖动。
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

float sdSegment(vec2 p, vec2 a, vec2 b)
{
    vec2  pa = p - a;
    vec2  ba = b - a;
    float h  = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdPie(vec2 p, float halfAng)
{
    vec2 n = vec2(cos(halfAng), sin(halfAng));
    return abs(p.x) * n.x - p.y * n.y;
}

vec2 rotCW(vec2 p, float a)
{
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c) * p;
}

float sdArc(vec2 p, float r, float w, float sweep)
{
    p = rotCW(p, sweep * 0.5);
    return max(sdRing(p, r, w), sdPie(p, sweep * 0.5));
}

vec2 fold(vec2 p, float n)
{
    float sector = TAU / n;
    float a = atan(p.x, p.y);
    a = mod(a + 0.5 * sector, sector) - 0.5 * sector;
    return length(p) * vec2(sin(a), cos(a));
}

float tickRing(vec2 p, float n, float r0, float r1, float w)
{
    return sdSegment(fold(p, n), vec2(0.0, r0), vec2(0.0, r1)) - w;
}

vec2 clockDir(float ang)
{
    return vec2(sin(ang), cos(ang));
}

float hand(vec2 p, float ang, float r0, float r1, float w)
{
    vec2 d = clockDir(ang);
    return sdSegment(p, d * r0, d * r1) - w;
}

float fill(float d, float aa)
{
    return smoothstep(aa, -aa, d);
}

float stroke(float d, float w, float aa)
{
    return smoothstep(aa, -aa, abs(d) - w);
}

// 软膝压缩：K 以下原样保留，K 以上平滑压回 1。
// 辉光是加上去的，很容易冲过 1.0；直接 clamp 会出一片死白的硬边，
// 而 1-exp(-x) 那种全局 tonemap 又会把没超标的暗部一起抬灰。
vec3 softKnee(vec3 c)
{
    const float K = 0.82;
    vec3 hi = max(c - K, 0.0);
    return min(c, vec3(K)) + (1.0 - K) * (1.0 - exp(-hi / (1.0 - K)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2  p  = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float aa = 2.0 / iResolution.y;

    vec2 q = p - vec2(0.0, -0.10);

    vec3 col = mix(vec3(0.050, 0.070, 0.110), vec3(0.006, 0.008, 0.020),
                   smoothstep(0.05, 1.25, length(p)));

    float dCase  = sdCircle(q, 0.62);
    float dBezel = sdRing(q, 0.595, 0.025);
    float dDial  = sdCircle(q, 0.555);

    float dCrown = sdBox(q - vec2(0.0, 0.655), vec2(0.075, 0.055), 0.026);
    vec2  bq     = q - vec2(0.0, 0.800);
    float dBow   = max(sdCircle(bq, 0.105), -sdCircle(bq, 0.062));

    float dBody = smin(dCase, dCrown, 0.045);
    dBody = min(dBody, dBow);

    float dTicks = tickRing(q, 60.0, 0.462, 0.500, 0.0030);
    dTicks = min(dTicks, tickRing(q, 12.0, 0.432, 0.500, 0.0075));
    dTicks = min(dTicks, tickRing(q,  4.0, 0.398, 0.500, 0.0130));

    float S  = 36540.0 + iTime * 3.0;
    float aH = TAU * fract(S / 43200.0);
    float aM = TAU * fract(S /  3600.0);
    float aS = TAU * fract(S /    60.0);

    float dHour = hand(q, aH, 0.055, 0.315, 0.024);
    dHour = max(dHour, -hand(q, aH, 0.105, 0.262, 0.0095));
    float dMin = hand(q, aM, 0.045, 0.452, 0.0130);
    float dSec = hand(q, aS, -0.105, 0.487, 0.0045);
    dSec = smin(dSec, sdCircle(q + clockDir(aS) * 0.112, 0.027), 0.018);
    float dHub = sdRing(q, 0.030, 0.010);

    float dWin     = sdBox(q - vec2(0.0, -0.292), vec2(0.086, 0.052), 0.016);
    float dDialCut = max(dDial, -dWin);

    float dTrack = sdRing(q, 0.532, 0.0055);
    float dArc   = sdArc(q, 0.532, 0.0110, aS);

    // --- 辉光 ②：k/d 长尾光晕。只给整块壳用一次，负责"这东西在发光"的氛围。 ---
    // 放在实体之前，让它同时染到背景上；max(·, 0.006) 是必须的，否则轮廓上会爆成白斑。
    col += CY * 0.0075 / max(abs(dBody), 0.006);

    // 表圈不再是一个死色：沿左上→右下打一道明暗，金属立刻不平了。
    // 一行代码换来"有个光源在左上"的暗示，比任何几何都便宜。
    float lit = smoothstep(-0.75, 0.75, q.y * 0.8 - q.x * 0.6);

    col = mix(col, vec3(0.030, 0.045, 0.075), fill(dBody, aa));
    col = mix(col, vec3(0.075, 0.115, 0.170) * (0.45 + 1.15 * lit), fill(dBezel, aa));
    col = mix(col, vec3(0.012, 0.020, 0.038), fill(dDialCut, aa));

    col = mix(col, CY,        stroke(dBody, 0.0045, aa));
    col = mix(col, CY * 0.7,  stroke(dDial, 0.0035, aa));
    col = mix(col, CY * 0.9,  fill(dTicks, aa));
    col = mix(col, AM * 0.85, stroke(dWin, 0.0030, aa));
    col = mix(col, CY * 0.22, fill(dTrack, aa));
    col = mix(col, MG,        fill(dArc, aa));

    col = mix(col, vec3(0.020, 0.028, 0.050), fill(dHour, aa));
    col = mix(col, AM, stroke(dHour, 0.0035, aa));
    col = mix(col, vec3(0.020, 0.028, 0.050), fill(dMin, aa));
    col = mix(col, AM, stroke(dMin, 0.0035, aa));
    col = mix(col, MG, fill(dSec, aa));
    col = mix(col, CY, fill(dHub, aa));

    // --- 辉光 ①：exp(-k*|d|) 贴身光。k 在 55~110 之间，光就只有一两毫米厚。 ---
    // 秒相关的东西给一点脉动，让画面有呼吸而不是死的。
    float pulse = 0.88 + 0.12 * sin(iTime * 1.7);
    col += CY * exp(-abs(dDial)  *  60.0) * 0.28;   // 玻璃边缘：暗示一块凸镜
    col += CY * exp(-abs(dTicks) * 110.0) * 0.35;
    col += AM * exp(-abs(dHour)  *  75.0) * 0.30;
    col += AM * exp(-abs(dMin)   *  75.0) * 0.30;
    col += MG * exp(-abs(dSec)   *  95.0) * 0.45 * pulse;
    col += MG * exp(-abs(dArc)   *  70.0) * 0.50 * pulse;

    // --- 辉光 ③：pow(k/d, p) 只用在一个点上 —— 中心轴。p>1 让核心更锐、周围掉得更快。 ---
    col += CY * pow(0.012 / max(abs(dHub), 0.006), 1.6) * 0.20;

    // --- 玻璃反光（阶段 5 的那两条，现在挪到辉光之后，玻璃在最上层）---
    vec2  gq = rotCW(q - vec2(-0.135, 0.150), -0.70);
    float g1 = sdBox(gq, vec2(0.26, 0.020), 0.020);
    float g2 = sdBox(gq - vec2(0.085, -0.080), vec2(0.115, 0.010), 0.010);
    float glass = smoothstep(0.050, -0.004, g1) * 0.60
                + smoothstep(0.028, -0.003, g2) * 0.40;
    col += vec3(0.20, 0.36, 0.50) * glass * fill(dDial, aa);

    // --- 暗角：四角压暗，视线自动收到表盘上 ---
    vec2 uvq = fragCoord / iResolution.xy;
    col *= 0.52 + 0.48 * pow(16.0 * uvq.x * uvq.y * (1.0 - uvq.x) * (1.0 - uvq.y), 0.28);

    // --- 只压过曝的部分 ---
    col = softKnee(col);

    // --- 抖动：抹掉背景大面积渐变上的 8-bit 色带 ---
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;

    fragColor = vec4(col, 1.0);
}
