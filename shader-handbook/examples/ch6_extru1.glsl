// 第 6 章 · 挤出 ①：圆点阵 → 柱林（最小 raymarch）
// 先看懂：2D 距离 d2 = length(fract(xz)-0.5)-r，再 opExtrusion 成柱，然后 march。
// 超纲一点点（第 7 章骨架），但只为证明「格子图案能站起来」。
#define MAX_STEPS 80
#define MAX_DIST  40.0

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 2D：无限圆点阵（每格一个圆）
float sdCircleGrid(vec2 p, float halfCell, float radius)
{
    vec2 q = p / halfCell;
    vec2 id = floor(q);
    vec2 lp = fract(q) - 0.5;
    float r = radius * (0.65 + 0.35 * hash21(id));
    return length(lp) * halfCell - r;
}

// iq 式挤出：2D SDF + 半高 h → 3D 柱体
float opExtrusion(float d2, float y, float h)
{
    vec2 w = vec2(d2, abs(y) - h);
    return min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
}

float map(vec3 p)
{
    float d2 = sdCircleGrid(p.xz, 0.55, 0.18);
    float pillars = opExtrusion(d2, p.y - 0.6, 0.6);
    float ground = p.y;
    return min(ground, pillars);
}

float march(vec3 ro, vec3 rd)
{
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float h = map(ro + rd * t);
        if (h < 0.001 * t || t > MAX_DIST) break;
        t += h;
    }
    return t;
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
    float ang = 0.6 + iTime * 0.15;
    vec3 ro = vec3(3.5 * sin(ang), 2.8, 3.5 * cos(ang));
    vec3 ta = vec3(0.0, 0.4, 0.0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0, 1, 0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 1.6 * ww);

    float t = march(ro, rd);
    vec3 sky = mix(vec3(0.55, 0.7, 0.9), vec3(0.9, 0.85, 0.75), rd.y * 0.5 + 0.5);
    vec3 col = sky;
    if (t < MAX_DIST) {
        vec3 p = ro + rd * t;
        vec3 n = calcN(p);
        vec3 L = normalize(vec3(0.5, 0.9, 0.2));
        float dif = max(dot(n, L), 0.0);
        vec3 albedo = (p.y < 0.02) ? vec3(0.35, 0.38, 0.4)
                                   : vec3(0.75, 0.45, 0.35);
        col = albedo * (0.18 + 0.82 * dif);
        col = mix(col, sky, 1.0 - exp(-0.02 * t));
    }
    fragColor = vec4(pow(max(col, 0.0), vec3(0.95)), 1.0);
}
