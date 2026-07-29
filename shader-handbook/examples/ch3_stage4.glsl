// 第 3 章 · 阶梯实战 · 阶段 4：指针 —— 方向向量 + 差集镂空
// 新增：clockDir / hand，时针用 max(a,-b) 挖空，秒针用 smin 长出配重。
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

// 表盘方向：ang 从 12 点起、顺时针为正。和 fold 里的 atan(p.x,p.y) 同一个约定。
vec2 clockDir(float ang)
{
    return vec2(sin(ang), cos(ang));
}

// 指针 = 一根圆头线段。有了方向向量，连旋转矩阵都不需要。
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

    // --- 新增：时间 → 三个角度。从 10:09:00 起算，走 3 倍速 ---
    float S  = 36540.0 + iTime * 3.0;
    float aH = TAU * fract(S / 43200.0);
    float aM = TAU * fract(S /  3600.0);
    float aS = TAU * fract(S /    60.0);

    // --- 新增：时针。粗线段减掉一根短细线段 → 镂空骨架针 ---
    float dHour = hand(q, aH, 0.055, 0.315, 0.024);
    dHour = max(dHour, -hand(q, aH, 0.105, 0.262, 0.0095));

    // --- 新增：分针。实心，更长更细 ---
    float dMin = hand(q, aM, 0.045, 0.452, 0.0130);

    // --- 新增：秒针 + 尾部配重。smin 让配重和针杆长成一体 ---
    float dSec = hand(q, aS, -0.105, 0.487, 0.0045);
    dSec = smin(dSec, sdCircle(q + clockDir(aS) * 0.112, 0.027), 0.018);

    float dHub = sdRing(q, 0.030, 0.010);

    col = mix(col, vec3(0.030, 0.045, 0.075), fill(dBody,  aa));
    col = mix(col, vec3(0.075, 0.115, 0.170), fill(dBezel, aa));
    col = mix(col, vec3(0.012, 0.020, 0.038), fill(dDial,  aa));

    col = mix(col, CY,       stroke(dBody, 0.0045, aa));
    col = mix(col, CY * 0.7, stroke(dDial, 0.0035, aa));
    col = mix(col, CY * 0.9, fill(dTicks, aa));

    // --- 新增：指针的着色。时针分针是"暗填充 + 亮描边"，秒针整根发亮 ---
    col = mix(col, vec3(0.020, 0.028, 0.050), fill(dHour, aa));
    col = mix(col, AM, stroke(dHour, 0.0035, aa));
    col = mix(col, vec3(0.020, 0.028, 0.050), fill(dMin, aa));
    col = mix(col, AM, stroke(dMin, 0.0035, aa));
    col = mix(col, MG, fill(dSec, aa));
    col = mix(col, CY, fill(dHub, aa));

    fragColor = vec4(col, 1.0);
}
