// 第 8 章 · 阶梯实战 · 阶段 3：平滑并集 smin 拼角色
// 教学点：min 并集会留下硬棱；smin 在两体接近时"融"成一体，
// 适合有机体、角色、黏液怪。四条胶囊腿 + 身体 + 头，带轻微 idle 动画。
#define MAX_STEPS 90
#define MAX_DIST  30.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);

float sdSphere(vec3 p, float r) { return length(p) - r; }

float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

// 多项式 smin（Inigo Quilez）：k 越大融合区越宽
float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

vec2 map(vec3 p)
{
    float wob = 0.06 * sin(iTime * 1.8);
    float bob = 0.05 * sin(iTime * 2.4);

    // 躯干：略扁的球，上下轻轻浮动
    vec3 bp = p - vec3(0.0, 0.85 + bob, 0.0);
    float body = sdSphere(bp * vec3(1.0, 0.88, 1.0), 0.52);

    // 头：叠在躯干上方，随 wob 左右微摆
    vec3 hp = p - vec3(wob, 1.42 + bob, 0.0);
    float head = sdSphere(hp, 0.32);

    // 四条腿：胶囊从身体底部接到地面，足尖随 iTime 轻颤
    float crea = smin(body, head, 0.18);
    vec2 legOff[4];
    legOff[0] = vec2(-0.28, -0.22);
    legOff[1] = vec2( 0.28, -0.22);
    legOff[2] = vec2(-0.22,  0.26);
    legOff[3] = vec2( 0.22,  0.26);

    for (int i = 0; i < 4; i++) {
        vec2 o = legOff[i];
        float phase = float(i) * 1.57 + iTime * 2.0;
        vec3 foot = vec3(o.x, 0.08 + 0.04 * sin(phase), o.y);
        vec3 hip  = vec3(o.x * 0.6, 0.55 + bob, o.y * 0.6);
        float leg = sdCapsule(p, hip, foot, 0.07);
        crea = smin(crea, leg, 0.12);
    }

    vec2 res = vec2(crea, 1.0);
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

    float an = 0.30 + 0.14 * sin(iTime * 0.14);
    vec3  ta = vec3(0.0, 0.85, 0.0);
    vec3  ro = vec3(3.8 * sin(an), 1.35, 3.8 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec2  res = raymarch(ro, rd);
    float t   = res.x;
    vec3  col = sky(rd);

    if (res.y > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);
        vec3 mate = (res.y < 1.5) ? vec3(0.38, 0.72, 0.55)
                                  : vec3(0.26, 0.26, 0.24);

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float amb = 0.5 + 0.5 * nor.y;
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;
        col = mate * (1.25 * dif * sha + 0.28 * amb);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
