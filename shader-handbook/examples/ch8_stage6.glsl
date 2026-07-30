// 第 8 章 · 阶梯实战 · 阶段 6：微型神庙（综合较难）
// 教学点：台阶 + RepLim 柱列 + 墙体/山墙 + 穹顶，材质 id 分色。
// 循序：先搭台阶与墙 → 再加柱 → 最后加穹顶。
#define MAX_STEPS 100
#define MAX_DIST  40.0

const vec3 LIG = normalize(vec3(0.55, 0.65, -0.45));

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdCylY(vec3 p, float h, float r)
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdSphere(vec3 p, float r) { return length(p) - r; }

vec2 opU(vec2 a, vec2 b) { return (a.x < b.x) ? a : b; }

vec2 map(vec3 p)
{
    vec2 res = vec2(p.y, 6.0); // 地面

    // 三级台阶
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float st = sdBox(p - vec3(0.0, 0.06 + fi * 0.12, 0.0),
                         vec3(2.4 - fi * 0.28, 0.06, 1.55 - fi * 0.18));
        res = opU(res, vec2(st, 1.0));
    }

    // 主体墙
    float wall = sdBox(p - vec3(0.0, 1.05, 0.15), vec3(1.35, 0.72, 0.55));
    res = opU(res, vec2(wall, 3.0));

    // 山墙（扁盒）
    float ped = sdBox(p - vec3(0.0, 1.85, 0.15), vec3(1.50, 0.14, 0.62));
    res = opU(res, vec2(ped, 4.0));

    // 前廊四柱：有限位置（不用无限 mod，避免乱柱）
    for (int i = 0; i < 4; i++) {
        float x = mix(-1.05, 1.05, float(i) / 3.0);
        float col = sdCylY(p - vec3(x, 1.05, 0.85), 0.72, 0.09);
        res = opU(res, vec2(col, 2.0));
    }

    // 穹顶：球心抬高，只取上半
    vec3 dp = p - vec3(0.0, 1.95, 0.15);
    float dome = sdSphere(dp, 0.85);
    dome = max(dome, -dp.y); // 只要 y>=0 的半球
    res = opU(res, vec2(dome, 5.0));

    return res;
}

vec2 raymarch(vec3 ro, vec3 rd)
{
    float t = 0.0, m = -1.0;
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
    float res = 1.0, t = 0.04;
    for (int i = 0; i < 28; i++) {
        float h = map(ro + rd * t).x;
        res = min(res, h / (0.06 * t));
        t += clamp(h, 0.05, 0.8);
        if (res < 0.003 || t > 18.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y, 0.0, 1.0);
    return mix(vec3(0.92, 0.76, 0.58), vec3(0.30, 0.48, 0.78), pow(h, 0.55));
}

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

vec3 matColor(float id)
{
    if (id < 1.5) return vec3(0.55, 0.50, 0.44);
    if (id < 2.5) return vec3(0.78, 0.74, 0.66);
    if (id < 3.5) return vec3(0.62, 0.58, 0.52);
    if (id < 4.5) return vec3(0.48, 0.42, 0.38);
    if (id < 5.5) return vec3(0.85, 0.80, 0.72);
    return vec3(0.28, 0.30, 0.28);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float an = 0.85 + 0.20 * sin(iTime * 0.12);
    vec3  ta = vec3(0.0, 1.1, 0.2);
    vec3  ro = vec3(5.5 * sin(an), 2.2, 5.5 * cos(an));
    vec3  rd = setCamera(ro, ta) * normalize(vec3(p, 2.1));

    vec2  hit = raymarch(ro, rd);
    vec3  col = sky(rd);
    if (hit.y > 0.0) {
        vec3 pos = ro + rd * hit.x;
        vec3 nor = calcNormal(pos);
        vec3 mate = matColor(hit.y);
        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.02, LIG) : 0.0;
        float amb = 0.22 + 0.28 * nor.y;
        col = mate * (1.35 * dif * sha + amb);
        // 穹顶一点天光反射感
        if (hit.y > 4.5 && hit.y < 5.5)
            col += sky(reflect(rd, nor)) * 0.12;
    }
    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
