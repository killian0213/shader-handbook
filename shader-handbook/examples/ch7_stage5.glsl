// 第 7 章 · 阶梯实战 · 阶段 5：环境光遮蔽 + 把"环境"补齐
// 到上一阶段，除了太阳以外的光都是一个没有方向的常数。这一步把它拆成
// 天空的冷光 + 地面反弹的暖光，再用 AO 决定每个点能看到多少环境。
// 顺手往场景里放三颗远去的小球，和一层地面棋盘 —— 下一阶段的雾需要参照物。
#define MAX_STEPS 90
#define MAX_DIST  30.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);

float sdSphere(vec3 p, float r) { return length(p) - r; }

vec2 map(vec3 p)
{
    vec2 res = vec2(sdSphere(p - vec3(0.0, 1.0, 0.0), 1.0), 1.0);

    float dp = p.y;
    if (dp < res.x) res = vec2(dp, 2.0);

    // 三颗越来越远的小球：给纵深一把可读的尺子
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

// 环境光遮蔽：沿法线往外探几步，
// 把"该走到 h 却发现最近表面只有 d"的亏空累加起来 —— 亏得越多，越是缝里。
float calcAO(vec3 pos, vec3 nor)
{
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.02 + 0.14 * float(i) / 4.0;
        float d = map(pos + h * nor).x;
        occ += (h - d) * sca;
        sca *= 0.92;               // 越远的采样权重越低
    }
    return clamp(1.0 - 1.8 * occ, 0.0, 1.0);
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

        vec3 mate = vec3(0.68, 0.64, 0.58);                  // 主球：浅暖瓷
        if (res.y > 2.5) {
            mate = vec3(0.13, 0.15, 0.18);                   // 小球：深板岩
        } else if (res.y > 1.5) {
            mate = vec3(0.26, 0.26, 0.24);                   // 地面
            // 棋盘：只在近处显形（exp 衰减），远处让它自己消失，不留摩尔纹
            float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
            mate *= 1.0 + 0.45 * (chk - 0.5) * exp(-0.02 * t * t);
        }

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;
        float occ = calcAO(pos, nor);

        float skyL = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);     // 朝上 → 看见天
        float bou  = clamp(0.3 - 0.3 * nor.y, 0.0, 1.0);     // 朝下 → 接到地面的反弹

        // 三个光源分开算再相加。暖太阳 + 冷天光是整张图立体感的真正来源。
        vec3 lin = vec3(0.0);
        lin += vec3(1.30, 1.02, 0.70) * dif * sha;
        lin += vec3(0.26, 0.36, 0.58) * skyL * occ;
        lin += vec3(0.26, 0.20, 0.14) * bou  * occ;
        col = mate * lin;
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
