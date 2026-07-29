// 第 3 章 · 阶梯实战 · 阶段 3：刻度环 —— 线段 SDF + 极角折叠
// 新增：sdSegment、fold、tickRing。三档粗细的刻度用同一个函数换参数得到。
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

// 线段：把 p 投影到 ab 上，钳到 [0,1] 之内，再取距离。
// 返回的是到【中心线】的距离，所以外面要自己减半宽。
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

// 极角折叠：把整圈复制成 n 份，于是你只需要画一份。
// atan(p.x, p.y) 是"从 12 点方向起、顺时针"的角，所以 0 号扇区正对上方。
vec2 fold(vec2 p, float n)
{
    float sector = TAU / n;
    float a = atan(p.x, p.y);
    a = mod(a + 0.5 * sector, sector) - 0.5 * sector;
    return length(p) * vec2(sin(a), cos(a));
}

// 一圈径向刻度：n 根，从半径 r0 到 r1，半宽 w。代码里只画了一根。
float tickRing(vec2 p, float n, float r0, float r1, float w)
{
    return sdSegment(fold(p, n), vec2(0.0, r0), vec2(0.0, r1)) - w;
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

    // --- 新增：三档刻度，外端一律对齐到 0.500，内端决定长短 ---
    // 数量必须是整数，而且 4 | 12 | 60 互相整除，三档才会精确重合。
    float dTicks = tickRing(q, 60.0, 0.462, 0.500, 0.0030);
    dTicks = min(dTicks, tickRing(q, 12.0, 0.432, 0.500, 0.0075));
    dTicks = min(dTicks, tickRing(q,  4.0, 0.398, 0.500, 0.0130));

    col = mix(col, vec3(0.030, 0.045, 0.075), fill(dBody,  aa));
    col = mix(col, vec3(0.075, 0.115, 0.170), fill(dBezel, aa));
    col = mix(col, vec3(0.012, 0.020, 0.038), fill(dDial,  aa));

    col = mix(col, CY,       stroke(dBody, 0.0045, aa));
    col = mix(col, CY * 0.7, stroke(dDial, 0.0035, aa));
    col = mix(col, CY * 0.9, fill(dTicks, aa));

    fragColor = vec4(col, 1.0);
}
