// 第 8 章 · 阶梯实战 · 阶段 1：域平移拼出基本体
// 教学点：SDF 基本体公式只描述"以原点为中心"的形状；
// 把 p 平移到局部坐标（p - center）就能在世界里任意摆放。
// 地面 + 球 + 盒并排，Lambert + 软阴影 —— 和第 7 章同一套 march 管线。
#define MAX_STEPS 90
#define MAX_DIST  30.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);

float sdSphere(vec3 p, float r) { return length(p) - r; }

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// 三个物体各用一次域平移，再取最近距离 + 材质号
vec2 map(vec3 p)
{
    vec2 res = vec2(sdSphere(p - vec3(-1.6, 0.75, 0.0), 0.75), 1.0);
    float db = sdBox(p - vec3(0.0, 0.55, 0.0), vec3(0.55, 0.55, 0.55));
    if (db < res.x) res = vec2(db, 2.0);
    float ds = sdSphere(p - vec3(1.6, 0.55, 0.0), 0.55);
    if (ds < res.x) res = vec2(ds, 3.0);
    float dp = p.y;
    if (dp < res.x) res = vec2(dp, 4.0);
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

    float an = 0.22 + 0.12 * sin(iTime * 0.15);
    vec3  ta = vec3(0.0, 0.55, 0.0);
    vec3  ro = vec3(5.0 * sin(an), 1.55, 5.0 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec2  res = raymarch(ro, rd);
    float t   = res.x;
    vec3  col = sky(rd);

    if (res.y > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);

        // 材质按 id 区分：左球暖色、中盒灰、右球青、地面暗
        vec3 mate = vec3(0.68, 0.64, 0.58);
        if (res.y > 3.5)      mate = vec3(0.24, 0.24, 0.22);
        else if (res.y > 2.5) mate = vec3(0.42, 0.58, 0.62);
        else if (res.y > 1.5) mate = vec3(0.52, 0.50, 0.48);

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float amb = 0.5 + 0.5 * nor.y;
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;
        col = mate * (1.25 * dif * sha + 0.28 * amb);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
