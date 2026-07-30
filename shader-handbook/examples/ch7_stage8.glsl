// 第 7 章 · 阶梯实战 · 阶段 8：传送门环面（Portal Torus）
// 环面隧道 + 内外双色空间 + 简易体积光；比基础球更有趣的收官场景。
// 可选调试：取消下行注释可叠加热力图显示 raymarch 步数（蓝→红 = 便宜→贵）
// #define HEAT_OVERLAY 1
#define MAX_STEPS 96
#define MAX_DIST  28.0

const vec3 LIG = vec3(0.55, 0.62, -0.55);

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

// 环面 + 地面 + 装饰柱
vec2 map(vec3 p)
{
    vec2 res = vec2(1e6, 0.0);

    // 主环面：大半径 1.1，管半径 0.38
    float tor = sdTorus(p - vec3(0.0, 1.05, 0.0), vec2(1.1, 0.38));
    res = vec2(tor, 1.0);

    // 地面
    float fl = p.y;
    if (fl < res.x) res = vec2(fl, 2.0);

    // 小装饰球
    float ds = length(p - vec3(-2.2, 0.28, -1.5)) - 0.22;
    if (ds < res.x) res = vec2(ds, 3.0);

    return res;
}

// 带步数统计的 raymarch（HEAT_OVERLAY 时用）
vec3 raymarch(vec3 ro, vec3 rd, out float steps)
{
    float t = 0.0;
    float m = -1.0;
    steps = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        steps += 1.0;
        vec2 h = map(ro + rd * t);
        if (h.x < 0.0012 * t) { m = h.y; break; }
        if (t > MAX_DIST) break;
        t += h.x * 0.85;
    }
    return vec3(t, m, 0.0);
}

vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.0012;
    return normalize(e.xyy * map(pos + e.xyy).x +
                     e.yyx * map(pos + e.yyx).x +
                     e.yxy * map(pos + e.yxy).x +
                     e.xxx * map(pos + e.xxx).x);
}

float softShadow(vec3 ro, vec3 rd)
{
    float res = 1.0, t = 0.04;
    for (int i = 0; i < 20; i++) {
        float h = map(ro + rd * t).x;
        res = min(res, h / (0.05 * t));
        t += clamp(h, 0.05, 0.7);
        if (res < 0.004 || t > 12.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

float calcAO(vec3 pos, vec3 nor)
{
    float occ = 0.0, sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.02 + 0.15 * float(i) / 4.0;
        occ += (h - map(pos + h * nor).x) * sca;
        sca *= 0.9;
    }
    return clamp(1.0 - 1.6 * occ, 0.0, 1.0);
}

// 隧道内部：另一套「空间」配色 + 缓慢旋转
vec3 portalInterior(vec3 pos, vec3 nor, vec3 rd)
{
    float ang = atan(pos.z, pos.x);
    float u = ang * 0.5 + pos.y * 0.8 + iTime * 0.3;
    vec3 inner = 0.5 + 0.5 * cos(vec3(0.0, 2.0, 4.0) + u * 3.0);
    inner = mix(inner, vec3(0.05, 0.02, 0.12), 0.35);

    float fre = pow(1.0 - clamp(dot(nor, -rd), 0.0, 1.0), 2.0);
    return inner * (0.6 + 0.4 * fre);
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y, 0.0, 1.0);
    vec3 col = mix(vec3(0.55, 0.45, 0.65), vec3(0.08, 0.12, 0.28), pow(h, 0.4));
    col += vec3(0.9, 0.6, 1.0) * pow(clamp(dot(rd, LIG), 0.0, 1.0), 12.0) * 0.3;
    return col;
}

mat3 setCamera(vec3 ro, vec3 ta, float cr)
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    return mat3(cu, cross(cu, cw), cw);
}

vec3 heatColor(float steps)
{
    float t = clamp(steps / float(MAX_STEPS), 0.0, 1.0);
    return mix(vec3(0.1, 0.3, 0.9), mix(vec3(0.2, 0.9, 0.4), vec3(0.95, 0.2, 0.1), t), t);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.32 + 0.14 * sin(iTime * 0.11);
    vec3  ta = vec3(0.0, 1.0, 0.0);
    vec3  ro = vec3(3.8 * sin(an), 1.35, 3.8 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.05 * sin(iTime * 0.2));
    vec3  rd = ca * normalize(vec3(p, 2.0));

    float steps;
    vec3  res = raymarch(ro, rd, steps);
    float t   = res.x;
    float mid = res.y;
    vec3  col = sky(rd);

    if (mid > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);

        vec3 mate;
        if (mid > 2.5) {
            mate = vec3(0.75, 0.55, 0.95);
        } else if (mid > 1.5) {
            mate = vec3(0.14, 0.13, 0.15);
            float chk = mod(floor(pos.x * 2.0) + floor(pos.z * 2.0), 2.0);
            mate *= 1.0 + 0.3 * (chk - 0.5);
        } else {
            // 环面：外壁金属，内壁 portal 色
            float tube = length(vec2(length(pos.xz) - 1.1, pos.y - 1.05));
            bool inside = tube < 0.25 && pos.y > 0.5;
            mate = inside ? portalInterior(pos, nor, rd) : vec3(0.35, 0.38, 0.42);
        }

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;
        float occ = calcAO(pos, nor);
        float skyL = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
        float fre  = pow(clamp(1.0 + dot(rd, nor), 0.0, 1.0), 4.0);

        vec3 lin = vec3(0.0);
        lin += vec3(1.15, 0.95, 1.05) * dif * sha;
        lin += vec3(0.28, 0.32, 0.55) * skyL * occ;
        col = mate * lin;
        col += vec3(0.7, 0.85, 1.0) * fre * occ * 0.5;

        // 隧道入口辉光
        if (mid < 1.5) {
            float glow = exp(-abs(sdTorus(pos - vec3(0.0, 1.05, 0.0), vec2(1.1, 0.38))) * 8.0);
            col += vec3(0.5, 0.3, 0.95) * glow * 0.4;
        }

        col = mix(col, sky(rd), 1.0 - exp(-0.0005 * t * t));
    }

#ifdef HEAT_OVERLAY
    col = mix(col, heatColor(steps), 0.45);
#endif

    col = pow(col * 1.05, vec3(0.4545));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
