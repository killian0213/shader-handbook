// 第 6 章 · 挤出 ③：Truchet 浮雕迷宫
// 2D 圆弧 Truchet → 挤成矮墙 → 相机扫过。管道感来自「图案」，立体感来自「挤出」。
#define MAX_STEPS 90
#define MAX_DIST  40.0

float hash21(vec2 p)
{
    p = fract(p * vec2(127.1, 311.7));
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float truchet2D(vec2 p)
{
    float scale = 1.0;
    vec2 gp = p * scale;
    vec2 id = floor(gp);
    vec2 lp = fract(gp) - 0.5;
    float side = step(0.5, hash21(id));
    vec2 a = (side < 0.5) ? lp - vec2(-0.5, -0.5) : lp - vec2(0.5, -0.5);
    vec2 b = (side < 0.5) ? lp - vec2(0.5, 0.5)  : lp - vec2(-0.5, 0.5);
    float d = min(abs(length(a) - 0.5), abs(length(b) - 0.5));
    return d - 0.12; // 负值 = 管道内部（墙的「槽」）
}

float opExtrusion(float d2, float y, float h)
{
    vec2 w = vec2(d2, abs(y) - h);
    return min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
}

float map(vec3 p)
{
    // 管道槽挤成「沟」：用 -truchet 让管道凹下去，或反过来做凸浮雕
    float d2 = -truchet2D(p.xz); // 正 = 墙体固体
    float relief = opExtrusion(d2, p.y - 0.18, 0.18);
    float ground = p.y;
    return min(ground, relief);
}

float march(vec3 ro, vec3 rd)
{
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float h = map(ro + rd * t);
        if (h < 0.0012 * t || t > MAX_DIST) break;
        t += h;
    }
    return t;
}

float softShadow(vec3 ro, vec3 rd)
{
    float res = 1.0, t = 0.02;
    for (int i = 0; i < 24; i++) {
        float h = map(ro + rd * t);
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.2);
        if (res < 0.01 || t > 10.0) break;
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
    // 掠射扫过迷宫
    vec3 ro = vec3(iTime * 0.35, 1.6, 0.0);
    vec3 ta = ro + vec3(1.2, -0.35, 0.15 * sin(iTime * 0.4));
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0, 1, 0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 1.4 * ww);

    float t = march(ro, rd);
    vec3 sky = mix(vec3(0.7, 0.55, 0.4), vec3(0.35, 0.55, 0.85), rd.y * 0.5 + 0.5);
    vec3 col = sky;
    if (t < MAX_DIST) {
        vec3 p = ro + rd * t;
        vec3 n = calcN(p);
        vec3 L = normalize(vec3(0.4, 0.85, 0.3));
        float sh = softShadow(p + n * 0.02, L);
        float dif = max(dot(n, L), 0.0) * sh;
        float ao = clamp(0.4 + 0.6 * n.y, 0.0, 1.0);
        vec3 albedo = (p.y < 0.02) ? vec3(0.45, 0.4, 0.35) : vec3(0.85, 0.7, 0.45);
        // 槽底略亮，像金属管道
        float groove = smoothstep(0.15, 0.0, abs(truchet2D(p.xz)));
        albedo = mix(albedo, vec3(0.95, 0.85, 0.55), groove * step(0.02, p.y) * 0.5);
        col = albedo * (0.15 * ao + 0.85 * dif);
        col = mix(col, sky, 1.0 - exp(-0.03 * t));
    }
    fragColor = vec4(pow(max(col, 0.0), vec3(0.95)), 1.0);
}
