// 第 6 章 · 阶梯实战 · 阶段 6：打磨
// 几何一个都没加。变化全在：统一调色板 / 辉光 / 呼吸动画 / 暗角 / 色调映射 / 抖动。
// 对比阶段 5 —— 这一步的性价比高得离谱。
const float TAU = 6.2831853;

// iq 的余弦调色板：a + b*cos(TAU*(c*t + d))。
// 一个 t 进去，一整套和谐配色出来（第 4 章）。前面几个阶段手调的
// 粉/橙/奶油三色，其实都落在这一条曲线上 —— 现在改 4 个向量就能整体换配色。
vec3 pal(float t)
{
    return vec3(0.455, 0.162, 0.580)
         + vec3(0.577, 0.749, 0.312)
         * cos(TAU * (vec3(0.584, 0.790, 1.789) * t + vec3(-0.142, 0.759, 0.258)));
}

vec2 fold(vec2 p, float n)
{
    float sector = TAU / n;
    float a = atan(p.x, p.y);
    a = mod(a + 0.5 * sector, sector) - 0.5 * sector;
    return length(p) * vec2(sin(a), cos(a));
}

float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);
    float b = sqrt(r * r - d * d);
    return ((p.y - b) * d > p.x * b)
        ? length(p - vec2(0.0, b))
        : length(p - vec2(-d, 0.0)) - r;
}

float sdPetal(vec2 p, float L, float W)
{
    float s = L * L / W;
    return sdVesica(p, 0.5 * (W + s), 0.5 * (s - W));
}

float petalRing(vec2 p, float n, float rad, float L, float W, float rot)
{
    float c = cos(rot), s = sin(rot);
    p = mat2(c, -s, s, c) * p;
    return sdPetal(fold(p, n) - vec2(0.0, rad), L, W);
}

float ringBand(float r, float rad, float w)
{
    return smoothstep(0.005, 0.0, abs(r - rad) - w);
}

float veins(vec2 q, float freq, float bend)
{
    return 0.5 + 0.5 * sin(freq * q.y + bend * sin(freq * 0.4 * q.x));
}

// 软膝压缩：K 以下【原样保留】，K 以上平滑压回 1。
// 为什么不用常见的 1-exp(-c)？因为它会把 (0.85,0.28,0.50) 抬成
// (0.83,0.45,0.65) —— 低通道被抬得更多，颜色整体发灰发奶。
// 那种 tonemap 是给 HDR 亮度用的；我们这些颜色本来就挑在显示空间里，
// 只有辉光会溢出，所以只压溢出的那部分。
vec3 softKnee(vec3 c)
{
    const float K = 0.85;
    vec3 hi = max(c - K, 0.0);
    return min(c, vec3(K)) + (1.0 - K) * (1.0 - exp(-hi / (1.0 - K)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 呼吸：整体极缓地涨缩。曼陀罗不该快速旋转，那样很廉价。
    float breathe = 1.0 + 0.020 * sin(iTime * 0.55);
    p /= breathe;
    float r = length(p);
    float a = atan(p.y, p.x);

    vec3 col = mix(vec3(0.14, 0.05, 0.13), vec3(0.015, 0.015, 0.05),
                   smoothstep(0.0, 1.10, r));
    float k    = r * 14.0;
    float ring = (abs(fract(k) - 0.5) - 0.18) / 14.0;
    col += vec3(0.10, 0.06, 0.16) * smoothstep(0.004, 0.0, ring);

    // 三层反向缓转 —— 让层与层之间有相对运动，比整体转好看得多
    float d1 = petalRing(p, 12.0, 0.62, 0.26, 0.085,  iTime * 0.045);
    float d2 = petalRing(p,  8.0, 0.40, 0.20, 0.075,  0.26 - iTime * 0.075);
    float d3 = petalRing(p, 16.0, 0.22, 0.12, 0.038, -0.10 + iTime * 0.110);

    // 三层颜色全部来自同一条调色板 → 天然和谐，改一个数就换整套配色
    vec3 c1 = pal(0.02);
    vec3 c2 = pal(0.13);
    vec3 c3 = pal(0.26);

    float v1 = veins(fold(p, 12.0), 44.0, 2.2);
    float v2 = veins(fold(p,  8.0), 60.0, 1.6);

    col = mix(col, c1 * (0.72 + 0.28 * v1), smoothstep(0.005, -0.005, d1));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d1) - 0.003));
    col = mix(col, c2 * (0.78 + 0.22 * v2), smoothstep(0.005, -0.005, d2));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d2) - 0.003));
    col = mix(col, c3, smoothstep(0.005, -0.005, d3));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d3) - 0.003));

    const float NS     = 36.0;
    float       sector = TAU / NS;
    float sid = mod(floor(a / sector), NS);
    vec3 bc   = mix(pal(0.05), pal(0.30), mod(sid, 2.0));
    col = mix(col, bc, ringBand(r, 0.95, 0.030));
    col = mix(col, pal(0.34), ringBand(r, 1.005, 0.004));

    float teeth = 0.5 + 0.5 * cos(a * 72.0);
    col = mix(col, pal(0.42) * teeth, ringBand(r, 0.885, 0.020));

    col = mix(col, pal(0.62) * 0.4, smoothstep(0.005, -0.005, r - 0.115));
    col = mix(col, pal(0.20),       smoothstep(0.005, -0.005, r - 0.075));
    col = mix(col, pal(0.62) * 0.3, smoothstep(0.004, -0.004, r - 0.028));

    // --- 辉光：光是【加】上去的，不是 mix 的。用 exp 衰减最自然。 ---
    // 衰减系数要够大（这里 60~90），辉光才是"贴着轮廓的一圈光"；
    // 系数太小会漫进花瓣内部，整张图发灰发奶 —— 这是新手最常犯的过度打磨。
    col += c1 * exp(-abs(d1) * 60.0) * 0.20;
    col += c2 * exp(-abs(d2) * 70.0) * 0.18;
    col += c3 * exp(-abs(d3) * 90.0) * 0.16;
    col += pal(0.20) * exp(-max(r - 0.075, 0.0) * 11.0) * 0.30;   // 花心透光

    // --- 暗角：四角压暗，视线自动收到中心 ---
    vec2 uvq = fragCoord / iResolution.xy;
    col *= 0.58 + 0.42 * pow(16.0 * uvq.x * uvq.y * (1.0 - uvq.x) * (1.0 - uvq.y), 0.30);

    // --- 收尾：只压过曝，不动正常颜色（也不再补 gamma，颜色本就在显示空间）---
    col = softKnee(col);

    // --- 抖动：抹掉 8-bit 渐变色带 ---
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;

    fragColor = vec4(col, 1.0);
}
