// 第 8 章 · 阶梯实战 · 阶段 2：硬 CSG — 并、减
// 教学点：min = 并集（UNION），max(a,-b) = 差集（从 a 里挖掉 b）。
// 造型：方盒 ∪ 穿心圆环，再减去一颗球做"咬痕"。
#define MAX_STEPS 90
#define MAX_DIST  30.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdSphere(vec3 p, float r) { return length(p) - r; }

float opUnion(float a, float b) { return min(a, b); }

// 差集：保留 a 中不在 b 内的部分
float opSub(float a, float b) { return max(a, -b); }

vec2 map(vec3 p)
{
    // 主体：立方体与水平圆环并在一起 —— "甜甜圈穿过方块"
    float box  = sdBox(p - vec3(0.0, 1.0, 0.0), vec3(1.05, 1.05, 1.05));
    float tor  = sdTorus(p - vec3(0.0, 1.0, 0.0), vec2(0.85, 0.22));
    float arch = opUnion(box, tor);

    // 右上角咬掉一块球，让 CSG 差集一眼可读
    float bite = sdSphere(p - vec3(0.75, 1.35, 0.55), 0.55);
    float body = opSub(arch, bite);

    vec2 res = vec2(body, 1.0);
    float dp = p.y;
    if (dp < res.x) res = vec2(dp, 2.0);
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
        if (res < 0.003 || t > 14.0) break;
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

    float an = 0.35 + 0.18 * sin(iTime * 0.12);
    vec3  ta = vec3(0.0, 1.0, 0.0);
    vec3  ro = vec3(4.5 * sin(an), 1.65, 4.5 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec2  res = raymarch(ro, rd);
    float t   = res.x;
    vec3  col = sky(rd);

    if (res.y > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);
        vec3 mate = (res.y < 1.5) ? vec3(0.62, 0.58, 0.52)
                                  : vec3(0.26, 0.26, 0.24);

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float amb = 0.5 + 0.5 * nor.y;
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;
        col = mate * (1.25 * dif * sha + 0.28 * amb);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
