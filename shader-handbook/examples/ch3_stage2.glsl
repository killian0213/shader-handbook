// 第 3 章 · 阶梯实战 · 阶段 2：表冠与提环 —— 布尔运算 + smin
// 新增：圆角矩形图元、smin 平滑并集、max(a,-b) 差集。
// 关键变化：壳不再是一个圆，而是一个叫 dBody 的【合成距离场】。
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

// 圆角矩形：先把半尺寸缩小 r，算完再膨胀 r 回来
float sdBox(vec2 p, vec2 b, float r)
{
    vec2 d = abs(p) - b + r;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}

// 平滑最小值：k 是混合半径，两个距离相差小于 k 的地方才会被抹圆
float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
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

    // --- 新增：表冠。圆角矩形，故意和壳重叠 0.02，好让 smin 有东西可混 ---
    float dCrown = sdBox(q - vec2(0.0, 0.655), vec2(0.075, 0.055), 0.026);

    // --- 新增：提环。圆盘减圆盘，就是 3.4 的差集 max(a, -b) ---
    // 它和 abs(length-r)-w 结果一样，但写成差集更能看出"减"的动作。
    vec2  bq   = q - vec2(0.0, 0.800);
    float dBow = max(sdCircle(bq, 0.105), -sdCircle(bq, 0.062));

    // --- 新增：三个零件合成一个实体 ---
    // 表冠用 smin：车出来的一块料，根部应该有倒角。
    // 提环用 min：金属焊上去的，接缝就该是硬的。
    float dBody = smin(dCase, dCrown, 0.045);
    dBody = min(dBody, dBow);

    col = mix(col, vec3(0.030, 0.045, 0.075), fill(dBody,  aa));
    col = mix(col, vec3(0.075, 0.115, 0.170), fill(dBezel, aa));
    col = mix(col, vec3(0.012, 0.020, 0.038), fill(dDial,  aa));

    col = mix(col, CY,       stroke(dBody, 0.0045, aa));
    col = mix(col, CY * 0.7, stroke(dDial, 0.0035, aa));

    fragColor = vec4(col, 1.0);
}
