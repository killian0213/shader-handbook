// 第 6 章 · 挤出 ④：扭曲晶格走廊（压轴）
// 方格柱林 + 域扭曲 + 飞穿相机 + 霓虹边。语料「晶格世界」的趣味浓缩版。
#define MAX_STEPS 100
#define MAX_DIST  50.0

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float sdBox2(vec2 p, vec2 b)
{
    vec2 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float map(vec3 p)
{
    // 沿 z 飞穿；轻微 sine 扭曲让格子「活」
    vec3 q = p;
    q.x += 0.35 * sin(q.z * 0.45 + iTime * 0.6);
    q.y += 0.15 * sin(q.z * 0.3 + 1.7);

    float cell = 1.1;
    vec2 id = floor(q.xz / cell);
    vec2 lp = fract(q.xz / cell) - 0.5;
    float h = 0.5 + 1.6 * hash21(id);
    // 只在部分格子放柱（稀疏晶格）
    float occ = step(0.42, hash21(id + 2.3));
    float pillar = 1e3;
    if (occ > 0.5) {
        float d2 = sdBox2(lp * cell, vec2(0.2));
        vec2 w = vec2(d2, abs(q.y - 0.5 * h) - 0.5 * h);
        pillar = min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
    }

    float ground = q.y + 0.02;
    float ceiln = 3.2 - q.y;
    return min(pillar, min(ground, ceiln));
}

float march(vec3 ro, vec3 rd)
{
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float h = map(ro + rd * t);
        if (h < 0.0015 * t || t > MAX_DIST) break;
        t += h * 0.9;
    }
    return t;
}

float softShadow(vec3 ro, vec3 rd)
{
    float res = 1.0, t = 0.03;
    for (int i = 0; i < 20; i++) {
        float h = map(ro + rd * t);
        res = min(res, 12.0 * h / t);
        t += clamp(h, 0.03, 0.25);
        if (res < 0.01 || t > 14.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

vec3 calcN(vec3 p)
{
    vec2 e = vec2(0.0015, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 ro = vec3(0.2 * sin(iTime * 0.5), 1.4, iTime * 1.1);
    vec3 ta = ro + vec3(0.0, 0.0, 1.5);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0, 1, 0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 1.35 * ww);

    float t = march(ro, rd);
    vec3 fogCol = vec3(0.05, 0.08, 0.16);
    vec3 col = fogCol;

    if (t < MAX_DIST) {
        vec3 p = ro + rd * t;
        vec3 n = calcN(p);
        vec3 L = normalize(vec3(0.3, 0.8, 0.4));
        float sh = softShadow(p + n * 0.02, L);
        float dif = max(dot(n, L), 0.0) * sh;
        vec3 albedo = vec3(0.12, 0.16, 0.22);
        if (p.y < 0.05) albedo = vec3(0.08, 0.1, 0.14);
        if (p.y > 3.0) albedo = vec3(0.06, 0.07, 0.1);

        // 霓虹边：靠近表面时提亮
        float edge = exp(-abs(map(p)) * 25.0);
        vec3 neon = 0.5 + 0.5 * cos(6.28318 * (p.z * 0.08 + vec3(0.0, 0.33, 0.67)));
        col = albedo * (0.1 + 0.9 * dif);
        col += neon * edge * 0.45;
        // 地面网格微光
        float grid = abs(fract(p.x * 0.9) - 0.5) * abs(fract(p.z * 0.9) - 0.5);
        col += vec3(0.2, 0.6, 1.0) * step(p.y, 0.05) * smoothstep(0.02, 0.0, grid) * 0.25;
        col = mix(col, fogCol, 1.0 - exp(-0.045 * t));
    }

    vec2 q = fragCoord / iResolution.xy;
    col *= 0.6 + 0.4 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.4);
    fragColor = vec4(pow(max(col, 0.0), vec3(0.9)), 1.0);
}
