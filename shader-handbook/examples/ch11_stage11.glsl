// 第 11 章 · 阶梯实战 · 阶段 11：KIFS 四面体折叠
// 四面体 Kaleidoscopic 折叠 + 球体交集 → 晶体洞窟。比 Apollonian 更短更亮。
// 陷阱=min|z| 染色，慢速轨道相机。迭代 6 层，MAX_STEPS=72。
#define MAX_STEPS 72
#define MAX_DIST  14.0
#define FOLD_ITER 6

const float TAU = 6.2831853;

void kifsFold(inout vec3 p)
{
    p = abs(p);
    if (p.x < p.y) p.xy = p.yx;
    if (p.x < p.z) p.xz = p.zx;
    if (p.y < p.z) p.yz = p.zy;
    p = p - 2.0 * min(dot(p, vec3(-1.0)), 0.0) * vec3(-1.0);
}

float kifsDE(vec3 p, out float trap)
{
    float scale = 1.0;
    trap = 1e10;
    for (int i = 0; i < 8; i++) {
        if (i >= FOLD_ITER) break;
        kifsFold(p);
        p = p * 2.0 + vec3(-1.0, -0.8, -1.2);
        scale *= 2.0;
        trap = min(trap, length(p));
    }
    return (length(p) - 0.35) / scale;
}

float map(vec3 p, out float trap)
{
    return kifsDE(p * 0.65, trap) / 0.65;
}

vec3 pal(float t)
{
    return 0.5 + 0.5 * cos(TAU * (vec3(0.15, 0.55, 0.85) + t));
}

vec2 raymarch(vec3 ro, vec3 rd, out float trap)
{
    float t = 0.0, m = -1.0;
    trap = 1e10;
    for (int i = 0; i < MAX_STEPS; i++) {
        float tr;
        float h = map(ro + rd * t, tr);
        trap = min(trap, tr);
        if (h < 0.0007 * max(t, 1.0)) { m = 1.0; break; }
        if (t > MAX_DIST) break;
        t += h * 0.78;
    }
    return vec2(t, m);
}

vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.0006;
    float tr;
    return normalize(e.xyy * map(pos + e.xyy, tr) +
                     e.yyx * map(pos + e.yyx, tr) +
                     e.yxy * map(pos + e.yxy, tr) +
                     e.xxx * map(pos + e.xxx, tr));
}

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    return mat3(cu, cross(cu, cw), cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = iTime * 0.14;
    vec3  ro = vec3(2.8 * cos(an), 1.3, 2.8 * sin(an));
    vec3  rd = setCamera(ro, vec3(0.0, -0.2, 0.0)) * normalize(vec3(p, 1.85));

    vec3  lig = normalize(vec3(0.4, 0.85, -0.5));
    float trap;
    vec2  res = raymarch(ro, rd, trap);

    vec3 bg = mix(vec3(0.01, 0.02, 0.05), vec3(0.08, 0.12, 0.22), 0.5 + 0.5 * rd.y);
    vec3 col = bg;

    if (res.y > 0.0) {
        vec3 pos = ro + rd * res.x;
        vec3 nor = calcNormal(pos);
        float dif = clamp(dot(nor, lig), 0.0, 1.0);
        float spe = pow(clamp(dot(reflect(-rd, nor), lig), 0.0, 1.0), 16.0);

        vec3 mate = pal(trap * 1.6 + length(pos) * 0.08);
        col = mate * (0.15 + 0.85 * dif);
        col += vec3(1.0, 0.95, 0.85) * spe * 0.35;
        col += pal(0.3) * pow(clamp(1.0 + dot(rd, nor), 0.0, 1.0), 3.0) * 0.18;
        col = mix(col, bg, 1.0 - exp(-0.018 * res.x * res.x));
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
