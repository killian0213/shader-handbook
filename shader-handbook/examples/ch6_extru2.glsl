// 第 6 章 · 挤出 ②：六边形高度场地板（科幻地砖）
// 每格 hash → 不同挤出高度；再加软阴影。这就是语料里「科幻地板」的最小完整版。
#define MAX_STEPS 90
#define MAX_DIST  45.0

float hash21(vec2 p)
{
    p = fract(p * vec2(127.1, 311.7));
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 简易 hex：返回 id 与局部坐标（近似，教学够用）
vec4 hexCell(vec2 p)
{
    const vec2 s = vec2(1.0, 1.7320508);
    vec2 p1 = mod(p, s) - 0.5 * s;
    vec2 p2 = mod(p + 0.5 * s, s) - 0.5 * s;
    vec2 lp = (dot(p1, p1) < dot(p2, p2)) ? p1 : p2;
    vec2 id = p - lp;
    float dEdge = 0.5 - max(abs(lp.x), abs(lp.x * 0.5 + lp.y * 0.866));
    return vec4(id, lp);
}

float map(vec3 p)
{
    vec2 q = p.xz * 1.35;
    vec4 hx = hexCell(q);
    float h = 0.08 + 0.55 * hash21(hx.xy * 1.3);
    // 六边形柱：用局部到边距离近似
    vec2 lp = hx.zw;
    float dHex = -(0.48 - max(abs(lp.x) * 1.15, abs(lp.x * 0.5 + lp.y * 0.8660254) * 1.05));
    // 挤出到高度 h（柱脚在 y=0）
    vec2 w = vec2(dHex, abs(p.y - 0.5 * h) - 0.5 * h);
    float pillar = min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
    // 细缝地面
    float ground = p.y + 0.01;
    return min(ground, pillar);
}

float march(vec3 ro, vec3 rd)
{
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float h = map(ro + rd * t);
        if (h < 0.0015 * t || t > MAX_DIST) break;
        t += h;
    }
    return t;
}

float softShadow(vec3 ro, vec3 rd)
{
    float res = 1.0, t = 0.02;
    for (int i = 0; i < 28; i++) {
        float h = map(ro + rd * t);
        res = min(res, 10.0 * h / t);
        t += clamp(h, 0.02, 0.2);
        if (res < 0.01 || t > 12.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

vec3 calcN(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float ang = iTime * 0.12;
    vec3 ro = vec3(4.0 * sin(ang), 3.2, 4.0 * cos(ang));
    vec3 ta = vec3(0.0, 0.2, 0.0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0, 1, 0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 1.55 * ww);

    float t = march(ro, rd);
    vec3 sky = mix(vec3(0.08, 0.1, 0.18), vec3(0.35, 0.55, 0.85), rd.y * 0.5 + 0.5);
    sky += vec3(1.0, 0.85, 0.6) * pow(max(dot(rd, normalize(vec3(0.4, 0.7, 0.3))), 0.0), 40.0) * 0.6;
    vec3 col = sky;

    if (t < MAX_DIST) {
        vec3 p = ro + rd * t;
        vec3 n = calcN(p);
        vec3 L = normalize(vec3(0.45, 0.85, 0.25));
        float sh = softShadow(p + n * 0.02, L);
        float dif = max(dot(n, L), 0.0) * sh;
        vec4 hx = hexCell(p.xz * 1.35);
        vec3 albedo = mix(vec3(0.15, 0.35, 0.45), vec3(0.55, 0.85, 0.95), hash21(hx.xy));
        if (p.y < 0.02) albedo = vec3(0.08, 0.1, 0.14);
        // 边缘霓虹
        float edge = exp(-abs(map(p)) * 40.0);
        col = albedo * (0.12 + 0.88 * dif);
        col += vec3(0.3, 0.85, 1.0) * edge * 0.15 * (1.0 - step(p.y, 0.02));
        col = mix(col, sky, 1.0 - exp(-0.025 * t));
    }
    fragColor = vec4(pow(max(col, 0.0), vec3(0.92)), 1.0);
}
