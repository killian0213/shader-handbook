// 第 8 章 · 阶梯实战 · 阶段 5：域扭曲 — 螺旋柱雕
// 教学点：在求距离之前对坐标做非线性变形（twist/bend），
// 直线棱柱在世界里就会弯成螺旋。这里用 angle * y 绕 Y 轴扭转方柱。
#define MAX_STEPS 90
#define MAX_DIST  30.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// 绕 Y 轴扭转：角度随高度线性增大 → 螺旋感
void opTwist(inout vec3 p, float k)
{
    float c = cos(k * p.y);
    float s = sin(k * p.y);
    p.xz = mat2(c, -s, s, c) * p.xz;
}

vec2 map(vec3 p)
{
    vec2 res = vec2(p.y, 2.0);

    vec3 q = p - vec3(0.0, 1.6, 0.0);
    // k ≈ 1.8：整根 3.2 高的方柱大约扭转一圈
    opTwist(q, 1.8);
    float col = sdBox(q, vec3(0.35, 1.6, 0.35));
    if (col < res.x) res = vec2(col, 1.0);

    // 底座：不扭曲的扁盒，让雕塑"长"在地面上
    float base = sdBox(p - vec3(0.0, 0.12, 0.0), vec3(0.55, 0.12, 0.55));
    if (base < res.x) res = vec2(base, 3.0);

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

    float an = 0.42 + 0.20 * sin(iTime * 0.11);
    vec3  ta = vec3(0.0, 1.2, 0.0);
    vec3  ro = vec3(4.8 * sin(an), 1.75, 4.8 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec2  res = raymarch(ro, rd);
    float t   = res.x;
    vec3  col = sky(rd);

    if (res.y > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);

        vec3 mate = vec3(0.62, 0.56, 0.48);
        if (res.y > 2.5) mate = vec3(0.34, 0.32, 0.30);
        else if (res.y > 1.5) mate = vec3(0.52, 0.48, 0.42);

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float amb = 0.5 + 0.5 * nor.y;
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;
        col = mate * (1.25 * dif * sha + 0.28 * amb);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
