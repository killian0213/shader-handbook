// 第 8 章 · 阶梯实战 · 阶段 4：域重复 — 无限柱阵
// 教学点：p.xz = mod(p.xz + 0.5*s, s) - 0.5*s 把空间切成周期单元，
// 在每个单元里放同一根柱子，视觉上就是无穷延伸的柱廊。
#define MAX_STEPS 100
#define MAX_DIST  40.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);
const float CELL = 1.35;

float sdCylinder(vec3 p, float h, float r)
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// 单格内的柱子：先在局部坐标里算 SDF，再和全局地面取 min
vec2 map(vec3 p)
{
    vec2 res = vec2(p.y, 2.0);

    // 核心公式：把 xz 折叠进 [-0.5*s, 0.5*s] 的周期方格
    vec3 q = p;
    q.xz = mod(q.xz + 0.5 * CELL, CELL) - 0.5 * CELL;

    float col = sdCylinder(q - vec3(0.0, 1.1, 0.0), 1.1, 0.14);
    if (col < res.x) res = vec2(col, 1.0);

    return res;
}

vec2 raymarch(vec3 ro, vec3 rd)
{
    float t = 0.0;
    float m = -1.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec2 h = map(ro + rd * t);
        if (h.x < 0.0015 * t) { m = h.y; break; }
        if (t > MAX_DIST) break;
        t += h.x;
    }
    return vec2(t, m);
}

vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.0015;
    return normalize(e.xyy * map(pos + e.xyy).x +
                     e.yyx * map(pos + e.yyx).x +
                     e.yxy * map(pos + e.yxy).x +
                     e.xxx * map(pos + e.xxx).x);
}

float softShadow(vec3 ro, vec3 rd)
{
    float res = 1.0;
    float t   = 0.04;
    for (int i = 0; i < 24; i++) {
        float h = map(ro + rd * t).x;
        res = min(res, h / (0.055 * t));
        t += clamp(h, 0.06, 0.9);
        if (res < 0.003 || t > 18.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y, 0.0, 1.0);
    return mix(vec3(0.90, 0.74, 0.60), vec3(0.14, 0.30, 0.62), pow(h, 0.45));
}

mat3 setCamera(vec3 ro, vec3 ta, float cr)
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 环绕相机：从柱廊上方俯瞰重复图案
    float an = iTime * 0.18;
    vec3  ta = vec3(0.0, 0.6, 0.0);
    vec3  ro = vec3(5.5 * sin(an), 2.2, 5.5 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec2  res = raymarch(ro, rd);
    float t   = res.x;
    vec3  col = sky(rd);

    if (res.y > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);
        vec3 mate = (res.y < 1.5) ? vec3(0.58, 0.54, 0.48)
                                  : vec3(0.24, 0.24, 0.22);

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float amb = 0.5 + 0.5 * nor.y;
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;
        col = mate * (1.25 * dif * sha + 0.28 * amb);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
