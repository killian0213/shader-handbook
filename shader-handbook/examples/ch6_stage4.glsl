// 第 6 章 · 阶梯实战 · 阶段 4：外圈扇形色环 + 花心
// 花瓣是"面"，现在补"边"和"心"。构图上，曼陀罗需要一个把画面收住的外环。
const float TAU = 6.2831853;

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

// 环带遮罩：以 rad 为中心、半宽 w 的一条圆环，带抗锯齿
float ringBand(float r, float rad, float w)
{
    return smoothstep(0.005, 0.0, abs(r - rad) - w);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float r = length(p);

    vec3 col = mix(vec3(0.16, 0.06, 0.14), vec3(0.02, 0.02, 0.06),
                   smoothstep(0.0, 1.10, r));
    float k    = r * 14.0;
    float ring = (abs(fract(k) - 0.5) - 0.18) / 14.0;
    col += vec3(0.10, 0.06, 0.16) * smoothstep(0.004, 0.0, ring);

    float d1 = petalRing(p, 12.0, 0.62, 0.26, 0.085,  0.00);
    float d2 = petalRing(p,  8.0, 0.40, 0.20, 0.075,  0.26);
    float d3 = petalRing(p, 16.0, 0.22, 0.12, 0.038, -0.10);

    vec3 c1 = vec3(0.86, 0.30, 0.48);
    vec3 c2 = vec3(0.98, 0.62, 0.30);
    vec3 c3 = vec3(1.00, 0.88, 0.52);

    col = mix(col, c1, smoothstep(0.005, -0.005, d1));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d1) - 0.003));
    col = mix(col, c2, smoothstep(0.005, -0.005, d2));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d2) - 0.003));
    col = mix(col, c3, smoothstep(0.005, -0.005, d3));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d3) - 0.003));

    // --- 新增 1：外圈扇形间隔色环（6.7.3 那一节的直接应用）---
    const float NS     = 36.0;
    float       sector = TAU / NS;
    float a   = atan(p.y, p.x);
    // mod(..., NS) 很关键：atan 在 ±π 处跳 2π，扇号会从 -18 跳到 18，
    // 取模之后两侧对上，接缝就消失了。
    float sid = mod(floor(a / sector), NS);
    vec3 bc   = mix(vec3(0.80, 0.26, 0.42), vec3(1.00, 0.84, 0.52), mod(sid, 2.0));
    col = mix(col, bc, ringBand(r, 0.95, 0.030));

    // 外环再压一条细线，把色环"框"住
    col = mix(col, vec3(1.00, 0.92, 0.72), ringBand(r, 1.005, 0.004));

    // --- 新增 2：花心。极坐标在 r=0 处是奇点，必须用一个圆盘盖住 ---
    col = mix(col, vec3(0.35, 0.10, 0.22), smoothstep(0.005, -0.005, r - 0.115));
    col = mix(col, vec3(1.00, 0.86, 0.40), smoothstep(0.005, -0.005, r - 0.075));
    col = mix(col, vec3(0.30, 0.08, 0.18), smoothstep(0.004, -0.004, r - 0.028));

    fragColor = vec4(col, 1.0);
}
