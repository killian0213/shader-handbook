// 第 7 章 · 阶梯实战 · 阶段 4：软阴影
// 只加一个 softShadow：从被照亮的点朝太阳再 march 一次，
// 路上离物体多近，就说明被挡得多厉害。球终于"坐"在地上了。
#define MAX_STEPS 90
#define MAX_DIST  30.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);

float sdSphere(vec3 p, float r) { return length(p) - r; }

vec2 map(vec3 p)
{
    vec2 res = vec2(sdSphere(p - vec3(0.0, 1.0, 0.0), 1.0), 1.0);
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

// 软阴影：SDF 免费送的半影。
// h/(k*t) 是"这条射线看遮挡物张开的角"，角越小挡得越死。
// k 就是太阳的角半径 —— 调大 = 阴影更软。
float softShadow(vec3 ro, vec3 rd)
{
    float res = 1.0;
    float t   = 0.04;              // 起点必须抬离表面，否则第一次采样自己就是 0
    for (int i = 0; i < 24; i++) {
        float h = map(ro + rd * t).x;
        res = min(res, h / (0.055 * t));
        t += clamp(h, 0.06, 0.9);  // 下限防止在表面附近原地踏步，上限防止跨过细物体
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
        vec3 mate = (res.y < 1.5) ? vec3(0.68, 0.64, 0.58)
                                  : vec3(0.26, 0.26, 0.24);

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float amb = 0.5 + 0.5 * nor.y;

        // 只有真的被照到的地方才值得花一次阴影 march。
        // 顺便：dif≈0 的明暗交界处本来就黑，阴影的麻点会被它自动吃掉。
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;

        col = mate * (1.25 * dif * sha + 0.28 * amb);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
