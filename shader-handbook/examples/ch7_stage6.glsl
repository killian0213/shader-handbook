// 第 7 章 · 阶梯实战 · 阶段 6：晨雾与空气透视
// 几何一个都没加。加的是两层雾：贴地的晨雾（高度雾，解析积分）
// 和随距离整体混向天空的空气透视。纵深一下就出来了。
#define MAX_STEPS 90
#define MAX_DIST  30.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);

float sdSphere(vec3 p, float r) { return length(p) - r; }

vec2 map(vec3 p)
{
    vec2 res = vec2(sdSphere(p - vec3(0.0, 1.0, 0.0), 1.0), 1.0);

    float dp = p.y;
    if (dp < res.x) res = vec2(dp, 2.0);

    float ds = sdSphere(p - vec3(-2.30, 0.35, -0.60), 0.35);
    ds = min(ds, sdSphere(p - vec3(-4.40, 0.25, -2.40), 0.25));
    ds = min(ds, sdSphere(p - vec3( 1.50, 0.45, -3.80), 0.45));
    if (ds < res.x) res = vec2(ds, 3.0);

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

float calcAO(vec3 pos, vec3 nor)
{
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.02 + 0.14 * float(i) / 4.0;
        float d = map(pos + h * nor).x;
        occ += (h - d) * sca;
        sca *= 0.92;
    }
    return clamp(1.0 - 1.8 * occ, 0.0, 1.0);
}

// 天空：渐变 + 太阳光晕。太阳本体在画面右外侧，进得来的只有它的大范围晕。
vec3 sky(vec3 rd)
{
    float h = clamp(rd.y, 0.0, 1.0);
    vec3  col = mix(vec3(0.90, 0.74, 0.60), vec3(0.14, 0.30, 0.62), pow(h, 0.45));
    float s = clamp(dot(rd, LIG), 0.0, 1.0);
    col += vec3(1.00, 0.52, 0.22) * pow(s,  4.0) * 0.60;
    col += vec3(1.00, 0.80, 0.55) * pow(s, 40.0) * 0.80;
    return col;
}

// 晨雾：密度随高度指数衰减 exp(-y/H)，沿射线可以【解析积分】出来 ——
// 不必在雾里再 march 一遍，一次 exp 就够。
float mist(vec3 ro, vec3 rd, float t)
{
    const float H = 0.60;                       // 雾的特征高度
    const float D = 0.45;                       // y=0 处的密度
    float ky = rd.y / H;
    // rd.y→0 时 (1-e^-x)/x 是 0/0，用一阶展开 t 顶上
    float s  = (abs(ky) < 1e-3) ? t : (1.0 - exp(-ky * t)) / ky;
    return 1.0 - exp(-D * exp(-ro.y / H) * s);
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

    float an = 0.28 + 0.10 * sin(iTime * 0.13);
    vec3  ta = vec3(0.0, 0.95, 0.0);
    vec3  ro = vec3(4.2 * sin(an), 1.45, 4.2 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec2  res = raymarch(ro, rd);
    float t   = res.x;
    vec3  col = sky(rd);

    if (res.y > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);

        vec3 mate = vec3(0.68, 0.64, 0.58);
        if (res.y > 2.5) {
            mate = vec3(0.13, 0.15, 0.18);
        } else if (res.y > 1.5) {
            mate = vec3(0.26, 0.26, 0.24);
            float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
            mate *= 1.0 + 0.45 * (chk - 0.5) * exp(-0.02 * t * t);
        }

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;
        float occ = calcAO(pos, nor);

        float skyL = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
        float bou  = clamp(0.3 - 0.3 * nor.y, 0.0, 1.0);

        vec3 lin = vec3(0.0);
        lin += vec3(1.30, 1.02, 0.70) * dif * sha;
        lin += vec3(0.26, 0.36, 0.58) * skyL * occ;
        lin += vec3(0.26, 0.20, 0.14) * bou  * occ;
        col = mate * lin;

        // --- 第一层：贴地晨雾。朝太阳的一侧更亮（前向散射）---
        vec3 mistCol = mix(vec3(0.80, 0.80, 0.84), vec3(1.05, 0.82, 0.58),
                           pow(clamp(dot(rd, LIG), 0.0, 1.0), 3.0));
        col = mix(col, mistCol, mist(ro, rd, t));

        // --- 第二层：空气透视。t³ 让近处几乎不受影响、远处迅速吃满。
        //     终点色用的是同一个 sky(rd)，所以地面和天空在地平线上无缝接上。---
        col = mix(col, sky(rd), 1.0 - exp(-0.0007 * t * t * t));
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
