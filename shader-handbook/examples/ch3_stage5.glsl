// 第 3 章 · 阶梯实战 · 阶段 5：秒进度弧 + 日期窗 + 玻璃反光
// 新增：sdPie / rotCW / sdArc（圆环 ∩ 扇形），盘面挖窗（差集），
//       以及一条用【硬蒙版相乘】裁进盘面的软反光。
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

// 扇形（两个半平面的交，Maarten 版）：halfAng 是半张角，开口朝 +y。
// halfAng 超过 π/2 也成立 —— abs(p.x) 那一项会自动翻成"挖掉一个反向锥"，
// 所以 halfAng 从 0 一直调到 π（整圆）都不会崩。
float sdPie(vec2 p, float halfAng)
{
    vec2 n = vec2(cos(halfAng), sin(halfAng));
    return abs(p.x) * n.x - p.y * n.y;
}

// 让图形看起来顺时针转了 a（做法是把坐标反着转）
vec2 rotCW(vec2 p, float a)
{
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c) * p;
}

// 圆弧 = 圆环 ∩ 扇形。起点固定在 12 点，顺时针扫过 sweep 弧度。
float sdArc(vec2 p, float r, float w, float sweep)
{
    p = rotCW(p, sweep * 0.5);                  // 把扇形的中轴转到弧的中点
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

    // --- 新增：日期窗。从盘面里减掉一个圆角矩形，露出下面较亮的壳体 ---
    float dWin  = sdBox(q - vec2(0.0, -0.292), vec2(0.086, 0.052), 0.016);
    float dDialCut = max(dDial, -dWin);

    // --- 新增：秒进度弧 + 它的底轨 ---
    float dTrack = sdRing(q, 0.532, 0.0055);
    float dArc   = sdArc(q, 0.532, 0.0110, aS);

    col = mix(col, vec3(0.030, 0.045, 0.075), fill(dBody,     aa));
    col = mix(col, vec3(0.075, 0.115, 0.170), fill(dBezel,    aa));
    col = mix(col, vec3(0.012, 0.020, 0.038), fill(dDialCut,  aa));

    col = mix(col, CY,        stroke(dBody, 0.0045, aa));
    col = mix(col, CY * 0.7,  stroke(dDial, 0.0035, aa));
    col = mix(col, CY * 0.9,  fill(dTicks, aa));
    col = mix(col, AM * 0.85, stroke(dWin, 0.0030, aa));      // 窗框
    col = mix(col, CY * 0.22, fill(dTrack, aa));              // 底轨：暗一圈就够
    col = mix(col, MG,        fill(dArc, aa));

    col = mix(col, vec3(0.020, 0.028, 0.050), fill(dHour, aa));
    col = mix(col, AM, stroke(dHour, 0.0035, aa));
    col = mix(col, vec3(0.020, 0.028, 0.050), fill(dMin, aa));
    col = mix(col, AM, stroke(dMin, 0.0035, aa));
    col = mix(col, MG, fill(dSec, aa));
    col = mix(col, CY, fill(dHub, aa));

    // --- 新增：玻璃反光。它在所有东西之上，所以放最后，而且是加法。
    // 一条主亮条 + 一条细伴条，是玻璃/塑料高光的通用画法：单独一条会像污渍。
    // 注意裁剪用的是 fill(dDial) 硬蒙版【相乘】，不是 max(dGlass, dDial)。
    // 软过渡碰上 max 会从盘外漏出去 —— 这个坑正文里讲。
    vec2  gq = rotCW(q - vec2(-0.135, 0.150), -0.70);
    float g1 = sdBox(gq, vec2(0.26, 0.020), 0.020);
    float g2 = sdBox(gq - vec2(0.085, -0.080), vec2(0.115, 0.010), 0.010);
    float glass = smoothstep(0.050, -0.004, g1) * 0.60
                + smoothstep(0.028, -0.003, g2) * 0.40;
    col += vec3(0.20, 0.36, 0.50) * glass * fill(dDial, aa);

    fragColor = vec4(col, 1.0);
}
